//
//  MessageBubbleView.swift
//  CogiTap
//
//  Created by mengfs on 11/1/25.
//

import SwiftUI
import SwiftData
import UIKit

struct MessageBubbleView: View {
    @Bindable var message: Message
    @State private var showReasoningContent = false
    @AppStorage(AppearanceStorageKey.userBubbleColor)
    private var userBubbleColorName: String = ChatBubbleColorOption.default.rawValue
    @AppStorage(AppearanceStorageKey.userMessageFont)
    private var userFontName: String = ChatFontSizeOption.default.rawValue
    @AppStorage(AppearanceStorageKey.assistantMessageFont)
    private var assistantFontName: String = ChatFontSizeOption.default.rawValue
    @AppStorage(AppearanceStorageKey.reasoningFont)
    private var reasoningFontName: String = ChatFontSizeOption.default.rawValue
    
    private var userBubbleOption: ChatBubbleColorOption {
        ChatBubbleColorOption(rawValue: userBubbleColorName) ?? .default
    }
    
    private var userFontOption: ChatFontSizeOption {
        ChatFontSizeOption(rawValue: userFontName) ?? .default
    }
    
    private var assistantFontOption: ChatFontSizeOption {
        ChatFontSizeOption(rawValue: assistantFontName) ?? .default
    }
    
    private var reasoningFontOption: ChatFontSizeOption {
        ChatFontSizeOption(rawValue: reasoningFontName) ?? .default
    }
    
    var body: some View {
        Group {
            switch message.messageRole {
            case .assistant:
                assistantLayout
            case .user:
                userLayout
            case .system:
                systemLayout
            case .tool:
                toolLayout
            }
        }
        .padding(.horizontal)
    }
}

private extension MessageBubbleView {
    var assistantLayout: some View {
        VStack(alignment: .leading, spacing: 12) {
            reasoningSection
            bubbleContent(alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    var userLayout: some View {
        HStack(alignment: .top, spacing: 12) {
            Spacer(minLength: 0)
            
            bubbleContent(alignment: .trailing)
        }
    }
    
    var systemLayout: some View {
        VStack(alignment: .leading, spacing: 8) {
            bubbleContent(alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .opacity(0.85)
    }
    
    var toolLayout: some View {
        HStack(alignment: .center, spacing: 8) {
            Image(systemName: "wrench.and.screwdriver")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(message.content.isEmpty ? "工具执行完成" : message.content)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .center)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
    
    @ViewBuilder
    var reasoningSection: some View {
        if let reasoning = message.reasoningContent, !reasoning.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Button {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.9)) {
                        showReasoningContent.toggle()
                    }
                } label: {
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("思维链轨道")
                                .font(.system(size: max(reasoningFontOption.reasoningSize - 1, 11), weight: .semibold))
                                .foregroundStyle(.primary)
                            Text(showReasoningContent ? "点击收起推理动画" : "点击展开推理动画")
                                .font(.system(size: max(reasoningFontOption.reasoningSize - 2, 10)))
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: showReasoningContent ? "chevron.up" : "chevron.down")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color(.systemGray6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
                
                if showReasoningContent {
                   ReasoningFlowView(reasoning: reasoning)
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .opacity
                        ))
                        .contextMenu {
                            Button {
                                UIPasteboard.general.string = reasoning
                            } label: {
                                Label("复制思维链", systemImage: "doc.on.doc")
                            }
                        }
                }
            }
        }
    }
    
    @ViewBuilder
    private func bubbleContent(alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 6) {
            if shouldShowStreamingPlaceholder {
                StreamingResponsePlaceholder(
                    accentColor: placeholderAccentColor,
                    height: max(messageFontSize + 10, 22)
                )
            } else {
                Text(message.content)
                    .font(.system(size: messageFontSize))
                    .foregroundStyle(messageTextColor)
                    .textSelection(.enabled)
                    .multilineTextAlignment(alignment == .trailing ? .trailing : .leading)
            }
            
            if message.isStreaming,
               !message.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                HStack(spacing: 4) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(streamingIndicatorColor.opacity(0.7))
                            .frame(width: 4, height: 4)
                            .scaleEffect(message.isStreaming ? 1.0 : 0.5)
                            .animation(
                                .easeInOut(duration: 0.6)
                                .repeatForever()
                                .delay(Double(index) * 0.2),
                                value: message.isStreaming
                            )
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(messageBubbleFillColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(messageBubbleBorderColor, lineWidth: messageBubbleBorderWidth)
        )
        .shadow(color: messageShadowColor, radius: messageShadowRadius, x: 0, y: messageShadowYOffset)
        .contextMenu {
            Button {
                UIPasteboard.general.string = message.content
            } label: {
                Label("复制", systemImage: "doc.on.doc")
            }
        }
        .frame(maxWidth: bubbleMaxWidth, alignment: alignment == .trailing ? .trailing : .leading)
    }
    
    private var messageBubbleFillColor: Color {
        switch message.messageRole {
        case .user:
            return userBubbleOption.fillColor
        case .assistant:
            return Color(.systemGray6)
        case .system:
            return Color(.secondarySystemBackground)
        case .tool:
            return Color(.systemGray6)
        }
    }
    
    private var messageBubbleBorderColor: Color {
        switch message.messageRole {
        case .user:
            return userBubbleOption.needsBorder ? userBubbleOption.borderColor : .clear
        case .assistant, .system, .tool:
            return Color.clear
        }
    }
    
    private var messageBubbleBorderWidth: CGFloat {
        switch message.messageRole {
        case .user:
            return userBubbleOption.needsBorder ? 1 : 0
        case .assistant, .system, .tool:
            return 0
        }
    }
    
    private var messageTextColor: Color {
        switch message.messageRole {
        case .user:
            return userBubbleOption.textColor
        case .assistant, .system:
            return .primary
        case .tool:
            return .secondary
        }
    }
    
    private var streamingIndicatorColor: Color {
        switch message.messageRole {
        case .user:
            return userBubbleOption.textColor
        case .assistant, .system:
            return Color.secondary
        case .tool:
            return Color.secondary
        }
    }
    
    private var placeholderAccentColor: Color {
        switch message.messageRole {
        case .user:
            return userBubbleOption.fillColor
        case .assistant, .system, .tool:
            return Color.blue
        }
    }
    
    private var shouldShowStreamingPlaceholder: Bool {
        message.isStreaming && message.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var messageShadowColor: Color {
        message.messageRole == .assistant ? Color.black.opacity(0.05) : Color.black.opacity(0.08)
    }
    
    private var messageShadowRadius: CGFloat {
        message.messageRole == .assistant ? 6 : 8
    }
    
    private var messageShadowYOffset: CGFloat {
        message.messageRole == .assistant ? 3 : 4
    }
    
    private var bubbleMaxWidth: CGFloat? {
        let screenWidth = UIScreen.main.bounds.width
        return min(screenWidth * 0.78, 360)
    }
    
    private var messageFontSize: CGFloat {
        switch message.messageRole {
        case .user:
            return userFontOption.userMessageSize
        case .assistant, .system:
            return assistantFontOption.assistantMessageSize
        case .tool:
            return max(assistantFontOption.assistantMessageSize - 2, 11)
        }
    }
    
}

private struct StreamingResponsePlaceholder: View {
    let accentColor: Color
    let height: CGFloat
    @State private var highlightWidth: CGFloat = 64
    
    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            Capsule(style: .continuous)
                .fill(accentColor.opacity(0.14))
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(accentColor.opacity(0.2), lineWidth: 1)
                )
                .overlay(
                    TimelineView(.animation) { timeline in
                        let time = timeline.date.timeIntervalSinceReferenceDate
                        let progress = (sin(time * 1.8) + 1) * 0.5
                        let glowWidth = max(highlightWidth, width * 0.32)
                        let offsetRange = width - glowWidth
                        Capsule(style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.0),
                                        Color.white.opacity(0.9),
                                        Color.white.opacity(0.0)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: glowWidth)
                            .offset(x: (progress - 0.5) * offsetRange)
                            .blendMode(.plusLighter)
                    }
                    .allowsHitTesting(false)
                )
                .onAppear {
                    highlightWidth = max(64, width * 0.28)
                }
        }
        .frame(height: height)
    }
}

private struct MessageBubblePreview: View {
    let container: ModelContainer?
    let userMessage: Message?
    let assistantMessage: Message?
    
    init() {
        if let container = try? ModelContainer(
            for: Conversation.self,
                Message.self,
                ChatModel.self,
                APIProvider.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        ) {
            self.container = container
            let context = container.mainContext
            
            let provider = APIProvider(
                nickname: "默认分组",
                providerType: .openai,
                baseURL: "https://api.openai.com/v1",
                apiKey: "preview-key"
            )
            let chatModel = ChatModel(
                modelName: "gpt-4o",
                displayName: "实验室",
                isEnabled: true,
                provider: provider
            )
            let conversation = Conversation(
                title: "Preview",
                selectedModelId: chatModel.id
            )
            let userMessage = Message(
                role: .user,
                content: "你好，请帮我解释一下量子计算的基本原理。",
                conversation: conversation
            )
            let assistantMessage = Message(
                role: .assistant,
                content: "量子计算是一种利用量子力学原理进行信息处理的计算方式...",
                reasoningContent: "首先，我需要理解用户想要了解量子计算的哪些方面。考虑到这是一个基础性问题，我应该从最基本的概念开始解释...",
                conversation: conversation
            )
            
            context.insert(provider)
            context.insert(chatModel)
            context.insert(conversation)
            context.insert(userMessage)
            context.insert(assistantMessage)
            
            self.userMessage = userMessage
            self.assistantMessage = assistantMessage
        } else {
            self.container = nil
            self.userMessage = nil
            self.assistantMessage = nil
        }
    }
    
    var body: some View {
        if let container,
           let userMessage,
           let assistantMessage {
            VStack(spacing: 16) {
                MessageBubbleView(message: userMessage)
                MessageBubbleView(message: assistantMessage)
            }
            .padding()
            .background(Color(.systemBackground))
            .modelContainer(container)
        } else {
            Text("Preview Unavailable")
        }
    }
}

#Preview {
    MessageBubblePreview()
}
