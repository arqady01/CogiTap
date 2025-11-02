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
        let body: [String: Any] = [
            "model": request.model,
            "messages": request.messages.map { ["role": $0.role, "content": $0.content] },
            "temperature": request.temperature,
            "stream": request.stream
        ]
        
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
            return StreamChunk(content: nil, reasoningContent: nil, isFinished: true)
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
        
        return StreamChunk(
            content: content,
            reasoningContent: reasoningContent,
            isFinished: finishReason != nil
        )
    }
    
    override func parseResponse(_ data: Data) throws -> UnifiedChatResponse {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw APIAdapterError.decodingError("无法解析响应")
        }
        
        let reasoningContent = message["reasoning_content"] as? String
        let finishReason = firstChoice["finish_reason"] as? String
        
        return UnifiedChatResponse(
            content: content,
            reasoningContent: reasoningContent,
            finishReason: finishReason
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
