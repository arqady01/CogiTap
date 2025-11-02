//
//  GeminiAdapter.swift
//  CogiTap
//
//  Created by mengfs on 11/1/25.
//

import Foundation

class GeminiAdapter: BaseAPIAdapter {
    
    override func convertRequest(_ request: UnifiedChatRequest) throws -> URLRequest {
        // Gemini的URL格式不同
        let streamParam = request.stream ? "streamGenerateContent" : "generateContent"
        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/\(request.model):\(streamParam)?key=\(provider.apiKey)"
        
        guard let url = URL(string: urlString) else {
            throw APIAdapterError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 提取system消息作为systemInstruction
        var systemInstruction: String?
        var contents: [[String: Any]] = []
        
        for message in request.messages {
            if message.role == "system" {
                systemInstruction = message.content
            } else {
                // Gemini使用 "user" 和 "model" 作为角色
                let role = message.role == "assistant" ? "model" : "user"
                contents.append([
                    "role": role,
                    "parts": [["text": message.content]]
                ])
            }
        }
        
        // 构建请求体
        var body: [String: Any] = [
            "contents": contents,
            "generationConfig": [
                "temperature": request.temperature
            ]
        ]
        
        if let system = systemInstruction {
            body["systemInstruction"] = [
                "parts": [["text": system]]
            ]
        }
        
        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        return urlRequest
    }
    
    override func parseStreamChunk(_ line: String) throws -> StreamChunk? {
        // Gemini的流式响应是JSON数组
        guard !line.isEmpty else {
            return nil
        }
        
        guard let jsonData = line.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let text = firstPart["text"] as? String else {
            return nil
        }
        
        let finishReason = firstCandidate["finishReason"] as? String
        
        return StreamChunk(
            content: text,
            reasoningContent: nil,
            isFinished: finishReason != nil
        )
    }
    
    override func parseResponse(_ data: Data) throws -> UnifiedChatResponse {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let text = firstPart["text"] as? String else {
            throw APIAdapterError.decodingError("无法解析响应")
        }
        
        let finishReason = firstCandidate["finishReason"] as? String
        
        return UnifiedChatResponse(
            content: text,
            reasoningContent: nil,
            finishReason: finishReason
        )
    }
    
    override func fetchModels() async throws -> [String] {
        let urlString = "https://generativelanguage.googleapis.com/v1beta/models?key=\(provider.apiKey)"
        
        guard let url = URL(string: urlString) else {
            throw APIAdapterError.invalidURL
        }
        
        let request = URLRequest(url: url)
        let (data, _) = try await URLSession.shared.data(for: request)
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let modelsArray = json["models"] as? [[String: Any]] else {
            // 如果API不可用，返回预设的模型列表
            return [
                "gemini-2.0-flash-exp",
                "gemini-1.5-pro",
                "gemini-1.5-flash",
                "gemini-1.5-flash-8b"
            ]
        }
        
        // 只返回支持generateContent的模型
        return modelsArray.compactMap { model -> String? in
            guard let name = model["name"] as? String,
                  let supportedMethods = model["supportedGenerationMethods"] as? [String],
                  supportedMethods.contains("generateContent") else {
                return nil
            }
            // 提取模型ID（去掉 "models/" 前缀）
            return name.replacingOccurrences(of: "models/", with: "")
        }
    }
}
