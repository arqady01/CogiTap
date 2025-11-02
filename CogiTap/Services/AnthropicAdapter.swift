//
//  AnthropicAdapter.swift
//  CogiTap
//
//  Created by mengfs on 11/1/25.
//

import Foundation

class AnthropicAdapter: BaseAPIAdapter {
    
    override func convertRequest(_ request: UnifiedChatRequest) throws -> URLRequest {
        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else {
            throw APIAdapterError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(provider.apiKey, forHTTPHeaderField: "x-api-key")
        urlRequest.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        
        // 提取system消息
        var systemMessage: String?
        var userMessages: [[String: String]] = []
        
        for message in request.messages {
            if message.role == "system" {
                systemMessage = message.content
            } else {
                userMessages.append(["role": message.role, "content": message.content])
            }
        }
        
        // 构建请求体
        var body: [String: Any] = [
            "model": request.model,
            "messages": userMessages,
            "max_tokens": 4096,
            "temperature": request.temperature,
            "stream": request.stream
        ]
        
        if let system = systemMessage {
            body["system"] = system
        }
        
        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        return urlRequest
    }
    
    override func parseStreamChunk(_ line: String) throws -> StreamChunk? {
        // Anthropic的流式响应格式
        guard !line.isEmpty, line.hasPrefix("data: ") else {
            return nil
        }
        
        let data = line.dropFirst(6)
        
        guard let jsonData = data.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let type = json["type"] as? String else {
            return nil
        }
        
        switch type {
        case "content_block_delta":
            if let delta = json["delta"] as? [String: Any],
               let text = delta["text"] as? String {
                return StreamChunk(content: text, reasoningContent: nil, isFinished: false)
            }
        case "message_stop":
            return StreamChunk(content: nil, reasoningContent: nil, isFinished: true)
        default:
            break
        }
        
        return nil
    }
    
    override func parseResponse(_ data: Data) throws -> UnifiedChatResponse {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let firstContent = content.first,
              let text = firstContent["text"] as? String else {
            throw APIAdapterError.decodingError("无法解析响应")
        }
        
        let finishReason = json["stop_reason"] as? String
        
        return UnifiedChatResponse(
            content: text,
            reasoningContent: nil,
            finishReason: finishReason
        )
    }
    
    override func fetchModels() async throws -> [String] {
        // Anthropic的模型列表API
        guard let url = URL(string: "https://api.anthropic.com/v1/models") else {
            throw APIAdapterError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue(provider.apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let modelsArray = json["data"] as? [[String: Any]] else {
            // 如果API不可用，返回预设的模型列表
            return [
                "claude-3-5-sonnet-20241022",
                "claude-3-5-haiku-20241022",
                "claude-3-opus-20240229",
                "claude-3-sonnet-20240229",
                "claude-3-haiku-20240307"
            ]
        }
        
        return modelsArray.compactMap { $0["id"] as? String }
    }
}
