//
//  MemoryToolBuilder.swift
//  CogiTap
//
//  Created by mengfs on 11/3/25.
//

import Foundation

enum MemoryToolName: String {
    case saveMemory = "save_memory"
    case retrieveMemory = "retrieve_memory"
    case updateMemory = "update_memory"
}

struct MemoryToolBuilder {
    static func makeTools(using config: MemoryConfig) -> (tools: [FunctionTool], choice: ToolChoice) {
        guard config.isMemoryEnabled else {
            return ([], .none)
        }
        let tools: [FunctionTool] = [
            FunctionTool(
                name: MemoryToolName.saveMemory.rawValue,
                description: "保存记忆 (Save memory). 用途: 将重要信息写入长期记忆。",
                parameters: [
                    "type": "object",
                    "properties": [
                        "content": [
                            "type": "string",
                            "description": "记忆内容 / Memory content."
                        ]
                    ],
                    "required": ["content"]
                ]
            ),
            FunctionTool(
                name: MemoryToolName.retrieveMemory.rawValue,
                description: "检索记忆 (Retrieve memory). 用途: 根据关键词查询长期记忆。",
                parameters: [
                    "type": "object",
                    "properties": [
                        "keywords": [
                            "type": "string",
                            "description": "检索关键词，多个关键词用分号分隔 / Keywords separated by semicolons."
                        ]
                    ],
                    "required": ["keywords"]
                ]
            ),
            FunctionTool(
                name: MemoryToolName.updateMemory.rawValue,
                description: "更新记忆 (Update memory). 用途: 修正已有记忆内容。",
                parameters: [
                    "type": "object",
                    "properties": [
                        "original": [
                            "type": "string",
                            "description": "原始记忆文本 / Original memory text."
                        ],
                        "replacement": [
                            "type": "string",
                            "description": "更新后的记忆文本 / Updated memory text."
                        ]
                    ],
                    "required": ["original", "replacement"]
                ]
            )
        ]
        return (tools, .auto)
    }
}
