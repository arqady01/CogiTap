//
//  ConversationSettingsView.swift
//  CogiTap
//
//  Created by mengfs on 11/1/25.
//

import SwiftUI

struct ConversationSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var conversation: Conversation
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Temperature")
                            Spacer()
                            Text(String(format: "%.1f", conversation.temperature))
                                .foregroundStyle(.secondary)
                        }
                        
                        Slider(value: $conversation.temperature, in: 0...2, step: 0.1)
                    }
                } header: {
                    Text("温度")
                } footer: {
                    Text("较高的值会使输出更随机，较低的值会使其更集中和确定")
                }
                
                Section {
                    TextEditor(text: $conversation.systemPrompt)
                        .frame(minHeight: 100)
                        .font(.body)
                } header: {
                    Text("系统提示词")
                } footer: {
                    Text("设置AI助手的行为和角色")
                }
            }
            .navigationTitle("对话设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    let conversation = Conversation()
    return ConversationSettingsView(conversation: conversation)
}
