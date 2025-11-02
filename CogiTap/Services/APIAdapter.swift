//
//  APIAdapter.swift
//  CogiTap
//
//  Created by mengfs on 11/1/25.
//

import Foundation

// 统一的消息格式
struct UnifiedMessage: Codable {
    let role: String
    let content: String
}

// 统一的聊天请求
struct UnifiedChatRequest {
    let messages: [UnifiedMessage]
    let temperature: Double
    let stream: Bool
    let model: String
}

// 统一的聊天响应
struct UnifiedChatResponse {
    let content: String
    let reasoningContent: String?
    let finishReason: String?
}

// 流式响应的数据块
struct StreamChunk {
    let content: String?
    let reasoningContent: String?
    let isFinished: Bool
}

// API适配器协议
protocol APIAdapter {
    var provider: APIProvider { get }
    
    // 转换请求格式
    func convertRequest(_ request: UnifiedChatRequest) throws -> URLRequest
    
    // 解析流式响应
    func parseStreamChunk(_ line: String) throws -> StreamChunk?
    
    // 解析完整响应
    func parseResponse(_ data: Data) throws -> UnifiedChatResponse
    
    // 获取模型列表
    func fetchModels() async throws -> [String]
}

// 基础适配器实现
class BaseAPIAdapter: APIAdapter {
    let provider: APIProvider
    
    init(provider: APIProvider) {
        self.provider = provider
    }
    
    func convertRequest(_ request: UnifiedChatRequest) throws -> URLRequest {
        fatalError("Subclass must implement convertRequest")
    }
    
    func parseStreamChunk(_ line: String) throws -> StreamChunk? {
        fatalError("Subclass must implement parseStreamChunk")
    }
    
    func parseResponse(_ data: Data) throws -> UnifiedChatResponse {
        fatalError("Subclass must implement parseResponse")
    }
    
    func fetchModels() async throws -> [String] {
        fatalError("Subclass must implement fetchModels")
    }
}

// 错误类型
enum APIAdapterError: LocalizedError {
    case invalidURL
    case invalidResponse
    case decodingError(String)
    case networkError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的URL"
        case .invalidResponse:
            return "无效的响应"
        case .decodingError(let message):
            return "解析错误: \(message)"
        case .networkError(let message):
            return "网络错误: \(message)"
        }
    }
}
