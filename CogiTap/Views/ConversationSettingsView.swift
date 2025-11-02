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
    @State private var isInitialized = false
    
    var body: some View {
        NavigationStack {
            Form {
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
            }
            .navigationTitle("对话设置")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if !isInitialized {
                    localTemperature = conversation.temperature
                    localSystemPrompt = conversation.systemPrompt
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
}

#Preview {
    let conversation = Conversation()
    return ConversationSettingsView(conversation: conversation)
}
