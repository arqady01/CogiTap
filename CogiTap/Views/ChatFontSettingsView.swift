//
//  ChatFontSettingsView.swift
//  CogiTap
//
//  Created by Codex on 11/1/25.
//

import SwiftUI

struct ChatFontSettingsView: View {
    @AppStorage(AppearanceStorageKey.userMessageFont)
    private var userFontName: String = ChatFontSizeOption.default.rawValue
    @AppStorage(AppearanceStorageKey.reasoningFont)
    private var reasoningFontName: String = ChatFontSizeOption.default.rawValue
    @AppStorage(AppearanceStorageKey.assistantMessageFont)
    private var assistantFontName: String = ChatFontSizeOption.default.rawValue
    
    private var userSelection: ChatFontSizeOption {
        ChatFontSizeOption(rawValue: userFontName) ?? .default
    }
    
    private var reasoningSelection: ChatFontSizeOption {
        ChatFontSizeOption(rawValue: reasoningFontName) ?? .default
    }
    
    private var assistantSelection: ChatFontSizeOption {
        ChatFontSizeOption(rawValue: assistantFontName) ?? .default
    }
    
    var body: some View {
        List {
            fontSection(
                title: "用户消息",
                description: "改变用户发送消息的文本字体大小",
                selection: userSelection
            ) { option in
                userFontName = option.rawValue
            } preview: { option in
                FontPreviewCard(
                    title: "我思故我在",
                    subtitle: "自定义字号让你的表达更舒适",
                    primarySize: option.userMessageSize,
                    secondarySize: max(option.userMessageSize - 1, 11)
                )
            }
            
            fontSection(
                title: "思维链文本",
                description: "影响“思维链轨道”中的推理字体大小",
                selection: reasoningSelection
            ) { option in
                reasoningFontName = option.rawValue
            } preview: { option in
                FontPreviewCard(
                    title: "Step 3 · 推理延伸",
                    subtitle: "使用更清晰的字号查看模型思考细节",
                    primarySize: option.reasoningSize,
                    secondarySize: max(option.reasoningSize - 1, 10)
                )
            }
            
            fontSection(
                title: "模型回复",
                description: "影响助手生成的最终回答文本",
                selection: assistantSelection
            ) { option in
                assistantFontName = option.rawValue
            } preview: { option in
                FontPreviewCard(
                    title: "量子计算是一种利用量子叠加特性进行并行运算的方式。",
                    subtitle: "字号会同时应用在流式输出和完整消息上",
                    primarySize: option.assistantMessageSize,
                    secondarySize: max(option.assistantMessageSize - 1, 11)
                )
            }
        }
        .navigationTitle("文本字体大小")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    @ViewBuilder
    private func fontSection(
        title: String,
        description: String,
        selection: ChatFontSizeOption,
        onSelect: @escaping (ChatFontSizeOption) -> Void,
        preview: @escaping (ChatFontSizeOption) -> FontPreviewCard
    ) -> some View {
        Section {
            VStack(alignment: .leading, spacing: 6) {
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                preview(selection)
                    .padding(.top, 6)
                
                ForEach(ChatFontSizeOption.allCases) { option in
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            onSelect(option)
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Text(option.displayName)
                                .font(.body)
                            
                            Spacer()
                            
                            Text(sizeDescription(for: option, context: title))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            if option == selection {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 4)
        } header: {
            Text(title)
        }
    }
    
    private func sizeDescription(for option: ChatFontSizeOption, context: String) -> String {
        switch context {
        case "用户消息":
            return "\(Int(option.userMessageSize)) pt"
        case "思维链文本":
            return "\(Int(option.reasoningSize)) pt"
        case "模型回复":
            return "\(Int(option.assistantMessageSize)) pt"
        default:
            return ""
        }
    }
}

private struct FontPreviewCard: View {
    let title: String
    let subtitle: String
    let primarySize: CGFloat
    let secondarySize: CGFloat
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: primarySize, weight: .semibold))
                .foregroundStyle(.primary)
            
            Text(subtitle)
                .font(.system(size: secondarySize))
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

#Preview {
    NavigationStack {
        ChatFontSettingsView()
    }
}
