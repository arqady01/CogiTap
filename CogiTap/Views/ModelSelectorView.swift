//
//  ModelSelectorView.swift
//  CogiTap
//
//  Created by mengfs on 11/1/25.
//

import SwiftUI
import SwiftData

struct ModelSelectorView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var providers: [APIProvider]
    @Query private var allModels: [ChatModel]
    
    @Binding var selectedModel: ChatModel?
    
    var body: some View {
        NavigationStack {
            List {
                if providers.isEmpty {
                    ContentUnavailableView(
                        "没有配置的服务商",
                        systemImage: "server.rack",
                        description: Text("请先在设置中添加模型服务商")
                    )
                } else if !hasEnabledModels {
                    ContentUnavailableView(
                        "暂无可用模型",
                        systemImage: "cube.transparent",
                        description: Text("请在设置中管理模型，启用您需要的模型")
                    )
                } else {
                    ForEach(providers) { provider in
                        let enabledModels = provider.models?.filter { $0.isEnabled } ?? []
                        
                        if !enabledModels.isEmpty {
                            Section(provider.nickname) {
                                ForEach(enabledModels) { model in
                                    Button {
                                        selectedModel = model
                                        dismiss()
                                    } label: {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(model.modelName)
                                                    .foregroundStyle(.primary)
                                                
                                                if model.isManuallyAdded {
                                                    Text("手动添加")
                                                        .font(.caption)
                                                        .foregroundStyle(.secondary)
                                                }
                                            }
                                            
                                            Spacer()
                                            
                                            if selectedModel?.id == model.id {
                                                Image(systemName: "checkmark")
                                                    .foregroundStyle(.blue)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("选择模型")
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
    
    // 检查是否有已启用的模型
    private var hasEnabledModels: Bool {
        providers.contains { provider in
            provider.models?.contains { $0.isEnabled } ?? false
        }
    }
}

#Preview {
    ModelSelectorView(selectedModel: .constant(nil))
        .modelContainer(for: [APIProvider.self, ChatModel.self])
}
