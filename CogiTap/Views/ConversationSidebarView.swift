//
//  ConversationSidebarView.swift
//  CogiTap
//
//  Created by mengfs on 11/1/25.
//

import SwiftUI
import SwiftData

struct ConversationSidebarView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Conversation.updatedAt, order: .reverse) private var conversations: [Conversation]
    
    @Binding var selectedConversation: Conversation?
    @Binding var isPresented: Bool
    @Binding var showSettings: Bool
    
    @State private var showingDeleteAlert = false
    @State private var conversationToDelete: Conversation?
    @State private var editingConversation: Conversation?
    @State private var newTitle = ""
    @State private var conversationForSettings: Conversation?
    @State private var isBulkDeleteMode = false
    @State private var pendingDeletionIDs = Set<UUID>()
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text("对话")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button {
                    createNewConversation()
                } label: {
                    Image(systemName: "externaldrive.badge.plus")
                        .font(.title3)
                        .foregroundStyle(.blue)
                }
                .disabled(isBulkDeleteMode)
                
                Button {
                    exitBulkDeleteMode()
                    isPresented = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            
        // 会话列表
        ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(conversations) { conversation in
                        ConversationRow(
                            conversation: conversation,
                            isSelected: selectedConversation?.id == conversation.id,
                            isDeleteMode: isBulkDeleteMode,
                            isSelectedForDeletion: pendingDeletionIDs.contains(conversation.id),
                            onTap: {
                                selectedConversation = conversation
                                isPresented = false
                            },
                            onEdit: {
                                editingConversation = conversation
                                newTitle = conversation.title
                            },
                            onDelete: {
                                conversationToDelete = conversation
                                showingDeleteAlert = true
                            },
                            onSettings: {
                                conversationForSettings = conversation
                            },
                            onSelectionToggle: {
                                toggleSelection(for: conversation)
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
            
            Spacer()
            
            // 底部按钮栏
            HStack(spacing: 12) {
                SidebarButton(icon: "square.and.pencil") {
                    // 占位按钮
                }
                .disabled(isBulkDeleteMode)
                
                SidebarButton(icon: "folder") {
                    // 占位按钮
                }
                .disabled(isBulkDeleteMode)
                
                SidebarButton(icon: "archivebox") {
                    // 占位按钮
                }
                .disabled(isBulkDeleteMode)
                
                SidebarButton(icon: deleteButtonIcon) {
                    // 开始批量删除
                    handleDeleteButtonTap()
                }
                
                SidebarButton(icon: "gearshape.fill") {
                    exitBulkDeleteMode()
                    showSettings = true
                    isPresented = false
                }
                .disabled(isBulkDeleteMode)
            }
            .padding()
            .background(Color(.systemBackground))
        }
        .frame(width: 300)
        .background(Color(.systemGroupedBackground))
        .alert("删除对话", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                if let conversation = conversationToDelete {
                    deleteConversation(conversation)
                    try? modelContext.save()
                }
            }
        } message: {
            Text("确定要删除这个对话吗？此操作无法撤销。")
        }
        .alert("重命名对话", isPresented: Binding(
            get: { editingConversation != nil },
            set: { if !$0 { editingConversation = nil } }
        )) {
            TextField("标题", text: $newTitle)
            Button("取消", role: .cancel) {
                editingConversation = nil
            }
            Button("保存") {
                if let conversation = editingConversation {
                    conversation.title = newTitle
                    try? modelContext.save()
                }
                editingConversation = nil
            }
        }
        .sheet(item: $conversationForSettings) { conversation in
            ConversationSettingsView(conversation: conversation)
                .environment(\.modelContext, modelContext)
        }
    }
    
    private func deleteConversation(_ conversation: Conversation) {
        modelContext.delete(conversation)
        if selectedConversation?.id == conversation.id {
            selectedConversation = nil
        }
        if conversationForSettings?.id == conversation.id {
            conversationForSettings = nil
        }
    }
    
    private func toggleSelection(for conversation: Conversation) {
        if pendingDeletionIDs.contains(conversation.id) {
            pendingDeletionIDs.remove(conversation.id)
        } else {
            pendingDeletionIDs.insert(conversation.id)
        }
    }
    
    private func handleDeleteButtonTap() {
        if isBulkDeleteMode {
            guard !pendingDeletionIDs.isEmpty else {
                exitBulkDeleteMode()
                return
            }
            confirmBulkDeletion()
        } else {
            isBulkDeleteMode = true
        }
    }
    
    private func confirmBulkDeletion() {
        let targets = conversations.filter { pendingDeletionIDs.contains($0.id) }
        targets.forEach { deleteConversation($0) }
        try? modelContext.save()
        exitBulkDeleteMode()
    }
    
    private func exitBulkDeleteMode() {
        isBulkDeleteMode = false
        pendingDeletionIDs.removeAll()
    }
    
    private func createNewConversation() {
        let newConversation = Conversation()
        modelContext.insert(newConversation)
        selectedConversation = newConversation
        isPresented = false
        try? modelContext.save()
    }
    
    private var deleteButtonIcon: String {
        if isBulkDeleteMode && !pendingDeletionIDs.isEmpty {
            return "checkmark.circle.fill"
        }
        return "trash"
    }
}

struct ConversationRow: View {
    let conversation: Conversation
    let isSelected: Bool
    let isDeleteMode: Bool
    let isSelectedForDeletion: Bool
    let onTap: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onSettings: () -> Void
    let onSelectionToggle: () -> Void
    
    @State private var showingActions = false
    
    var body: some View {
        Button {
            if isDeleteMode {
                onSelectionToggle()
            } else {
                onTap()
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(conversation.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    if let lastMessage = conversation.sortedMessages.last {
                        Text(lastMessage.content)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                if isDeleteMode {
                    Image(systemName: isSelectedForDeletion ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(isSelectedForDeletion ? .red : .secondary)
                } else {
                    Button {
                        showingActions = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(rowBackgroundColor)
            )
        }
        .buttonStyle(.plain)
        .confirmationDialog("对话操作", isPresented: $showingActions) {
            Button("设置") {
                onSettings()
            }
            Button("重命名") {
                onEdit()
            }
            Button("删除", role: .destructive) {
                onDelete()
            }
            Button("取消", role: .cancel) {}
        }
    }
    
    private var rowBackgroundColor: Color {
        if isSelectedForDeletion {
            return Color.red.opacity(0.08)
        }
        return isSelected ? Color.blue.opacity(0.1) : Color(.systemBackground)
    }
}

struct SidebarButton: View {
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.systemGray6))
                )
        }
    }
}

#Preview {
    ConversationSidebarView(
        selectedConversation: .constant(nil),
        isPresented: .constant(true),
        showSettings: .constant(false)
    )
    .modelContainer(for: [Conversation.self])
}
