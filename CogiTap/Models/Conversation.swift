//
//  Conversation.swift
//  CogiTap
//
//  Created by mengfs on 11/1/25.
//

import Foundation
import SwiftData

@Model
final class Conversation {
    var id: UUID
    var title: String
    var createdAt: Date
    var updatedAt: Date
    
    // 会话级别的参数
    var temperature: Double
    var systemPrompt: String
    
    // 当前使用的模型
    var selectedModelId: UUID?
    
    // 关联的消息列表
    @Relationship(deleteRule: .cascade, inverse: \Message.conversation)
    var messages: [Message]?
    
    init(
        id: UUID = UUID(),
        title: String = "新对话",
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        temperature: Double = 0.7,
        systemPrompt: String = "You are a helpful assistant.",
        selectedModelId: UUID? = nil
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.temperature = temperature
        self.systemPrompt = systemPrompt
        self.selectedModelId = selectedModelId
    }
    
    var sortedMessages: [Message] {
        (messages ?? []).sorted { $0.createdAt < $1.createdAt }
    }
}
