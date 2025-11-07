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
    @State private var conversationSettingsTarget: Conversation?
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
                    onMenuTap: { showSidebar = true }
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 10)
                
                // 消息列表
                if let conversation = currentConversation {
                    MessageListView(conversation: conversation)
                        .contentShape(Rectangle())
                        .simultaneousGesture(TapGesture().onEnded {
                            dismissKeyboard()
                        })
                } else {
                    EmptyStateView()
                        .contentShape(Rectangle())
                        .simultaneousGesture(TapGesture().onEnded {
                            dismissKeyboard()
                        })
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
                        if let conversation = currentConversation {
                            conversationSettingsTarget = conversation
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
        .sheet(item: $conversationSettingsTarget) { conversation in
            ConversationSettingsView(conversation: conversation)
                .environment(\.modelContext, modelContext)
        }
        .onAppear {
            initializeApp()
        }
        .onChange(of: currentConversation?.id) { _, _ in
            if let target = conversationSettingsTarget, target.id != currentConversation?.id {
                conversationSettingsTarget = nil
            }
        }
        .animation(.easeInOut, value: showSidebar)
    }
    
    private func dismissKeyboard() {
        isKeyboardFocused = false
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
        
        // 立即创建用户消息并显示
        let userMessage = Message(role: .user, content: messageContent, conversation: conversation)
        modelContext.insert(userMessage)
        
        // 立即创建助手消息（空内容，用于流式输出）
        let assistantMessage = Message(
            role: .assistant,
            content: "",
            isStreaming: true,
            conversation: conversation
        )
        modelContext.insert(assistantMessage)
        
        // 立即保存，触发UI更新
        try? modelContext.save()
        
        // 更新会话时间
        conversation.updatedAt = Date()
        try? modelContext.save()
        
        // 异步发送请求
        Task {
            do {
                try await chatService.sendMessageWithExistingMessages(
                    userMessage: userMessage,
                    assistantMessage: assistantMessage,
                    conversation: conversation,
                    model: model,
                    modelContext: modelContext
                )
            } catch {
                print("发送消息失败: \(error)")
                // 如果失败，更新助手消息显示错误
                assistantMessage.content = "错误: \(error.localizedDescription)"
                assistantMessage.isStreaming = false
                try? modelContext.save()
            }
        }
    }
}

// MARK: - Chat Components

struct ChatTopBar: View {
    let conversation: Conversation?
    let selectedModel: ChatModel?
    let onMenuTap: () -> Void
    
    var body: some View {
        ZStack {
            HStack {
                Button(action: onMenuTap) {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            
            Text(conversation?.title ?? "新对话")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
        }
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

    init(conversation: Conversation) {
        self._conversation = Bindable(conversation)
    }

    private var messages: [Message] {
        conversation.sortedMessages
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(visibleMessages) { message in
                        MessageBubbleView(message: message)
                            .id(message.id)
                    }
                }
                .padding(.vertical)
            }
            .onChange(of: messages.count) { oldValue, newValue in
                // 当消息数量变化时，立即滚动到底部
                print("消息数量变化: \(oldValue) -> \(newValue)")
                if let lastMessage = visibleMessages.last {
                    DispatchQueue.main.async {
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            .onChange(of: messages.last?.content) { oldValue, newValue in
                // 当最后一条消息内容变化时（流式更新），也滚动到底部
                if let lastMessage = visibleMessages.last, let content = newValue, !content.isEmpty {
                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                }
            }
            .onAppear {
                // 初始加载时滚动到底部
                if let lastMessage = visibleMessages.last {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    private var visibleMessages: [Message] {
        messages.filter { message in
            message.messageRole != .tool && message.messageRole != .system
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
    @AppStorage(AppearanceStorageKey.userMessageFont)
    private var userFontName: String = ChatFontSizeOption.default.rawValue
    @AppStorage(AppearanceStorageKey.userBubbleColor)
    private var userBubbleColorName: String = ChatBubbleColorOption.default.rawValue
    
    private var userFontOption: ChatFontSizeOption {
        ChatFontSizeOption(rawValue: userFontName) ?? .default
    }

    private var userBubbleOption: ChatBubbleColorOption {
        ChatBubbleColorOption(rawValue: userBubbleColorName) ?? .default
    }

    private var sendButtonColor: Color {
        userBubbleOption.accentButtonColor
    }

    private let stopButtonColor = Color(red: 0.85, green: 0.2, blue: 0.35)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ZStack(alignment: .topLeading) {
                if inputText.isEmpty {
                    Text("connect any model, chat anywhere")
                        .font(.system(size: max(userFontOption.userMessageSize - 2, 11)))
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)
                        .padding(.leading, 4)
                }
                
                TextEditor(text: $inputText)
                    .font(.system(size: userFontOption.userMessageSize))
                    .foregroundStyle(.primary)
                    .focused($isKeyboardFocused)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .frame(minHeight: -10, maxHeight: 70)
            }
            
            HStack(spacing: 10) {
                Button(action: {}) {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.black)
                        .frame(width: 32, height: 32)
                }
                
                Button(action: onSettingsTap) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.black)
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
                        .foregroundStyle(.black)
                }
                
                if isStreaming {
                    Button(action: onStopGeneration) {
                        ZStack {
                            glassCircle(baseColor: stopButtonColor)
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(Color.white)
                                .frame(width: 18, height: 18)
                                .shadow(color: Color.white.opacity(0.45), radius: 6, x: 0, y: 2)
                        }
                        .frame(width: 38, height: 38)
                    }
                } else {
                    Button(action: onSend) {
                        ZStack {
                            glassCircle(baseColor: sendButtonColor)
                            Image(systemName: "arrow.up")
                                .font(.system(size: 18, weight: .heavy))
                                .foregroundStyle(.white)
                                .shadow(color: Color.white.opacity(0.5), radius: 6, x: 0, y: 2)
                        }
                        .frame(width: 38, height: 38)
                    }
                    .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.4 : 1)
                }
            }
        }
        .padding(.top, 12)
        .padding(.horizontal, 20)
        .padding(.bottom, 3)
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

    @ViewBuilder
    private func glassCircle(baseColor: Color) -> some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            baseColor.opacity(0.92),
                            baseColor.opacity(0.6)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.9),
                            Color.white.opacity(0.05)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .scaleEffect(0.55)
                .blur(radius: 3)
            

        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Conversation.self, Message.self, APIProvider.self, ChatModel.self])
}
