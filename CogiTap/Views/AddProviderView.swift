//
//  AddProviderView.swift
//  CogiTap
//
//  Created by mengfs on 11/1/25.
//

import SwiftUI
import SwiftData

struct AddProviderView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Binding var selectedType: ProviderType?
    
    @State private var step = 1 // 1: 选择类型, 2: 填写信息
    @State private var providerType: ProviderType = .openai
    @State private var nickname = ""
    @State private var baseURL = ""
    @State private var apiKey = ""
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            Form {
                if step == 1 {
                    // 第一步：选择服务商类型
                    Section {
                        Button {
                            providerType = .openai
                            step = 2
                        } label: {
                            ProviderTypeRow(
                                icon: "brain",
                                title: "OpenAI",
                                description: "GPT-4, GPT-3.5等模型"
                            )
                        }
                        
                        Button {
                            providerType = .anthropic
                            step = 2
                        } label: {
                            ProviderTypeRow(
                                icon: "sparkles",
                                title: "Anthropic",
                                description: "Claude系列模型"
                            )
                        }
                        
                        Button {
                            providerType = .gemini
                            step = 2
                        } label: {
                            ProviderTypeRow(
                                icon: "star.fill",
                                title: "Google Gemini",
                                description: "Gemini系列模型"
                            )
                        }
                        
                        Button {
                            providerType = .openrouter
                            step = 2
                        } label: {
                            ProviderTypeRow(
                                icon: "arrow.triangle.branch",
                                title: "OpenRouter",
                                description: "统一访问多个模型"
                            )
                        }
                    } header: {
                        Text("预设服务商")
                    }
                    
                    Section {
                        Button {
                            providerType = .custom
                            step = 2
                        } label: {
                            ProviderTypeRow(
                                icon: "gearshape.fill",
                                title: "自定义端点",
                                description: "配置自己的API端点"
                            )
                        }
                    } header: {
                        Text("自定义")
                    }
                } else {
                    // 第二步：填写配置信息
                    Section {
                        TextField("昵称", text: $nickname)
                            .autocorrectionDisabled()
                    } header: {
                        Text("服务商昵称")
                    } footer: {
                        Text("为这个服务商设置一个易于识别的名称")
                    }
                    
                    if providerType == .custom {
                        Section {
                            TextField("Base URL", text: $baseURL)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                                .keyboardType(.URL)
                        } header: {
                            Text("API端点")
                        } footer: {
                            Text("/ 结尾忽略 v1 版本，# 结尾强制使用输入地址")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Section {
                        SecureField("API Key", text: $apiKey)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                    } header: {
                        Text("API密钥")
                    } footer: {
                        Text("您的API密钥仅存储在本地设备")
                    }
                }
            }
            .navigationTitle(step == 1 ? "选择服务商" : "配置信息")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                if step == 2 {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("保存") {
                            saveProvider()
                        }
                        .disabled(!isValid)
                    }
                }
            }
            .alert("错误", isPresented: $showError) {
                Button("确定", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private var isValid: Bool {
        !nickname.isEmpty && !apiKey.isEmpty && (providerType != .custom || !baseURL.isEmpty)
    }
    
    private func saveProvider() {
        let finalBaseURL: String
        
        switch providerType {
        case .openai:
            finalBaseURL = "https://api.openai.com"
        case .anthropic:
            finalBaseURL = "https://api.anthropic.com"
        case .gemini:
            finalBaseURL = "https://generativelanguage.googleapis.com"
        case .openrouter:
            finalBaseURL = "https://openrouter.ai"
        case .custom:
            finalBaseURL = baseURL
        }
        
        let provider = APIProvider(
            nickname: nickname,
            providerType: providerType,
            baseURL: finalBaseURL,
            apiKey: apiKey
        )
        
        modelContext.insert(provider)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = "保存失败: \(error.localizedDescription)"
            showError = true
        }
    }
}

struct ProviderTypeRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    AddProviderView(selectedType: .constant(nil))
        .modelContainer(for: [APIProvider.self])
}
