# CogiTap - AI对话应用

> Cogito, ergo sum - 我思故我在

CogiTap 是一个功能强大的iOS AI对话应用，支持多种主流AI模型服务商，提供流畅的对话体验。

## 功能特性

### 🤖 多模型支持
- **预设服务商**：OpenAI、Anthropic、Google Gemini、OpenRouter
- **自定义端点**：支持配置任何兼容OpenAI API格式的服务
- **智能适配**：自动适配不同服务商的API格式差异

### 💬 强大的对话功能
- **流式响应**：实时显示AI回复，无需等待
- **推理模型支持**：支持显示思考过程（reasoning_content）
- **一键复制**：长按消息即可复制
- **停止生成**：随时中断AI回复

### 📝 会话管理
- **多会话支持**：创建、删除、重命名会话
- **会话历史**：自动保存所有对话记录
- **会话级参数**：每个会话可独立设置temperature和system prompt

### ⚙️ 灵活配置
- **模型快速切换**：在对话中随时切换模型
- **参数调整**：调整temperature和system prompt
- **本地存储**：所有API Key仅存储在本地设备

## 项目结构

```
CogiTap/
├── Models/                      # 数据模型
│   ├── APIProvider.swift       # API服务商模型
│   ├── ChatModel.swift         # 聊天模型
│   ├── Conversation.swift      # 会话模型
│   └── Message.swift           # 消息模型
│
├── Services/                    # 服务层
│   ├── APIAdapter.swift        # API适配器协议
│   ├── OpenAIAdapter.swift     # OpenAI适配器
│   ├── AnthropicAdapter.swift  # Anthropic适配器
│   ├── GeminiAdapter.swift     # Gemini适配器
│   ├── APIAdapterFactory.swift # 适配器工厂
│   └── ChatService.swift       # 聊天服务
│
├── Views/                       # 视图层
│   ├── ContentView.swift       # 主界面
│   ├── MessageBubbleView.swift # 消息气泡
│   ├── ConversationSidebarView.swift  # 会话侧边栏
│   ├── SettingsView.swift      # 设置页面
│   ├── ModelProvidersView.swift # 模型服务商列表
│   ├── AddProviderView.swift   # 添加服务商
│   ├── ProviderDetailView.swift # 服务商详情
│   ├── AboutView.swift         # 关于页面
│   ├── ModelSelectorView.swift # 模型选择器
│   └── ConversationSettingsView.swift # 会话设置
│
└── CogiTapApp.swift            # 应用入口
```

## 技术架构

### 数据持久化
使用 **SwiftData** 框架进行本地数据存储，支持：
- API配置管理
- 会话和消息历史
- 模型列表缓存

### API适配器模式
通过适配器模式统一不同服务商的API格式：

```swift
// 统一的内部格式
UnifiedMessage -> APIAdapter -> 服务商特定格式

// 示例：
OpenAI:    直接发送
Anthropic: 提取system到顶层
Gemini:    转换为contents数组
```

### 自定义端点的魔法字符规则

| 输入 | 最终URL |
|------|---------|
| `https://my.test.com` | `https://my.test.com/v1/chat/completions` |
| `https://my.test.com/` | `https://my.test.com/chat/completions` |
| `https://my.test.com#` | `https://my.test.com` |
| `https://my.test.com/v1/` | `https://my.test.com/v1/chat/completions` |
| `https://my.test.com/v1/chat/completions#` | `https://my.test.com/v1/chat/completions` |

**规则说明**：
- 默认：自动添加 `/v1/chat/completions`
- `/` 结尾：忽略 `v1` 版本，添加 `/chat/completions`
- `#` 结尾：强制使用输入地址，不添加任何后缀

## 使用指南

### 1. 添加模型服务商

1. 点击右上角头像进入设置
2. 选择"模型服务商"
3. 点击"添加模型服务商"
4. 选择预设服务商或自定义端点
5. 填写昵称和API Key
6. 保存后自动获取模型列表

### 2. 开始对话

1. 点击左上角菜单图标打开会话列表
2. 点击右上角的新建按钮创建新会话
3. 点击底部的模型按钮选择要使用的模型
4. 输入消息并发送

### 3. 调整会话参数

1. 点击底部的滑块图标
2. 调整Temperature（0-2）
3. 修改System Prompt
4. 点击完成保存

### 4. 查看推理过程

对于支持推理的模型（如OpenAI o1）：
- 消息上方会显示"思考过程"按钮
- 点击按钮展开/折叠思考内容
- 长按可复制思考过程

## 系统要求

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## 安全性

- ✅ 所有API Key仅存储在本地设备
- ✅ 使用SwiftData加密存储
- ✅ 不会上传任何用户数据到第三方服务器
- ✅ 所有网络请求直接连接到用户配置的API端点

## 开发计划

- [ ] 支持图片上传和多模态对话
- [ ] 支持语音输入
- [ ] 支持对话导出（Markdown、JSON）
- [ ] 支持主题切换
- [ ] 支持iCloud同步

## 许可证

MIT License

## 联系方式

- 开发者：mengfs
- 项目主页：[GitHub](https://github.com)

---

**Cogito, ergo sum** - 我思故我在
