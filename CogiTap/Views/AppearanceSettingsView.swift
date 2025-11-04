//
//  AppearanceSettingsView.swift
//  CogiTap
//
//  Created by MengFs on 11/1/25.
//

import SwiftUI

struct AppearanceSettingsView: View {
    var body: some View {
        List {
            Section {
                NavigationLink {
                    ChatBubbleAppearanceView()
                } label: {
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 36, height: 36)
                            .overlay(
                                Image(systemName: "ellipsis.bubble")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.blue)
                            )
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("聊天气泡")
                                .font(.body)
                            Text("自定义消息气泡外观")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                NavigationLink {
                    ChatFontSettingsView()
                } label: {
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.orange.opacity(0.18))
                            .frame(width: 36, height: 36)
                            .overlay(
                                Image(systemName: "textformat.size")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(Color.orange)
                            )
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("文本字体大小")
                                .font(.body)
                            Text("可分别设置用户、推理、回复字体大小")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("外观显示")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        AppearanceSettingsView()
    }
}
