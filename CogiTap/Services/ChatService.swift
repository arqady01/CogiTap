//
//  ChatService.swift
//  CogiTap
//
//  Created by mengfs on 11/1/25.
//

import Foundation
import SwiftData

@MainActor
final class ChatService: ObservableObject {
    @Published var isStreaming = false
    @Published var currentStreamingMessage: Message?
    
    private enum StreamResult {
        case finished
        case toolCalls([UnifiedToolCall])
    }
    
    private let memoryService = MemoryService.shared
    private let mcpManager = MCPManager.shared
    private var streamTask: Task<Void, Never>?
    private var mcpRegistry = MCPToolRegistry()
    
    // MARK: - Public API
    
    func sendMessage(
        content: String,
        conversation: Conversation,
        model: ChatModel,
        modelContext: ModelContext
    ) async throws {
        guard model.provider != nil else {
            throw APIAdapterError.networkError("模型未关联到任何服务商")
        }
        
        let userMessage = Message(role: .user, content: content, conversation: conversation)
        modelContext.insert(userMessage)
        
        let assistantMessage = Message(
            role: .assistant,
            content: "",
            isStreaming: true,
            conversation: conversation
        )
        modelContext.insert(assistantMessage)
        currentStreamingMessage = assistantMessage
        
        try modelContext.save()
        
        try await sendMessageWithExistingMessages(
            userMessage: userMessage,
            assistantMessage: assistantMessage,
            conversation: conversation,
            model: model,
            modelContext: modelContext
        )
    }
    
    func sendMessageWithExistingMessages(
        userMessage: Message,
        assistantMessage: Message,
        conversation: Conversation,
        model: ChatModel,
        modelContext: ModelContext
    ) async throws {
        guard let provider = model.provider else {
            throw NSError(domain: "ChatService", code: -1, userInfo: [NSLocalizedDescriptionKey: "模型没有关联的服务商"])
        }
        
        streamTask?.cancel()
        streamTask = nil
        currentStreamingMessage = assistantMessage
        
        let adapter = APIAdapterFactory.createAdapter(for: provider)
        let shouldStream = conversation.isStreamingEnabled
        isStreaming = true
        
        if shouldStream {
            streamTask = Task { [weak self] in
                guard let self else { return }
                defer {
                    Task { @MainActor in
                        self.isStreaming = false
                        self.currentStreamingMessage = nil
                        self.streamTask = nil
                    }
                }
                do {
                    try await runStreamingSequence(
                        adapter: adapter,
                        conversation: conversation,
                        model: model,
                        assistantMessage: assistantMessage,
                        lastUserMessage: userMessage,
                        modelContext: modelContext
                    )
                } catch {
                    await MainActor.run {
                        assistantMessage.content = "错误: \(error.localizedDescription)"
                        assistantMessage.isStreaming = false
                        try? modelContext.save()
                    }
                }
            }
        } else {
            streamTask = Task { [weak self] in
                guard let self else { return }
                defer {
                    Task { @MainActor in
                        self.isStreaming = false
                        self.currentStreamingMessage = nil
                        self.streamTask = nil
                    }
                }
                await self.runNonStreamingSequence(
                    adapter: adapter,
                    conversation: conversation,
                    model: model,
                    assistantMessage: assistantMessage,
                    lastUserMessage: userMessage,
                    modelContext: modelContext
                )
            }
        }
    }
    
    func stopGeneration() {
        streamTask?.cancel()
        streamTask = nil
        isStreaming = false
        
        if let message = currentStreamingMessage {
            message.isStreaming = false
        }
        currentStreamingMessage = nil
    }
    
    // MARK: - Streaming flow
    
    private func runStreamingSequence(
        adapter: APIAdapter,
        conversation: Conversation,
        model: ChatModel,
        assistantMessage: Message,
        lastUserMessage: Message,
        modelContext: ModelContext
    ) async throws {
        let excludeIds: Set<UUID> = [assistantMessage.id]
        var continueLoop = true
        var safetyCounter = 0
        let maxIterations = 4
        
        while continueLoop && safetyCounter < maxIterations {
            safetyCounter += 1
            let request = makeChatRequest(
                conversation: conversation,
                model: model,
                excludeIds: excludeIds,
                lastUserQuery: lastUserMessage.content,
                modelContext: modelContext
            )
            let result = try await streamOnce(
                adapter: adapter,
                request: request,
                message: assistantMessage,
                modelContext: modelContext
            )
            switch result {
            case .finished:
                continueLoop = false
            case .toolCalls(let calls):
                try await handleToolCalls(
                    calls,
                    conversation: conversation,
                    assistantPlaceholder: assistantMessage,
                    modelContext: modelContext
                )
                assistantMessage.content = ""
                assistantMessage.reasoningContent = nil
                assistantMessage.isStreaming = true
                try? modelContext.save()
            }
        }
    }
    
    private func streamOnce(
        adapter: APIAdapter,
        request: UnifiedChatRequest,
        message: Message,
        modelContext: ModelContext
    ) async throws -> StreamResult {
        let urlRequest = try adapter.convertRequest(request)
        let (asyncBytes, _) = try await URLSession.shared.bytes(for: urlRequest)
        
        var contentBuffer = ""
        var reasoningBuffer = ""
        var accumulators: [Int: (id: String?, name: String?, arguments: String)] = [:]
        
        for try await line in asyncBytes.lines {
            if Task.isCancelled { break }
            guard let chunk = try adapter.parseStreamChunk(line) else { continue }
            
            if let deltas = chunk.toolCallDeltas {
                for delta in deltas {
                    let key = delta.index ?? 0
                    var accumulator = accumulators[key] ?? (id: nil, name: nil, arguments: "")
                    if let id = delta.id { accumulator.id = id }
                    if let name = delta.name {
                        accumulator.name = name
                        let status = statusText(for: name)
                        await MainActor.run {
                            message.content = status
                            message.isStreaming = false
                            try? modelContext.save()
                        }
                    }
                    if let arguments = delta.arguments {
                        accumulator.arguments.append(arguments)
                    }
                    accumulators[key] = accumulator
                }
            }
            
            if let content = chunk.content, !content.isEmpty {
                contentBuffer += content
                await MainActor.run {
                    message.content = contentBuffer
                    message.isStreaming = true
                    try? modelContext.save()
                }
            }
            
            if let reasoning = chunk.reasoningContent {
                reasoningBuffer += reasoning
                await MainActor.run {
                    message.reasoningContent = reasoningBuffer
                    try? modelContext.save()
                }
            }
            
            if chunk.isFinished {
                break
            }
        }
        
        await MainActor.run {
            message.isStreaming = false
            try? modelContext.save()
        }
        
        let toolCalls: [UnifiedToolCall] = accumulators
            .sorted { $0.key < $1.key }
            .compactMap { _, value in
                guard let name = value.name else { return nil }
                let identifier = value.id ?? UUID().uuidString
                return UnifiedToolCall(id: identifier, name: name, arguments: value.arguments)
            }
        
        if !toolCalls.isEmpty {
            return .toolCalls(toolCalls)
        }
        return .finished
    }
    
    // MARK: - Non streaming flow
    
    private func runNonStreamingSequence(
        adapter: APIAdapter,
        conversation: Conversation,
        model: ChatModel,
        assistantMessage: Message,
        lastUserMessage: Message,
        modelContext: ModelContext
    ) async {
        let excludeIds: Set<UUID> = [assistantMessage.id]
        var continueLoop = true
        var safetyCounter = 0
        let maxIterations = 4
        
        while continueLoop && safetyCounter < maxIterations {
            safetyCounter += 1
            let request = makeChatRequest(
                conversation: conversation,
                model: model,
                excludeIds: excludeIds,
                lastUserQuery: lastUserMessage.content,
                modelContext: modelContext
            )
            do {
                let urlRequest = try adapter.convertRequest(request)
                let (data, _) = try await URLSession.shared.data(for: urlRequest)
                let response = try adapter.parseResponse(data)
                
                if !response.toolCalls.isEmpty {
                    try await handleToolCalls(
                        response.toolCalls,
                        conversation: conversation,
                        assistantPlaceholder: assistantMessage,
                        modelContext: modelContext
                    )
                    assistantMessage.content = ""
                    assistantMessage.reasoningContent = nil
                    try? modelContext.save()
                    continue
                }
                
                assistantMessage.content = response.content
                assistantMessage.reasoningContent = response.reasoningContent
                assistantMessage.isStreaming = false
                try? modelContext.save()
                continueLoop = false
            } catch {
                assistantMessage.content = "错误: \(error.localizedDescription)"
                assistantMessage.isStreaming = false
                try? modelContext.save()
                continueLoop = false
            }
        }
    }
    
    // MARK: - Tool handling
    
    private func handleToolCalls(
        _ toolCalls: [UnifiedToolCall],
        conversation: Conversation,
        assistantPlaceholder: Message,
        modelContext: ModelContext
    ) async throws {
        guard !toolCalls.isEmpty else { return }
        
        for call in toolCalls {
            let assistantCallMessage = Message(
                role: .assistant,
                content: "",
                toolCallId: call.id,
                toolCallName: call.name,
                toolCallArguments: call.arguments,
                conversation: conversation
            )
            modelContext.insert(assistantCallMessage)
            
            let toolResult: String
            if MemoryToolName(rawValue: call.name) != nil {
                toolResult = executeMemoryTool(
                    name: call.name,
                    argumentsJSON: call.arguments,
                    conversation: conversation,
                    modelContext: modelContext
                )
            } else {
                toolResult = await executeRemoteTool(
                    toolName: call.name,
                    argumentsJSON: call.arguments
                )
            }
            
            let toolMessage = Message(
                role: .tool,
                content: toolResult,
                toolCallId: call.id,
                conversation: conversation
            )
            modelContext.insert(toolMessage)
            try? modelContext.save()
        }
        
        assistantPlaceholder.isStreaming = true
        try? modelContext.save()
    }
    
    private func executeMemoryTool(
        name: String,
        argumentsJSON: String,
        conversation: Conversation,
        modelContext: ModelContext
    ) -> String {
        let config = memoryService.getOrCreateConfig(using: modelContext)
        guard config.isMemoryEnabled else {
            return "记忆功能已关闭"
        }
        guard let data = argumentsJSON.data(using: .utf8),
              let payload = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return "参数解析失败"
        }

        switch MemoryToolName(rawValue: name) {
        case .saveMemory:
            let content = payload["content"] as? String ?? ""
            let saved = memoryService.saveMemory(
                content: content,
                conversation: conversation,
                context: modelContext
            )
            return saved ? "记忆已保存" : "重复内容，未保存"
        case .retrieveMemory:
            let keywords = payload["keywords"] as? String ?? ""
            let result = memoryService.retrieveMemories(
                for: keywords,
                conversation: conversation,
                context: modelContext
            )
            return result.isEmpty ? "未找到相关记忆" : "记忆内容：\n\(result)"
        case .updateMemory:
            let original = payload["original"] as? String ?? ""
            let replacement = payload["replacement"] as? String ?? ""
            return memoryService.updateMemory(
                originalContent: original,
                newContent: replacement,
                context: modelContext
            )
        case .none:
            return "未知的工具调用"
        }
    }
    
    private func executeRemoteTool(
        toolName: String,
        argumentsJSON: String
    ) async -> String {
        guard let registered = mcpRegistry.registeredTool(for: toolName) else {
            return "未找到对应的 MCP 工具"
        }
        do {
            let output = try await mcpManager.invokeTool(
                identifier: registered.descriptor.identifier,
                argumentsJSON: argumentsJSON
            )
            return output.isEmpty ? "MCP 工具执行完成" : output
        } catch {
            return "MCP 工具调用失败: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Request builder
    
    private func makeChatRequest(
        conversation: Conversation,
        model: ChatModel,
        excludeIds: Set<UUID>,
        lastUserQuery: String,
        modelContext: ModelContext
    ) -> UnifiedChatRequest {
        let historyMessages = fetchMessages(for: conversation, modelContext: modelContext)
            .filter { !excludeIds.contains($0.id) }
        
        var messages: [UnifiedMessage] = []
        let config = memoryService.getOrCreateConfig(using: modelContext)
        var systemPrompt = conversation.systemPrompt
        let memoryBlock = memoryService.retrieveMemories(
            for: lastUserQuery,
            conversation: conversation,
            context: modelContext
        )
        if !memoryBlock.isEmpty {
            let module = """
            # 记忆
            在回答用户问题时，请尽量忘记大部分不相关的信息。只有当用户提供的信息与当前问题或对话内容非常相关时，才记住这些信息并加以使用。
            信息：
            \(memoryBlock)
            
            如果用户更新了记忆，你可以调用记忆工具重新记忆。
            """
            if systemPrompt.isEmpty {
                systemPrompt = module
            } else {
                systemPrompt += "\n\n" + module
            }
        }
        if !systemPrompt.isEmpty {
            messages.append(UnifiedMessage(role: "system", content: systemPrompt))
        }
        
        messages.append(contentsOf: historyMessages.map(convertMessage))
        
        var functionTools: [FunctionTool] = []
        var toolChoice: ToolChoice = .none
        if let provider = model.provider, providerSupportsTools(provider) {
            let memoryResult = MemoryToolBuilder.makeTools(using: config)
            functionTools = memoryResult.tools
            toolChoice = memoryResult.choice
            
            let remoteTools = mcpRegistry.install(
                remote: mcpManager.registeredTools(for: conversation)
            )
            functionTools.append(contentsOf: remoteTools)
            if !remoteTools.isEmpty {
                toolChoice = .auto
            }
            if functionTools.isEmpty {
                toolChoice = .none
            }
        } else {
            _ = mcpRegistry.install(remote: [])
        }
        
        return UnifiedChatRequest(
            messages: messages,
            temperature: conversation.temperature,
            stream: conversation.isStreamingEnabled,
            model: model.modelName,
            functionTools: functionTools,
            toolChoice: toolChoice
        )
    }
    
    private func convertMessage(_ message: Message) -> UnifiedMessage {
        switch message.messageRole {
        case .tool:
            return UnifiedMessage(role: message.role, content: message.content, toolCallId: message.toolCallId)
        case .assistant:
            if let name = message.toolCallName,
               let id = message.toolCallId,
               let arguments = message.toolCallArguments {
                let call = UnifiedToolCall(id: id, name: name, arguments: arguments)
                return UnifiedMessage(role: message.role, content: message.content, toolCalls: [call])
            }
            fallthrough
        default:
            return UnifiedMessage(role: message.role, content: message.content)
        }
    }
    
    private func fetchMessages(
        for conversation: Conversation,
        modelContext: ModelContext
    ) -> [Message] {
        let cutoffDate = conversation.contextResetAt
        if let loaded = conversation.messages {
            return filterMessages(loaded.sorted { $0.createdAt < $1.createdAt }, cutoffDate: cutoffDate)
        }
        let descriptor = FetchDescriptor<Message>()
        let fetched = (try? modelContext.fetch(descriptor)) ?? []
        return filterMessages(
            fetched
            .filter { $0.conversation?.id == conversation.id }
            .sorted { $0.createdAt < $1.createdAt },
            cutoffDate: cutoffDate
        )
    }
    
    private func filterMessages(_ messages: [Message], cutoffDate: Date?) -> [Message] {
        guard let cutoffDate else { return messages }
        return messages.filter { $0.createdAt >= cutoffDate }
    }
    
    private func providerSupportsTools(_ provider: APIProvider) -> Bool {
        switch provider.type {
        case .openai, .openrouter, .custom:
            return true
        case .anthropic, .gemini:
            return false
        }
    }
    
    private func statusText(for toolName: String) -> String {
        if toolName.hasPrefix("mcp::") {
            return "正在调用 MCP 工具..."
        }
        switch MemoryToolName(rawValue: toolName) {
        case .saveMemory:
            return "正在记忆..."
        case .retrieveMemory:
            return "正在回忆..."
        case .updateMemory:
            return "正在更新记忆..."
        case .none:
            return "正在处理工具调用..."
        }
    }
}
