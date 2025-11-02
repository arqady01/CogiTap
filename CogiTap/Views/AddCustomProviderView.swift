//
//  AddCustomProviderView.swift
//  CogiTap
//
//  Created by mengfs on 11/2/25.
//

import SwiftUI
import SwiftData

struct AddCustomProviderView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var nickname = ""
    @State private var baseURL = ""
    @State private var apiKey = ""
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Image(systemName: "gearshape.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.blue)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("自定义端点")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("配置兼容OpenAI格式的API")
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
                    TextField("Base URL", text: $baseURL)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                        .textContentType(.URL)
                } header: {
                    Text("API端点")
                } footer: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("魔法字符规则：")
                            .fontWeight(.medium)
                        Text("• 默认：自动添加 /v1/chat/completions")
                        Text("• / 结尾：忽略 v1 版本")
                        Text("• # 结尾：强制使用输入地址")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("示例：")
                            .font(.caption)
                            .fontWeight(.medium)
                        
                        ExampleRow(
                            input: "https://api.example.com",
                            output: "https://api.example.com/v1/chat/completions"
                        )
                        
                        ExampleRow(
                            input: "https://api.example.com/",
                            output: "https://api.example.com/chat/completions"
                        )
                        
                        ExampleRow(
                            input: "https://api.example.com/custom#",
                            output: "https://api.example.com/custom"
                        )
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("添加自定义端点")
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
    }
    
    private var isValid: Bool {
        !nickname.isEmpty && !baseURL.isEmpty && !apiKey.isEmpty
    }
    
    private func saveProvider() {
        let provider = APIProvider(
            nickname: nickname,
            providerType: .custom,
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

struct ExampleRow: View {
    let input: String
    let output: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text("输入:")
                    .foregroundStyle(.secondary)
                Text(input)
                    .foregroundStyle(.primary)
            }
            HStack {
                Text("结果:")
                    .foregroundStyle(.secondary)
                Text(output)
                    .foregroundStyle(.blue)
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    AddCustomProviderView()
        .modelContainer(for: [APIProvider.self])
}
