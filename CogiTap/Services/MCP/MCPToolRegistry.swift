//
//  MCPToolRegistry.swift
//  CogiTap
//
//  Created by mengfs on 11/7/25.
//

import Foundation

struct MCPToolRegistry {
    private(set) var lookup: [String: MCPRegisteredTool] = [:]
    
    mutating func install(remote tools: [MCPRegisteredTool]) -> [FunctionTool] {
        lookup.removeAll()
        return tools.map { tool in
            let qualifiedName = tool.descriptor.qualifiedName
            lookup[qualifiedName] = tool
            return tool.functionTool
        }
    }
    
    func registeredTool(for functionName: String) -> MCPRegisteredTool? {
        lookup[functionName]
    }
}
