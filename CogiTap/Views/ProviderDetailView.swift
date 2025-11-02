//
//  ProviderDetailView.swift
//  CogiTap
//
//  Created by mengfs on 11/1/25.
//

import SwiftUI
import SwiftData

struct ProviderDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let provider: APIProvider
    
    @State private var showManageModels = false
    @State private var showAddModel = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    // 获取该服务商的所有模型（包括已启用和未启用）
    private var allModels: [ChatModel] {
        provider.models?.sorted { $0.createdAt < $1.createdAt } ?? []
    }
    
    // 只显示已启用的模型
    private var enabledModels: [ChatModel] {
        allModels.filter { $0.isEnabled }
    }
    
    var body: some View {
        List {
            Section("基本信息") {
                LabeledContent("昵称", value: provider.nickname)
                LabeledContent("类型", value: provider.type.rawValue)
                LabeledContent("Base URL", value: provider.baseURL)
            }
            
            Section {
                if enabledModels.isEmpty {
                    ContentUnavailableView(
                        "暂无模型",
                        systemImage: "cube.transparent",
                        description: Text("点击下方按钮管理或添加模型")
                    )
                } else {
                    ForEach(enabledModels) { model in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(model.modelName)
                                    .font(.body)
                                
                                if model.isManuallyAdded {
                                    Text("手动添加")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                    }
                    .onDelete(perform: deleteModels)
                }
            } header: {
                HStack {
                    Text("模型列表")
                    Spacer()
                    HStack(spacing: 12) {
                        Button {
                            showManageModels = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "slider.horizontal.3")
                                Text("管理")
                            }
                            .font(.caption)
                            .foregroundStyle(.blue)
                        }
                        
                        Button {
                            showAddModel = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "plus.circle")
                                Text("添加")
                            }
                            .font(.caption)
                            .foregroundStyle(.blue)
                        }
                    }
                }
            } footer: {
                Text("已启用 \(enabledModels.count) 个模型")
            }
        }
        .navigationTitle(provider.nickname)
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showManageModels) {
            ManageModelsView(provider: provider)
        }
        .sheet(isPresented: $showAddModel) {
            AddModelView(provider: provider)
        }
        .alert("错误", isPresented: $showError) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private func deleteModels(at offsets: IndexSet) {
        for index in offsets {
            let model = enabledModels[index]
            modelContext.delete(model)
        }
        try? modelContext.save()
    }
}

#Preview {
    let provider = APIProvider(
        nickname: "OpenAI",
        providerType: .openai,
        baseURL: "https://api.openai.com",
        apiKey: "test-key"
    )
    
    return NavigationStack {
        ProviderDetailView(provider: provider)
            .modelContainer(for: [APIProvider.self, ChatModel.self])
    }
}
