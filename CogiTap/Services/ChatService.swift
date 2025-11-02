//
//  ChatService.swift
//  CogiTap
//
//  Created by mengfs on 11/1/25.
//

import Foundation
import SwiftData

@MainActor
class ChatService: ObservableObject {
    @Published var isStreaming = false
    @Published var currentStreamingMessage: Message?
    
    private var streamTask: Task<Void, Never>?
    
    // 发送消息
    func sendMessage(
        content: String,
        conversation: Conversation,
        model: ChatModel,
        modelContext: ModelContext
    ) async throws {
        guard model.provider != nil else {
            throw APIAdapterError.networkError("模型未关联到任何服务商")
        }
        
        // 创建用户消息
        let userMessage = Message(role: .user, content: content, conversation: conversation)
        modelContext.insert(userMessage)
        
        // 创建助手消息（用于流式输出）
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
    
    // 使用已创建的消息发送请求
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
        
        currentStreamingMessage = assistantMessage
        
        // 准备消息历史
        var messages: [UnifiedMessage] = []
        
        // 添加system prompt
        if !conversation.systemPrompt.isEmpty {
            messages.append(UnifiedMessage(role: "system", content: conversation.systemPrompt))
        }
        
        // 添加历史消息
        for msg in conversation.sortedMessages {
            if msg.id != assistantMessage.id {
                messages.append(UnifiedMessage(role: msg.role, content: msg.content))
            }
        }
        
        // 创建请求
        let request = UnifiedChatRequest(
            messages: messages,
            temperature: conversation.temperature,
            stream: true,
            model: model.modelName
        )
        
        // 获取适配器
        let adapter = APIAdapterFactory.createAdapter(for: provider)
        
        // 发送请求
        isStreaming = true
        
        streamTask = Task {
            do {
                try await streamResponse(adapter: adapter, request: request, message: assistantMessage, modelContext: modelContext)
            } catch {
                assistantMessage.content = "错误: \(error.localizedDescription)"
                assistantMessage.isStreaming = false
                try? modelContext.save()
            }
            
            isStreaming = false
            currentStreamingMessage = nil
        }
    }
    
    // 停止生成
    func stopGeneration() {
        streamTask?.cancel()
        streamTask = nil
        isStreaming = false
        
        if let message = currentStreamingMessage {
            message.isStreaming = false
        }
        currentStreamingMessage = nil
    }
    
    // 流式响应处理
    private func streamResponse(
        adapter: APIAdapter,
        request: UnifiedChatRequest,
        message: Message,
        modelContext: ModelContext
    ) async throws {
        let urlRequest = try adapter.convertRequest(request)
        
        let (asyncBytes, _) = try await URLSession.shared.bytes(for: urlRequest)
        
        var contentBuffer = ""
        var reasoningBuffer = ""
        
        for try await line in asyncBytes.lines {
            // 检查是否被取消
            if Task.isCancelled {
                break
            }
            
            if let chunk = try adapter.parseStreamChunk(line) {
                if chunk.isFinished {
                    break
                }
                
                if let content = chunk.content {
                    contentBuffer += content
                    await MainActor.run {
                        message.content = contentBuffer
                    }
                }
                
                if let reasoning = chunk.reasoningContent {
                    reasoningBuffer += reasoning
                    await MainActor.run {
                        message.reasoningContent = reasoningBuffer
                    }
                }
                
                // 在主线程保存，确保UI更新
                await MainActor.run {
                    try? modelContext.save()
                }
            }
        }
        
        message.isStreaming = false
        try modelContext.save()
    }
}
