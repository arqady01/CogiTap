//
//  ChatModel.swift
//  CogiTap
//
//  Created by mengfs on 11/1/25.
//

import Foundation
import SwiftData

@Model
final class ChatModel {
    var id: UUID
    var modelName: String
    var displayName: String?
    var createdAt: Date
    var isEnabled: Bool // 用户是否启用此模型
    var isManuallyAdded: Bool // 是否手动添加的模型
    
    // 关联的Provider
    var provider: APIProvider?
    
    init(
        id: UUID = UUID(),
        modelName: String,
        displayName: String? = nil,
        createdAt: Date = Date(),
        isEnabled: Bool = false,
        isManuallyAdded: Bool = false,
        provider: APIProvider? = nil
    ) {
        self.id = id
        self.modelName = modelName
        self.displayName = displayName
        self.createdAt = createdAt
        self.isEnabled = isEnabled
        self.isManuallyAdded = isManuallyAdded
        self.provider = provider
    }
    
    var name: String {
        displayName ?? modelName
    }
}
