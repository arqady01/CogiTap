//
//  MCPServiceTypes.swift
//  CogiTap
//
//  Created by mengfs on 11/7/25.
//

import Foundation

enum MCPConnectionStatus: Equatable {
    case idle
    case connecting
    case connected(toolCount: Int)
    case error(message: String)
}

enum MCPError: LocalizedError {
    case invalidConfiguration
    case transportUnavailable
    case protocolViolation
    case disconnected
    case notImplemented
    case underlying(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidConfiguration:
            return "MCP 配置无效"
        case .transportUnavailable:
            return "暂不支持的传输方式"
        case .protocolViolation:
            return "服务器返回了无效的协议数据"
        case .disconnected:
            return "服务器连接已断开"
        case .notImplemented:
            return "功能暂未实现"
        case .underlying(let error):
            return error.localizedDescription
        }
    }
}

struct MCPToolIdentifier: Hashable {
    let serverID: UUID
    let toolName: String
}

struct MCPToolDescriptor {
    let identifier: MCPToolIdentifier
    let toolName: String
    let description: String
    let jsonSchema: String
    
    var qualifiedName: String {
        "mcp::\(identifier.serverID.uuidString)::\(toolName)"
    }
    
    var schemaDictionary: [String: Any] {
        guard
            let data = jsonSchema.data(using: .utf8),
            let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return [:]
        }
        return object
    }
}

struct MCPRegisteredTool {
    let descriptor: MCPToolDescriptor
    let serverIdentifier: String
    
    var functionTool: FunctionTool {
        FunctionTool(
            name: descriptor.qualifiedName,
            description: descriptionText,
            parameters: descriptor.schemaDictionary
        )
    }
    
    private var descriptionText: String {
        "\(descriptor.description)\n(Source: \(serverIdentifier))"
    }
}
