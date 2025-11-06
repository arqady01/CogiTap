//
//  MemoryManagementView.swift
//  CogiTap
//
//  Created by mengfs on 11/3/25.
//

import SwiftUI
import SwiftData

struct MemoryManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MemoryRecord.updatedAt, order: .reverse) private var records: [MemoryRecord]
    @Query private var configs: [MemoryConfig]
    
    @State private var searchText = ""
    @State private var showClearConfirmation = false
    @State private var editorMode: MemoryEditorView.Mode?
    
    private let memoryService = MemoryService.shared
    
    private var activeConfig: MemoryConfig? {
        configs.first
    }
    
    private var filteredRecords: [MemoryRecord] {
        guard !searchText.isEmpty else { return records }
        let keyword = searchText.lowercased()
        return records.filter { record in
            record.content.lowercased().contains(keyword)
        }
    }
    
    var body: some View {
        List {
            if let config = activeConfig {
                Section("功能开关") {
                    Toggle(isOn: binding(for: \MemoryConfig.isMemoryEnabled, config: config)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("启用记忆功能")
                            Text("关闭后将不会保存、检索或更新记忆")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Toggle(isOn: binding(for: \MemoryConfig.isCrossChatEnabled, config: config)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("跨聊天共享记忆")
                            Text("关闭后仅在当前会话中使用新记忆")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            
            Section("记忆列表") {
                if filteredRecords.isEmpty {
                    ContentUnavailableView(
                        searchText.isEmpty ? "暂无记忆" : "未找到匹配记忆",
                        systemImage: "tray"
                    )
                } else {
                    ForEach(filteredRecords) { record in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(record.content)
                                .font(.body)
                                .foregroundStyle(.primary)
                                .lineLimit(3)
                            
                            HStack(spacing: 8) {
                                Label(record.updatedAt.formatted(date: .numeric, time: .shortened), systemImage: "clock")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                if record.conversationId != nil {
                                    Label("当前会话", systemImage: "bubble.left.and.bubble.right")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                } else {
                                    Label("跨会话", systemImage: "globe")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            editorMode = .edit(record)
                        }
                    }
                    .onDelete(perform: delete)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("记忆管理")
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    editorMode = .create(UUID())
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("新建记忆")
            }
            ToolbarItem(placement: .bottomBar) {
                Button(role: .destructive) {
                    showClearConfirmation = true
                } label: {
                    Label("清空所有", systemImage: "trash")
                }
                .disabled(records.isEmpty && activeConfig == nil)
            }
        }
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "搜索记忆内容")
        .alert("清空所有记忆", isPresented: $showClearConfirmation) {
            Button("取消", role: .cancel) {}
            Button("确定", role: .destructive) {
                clearAll()
            }
        } message: {
            Text("此操作将删除全部记忆并重置记忆开关，请确认。")
        }
        .sheet(item: $editorMode) { mode in
            MemoryEditorView(mode: mode)
                .modelContext(modelContext)
        }
        .task {
            if configs.isEmpty {
                _ = memoryService.getOrCreateConfig(using: modelContext)
            }
        }
    }
    
    private func binding(
        for keyPath: ReferenceWritableKeyPath<MemoryConfig, Bool>,
        config: MemoryConfig
    ) -> Binding<Bool> {
        Binding(
            get: { config[keyPath: keyPath] },
            set: { newValue in
                config[keyPath: keyPath] = newValue
                config.updatedAt = Date()
                try? modelContext.save()
            }
        )
    }
    
    private func delete(at offsets: IndexSet) {
        let targets = offsets.map { filteredRecords[$0] }
        targets.forEach { record in
            memoryService.deleteMemory(record, context: modelContext)
        }
    }
    
    private func clearAll() {
        _ = memoryService.clearAllMemories(context: modelContext)
        if let config = activeConfig {
            config.isMemoryEnabled = true
            config.isCrossChatEnabled = true
            config.updatedAt = Date()
            try? modelContext.save()
        } else {
            _ = memoryService.getOrCreateConfig(using: modelContext)
        }
    }
}

struct MemoryEditorView: View {
    enum Mode: Identifiable {
        case create(UUID)
        case edit(MemoryRecord)
        
        var id: String {
            switch self {
            case .create(let token):
                return "create-\(token.uuidString)"
            case .edit(let record):
                return record.id.uuidString
            }
        }
    }

    let mode: Mode
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var content: String
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    private let memoryService = MemoryService.shared
    
    init(mode: Mode) {
        self.mode = mode
        switch mode {
        case .create:
            _content = State(initialValue: "")
        case .edit(let record):
            _content = State(initialValue: record.content)
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                TextEditor(text: $content)
                    .font(.body)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(.secondarySystemBackground))
                    )
                    .frame(minHeight: 160)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color(.separator), lineWidth: 0.5)
                    )
                    .padding(.horizontal)
                Spacer()
            }
            .padding(.top)
            .navigationTitle(modeTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { persist() }
                }
            }
            .alert("保存失败", isPresented: $showAlert) {
                Button("好的", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private var modeTitle: String {
        switch mode {
        case .create: return "新建记忆"
        case .edit: return "编辑记忆"
        }
    }
    
    private func persist() {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            alertMessage = "内容不能为空"
            showAlert = true
            return
        }
        
        switch mode {
        case .create:
            let saved = memoryService.saveMemory(content: trimmed, conversation: nil, context: modelContext)
            if saved {
                dismiss()
            } else {
                alertMessage = "内容重复或未开启记忆功能"
                showAlert = true
            }
        case .edit(let record):
            record.content = trimmed
            record.updatedAt = Date()
            try? modelContext.save()
            dismiss()
        }
    }
}
