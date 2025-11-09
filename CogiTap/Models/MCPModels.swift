//
//  MCPModels.swift
//  CogiTap
//
//  Created by mengfs on 11/7/25.
//

import Foundation
import SwiftData

enum MCPTransportType: String, Codable, CaseIterable {
    case sse
    case streamableHttp
    case localProcess
}

struct MCPHeader: Codable, Hashable {
    var key: String
    var value: String
}

@Model
final class MCPServer {
    var id: UUID
    var identifier: String
    var displayName: String
    var transportRawValue: String
    var baseURL: String?
    var eventURL: String?
    var commandPath: String?
    var isEnabled: Bool
    var customHeadersPayload: Data?
    var createdAt: Date
    var updatedAt: Date
    var lastErrorMessage: String?
    
    @Relationship(deleteRule: .cascade, inverse: \MCPTool.server)
    var tools: [MCPTool]?
    
    @Relationship(deleteRule: .cascade, inverse: \ConversationMCPSelection.server)
    var selections: [ConversationMCPSelection]?
    
    init(
        id: UUID = UUID(),
        identifier: String,
        displayName: String,
        transportType: MCPTransportType,
        baseURL: String? = nil,
        eventURL: String? = nil,
        commandPath: String? = nil,
        isEnabled: Bool = true,
        customHeaders: [MCPHeader] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        lastErrorMessage: String? = nil
    ) {
        self.id = id
        self.identifier = identifier
        self.displayName = displayName
        self.transportRawValue = transportType.rawValue
        self.baseURL = baseURL
        self.eventURL = eventURL
        self.commandPath = commandPath
        self.isEnabled = isEnabled
        self.customHeadersPayload = MCPServer.encodeHeaders(customHeaders)
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastErrorMessage = lastErrorMessage
    }
    
    var transportType: MCPTransportType {
        get { MCPTransportType(rawValue: transportRawValue) ?? .sse }
        set { transportRawValue = newValue.rawValue }
    }
    
    var headers: [MCPHeader] {
        get {
            guard
                let data = customHeadersPayload,
                let headers = try? JSONDecoder().decode([MCPHeader].self, from: data)
            else {
                return []
            }
            return headers
        }
        set {
            customHeadersPayload = MCPServer.encodeHeaders(newValue)
        }
    }
    
    private static func encodeHeaders(_ headers: [MCPHeader]) -> Data? {
        guard !headers.isEmpty else { return nil }
        return try? JSONEncoder().encode(headers)
    }
}

@Model
final class MCPTool {
    var id: UUID
    var name: String
    var toolDescription: String
    var schemaJSON: String
    var isEnabled: Bool
    var createdAt: Date
    var updatedAt: Date
    
    var server: MCPServer?
    
    init(
        id: UUID = UUID(),
        name: String,
        toolDescription: String,
        schemaJSON: String,
        isEnabled: Bool = true,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        server: MCPServer? = nil
    ) {
        self.id = id
        self.name = name
        self.toolDescription = toolDescription
        self.schemaJSON = schemaJSON
        self.isEnabled = isEnabled
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.server = server
    }
}

@Model
final class ConversationMCPSelection {
    var id: UUID
    var createdAt: Date
    var updatedAt: Date
    var isPinned: Bool
    
    var conversation: Conversation?
    var server: MCPServer?
    
    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isPinned: Bool = false,
        conversation: Conversation? = nil,
        server: MCPServer? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isPinned = isPinned
        self.conversation = conversation
        self.server = server
    }
}
