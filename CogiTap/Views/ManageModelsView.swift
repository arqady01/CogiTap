//
//  ManageModelsView.swift
//  CogiTap
//
//  Created by mengfs on 11/2/25.
//

import SwiftUI
import SwiftData

struct ManageModelsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let provider: APIProvider
    
    @State private var availableModels: [String] = []
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    // 获取该服务商的所有模型
    private var existingModels: [ChatModel] {
        provider.models?.sorted { $0.modelName < $1.modelName } ?? []
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    VStack(spacing: 20) {
                        ProgressView()
                        Text("正在获取模型列表...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } else if availableModels.isEmpty && existingModels.isEmpty {
                    ContentUnavailableView(
                        "暂无模型",
                        systemImage: "cube.transparent",
                        description: Text("点击下方按钮从服务商获取模型列表")
                    )
                } else {
                    List {
                        // 显示从API获取的模型
                        if !availableModels.isEmpty {
                            Section {
                                ForEach(availableModels, id: \.self) { modelName in
                                    let existingModel = existingModels.first { $0.modelName == modelName }
                                    
                                    Button {
                                        toggleModel(modelName: modelName, existing: existingModel)
                                    } label: {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(modelName)
                                                    .font(.body)
                                                    .foregroundStyle(.primary)
                                                
                                                if let model = existingModel, model.isManuallyAdded {
                                                    Text("手动添加")
                                                        .font(.caption)
                                                        .foregroundStyle(.secondary)
                                                }
                                            }
                                            
                                            Spacer()
                                            
                                            if let model = existingModel, model.isEnabled {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundStyle(.green)
                                            } else {
                                                Image(systemName: "circle")
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                    }
                                }
                            } header: {
                                Text("可用模型")
                            } footer: {
                                Text("勾选的模型将出现在对话页面的模型选择中")
                            }
                        }
                        
                        // 显示手动添加但不在API列表中的模型
                        let manualOnlyModels = existingModels.filter { model in
                            model.isManuallyAdded && !availableModels.contains(model.modelName)
                        }
                        
                        if !manualOnlyModels.isEmpty {
                            Section {
                                ForEach(manualOnlyModels) { model in
                                    Button {
                                        toggleModel(modelName: model.modelName, existing: model)
                                    } label: {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(model.modelName)
                                                    .font(.body)
                                                    .foregroundStyle(.primary)
                                                
                                                Text("手动添加")
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                            
                                            Spacer()
                                            
                                            if model.isEnabled {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundStyle(.green)
                                            } else {
                                                Image(systemName: "circle")
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                    }
                                }
                                .onDelete { offsets in
                                    deleteManualModels(at: offsets, from: manualOnlyModels)
                                }
                            } header: {
                                Text("手动添加的模型")
                            }
                        }
                    }
                }
            }
            .navigationTitle("管理模型")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .bottomBar) {
                    Button {
                        Task {
                            await fetchModels()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("从服务商获取")
                        }
                    }
                    .disabled(isLoading)
                }
            }
            .alert("错误", isPresented: $showError) {
                Button("确定", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func toggleModel(modelName: String, existing: ChatModel?) {
        if let model = existing {
            // 切换已存在模型的启用状态
            model.isEnabled.toggle()
        } else {
            // 创建新模型并启用
            let newModel = ChatModel(
                modelName: modelName,
                isEnabled: true,
                isManuallyAdded: false,
                provider: provider
            )
            modelContext.insert(newModel)
        }
        
        try? modelContext.save()
    }
    
    private func deleteManualModels(at offsets: IndexSet, from models: [ChatModel]) {
        for index in offsets {
            modelContext.delete(models[index])
        }
        try? modelContext.save()
    }
    
    private func fetchModels() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let adapter = APIAdapterFactory.createAdapter(for: provider)
            let modelNames = try await adapter.fetchModels()
            availableModels = modelNames.sorted()
        } catch {
            errorMessage = "获取模型列表失败: \(error.localizedDescription)"
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
    
    return ManageModelsView(provider: provider)
        .modelContainer(for: [APIProvider.self, ChatModel.self])
}
