# CogiTap 使用和测试指南

## 快速开始

### 第一次运行

1. **打开项目**
   ```bash
   cd /Users/mengfs/xxn/CogiTap
   open CogiTap.xcodeproj
   ```

2. **选择模拟器或真机**
   - 推荐使用 iPhone 15 Pro 模拟器
   - 或连接真实的iOS设备（需要iOS 17+）

3. **运行应用**
   - 按 `Cmd + R` 或点击运行按钮
   - 首次运行会自动创建一个新会话

### 配置第一个模型服务商

#### 方式1：使用OpenAI

1. 点击右上角的彩色头像图标
2. 选择"模型服务商"
3. 点击"添加模型服务商"
4. 选择"OpenAI"
5. 填写：
   - 昵称：`我的OpenAI`
   - API Key：你的OpenAI API密钥
6. 点击"保存"
7. 等待自动获取模型列表

#### 方式2：使用Anthropic

1. 同样的步骤，选择"Anthropic"
2. 填写：
   - 昵称：`我的Claude`
   - API Key：你的Anthropic API密钥
3. 保存后会获取Claude模型列表

#### 方式3：使用自定义端点

1. 选择"自定义端点"
2. 填写：
   - 昵称：`本地模型`
   - Base URL：`http://localhost:11434` （示例：Ollama）
   - API Key：可以留空或填写任意值
3. 注意魔法字符规则：
   - `http://localhost:11434` → `http://localhost:11434/v1/chat/completions`
   - `http://localhost:11434/` → `http://localhost:11434/chat/completions`
   - `http://localhost:11434#` → `http://localhost:11434`

## 功能测试清单

### ✅ 基础对话功能

- [ ] 发送第一条消息
- [ ] 查看流式响应（文字逐字显示）
- [ ] 等待完整回复
- [ ] 长按消息复制内容

### ✅ 会话管理

- [ ] 点击左上角菜单图标打开侧边栏
- [ ] 点击右上角新建按钮创建新会话
- [ ] 在会话列表中切换不同会话
- [ ] 长按会话，选择"重命名"
- [ ] 长按会话，选择"删除"

### ✅ 模型切换

- [ ] 点击底部的模型按钮（默认显示"选择模型"）
- [ ] 在列表中选择不同的模型
- [ ] 确认模型名称显示在按钮上
- [ ] 发送消息测试新模型

### ✅ 参数调整

- [ ] 点击底部的滑块图标
- [ ] 调整Temperature滑块（0-2）
- [ ] 修改System Prompt
- [ ] 点击"完成"保存
- [ ] 发送消息验证参数生效

### ✅ 推理模型测试

如果你有OpenAI o1模型的访问权限：

- [ ] 选择o1模型
- [ ] 发送一个需要推理的问题
- [ ] 查看"思考过程"按钮
- [ ] 点击展开思考内容
- [ ] 点击折叠思考内容
- [ ] 长按复制思考过程

### ✅ 停止生成

- [ ] 发送一个会产生长回复的问题
- [ ] 在回复过程中点击红色停止按钮
- [ ] 确认回复立即停止

### ✅ 设置页面

- [ ] 进入"模型服务商"
- [ ] 查看已配置的服务商列表
- [ ] 点击某个服务商查看详情
- [ ] 刷新模型列表
- [ ] 删除服务商
- [ ] 进入"关于我们"查看应用信息

## 常见问题排查

### 问题1：无法获取模型列表

**可能原因**：
- API Key错误
- 网络连接问题
- 服务商API暂时不可用

**解决方法**：
1. 检查API Key是否正确
2. 检查网络连接
3. 查看Xcode控制台的错误信息

### 问题2：发送消息没有响应

**检查清单**：
- [ ] 是否选择了模型？
- [ ] API Key是否有效？
- [ ] 是否有网络连接？
- [ ] 查看Xcode控制台的错误日志

### 问题3：自定义端点无法连接

**调试步骤**：
1. 确认端点URL格式正确
2. 测试端点是否可访问：
   ```bash
   curl http://localhost:11434/v1/models
   ```
3. 检查是否需要使用魔法字符：
   - 如果端点已经包含完整路径，使用 `#` 结尾
   - 如果需要忽略v1，使用 `/` 结尾

### 问题4：流式响应不工作

**可能原因**：
- 某些自定义端点可能不支持流式响应
- 网络问题导致连接中断

**解决方法**：
- 检查端点是否支持 `stream: true` 参数
- 尝试使用非流式模式（需要修改代码）

## 测试不同的API格式

### 测试OpenAI格式

```bash
# 使用curl测试
curl https://api.openai.com/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -d '{
    "model": "gpt-3.5-turbo",
    "messages": [{"role": "user", "content": "Hello"}],
    "stream": true
  }'
```

### 测试Anthropic格式

```bash
curl https://api.anthropic.com/v1/messages \
  -H "Content-Type: application/json" \
  -H "x-api-key: YOUR_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -d '{
    "model": "claude-3-5-sonnet-20241022",
    "max_tokens": 1024,
    "messages": [{"role": "user", "content": "Hello"}]
  }'
```

### 测试Gemini格式

```bash
curl "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "contents": [{
      "parts": [{"text": "Hello"}]
    }]
  }'
```

## 开发调试技巧

### 1. 查看SwiftData数据

在Xcode中：
1. 运行应用
2. 打开 Debug Navigator (Cmd + 7)
3. 查看内存中的数据模型

### 2. 重置应用数据

如果需要清空所有数据：
1. 删除应用
2. 重新安装
3. 或者在代码中添加清空数据的逻辑

### 3. 调试网络请求

在 `ChatService.swift` 中添加打印：
```swift
print("Request URL: \(urlRequest.url?.absoluteString ?? "")")
print("Request Headers: \(urlRequest.allHTTPHeaderFields ?? [:])")
```

### 4. 模拟流式响应

如果想测试流式UI但没有真实API：
1. 在 `ChatService.swift` 中添加模拟数据
2. 使用 `Timer` 逐字添加内容

## 性能优化建议

1. **消息列表优化**
   - 使用 `LazyVStack` 已实现
   - 对于超长对话，考虑分页加载

2. **网络请求优化**
   - 已实现流式响应
   - 可以添加请求缓存

3. **数据库优化**
   - SwiftData自动优化
   - 定期清理旧会话

## 下一步开发

如果你想继续完善应用，可以考虑：

1. **添加图片支持**
   - 修改Message模型添加图片字段
   - 实现图片上传和显示

2. **添加语音输入**
   - 集成Speech框架
   - 实现语音转文字

3. **添加导出功能**
   - 导出为Markdown
   - 导出为JSON
   - 分享对话

4. **添加主题切换**
   - 深色/浅色模式
   - 自定义颜色主题

5. **添加iCloud同步**
   - 使用CloudKit
   - 同步会话和配置

---

祝你使用愉快！如有问题，请查看README.md或联系开发者。
