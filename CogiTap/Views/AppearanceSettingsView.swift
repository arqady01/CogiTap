//
//  AppearanceSettingsView.swift
//  CogiTap
//
//  Created by Codex on 11/1/25.
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
