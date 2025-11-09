//
//  MCPManager.swift
//  CogiTap
//
//  Created by mengfs on 11/7/25.
//

import Foundation
import Combine
import SwiftData

@MainActor
final class MCPManager: ObservableObject {
    static let shared = MCPManager()
    
    @Published private(set) var statuses: [UUID: MCPConnectionStatus] = [:]
    
    private var clients: [UUID: MCPClient] = [:]
    private var subscriptions: [UUID: AnyCancellable] = [:]
    
    private init() {}
    
    func refreshServers(using context: ModelContext) {
        let descriptor = FetchDescriptor<MCPServer>()
        guard let servers = try? context.fetch(descriptor) else { return }
        
        let existingIDs = Set(clients.keys)
        let latestIDs = Set(servers.map { $0.id })
        
        // Remove clients for deleted servers
        let removedIDs = existingIDs.subtracting(latestIDs)
        removedIDs.forEach { id in
            clients[id]?.disconnect()
            clients[id] = nil
            subscriptions[id] = nil
            statuses[id] = .idle
        }
        
        // Add or update clients
        for server in servers where server.isEnabled {
            if let client = clients[server.id] {
                statuses[server.id] = client.status
            } else {
                let client = MCPClient(server: server)
                clients[server.id] = client
                observe(client: client, for: server.id)
            }
        }
    }
    
    func connectionStatus(for serverID: UUID) -> MCPConnectionStatus {
        statuses[serverID] ?? .idle
    }
    
    func registeredTools(for conversation: Conversation) -> [MCPRegisteredTool] {
        guard let selections = conversation.mcpSelections else { return [] }
        return selections
            .compactMap { selection -> [MCPRegisteredTool]? in
                guard
                    let server = selection.server,
                    server.isEnabled,
                    let tools = server.tools
                else {
                    return nil
                }
                return tools
                    .filter { $0.isEnabled }
                    .map { tool in
                        let descriptor = MCPToolDescriptor(
                            identifier: MCPToolIdentifier(serverID: server.id, toolName: tool.name),
                            toolName: tool.name,
                            description: tool.toolDescription,
                            jsonSchema: normalizedSchemaJSON(from: tool.schemaJSON)
                        )
                        return MCPRegisteredTool(descriptor: descriptor, serverIdentifier: server.displayName)
                    }
            }
            .flatMap { $0 }
    }
    
    func syncTools(for serverID: UUID, context: ModelContext) async throws {
        guard let client = clients[serverID] else {
            throw MCPError.invalidConfiguration
        }
        statuses[serverID] = .connecting
        do {
            try await client.connect()
            let descriptors = try await client.listTools()
            try await updateTools(for: serverID, descriptors: descriptors, context: context)
            statuses[serverID] = .connected(toolCount: descriptors.count)
        } catch {
            statuses[serverID] = .error(message: error.localizedDescription)
            throw error
        }
    }
    
    func invokeTool(
        identifier: MCPToolIdentifier,
        argumentsJSON: String
    ) async throws -> String {
        guard let client = clients[identifier.serverID] else {
            throw MCPError.invalidConfiguration
        }
        guard let data = argumentsJSON.data(using: .utf8),
              let payload = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw MCPError.protocolViolation
        }
        return try await client.invokeTool(name: identifier.toolName, arguments: payload)
    }
    
    func disconnectAll() {
        clients.values.forEach { $0.disconnect() }
        clients.removeAll()
        subscriptions.removeAll()
        statuses.removeAll()
    }
    
    private func observe(client: MCPClient, for serverID: UUID) {
        subscriptions[serverID] = client.$status
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.statuses[serverID] = status
            }
    }
    
    private func updateTools(
        for serverID: UUID,
        descriptors: [MCPToolDescriptor],
        context: ModelContext
    ) async throws {
        var fetchDescriptor = FetchDescriptor<MCPServer>()
        fetchDescriptor.predicate = #Predicate { $0.id == serverID }
        fetchDescriptor.fetchLimit = 1
        guard let server = try context.fetch(fetchDescriptor).first else {
            throw MCPError.invalidConfiguration
        }
        
        let existing = server.tools ?? []
        var existingMap: [String: MCPTool] = Dictionary(uniqueKeysWithValues: existing.map { ($0.name, $0) })
        
        // Add or update
        for descriptor in descriptors {
            if let tool = existingMap.removeValue(forKey: descriptor.toolName) {
                tool.toolDescription = descriptor.description
                tool.schemaJSON = descriptor.jsonSchema
                tool.updatedAt = Date()
            } else {
                let tool = MCPTool(
                    name: descriptor.toolName,
                    toolDescription: descriptor.description,
                    schemaJSON: descriptor.jsonSchema,
                    isEnabled: true,
                    server: server
                )
                context.insert(tool)
            }
        }
        
        // Remove tools no longer present
        for obsolete in existingMap.values {
            context.delete(obsolete)
        }
        
        try context.save()
    }
    
    private func normalizedSchemaJSON(from raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return MCPManager.defaultSchemaJSONString
        }
        return trimmed
    }
    
    static let defaultSchemaJSONString = """
    {
      "type": "object",
      "properties": {},
      "additionalProperties": true
    }
    """
}
