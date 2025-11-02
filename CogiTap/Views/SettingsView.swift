//
//  SettingsView.swift
//  CogiTap
//
//  Created by mengfs on 11/1/25.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink(destination: ModelProvidersView()) {
                        HStack(spacing: 12) {
                            Image(systemName: "server.rack")
                                .font(.title3)
                                .foregroundStyle(.blue)
                                .frame(width: 32)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("模型服务商")
                                    .font(.body)
                                Text("管理API配置和模型")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    
                    NavigationLink(destination: AboutView()) {
                        HStack(spacing: 12) {
                            Image(systemName: "info.circle")
                                .font(.title3)
                                .foregroundStyle(.purple)
                                .frame(width: 32)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("关于我们")
                                    .font(.body)
                                Text("应用信息和联系方式")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
