//
//  Message.swift
//  CogiTap
//
//  Created by mengfs on 11/1/25.
//

import Foundation
import SwiftData

enum MessageRole: String, Codable {
    case system
    case user
    case assistant
}

@Model
final class Message {
    var id: UUID
    var role: String // MessageRole的rawValue
    var content: String
    var reasoningContent: String? // 推理模型的思考过程
    var createdAt: Date
    var isStreaming: Bool // 是否正在流式输出
    
    // 关联的会话
    var conversation: Conversation?
    
    init(
        id: UUID = UUID(),
        role: MessageRole,
        content: String,
        reasoningContent: String? = nil,
        createdAt: Date = Date(),
        isStreaming: Bool = false,
        conversation: Conversation? = nil
    ) {
        self.id = id
        self.role = role.rawValue
        self.content = content
        self.reasoningContent = reasoningContent
        self.createdAt = createdAt
        self.isStreaming = isStreaming
        self.conversation = conversation
    }
    
    var messageRole: MessageRole {
        MessageRole(rawValue: role) ?? .user
    }
}
