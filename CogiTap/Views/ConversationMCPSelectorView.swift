//
//  ConversationMCPSelectorView.swift
//  CogiTap
//
//  Created by mengfs on 11/7/25.
//

import SwiftUI
import SwiftData

struct ConversationMCPSelectorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MCPServer.createdAt, order: .reverse) private var servers: [MCPServer]
    @Bindable var conversation: Conversation
    @ObservedObject private var manager = MCPManager.shared
    
    var body: some View {
        List {
            Section("可用服务器") {
                if servers.isEmpty {
                    ContentUnavailableView(
                        "暂无 MCP 服务器",
                        systemImage: "puzzlepiece.extension",
                        description: Text("请在设置中添加 MCP 服务器后再进行选择。")
                    )
                } else {
                    ForEach(servers) { server in
                        Button {
                            toggleSelection(for: server)
                        } label: {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(server.displayName)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    
                                    Text(statusText(for: server))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: isSelected(server) ? "checkmark.circle.fill" : "circle")
                                    .font(.title3)
                                    .foregroundStyle(isSelected(server) ? Color.blue : Color.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                        .disabled(!server.isEnabled)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("MCP 服务器")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("完成") {
                    dismiss()
                }
            }
        }
        .onAppear {
            manager.refreshServers(using: modelContext)
        }
    }
    
    private func isSelected(_ server: MCPServer) -> Bool {
        guard let selections = conversation.mcpSelections else {
            return false
        }
        return selections.contains { $0.server?.id == server.id }
    }
    
    private func toggleSelection(for server: MCPServer) {
        if let selections = conversation.mcpSelections,
           let target = selections.first(where: { $0.server?.id == server.id }) {
            modelContext.delete(target)
        } else {
            let newSelection = ConversationMCPSelection(conversation: conversation, server: server)
            modelContext.insert(newSelection)
        }
        try? modelContext.save()
    }
    
    private func statusText(for server: MCPServer) -> String {
        guard server.isEnabled else {
            return "已禁用"
        }
        switch manager.connectionStatus(for: server.id) {
        case .idle:
            return "待连接"
        case .connecting:
            return "连接中..."
        case .connected(let count):
            return "已连接 · \(count) 个工具"
        case .error(let message):
            return "错误：\(message)"
        }
    }
}
