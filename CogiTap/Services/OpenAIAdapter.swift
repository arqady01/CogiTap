//
//  OpenAIAdapter.swift
//  CogiTap
//
//  Created by mengfs on 11/1/25.
//

import Foundation

class OpenAIAdapter: BaseAPIAdapter {
    
    override func convertRequest(_ request: UnifiedChatRequest) throws -> URLRequest {
        let url: URL
        
        // 获取最终的URL
        if provider.type == .openai {
            url = URL(string: "https://api.openai.com/v1/chat/completions")!
        } else if provider.type == .openrouter {
            url = URL(string: "https://openrouter.ai/api/v1/chat/completions")!
        } else {
            // 自定义端点
            guard let customURL = URL(string: provider.getFinalBaseURL()) else {
                throw APIAdapterError.invalidURL
            }
            url = customURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(provider.apiKey)", forHTTPHeaderField: "Authorization")
        
        // OpenRouter需要额外的header
        if provider.type == .openrouter {
            urlRequest.setValue("CogiTap", forHTTPHeaderField: "HTTP-Referer")
            urlRequest.setValue("CogiTap/1.0", forHTTPHeaderField: "X-Title")
        }
        
        // 构建请求体
        var body: [String: Any] = [
            "model": request.model,
            "messages": request.messages.map { message -> [String: Any] in
                var payload: [String: Any] = [
                    "role": message.role,
                    "content": message.content
                ]
                if let toolCalls = message.toolCalls, !toolCalls.isEmpty {
                    payload["tool_calls"] = toolCalls.enumerated().map { index, call in
                        return [
                            "id": call.id,
                            "type": "function",
                            "index": index,
                            "function": [
                                "name": call.name,
                                "arguments": call.arguments
                            ]
                        ]
                    }
                }
                if message.role == "tool", let toolCallId = message.toolCallId {
                    payload["tool_call_id"] = toolCallId
                }
                return payload
            },
            "temperature": request.temperature,
            "stream": request.stream
        ]
        
        if !request.functionTools.isEmpty {
            body["tools"] = request.functionTools.map { tool in
                [
                    "type": "function",
                    "function": [
                        "name": tool.name,
                        "description": tool.description,
                        "parameters": tool.parameters
                    ]
                ]
            }
            switch request.toolChoice {
            case .auto:
                body["tool_choice"] = "auto"
            case .none:
                body["tool_choice"] = "none"
            }
        }

        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: body)

        return urlRequest
    }
    
    override func parseStreamChunk(_ line: String) throws -> StreamChunk? {
        // 跳过空行和注释
        guard !line.isEmpty, line.hasPrefix("data: ") else {
            return nil
        }
        
        let data = line.dropFirst(6) // 移除 "data: "
        
        // 检查是否是结束标记
        if data == "[DONE]" {
            return StreamChunk(
                content: nil,
                reasoningContent: nil,
                toolCallDeltas: nil,
                finishReason: nil,
                isFinished: true
            )
        }
        
        // 解析JSON
        guard let jsonData = data.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let delta = firstChoice["delta"] as? [String: Any] else {
            return nil
        }
        
        let content = delta["content"] as? String
        let reasoningContent = delta["reasoning_content"] as? String
        let finishReason = firstChoice["finish_reason"] as? String
        var toolDeltas: [ToolCallDelta]? = nil
        if let toolCalls = delta["tool_calls"] as? [[String: Any]] {
            toolDeltas = toolCalls.map { item in
                let id = item["id"] as? String
                let index = item["index"] as? Int
                var name: String?
                var arguments: String?
                if let functionDict = item["function"] as? [String: Any] {
                    name = functionDict["name"] as? String
                    arguments = functionDict["arguments"] as? String
                }
                return ToolCallDelta(id: id, name: name, arguments: arguments, index: index)
            }
        }
        
        return StreamChunk(
            content: content,
            reasoningContent: reasoningContent,
            toolCallDeltas: toolDeltas,
            finishReason: finishReason,
            isFinished: finishReason != nil
        )
    }
    
    override func parseResponse(_ data: Data) throws -> UnifiedChatResponse {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any] else {
            throw APIAdapterError.decodingError("无法解析响应")
        }
        
        let content = message["content"] as? String ?? ""
        
        let reasoningContent = message["reasoning_content"] as? String
        let finishReason = firstChoice["finish_reason"] as? String
        let toolCallsPayload = message["tool_calls"] as? [[String: Any]] ?? []
        let toolCalls: [UnifiedToolCall] = toolCallsPayload.compactMap { payload in
            guard
                let id = payload["id"] as? String,
                let functionDict = payload["function"] as? [String: Any],
                let name = functionDict["name"] as? String,
                let arguments = functionDict["arguments"] as? String
            else {
                return nil
            }
            return UnifiedToolCall(id: id, name: name, arguments: arguments)
        }

        return UnifiedChatResponse(
            content: content,
            reasoningContent: reasoningContent,
            finishReason: finishReason,
            toolCalls: toolCalls
        )
    }
    
    override func fetchModels() async throws -> [String] {
        let url: URL
        
        if provider.type == .openai {
            url = URL(string: "https://api.openai.com/v1/models")!
        } else if provider.type == .openrouter {
            url = URL(string: "https://openrouter.ai/api/v1/models")!
        } else {
            url = URL(string: provider.getModelsEndpoint())!
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(provider.apiKey)", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let modelsArray = json["data"] as? [[String: Any]] else {
            throw APIAdapterError.decodingError("无法解析模型列表")
        }
        
        return modelsArray.compactMap { $0["id"] as? String }
    }
}
