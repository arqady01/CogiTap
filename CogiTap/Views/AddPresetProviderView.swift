//
//  AddPresetProviderView.swift
//  CogiTap
//
//  Created by mengfs on 11/2/25.
//

import SwiftUI
import SwiftData

struct AddPresetProviderView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let providerType: ProviderType
    
    @State private var nickname = ""
    @State private var apiKey = ""
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Image(systemName: providerIcon)
                            .font(.largeTitle)
                            .foregroundStyle(.blue)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(providerName)
                                .font(.title2)
                                .fontWeight(.bold)
                            Text(providerDescription)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
                }
                .listRowBackground(Color.clear)
                
                Section {
                    TextField("昵称", text: $nickname)
                        .autocorrectionDisabled()
                } header: {
                    Text("服务商昵称")
                } footer: {
                    Text("为这个服务商设置一个易于识别的名称")
                }
                
                Section {
                    SecureField("API Key", text: $apiKey)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .textContentType(.password)
                } header: {
                    Text("API密钥")
                } footer: {
                    Text("您的API密钥仅存储在本地设备")
                }
            }
            .navigationTitle("添加\(providerName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveProvider()
                    }
                    .disabled(!isValid)
                }
            }
            .alert("错误", isPresented: $showError) {
                Button("确定", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
        .onAppear {
            // 设置默认昵称
            nickname = providerName
        }
    }
    
    private var isValid: Bool {
        !nickname.isEmpty && !apiKey.isEmpty
    }
    
    private var providerName: String {
        switch providerType {
        case .openai: return "OpenAI"
        case .anthropic: return "Anthropic"
        case .gemini: return "Google Gemini"
        case .openrouter: return "OpenRouter"
        case .custom: return "自定义"
        }
    }
    
    private var providerIcon: String {
        switch providerType {
        case .openai: return "brain"
        case .anthropic: return "sparkles"
        case .gemini: return "star.fill"
        case .openrouter: return "arrow.triangle.branch"
        case .custom: return "gearshape.fill"
        }
    }
    
    private var providerDescription: String {
        switch providerType {
        case .openai: return "GPT-4, GPT-3.5等模型"
        case .anthropic: return "Claude系列模型"
        case .gemini: return "Gemini系列模型"
        case .openrouter: return "统一访问多个模型"
        case .custom: return "自定义API端点"
        }
    }
    
    private func saveProvider() {
        let baseURL: String
        
        switch providerType {
        case .openai:
            baseURL = "https://api.openai.com"
        case .anthropic:
            baseURL = "https://api.anthropic.com"
        case .gemini:
            baseURL = "https://generativelanguage.googleapis.com"
        case .openrouter:
            baseURL = "https://openrouter.ai"
        case .custom:
            baseURL = ""
        }
        
        let provider = APIProvider(
            nickname: nickname,
            providerType: providerType,
            baseURL: baseURL,
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

// 使ProviderType遵循Identifiable协议
extension ProviderType: Identifiable {
    var id: String { self.rawValue }
}

#Preview {
    AddPresetProviderView(providerType: .openai)
        .modelContainer(for: [APIProvider.self])
}
