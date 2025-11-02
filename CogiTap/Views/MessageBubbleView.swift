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
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if message.messageRole == .user {
                Spacer()
            }
            
            VStack(alignment: message.messageRole == .user ? .trailing : .leading, spacing: 8) {
                // 推理内容（如果有）
                if let reasoning = message.reasoningContent, !reasoning.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Button {
                            withAnimation {
                                showReasoningContent.toggle()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "brain")
                                    .font(.caption)
                                Text("思考过程")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                Spacer()
                                Image(systemName: showReasoningContent ? "chevron.up" : "chevron.down")
                                    .font(.caption2)
                            }
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(.systemGray6))
                            )
                        }
                        
                        if showReasoningContent {
                            Text(reasoning)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemGray6))
                                )
                                .contextMenu {
                                    Button {
                                        UIPasteboard.general.string = reasoning
                                    } label: {
                                        Label("复制", systemImage: "doc.on.doc")
                                    }
                                }
                        }
                    }
                }
                
                // 主要内容
                HStack(alignment: .bottom, spacing: 8) {
                    if message.messageRole == .assistant {
                        VStack(spacing: 4) {
                            Circle()
                                .fill(Color.blue.gradient)
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 14))
                                        .foregroundStyle(.white)
                                )
                            
                            Spacer()
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(message.content)
                            .font(.body)
                            .foregroundStyle(message.messageRole == .user ? .white : .primary)
                            .textSelection(.enabled)
                        
                        if message.isStreaming {
                            HStack(spacing: 4) {
                                ForEach(0..<3) { index in
                                    Circle()
                                        .fill(message.messageRole == .user ? Color.white.opacity(0.7) : Color.secondary)
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
                        RoundedRectangle(cornerRadius: 16)
                            .fill(message.messageRole == .user ? Color.blue : Color(.systemGray6))
                    )
                    .contextMenu {
                        Button {
                            UIPasteboard.general.string = message.content
                        } label: {
                            Label("复制", systemImage: "doc.on.doc")
                        }
                    }
                }
            }
            
            if message.messageRole == .assistant {
                Spacer()
            }
        }
        .padding(.horizontal)
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
}
