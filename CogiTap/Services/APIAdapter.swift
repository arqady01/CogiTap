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
    let toolCalls: [UnifiedToolCall]?
    let toolCallId: String?
}

extension UnifiedMessage {
    init(role: String, content: String) {
        self.role = role
        self.content = content
        self.toolCalls = nil
        self.toolCallId = nil
    }
    
    init(role: String, content: String, toolCalls: [UnifiedToolCall]?) {
        self.role = role
        self.content = content
        self.toolCalls = toolCalls
        self.toolCallId = nil
    }
    
    init(role: String, content: String, toolCallId: String?) {
        self.role = role
        self.content = content
        self.toolCalls = nil
        self.toolCallId = toolCallId
    }
}

// 统一的聊天请求
struct UnifiedChatRequest {
    let messages: [UnifiedMessage]
    let temperature: Double
    let stream: Bool
    let model: String
    let functionTools: [FunctionTool]
    let toolChoice: ToolChoice
}

// 统一的聊天响应
struct UnifiedChatResponse {
    let content: String
    let reasoningContent: String?
    let finishReason: String?
    let toolCalls: [UnifiedToolCall]
}

// 流式响应的数据块
struct StreamChunk {
    let content: String?
    let reasoningContent: String?
    let toolCallDeltas: [ToolCallDelta]?
    let finishReason: String?
    let isFinished: Bool
}

struct UnifiedToolCall: Codable {
    let id: String
    let name: String
    let arguments: String
}

struct ToolCallDelta {
    let id: String?
    let name: String?
    let arguments: String?
    let index: Int?
}

struct FunctionTool {
    let name: String
    let description: String
    let parameters: [String: Any]
}

enum ToolChoice {
    case auto
    case none
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
