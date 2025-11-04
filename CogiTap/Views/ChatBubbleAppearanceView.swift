//
//  ChatBubbleAppearanceView.swift
//  CogiTap
//
//  Created by Codex on 11/1/25.
//

import SwiftUI

struct ChatBubbleAppearanceView: View {
    @AppStorage(AppearanceStorageKey.userBubbleColor)
    private var selectedColorName: String = ChatBubbleColorOption.default.rawValue
    
    private var selectedOption: ChatBubbleColorOption {
        ChatBubbleColorOption(rawValue: selectedColorName) ?? .default
    }
    
    var body: some View {
        List {
            Section("用户消息") {
                ForEach(ChatBubbleColorOption.allCases) { option in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedColorName = option.rawValue
                        }
                    } label: {
                        HStack(spacing: 16) {
                            BubblePreview(option: option)
                            
                            Text(option.displayName)
                                .font(.body)
                            
                            Spacer()
                            
                            if option == selectedOption {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                        .padding(.vertical, 6)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationTitle("聊天气泡")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct BubblePreview: View {
    let option: ChatBubbleColorOption
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(option.fillColor)
                .frame(width: 88, height: 40)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(option.borderColor, lineWidth: option.borderColor == .clear ? 0 : 1)
                )
                .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 4)
            
            Text("示例")
                .font(.footnote)
                .fontWeight(.medium)
                .foregroundStyle(option.textColor)
        }
    }
}

#Preview {
    NavigationStack {
        ChatBubbleAppearanceView()
    }
}
