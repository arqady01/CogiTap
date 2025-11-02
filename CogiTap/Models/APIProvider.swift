//
//  APIProvider.swift
//  CogiTap
//
//  Created by mengfs on 11/1/25.
//

import Foundation
import SwiftData

enum ProviderType: String, Codable {
    case openai = "OpenAI"
    case anthropic = "Anthropic"
    case gemini = "Gemini"
    case openrouter = "OpenRouter"
    case custom = "Custom"
}

@Model
final class APIProvider {
    var id: UUID
    var nickname: String
    var providerType: String // ProviderType的rawValue
    var baseURL: String
    var apiKey: String
    var createdAt: Date
    var isActive: Bool
    
    // 关联的模型列表
    @Relationship(deleteRule: .cascade, inverse: \ChatModel.provider)
    var models: [ChatModel]?
    
    init(
        id: UUID = UUID(),
        nickname: String,
        providerType: ProviderType,
        baseURL: String,
        apiKey: String,
        createdAt: Date = Date(),
        isActive: Bool = true
    ) {
        self.id = id
        self.nickname = nickname
        self.providerType = providerType.rawValue
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.createdAt = createdAt
        self.isActive = isActive
    }
    
    var type: ProviderType {
        ProviderType(rawValue: providerType) ?? .custom
    }
    
    // 获取最终的base_url（应用魔法字符规则）
    func getFinalBaseURL() -> String {
        // 只对自定义端点应用魔法规则
        guard type == .custom else {
            return baseURL
        }
        
        // 检查是否以 # 结尾（强制使用输入地址）
        if baseURL.hasSuffix("#") {
            return String(baseURL.dropLast())
        }
        
        // 检查是否以 / 结尾（忽略 v1 版本）
        if baseURL.hasSuffix("/") {
            return baseURL + "chat/completions"
        }
        
        // 默认情况：添加 /v1/chat/completions
        return baseURL + "/v1/chat/completions"
    }
    
    // 获取模型列表的端点
    func getModelsEndpoint() -> String {
        switch type {
        case .openai:
            return "https://api.openai.com/v1/models"
        case .anthropic:
            return "https://api.anthropic.com/v1/models"
        case .gemini:
            // Gemini使用不同的API结构
            return "https://generativelanguage.googleapis.com/v1beta/models"
        case .openrouter:
            return "https://openrouter.ai/api/v1/models"
        case .custom:
            // 自定义端点，需要根据baseURL构建
            if baseURL.hasSuffix("#") {
                let cleanURL = String(baseURL.dropLast())
                return cleanURL
            } else if baseURL.hasSuffix("/") {
                return baseURL + "models"
            } else {
                return baseURL + "/v1/models"
            }
        }
    }
}
