//
//  AboutView.swift
//  CogiTap
//
//  Created by mengfs on 11/1/25.
//

import SwiftUI

struct AboutView: View {
    var body: some View {
        List {
            Section {
                VStack(spacing: 16) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 60))
                        .foregroundStyle(.blue)
                    
                    Text("CogiTap")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("版本 1.0.0")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }
            .listRowBackground(Color.clear)
            
            Section {
                LabeledContent("开发者", value: "mengfs")
                LabeledContent("座右铭", value: "Cogito, ergo sum")
            }
            
            Section {
                Link(destination: URL(string: "https://github.com")!) {
                    HStack {
                        Text("GitHub")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Link(destination: URL(string: "https://twitter.com")!) {
                    HStack {
                        Text("Twitter")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("联系我们")
            }
            
            Section {
                Text("CogiTap 是一个支持多种AI模型的对话应用，让您可以随时随地与AI助手交流。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } header: {
                Text("关于")
            }
        }
        .navigationTitle("关于我们")
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    NavigationStack {
        AboutView()
    }
}
