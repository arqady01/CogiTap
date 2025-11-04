//
//  MessageBubbleView.swift
//  CogiTap
//
//  Created by mengfs on 11/1/25.
//

import SwiftUI

struct MessageBubbleView: View {
    @Bindable var message: Message
    @State private var showReasoningContent = false
    @AppStorage(AppearanceStorageKey.userBubbleColor)
    private var userBubbleColorName: String = ChatBubbleColorOption.default.rawValue
    
    private var userBubbleOption: ChatBubbleColorOption {
        ChatBubbleColorOption(rawValue: userBubbleColorName) ?? .default
    }
    
    var body: some View {
        Group {
            if message.messageRole == .assistant {
                assistantLayout
            } else {
                userLayout
            }
        }
        .padding(.horizontal)
    }
}

private extension MessageBubbleView {
    var assistantLayout: some View {
        HStack(alignment: .top, spacing: 12) {
            assistantAvatar
            
            VStack(alignment: .leading, spacing: 12) {
                reasoningSection
                bubbleContent(alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer(minLength: 0)
        }
    }
    
    var userLayout: some View {
        HStack(alignment: .top, spacing: 12) {
            Spacer(minLength: 0)
            
            bubbleContent(alignment: .trailing)
        }
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
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                            Text(showReasoningContent ? "点击收起推理动画" : "点击展开推理动画")
                                .font(.caption2)
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
        VStack(alignment: alignment, spacing: 4) {
            Text(message.content)
                .font(.body)
                .foregroundStyle(messageTextColor)
                .textSelection(.enabled)
                .multilineTextAlignment(alignment == .trailing ? .trailing : .leading)
            
            if message.isStreaming {
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
                .frame(maxWidth: .infinity, alignment: alignment == .trailing ? .trailing : .leading)
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
    }
    
    private var assistantAvatar: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(Color.blue.gradient)
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: "sparkles")
                        .font(.system(size: 14))
                        .foregroundStyle(.white)
                )
            
            Spacer(minLength: 0)
        }
    }
    
    private var messageBubbleFillColor: Color {
        switch message.messageRole {
        case .user:
            return userBubbleOption.fillColor
        case .assistant:
            return Color(.systemGray6)
        case .system:
            return Color(.systemGray6)
        }
    }
    
    private var messageBubbleBorderColor: Color {
        switch message.messageRole {
        case .user:
            return userBubbleOption.needsBorder ? userBubbleOption.borderColor : .clear
        case .assistant, .system:
            return Color.clear
        }
    }
    
    private var messageBubbleBorderWidth: CGFloat {
        switch message.messageRole {
        case .user:
            return userBubbleOption.needsBorder ? 1 : 0
        case .assistant, .system:
            return 0
        }
    }
    
    private var messageTextColor: Color {
        switch message.messageRole {
        case .user:
            return userBubbleOption.textColor
        case .assistant, .system:
            return .primary
        }
    }
    
    private var streamingIndicatorColor: Color {
        switch message.messageRole {
        case .user:
            return userBubbleOption.textColor
        case .assistant, .system:
            return Color.secondary
        }
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
}

#Preview {
    VStack(spacing: 16) {
        MessageBubbleView(message: Message(
            role: .user,
            content: "你好，请帮我解释一下量子计算的基本原理。"
        ))
        
        MessageBubbleView(message: Message(
            role: .assistant,
            content: "量子计算是一种利用量子力学原理进行信息处理的计算方式...",
            reasoningContent: "首先，我需要理解用户想要了解量子计算的哪些方面。考虑到这是一个基础性问题，我应该从最基本的概念开始解释..."
        ))
    }
    .padding()
    .background(Color(.systemBackground))
}
