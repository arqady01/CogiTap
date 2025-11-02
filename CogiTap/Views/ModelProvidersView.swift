//
//  ModelProvidersView.swift
//  CogiTap
//
//  Created by mengfs on 11/1/25.
//

import SwiftUI
import SwiftData

struct ModelProvidersView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \APIProvider.createdAt, order: .reverse) private var providers: [APIProvider]
    
    @State private var showingAddCustomProvider = false
    @State private var selectedPresetType: ProviderType?
    
    // 预设服务商列表
    private let presetProviders: [(type: ProviderType, icon: String, name: String, description: String)] = [
        (.openai, "brain", "OpenAI", "GPT-4, GPT-3.5等模型"),
        (.anthropic, "sparkles", "Anthropic", "Claude系列模型"),
        (.gemini, "star.fill", "Google Gemini", "Gemini系列模型"),
        (.openrouter, "arrow.triangle.branch", "OpenRouter", "统一访问多个模型")
    ]
    
    var body: some View {
        List {
            // 预设服务商
            Section {
                ForEach(presetProviders, id: \.type) { preset in
                    if let existingProvider = providers.first(where: { $0.type == preset.type }) {
                        // 已配置的预设服务商
                        NavigationLink(destination: ProviderDetailView(provider: existingProvider)) {
                            PresetProviderRow(
                                icon: preset.icon,
                                name: preset.name,
                                description: preset.description,
                                isConfigured: true,
                                nickname: existingProvider.nickname
                            )
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                modelContext.delete(existingProvider)
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                        }
                    } else {
                        // 未配置的预设服务商
                        Button {
                            selectedPresetType = preset.type
                        } label: {
                            PresetProviderRow(
                                icon: preset.icon,
                                name: preset.name,
                                description: preset.description,
                                isConfigured: false,
                                nickname: nil
                            )
                        }
                    }
                }
            } header: {
                Text("预设服务商")
            } footer: {
                Text("点击未配置的服务商快速添加")
            }
            
            // 自定义端点
            Section {
                // 已配置的自定义端点
                ForEach(providers.filter { $0.type == .custom }) { provider in
                    NavigationLink(destination: ProviderDetailView(provider: provider)) {
                        ProviderRow(provider: provider)
                    }
                }
                .onDelete(perform: deleteCustomProviders)
                
                // 添加自定义端点按钮
                Button {
                    showingAddCustomProvider = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(.blue)
                        Text("添加自定义端点")
                            .foregroundStyle(.primary)
                    }
                }
            } header: {
                Text("自定义端点")
            } footer: {
                Text("配置兼容OpenAI API格式的自定义服务")
            }
        }
        .navigationTitle("模型服务商")
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $selectedPresetType) { type in
            AddPresetProviderView(providerType: type)
        }
        .sheet(isPresented: $showingAddCustomProvider) {
            AddCustomProviderView()
        }
    }
    
    private func deleteCustomProviders(at offsets: IndexSet) {
        let customProviders = providers.filter { $0.type == .custom }
        for index in offsets {
            modelContext.delete(customProviders[index])
        }
    }
}

// 预设服务商行视图
struct PresetProviderRow: View {
    let icon: String
    let name: String
    let description: String
    let isConfigured: Bool
    let nickname: String?
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    if isConfigured {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
                
                if let nickname = nickname {
                    Text(nickname)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            if !isConfigured {
                Image(systemName: "plus.circle")
                    .foregroundStyle(.blue)
            }
        }
        .padding(.vertical, 4)
    }
}

struct ProviderRow: View {
    let provider: APIProvider
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(provider.nickname)
                .font(.headline)
            
            HStack {
                Text(provider.type.rawValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if provider.isActive {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        ModelProvidersView()
            .modelContainer(for: [APIProvider.self])
    }
}
