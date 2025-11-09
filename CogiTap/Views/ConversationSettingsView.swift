//
//  ConversationSettingsView.swift
//  CogiTap
//
//  Created by mengfs on 11/1/25.
//

import SwiftUI
import SwiftData

struct ConversationSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var conversation: Conversation
    
    @State private var localTemperature: Double = 0.7
    @State private var localSystemPrompt: String = "You are a helpful assistant."
    @State private var localStreamingEnabled: Bool = true
    @State private var isInitialized = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("启用流式输出", isOn: $localStreamingEnabled)
                        .onChange(of: localStreamingEnabled) { _, newValue in
                            conversation.isStreamingEnabled = newValue
                        }
                } footer: {
                    Text("某些模型不支持流式输出，关闭后将等待完整回复再显示。")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Temperature")
                            Spacer()
                            Text(String(format: "%.1f", localTemperature))
                                .foregroundStyle(.secondary)
                        }
                        
                        Slider(value: $localTemperature, in: 0...2, step: 0.1)
                            .onChange(of: localTemperature) { _, newValue in
                                conversation.temperature = newValue
                            }
                    }
                } header: {
                    Text("温度")
                } footer: {
                    Text("较高的值会使输出更随机，较低的值会使其更集中和确定")
                }
                
                Section {
                    TextEditor(text: $localSystemPrompt)
                            .onChange(of: localSystemPrompt) { _, newValue in
                                conversation.systemPrompt = newValue
                            }
                        .frame(minHeight: 100)
                        .font(.body)
                } header: {
                    Text("系统提示词")
                } footer: {
                    Text("设置AI助手的行为和角色")
                }
                
                Section {
                    NavigationLink {
                        ConversationMCPSelectorView(conversation: conversation)
                            .environment(\.modelContext, modelContext)
                    } label: {
                        HStack {
                            Text("MCP 工具")
                            Spacer()
                            Text(mcpSummary)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                } footer: {
                    Text("选择本会话可以使用的 MCP 服务器。")
                }
            }
            .navigationTitle("对话设置")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if !isInitialized {
                    localTemperature = conversation.temperature
                    localSystemPrompt = conversation.systemPrompt
                    localStreamingEnabled = conversation.isStreamingEnabled
                    isInitialized = true
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") {
                        try? modelContext.save()
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var mcpSummary: String {
        guard let selections = conversation.mcpSelections, !selections.isEmpty else {
            return "未启用"
        }
        let enabledCount = selections.filter { $0.server?.isEnabled ?? false }.count
        if enabledCount == 0 {
            return "未启用"
        }
        return "已选择 \(enabledCount) 个"
    }
}

#Preview {
    let conversation = Conversation()
    return ConversationSettingsView(conversation: conversation)
}
