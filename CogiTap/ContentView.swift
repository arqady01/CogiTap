//
//  ContentView.swift
//  CogiTap
//
//  Created by mengfs on 11/1/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Conversation.updatedAt, order: .reverse) private var conversations: [Conversation]
    @Query private var allModels: [ChatModel]
    
    @StateObject private var chatService = ChatService()
    
    @State private var currentConversation: Conversation?
    @State private var selectedModel: ChatModel?
    @State private var showSidebar = false
    @State private var showSettings = false
    @State private var showModelSelector = false
    @State private var showConversationSettings = false
    @State private var inputText = ""
    @FocusState private var isKeyboardFocused: Bool
    
    var body: some View {
        ZStack {
            // 主聊天界面
            VStack(spacing: 0) {
                // 顶部栏
                ChatTopBar(
                    conversation: currentConversation,
                    selectedModel: selectedModel,
                    onMenuTap: { showSidebar = true },
                    onSettingsTap: { showSettings = true }
                )
                .padding(.horizontal, 20)
                .padding(.top, 12)
                
                // 消息列表
                if let conversation = currentConversation {
                    MessageListView(conversation: conversation)
                } else {
                    EmptyStateView()
                }
                
                // 底部输入栏
                ChatInputBar(
                    inputText: $inputText,
                    isKeyboardFocused: $isKeyboardFocused,
                    selectedModel: selectedModel,
                    isStreaming: chatService.isStreaming,
                    onSend: sendMessage,
                    onStopGeneration: { chatService.stopGeneration() },
                    onModelTap: { showModelSelector = true },
                    onSettingsTap: { 
                        if currentConversation != nil {
                            showConversationSettings = true
                        }
                    }
                )
                .ignoresSafeArea(.container, edges: .bottom)
            }
            
            // 侧边栏
            if showSidebar {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        showSidebar = false
                    }
                
                HStack {
                    ConversationSidebarView(
                        selectedConversation: $currentConversation,
                        isPresented: $showSidebar,
                        showSettings: $showSettings
                    )
                    .transition(.move(edge: .leading))
                    
                    Spacer()
                }
            }
        }
        .fullScreenCover(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showModelSelector) {
            ModelSelectorView(selectedModel: $selectedModel)
        }
        .sheet(isPresented: $showConversationSettings) {
            if let conversation = currentConversation {
                ConversationSettingsView(conversation: conversation)
            }
        }
        .onAppear {
            initializeApp()
        }
        .animation(.easeInOut, value: showSidebar)
    }
    
    private func initializeApp() {
        // 如果没有会话，创建一个新会话
        if conversations.isEmpty {
            let newConversation = Conversation()
            modelContext.insert(newConversation)
            currentConversation = newConversation
            try? modelContext.save()
        } else if currentConversation == nil {
            currentConversation = conversations.first
        }
        
        // 选择第一个已启用的模型
        if selectedModel == nil {
            selectedModel = allModels.first { $0.isEnabled }
        }
    }
    
    private func sendMessage() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let conversation = currentConversation,
              let model = selectedModel else {
            return
        }
        
        let messageContent = inputText
        inputText = ""
        isKeyboardFocused = false
        
        Task {
            do {
                try await chatService.sendMessage(
                    content: messageContent,
                    conversation: conversation,
                    model: model,
                    modelContext: modelContext
                )
                
                // 更新会话时间
                conversation.updatedAt = Date()
                try? modelContext.save()
            } catch {
                print("发送消息失败: \(error)")
            }
        }
    }
}

// MARK: - Chat Components

struct ChatTopBar: View {
    let conversation: Conversation?
    let selectedModel: ChatModel?
    let onMenuTap: () -> Void
    let onSettingsTap: () -> Void
    
    var body: some View {
        ZStack {
            HStack {
                Button(action: onMenuTap) {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button(action: onSettingsTap) {
                    ProfileAvatar()
                }
            }
            
            Text(conversation?.title ?? "新对话")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
        }
    }
}

struct ProfileAvatar: View {
    var body: some View {
        Circle()
            .strokeBorder(AngularGradient(gradient: Gradient(colors: [
                .red, .orange, .yellow, .green, .blue, .purple, .red
            ]), center: .center), lineWidth: 3)
            .frame(width: 44, height: 44)
            .overlay(
                Circle()
                    .fill(Color(.systemGray6))
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(.white)
                    )
                    .padding(4)
            )
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack {
            Spacer()
            
            Text("Cogito, ergo sum")
                .font(.system(size: 42, weight: .semibold))
                .foregroundStyle(Color(red: 26/255, green: 115/255, blue: 232/255))
                .multilineTextAlignment(.center)
            
            Text("我思故我在")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top, 8)
            
            Spacer()
        }
    }
}

struct MessageListView: View {
    @Bindable var conversation: Conversation
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(conversation.sortedMessages) { message in
                        MessageBubbleView(message: message)
                            .id(message.id)
                    }
                }
                .padding(.vertical)
            }
            .onChange(of: conversation.sortedMessages.count) { _, _ in
                if let lastMessage = conversation.sortedMessages.last {
                    withAnimation {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }
}

struct ChatInputBar: View {
    @Binding var inputText: String
    @FocusState.Binding var isKeyboardFocused: Bool
    let selectedModel: ChatModel?
    let isStreaming: Bool
    let onSend: () -> Void
    let onStopGeneration: () -> Void
    let onModelTap: () -> Void
    let onSettingsTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ZStack(alignment: .topLeading) {
                if inputText.isEmpty {
                    Text("connect any model, chat anywhere")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)
                        .padding(.leading, 4)
                }
                
                TextEditor(text: $inputText)
                    .font(.footnote)
                    .foregroundStyle(.primary)
                    .focused($isKeyboardFocused)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .frame(minHeight: 20, maxHeight: 100)
            }
            
            HStack(spacing: 10) {
                Button(action: {}) {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.primary)
                        .frame(width: 32, height: 32)
                }
                
                Button(action: onSettingsTap) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.primary)
                        .frame(width: 32, height: 32)
                }
                
                Spacer()
                
                Button(action: onModelTap) {
                    Text(selectedModel?.modelName ?? "选择模型")
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(1)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule(style: .continuous)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                        .foregroundStyle(.primary)
                }
                
                if isStreaming {
                    Button(action: onStopGeneration) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 38, height: 38)
                            .overlay(
                                Image(systemName: "stop.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.white)
                            )
                    }
                } else {
                    Button(action: onSend) {
                        Circle()
                            .stroke(Color(.systemGray4), lineWidth: 1)
                            .frame(width: 38, height: 38)
                            .overlay(
                                Image(systemName: "sparkles")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.primary)
                            )
                    }
                    .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .padding(.top, 28)
        .padding(.horizontal, 20)
        .padding(.bottom, 10)
        .background(
            GeometryReader { geometry in
                UnevenRoundedRectangle(cornerRadii: .init(
                    topLeading: 32,
                    topTrailing: 32
                ), style: .continuous)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color(.sRGBLinear, white: 0, opacity: 0.12), radius: 16, x: 0, y: 8)
                    .frame(height: geometry.size.height + geometry.safeAreaInsets.bottom)
                    .offset(y: 0)
            }
        )
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Conversation.self, Message.self, APIProvider.self, ChatModel.self])
}
