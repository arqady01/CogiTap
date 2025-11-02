//
//  AddModelView.swift
//  CogiTap
//
//  Created by mengfs on 11/2/25.
//

import SwiftUI
import SwiftData

struct AddModelView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let provider: APIProvider
    
    @State private var modelName = ""
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("模型名称", text: $modelName)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                } header: {
                    Text("模型信息")
                } footer: {
                    Text("请输入完整的模型名称，例如：gpt-4、claude-3-5-sonnet-20241022")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("常见模型名称示例：")
                            .font(.caption)
                            .fontWeight(.medium)
                        
                        Group {
                            Text("• OpenAI: gpt-4, gpt-3.5-turbo")
                            Text("• Anthropic: claude-3-5-sonnet-20241022")
                            Text("• Gemini: gemini-2.0-flash-exp")
                            Text("• 自定义: 根据服务商文档填写")
                        }
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("添加模型")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("添加") {
                        addModel()
                    }
                    .disabled(modelName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .alert("错误", isPresented: $showError) {
                Button("确定", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func addModel() {
        let trimmedName = modelName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 检查是否已存在
        if let existingModels = provider.models,
           existingModels.contains(where: { $0.modelName == trimmedName }) {
            errorMessage = "该模型已存在"
            showError = true
            return
        }
        
        // 创建新模型
        let newModel = ChatModel(
            modelName: trimmedName,
            isEnabled: true, // 手动添加的模型默认启用
            isManuallyAdded: true,
            provider: provider
        )
        
        modelContext.insert(newModel)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = "添加失败: \(error.localizedDescription)"
            showError = true
        }
    }
}

#Preview {
    let provider = APIProvider(
        nickname: "OpenAI",
        providerType: .openai,
        baseURL: "https://api.openai.com",
        apiKey: "test-key"
    )
    
    return AddModelView(provider: provider)
        .modelContainer(for: [APIProvider.self, ChatModel.self])
}
