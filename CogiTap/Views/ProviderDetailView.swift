//
//  ProviderDetailView.swift
//  CogiTap
//
//  Created by mengfs on 11/1/25.
//

import SwiftUI
import SwiftData
import UIKit

struct ProviderDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let provider: APIProvider
    
    @State private var showManageModels = false
    @State private var showAddModel = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isEditing = false
    @State private var editedNickname: String
    @State private var editedBaseURL: String
    @State private var editedAPIKey: String
    @State private var showCopiedMessage = false
    @State private var showDeleteAPIKeyConfirmation = false
    @State private var isAPIKeyVisible = false
    
    init(provider: APIProvider) {
        self.provider = provider
        _editedNickname = State(initialValue: provider.nickname)
        _editedBaseURL = State(initialValue: provider.baseURL)
        _editedAPIKey = State(initialValue: provider.apiKey)
    }
    
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
                if isEditing {
                    TextField("昵称", text: $editedNickname)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    
                    LabeledContent("类型") {
                        Text(provider.type.displayName)
                            .foregroundStyle(.secondary)
                    }
                    
                    if provider.type == .custom {
                        TextField("Base URL", text: $editedBaseURL)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .keyboardType(.URL)
                            .textContentType(.URL)
                    } else {
                        LabeledContent("Base URL") {
                            Text(provider.baseURL)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    LabeledContent("昵称", value: provider.nickname)
                    LabeledContent("类型", value: provider.type.displayName)
                    LabeledContent("Base URL", value: provider.baseURL)
                }
            }
            
            Section("API密钥") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 12) {
                        if isEditing {
                            if isAPIKeyVisible {
                                TextField("API Key", text: $editedAPIKey)
                                    .textContentType(.password)
                                    .autocapitalization(.none)
                                    .autocorrectionDisabled()
                            } else {
                                SecureField("API Key", text: $editedAPIKey)
                                    .textContentType(.password)
                                    .autocapitalization(.none)
                                    .autocorrectionDisabled()
                            }
                        } else {
                            let keyIsEmpty = provider.apiKey.isEmpty
                            Text(keyIsEmpty ? "尚未设置" : displayedAPIKey)
                                .font(.body)
                                .foregroundStyle(keyIsEmpty ? .secondary : .primary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                        
                        Spacer(minLength: 8)
                        
                        HStack(spacing: 12) {
                            Button {
                                toggleAPIKeyVisibility()
                            } label: {
                                Image(systemName: isAPIKeyVisible ? "eye.slash" : "eye")
                            }
                            .disabled(currentAPIKey.isEmpty)
                            
                            Button {
                                copyAPIKey()
                            } label: {
                                Image(systemName: "doc.on.doc")
                            }
                            .disabled(currentAPIKey.isEmpty)
                            
                            Button(role: .destructive) {
                                requestDeleteAPIKey()
                            } label: {
                                Image(systemName: "trash")
                            }
                            .disabled(currentAPIKey.isEmpty)
                        }
                        .buttonStyle(.borderless)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(.systemGray6))
                    )
                    
                    if showCopiedMessage {
                        Text("已复制到剪贴板")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
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
        .navigationTitle(isEditing ? "编辑服务商" : provider.nickname)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                if isEditing {
                    Button("保存") {
                        saveChanges()
                    }
                    .disabled(!canSave)
                } else {
                    Button("编辑") {
                        beginEditing()
                    }
                }
            }
            if isEditing {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        cancelEditing()
                    }
                }
            }
        }
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
        .confirmationDialog("删除API密钥", isPresented: $showDeleteAPIKeyConfirmation) {
            Button("删除", role: .destructive) {
                clearAPIKey()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("删除后需要重新填写API密钥才能继续使用服务商")
        }
        .onChange(of: provider.nickname) { _, newValue in
            if !isEditing {
                editedNickname = newValue
            }
        }
        .onChange(of: provider.baseURL) { _, newValue in
            if !isEditing {
                editedBaseURL = newValue
            }
        }
        .onChange(of: provider.apiKey) { _, newValue in
            if !isEditing {
                editedAPIKey = newValue
            }
        }
    }
    
    private var canSave: Bool {
        let trimmedNickname = editedNickname.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedBase = editedBaseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if provider.type == .custom {
            return !trimmedNickname.isEmpty && !trimmedBase.isEmpty
        }
        return !trimmedNickname.isEmpty
    }
    
    private var currentAPIKey: String {
        isEditing ? editedAPIKey : provider.apiKey
    }
    
    private var maskedCurrentAPIKey: String {
        let key = currentAPIKey
        guard !key.isEmpty else { return "" }
        let bulletCount = max(4, min(key.count, 12))
        return String(repeating: "•", count: bulletCount)
    }
    
    private var displayedAPIKey: String {
        let key = provider.apiKey
        guard !key.isEmpty else { return "" }
        return isAPIKeyVisible ? key : maskedCurrentAPIKey
    }
    
    private func beginEditing() {
        if !isEditing {
            editedNickname = provider.nickname
            editedBaseURL = provider.baseURL
            editedAPIKey = provider.apiKey
            isEditing = true
        }
    }
    
    private func cancelEditing() {
        isEditing = false
        syncEditedStateWithProvider()
        showCopiedMessage = false
        isAPIKeyVisible = false
    }
    
    private func saveChanges() {
        let trimmedNickname = editedNickname.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAPIKey = editedAPIKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedBaseURL = editedBaseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedNickname.isEmpty else {
            errorMessage = "昵称不能为空"
            showError = true
            return
        }
        
        if provider.type == .custom && trimmedBaseURL.isEmpty {
            errorMessage = "Base URL 不能为空"
            showError = true
            return
        }
        
        provider.nickname = trimmedNickname
        provider.baseURL = provider.type == .custom ? trimmedBaseURL : defaultBaseURL(for: provider.type)
        provider.apiKey = trimmedAPIKey
        
        do {
            try modelContext.save()
            isEditing = false
            syncEditedStateWithProvider()
            isAPIKeyVisible = false
        } catch {
            errorMessage = "保存失败: \(error.localizedDescription)"
            showError = true
        }
    }
    
    private func syncEditedStateWithProvider() {
        editedNickname = provider.nickname
        editedBaseURL = provider.baseURL
        editedAPIKey = provider.apiKey
    }
    
    private func copyAPIKey() {
        let key = currentAPIKey
        guard !key.isEmpty else { return }
        UIPasteboard.general.string = key
        showCopiedMessage = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            showCopiedMessage = false
        }
    }
    
    private func requestDeleteAPIKey() {
        guard !currentAPIKey.isEmpty else { return }
        showDeleteAPIKeyConfirmation = true
    }
    
    private func clearAPIKey() {
        editedAPIKey = ""
        provider.apiKey = ""
        isAPIKeyVisible = false
        do {
            try modelContext.save()
        } catch {
            errorMessage = "删除API密钥失败: \(error.localizedDescription)"
            showError = true
        }
    }
    
    private func toggleAPIKeyVisibility() {
        guard !currentAPIKey.isEmpty else { return }
        withAnimation(.easeInOut(duration: 0.15)) {
            isAPIKeyVisible.toggle()
        }
    }
    
    private func defaultBaseURL(for type: ProviderType) -> String {
        switch type {
        case .openai:
            return "https://api.openai.com"
        case .anthropic:
            return "https://api.anthropic.com"
        case .gemini:
            return "https://generativelanguage.googleapis.com"
        case .openrouter:
            return "https://openrouter.ai"
        case .custom:
            return provider.baseURL
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
