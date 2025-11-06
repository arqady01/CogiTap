//
//  MemoryModels.swift
//  CogiTap
//
//  Created by mengfs on 11/3/25.
//

import Foundation
import SwiftData

@Model
final class MemoryRecord {
    var id: UUID
    var content: String
    var createdAt: Date
    var updatedAt: Date
    var conversationId: UUID?
    
    init(
        id: UUID = UUID(),
        content: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        conversationId: UUID? = nil
    ) {
        self.id = id
        self.content = content
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.conversationId = conversationId
    }
}

@Model
final class MemoryConfig {
    var id: UUID
    var isMemoryEnabled: Bool
    var isCrossChatEnabled: Bool
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        isMemoryEnabled: Bool = true,
        isCrossChatEnabled: Bool = true,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.isMemoryEnabled = isMemoryEnabled
        self.isCrossChatEnabled = isCrossChatEnabled
        self.updatedAt = updatedAt
    }
}
