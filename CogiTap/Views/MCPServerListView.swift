//
//  MCPServerListView.swift
//  CogiTap
//
//  Created by mengfs on 11/7/25.
//

import SwiftUI
import SwiftData

struct MCPServerListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MCPServer.createdAt, order: .reverse) private var servers: [MCPServer]
    @ObservedObject private var manager = MCPManager.shared
    
    @State private var showingAddServer = false
    @State private var showingJSONEditor = false
    
    var body: some View {
        List {
            if servers.isEmpty {
                Section {
                    ContentUnavailableView(
                        "尚未配置 MCP 服务器",
                        systemImage: "puzzlepiece.extension",
                        description: Text("点击右上角的添加按钮，创建第一个 MCP 服务器。")
                    )
                }
            } else {
                Section {
                    ForEach(servers) { server in
                        NavigationLink(destination: MCPServerDetailView(server: server)) {
                            MCPServerRow(server: server, status: manager.connectionStatus(for: server.id))
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                delete(server)
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                        }
                    }
                } header: {
                    Text("已配置服务器")
                } footer: {
                    Text("配置的服务器可以在会话设置中被选择，用于提供 MCP 工具。")
                }
            }
        }
        .navigationTitle("MCP 服务器")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showingJSONEditor = true
                } label: {
                    Label("编辑 JSON", systemImage: "curlybraces")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddServer = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
                .accessibilityLabel("添加 MCP 服务器")
            }
        }
        .sheet(isPresented: $showingAddServer) {
            NavigationStack {
                AddMCPServerView()
                    .environment(\.modelContext, modelContext)
            }
        }
        .sheet(isPresented: $showingJSONEditor) {
            NavigationStack {
                MCPServerCollectionJSONEditorView()
                    .environment(\.modelContext, modelContext)
            }
        }
        .onAppear {
            manager.refreshServers(using: modelContext)
        }
    }
    
    private func delete(_ server: MCPServer) {
        modelContext.delete(server)
        try? modelContext.save()
        manager.refreshServers(using: modelContext)
    }
}

private struct MCPServerRow: View {
    let server: MCPServer
    let status: MCPConnectionStatus
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "server.rack")
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(server.displayName)
                        .font(.headline)
                    if !server.isEnabled {
                        Text("已禁用")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule(style: .continuous)
                                    .stroke(Color.secondary.opacity(0.4), lineWidth: 1)
                            )
                    }
                }
                
                Text(server.identifier)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(statusDescription)
                    .font(.caption2)
                    .foregroundStyle(statusColor)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var statusDescription: String {
        switch status {
        case .idle:
            return "待连接"
        case .connecting:
            return "连接中..."
        case .connected(let count):
            return "已连接 · \(count) 个工具"
        case .error(let message):
            return "错误：\(message)"
        }
    }
    
    private var statusColor: Color {
        switch status {
        case .idle:
            return .secondary
        case .connecting:
            return .orange
        case .connected:
            return .green
        case .error:
            return .red
        }
    }
}

struct MCPServerDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var manager = MCPManager.shared
    
    @Bindable var server: MCPServer
    
    @State private var headerDrafts: [HeaderDraft] = []
    @State private var isSyncing = false
    @State private var syncError: String?
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        Form {
            Section("基本信息") {
                TextField("显示名称", text: binding(for: \.displayName))
                    .textInputAutocapitalization(.words)
                
                TextField("唯一定义符", text: binding(for: \.identifier))
                    .textInputAutocapitalization(.none)
                    .autocorrectionDisabled()
                
                Picker("传输类型", selection: transportBinding) {
                    ForEach(MCPTransportType.allCases, id: \.self) { type in
                        Text(label(for: type)).tag(type)
                    }
                }
                
                Toggle("启用服务器", isOn: binding(for: \.isEnabled))
            }
            
            Section("连接配置") {
                TextField("基础 URL", text: optionalBinding(for: \.baseURL))
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.none)
                    .autocorrectionDisabled()
                
                if server.transportType == .sse {
                    TextField("事件流 URL (可选)", text: optionalBinding(for: \.eventURL))
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.none)
                        .autocorrectionDisabled()
                }
                
                if server.transportType == .localProcess {
                    TextField("本地进程命令", text: optionalBinding(for: \.commandPath))
                        .textInputAutocapitalization(.none)
                        .autocorrectionDisabled()
                } else {
                    TextField("命令路径 / API 路径 (可选)", text: optionalBinding(for: \.commandPath))
                        .textInputAutocapitalization(.none)
                        .autocorrectionDisabled()
                }
            }
            
            Section("自定义请求头") {
                MCPHeaderListEditor(headers: $headerDrafts)
            }
            
            Section("连接状态") {
                HStack {
                    Text("当前状态")
                    Spacer()
                    Text(statusText)
                        .foregroundStyle(statusColor)
                }
                
                Button {
                    syncTools()
                } label: {
                    if isSyncing {
                        ProgressView()
                            .progressViewStyle(.circular)
                    } else {
                        Label("同步工具列表", systemImage: "arrow.clockwise")
                    }
                }
                .disabled(isSyncing)
                
                if let message = syncError {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }
            
            Section {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Label("删除服务器", systemImage: "trash")
                }
            }
        }
        .navigationTitle(server.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("完成") {
                    persistChanges()
                }
            }
        }
        .alert("删除服务器？", isPresented: $showDeleteConfirmation) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                deleteServer()
            }
        } message: {
            Text("此服务器及其工具将被移除，已选中的会话将无法继续使用它。")
        }
        .onAppear {
            headerDrafts = server.headers.map(HeaderDraft.init)
            if headerDrafts.isEmpty {
                headerDrafts = [HeaderDraft()]
            }
        }
        .onChange(of: headerDrafts) { _, newValue in
            let headers = newValue.compactMap { $0.toHeader }
            server.headers = headers
            touchServer()
        }
    }
    
    private func binding<Value>(for keyPath: ReferenceWritableKeyPath<MCPServer, Value>) -> Binding<Value> {
        Binding(
            get: { server[keyPath: keyPath] },
            set: {
                server[keyPath: keyPath] = $0
                touchServer()
            }
        )
    }
    
    private func optionalBinding(for keyPath: ReferenceWritableKeyPath<MCPServer, String?>) -> Binding<String> {
        Binding(
            get: { server[keyPath: keyPath] ?? "" },
            set: {
                server[keyPath: keyPath] = $0.isEmpty ? nil : $0
                touchServer()
            }
        )
    }
    
    private var transportBinding: Binding<MCPTransportType> {
        Binding(
            get: { server.transportType },
            set: {
                server.transportType = $0
                touchServer()
            }
        )
    }
    
    private func label(for type: MCPTransportType) -> String {
        switch type {
        case .sse:
            return "Server-Sent Events"
        case .streamableHttp:
            return "流式 HTTP"
        case .localProcess:
            return "本地进程"
        }
    }
    
    private var statusText: String {
        switch manager.connectionStatus(for: server.id) {
        case .idle:
            return "待连接"
        case .connecting:
            return "连接中..."
        case .connected(let count):
            return "已连接 · \(count) 个工具"
        case .error(let message):
            return "错误：\(message)"
        }
    }
    
    private var statusColor: Color {
        switch manager.connectionStatus(for: server.id) {
        case .idle:
            return .secondary
        case .connecting:
            return .orange
        case .connected:
            return .green
        case .error:
            return .red
        }
    }
    
    private func syncTools() {
        guard !isSyncing else { return }
        isSyncing = true
        syncError = nil
        Task {
            do {
                try await manager.syncTools(for: server.id, context: modelContext)
            } catch {
                syncError = error.localizedDescription
            }
            isSyncing = false
        }
    }
    
    private func deleteServer() {
        modelContext.delete(server)
        try? modelContext.save()
        manager.refreshServers(using: modelContext)
        dismiss()
    }
    
    private func persistChanges() {
        server.updatedAt = Date()
        try? modelContext.save()
        manager.refreshServers(using: modelContext)
        dismiss()
    }
    
    private func touchServer() {
        server.updatedAt = Date()
    }
}

struct AddMCPServerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var manager = MCPManager.shared
    
    @State private var identifier = ""
    @State private var displayName = ""
    @State private var transport: MCPTransportType = .sse
    @State private var baseURL = ""
    @State private var eventURL = ""
    @State private var commandPath = ""
    @State private var isEnabled = true
    @State private var headerDrafts: [HeaderDraft] = [HeaderDraft()]
    @State private var errorMessage: String?
    
    var body: some View {
        Form {
            Section("基本信息") {
                TextField("唯一定义符", text: $identifier)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.none)
                
                TextField("显示名称", text: $displayName)
                
                Picker("传输类型", selection: $transport) {
                    ForEach(MCPTransportType.allCases, id: \.self) { type in
                        Text(label(for: type)).tag(type)
                    }
                }
                
                Toggle("启用服务器", isOn: $isEnabled)
            }
            
            Section("连接配置") {
                TextField("基础 URL", text: $baseURL)
                    .keyboardType(.URL)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.none)
                
                if transport == .sse {
                    TextField("事件流 URL (可选)", text: $eventURL)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.none)
                }
                
                TextField(transport == .localProcess ? "本地进程命令" : "命令路径 / API 路径 (可选)", text: $commandPath)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.none)
            }
            
            Section("自定义请求头") {
                MCPHeaderListEditor(headers: $headerDrafts)
            }
            
            if let message = errorMessage {
                Section {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("添加 MCP 服务器")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("取消") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("保存") {
                    save()
                }
                .disabled(identifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }
    
    private func label(for type: MCPTransportType) -> String {
        switch type {
        case .sse:
            return "Server-Sent Events"
        case .streamableHttp:
            return "流式 HTTP"
        case .localProcess:
            return "本地进程"
        }
    }
    
    private func save() {
        let trimmedIdentifier = identifier.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedIdentifier.isEmpty else {
            errorMessage = "请填写唯一标识符"
            return
        }
        let display = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let headers = headerDrafts.compactMap { $0.toHeader }
        let server = MCPServer(
            identifier: trimmedIdentifier,
            displayName: display.isEmpty ? trimmedIdentifier : display,
            transportType: transport,
            baseURL: baseURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : baseURL,
            eventURL: eventURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : eventURL,
            commandPath: commandPath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : commandPath,
            isEnabled: isEnabled,
            customHeaders: headers
        )
        modelContext.insert(server)
        do {
            try modelContext.save()
            manager.refreshServers(using: modelContext)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct MCPHeaderListEditor: View {
    @Binding var headers: [HeaderDraft]
    
    var body: some View {
        if headers.isEmpty {
            ContentUnavailableView(
                "无自定义请求头",
                systemImage: "rectangle.stack.badge.plus",
                description: Text("需要时可以添加自定义 HTTP 请求头。")
            )
        } else {
            ForEach($headers) { $header in
                HStack(spacing: 8) {
                    TextField("Key", text: $header.key)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.none)
                    TextField("Value", text: $header.value)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.none)
                    Button {
                        remove(header.id)
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("删除请求头")
                }
            }
        }
        
        Button {
            headers.append(HeaderDraft())
        } label: {
            Label("添加请求头", systemImage: "plus.circle")
        }
    }
    
    private func remove(_ id: UUID) {
        headers.removeAll { $0.id == id }
        if headers.isEmpty {
            headers.append(HeaderDraft())
        }
    }
}

private struct HeaderDraft: Identifiable, Equatable {
    let id: UUID
    var key: String
    var value: String
    
    init(id: UUID = UUID(), key: String = "", value: String = "") {
        self.id = id
        self.key = key
        self.value = value
    }
    
    init(_ header: MCPHeader) {
        self.init(key: header.key, value: header.value)
    }
    
    var toHeader: MCPHeader? {
        let trimmedKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else { return nil }
        return MCPHeader(
            key: trimmedKey,
            value: value.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }
}

#Preview {
    NavigationStack {
        MCPServerListView()
            .modelContainer(for: [MCPServer.self, MCPTool.self])
    }
}

// MARK: - JSON Editing (bulk)

private struct MCPServerCollectionJSONEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var manager = MCPManager.shared
    
    @State private var jsonText: String = ""
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 12) {
            TextEditor(text: $jsonText)
                .font(.system(.body, design: .monospaced))
                .padding(8)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(.horizontal)
                .textInputAutocapitalization(.none)
                .disableAutocorrection(true)
            
            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .padding(.horizontal)
            } else {
                Text("编辑 JSON 数组以批量配置 MCP 服务器。缺失的服务器会被删除。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            }
            
            Spacer()
        }
        .navigationTitle("编辑 MCP JSON")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("取消") { dismiss() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("保存") { saveSnapshots() }
                    .fontWeight(.semibold)
            }
        }
        .onAppear {
            loadSnapshots()
        }
    }
    
    private func loadSnapshots() {
        let descriptor = FetchDescriptor<MCPServer>(sortBy: [SortDescriptor(\MCPServer.createdAt, order: .reverse)])
        let servers = (try? modelContext.fetch(descriptor)) ?? []
        let snapshots = servers.map { MCPServerConfigSnapshot(from: $0) }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? encoder.encode(snapshots),
           let text = String(data: data, encoding: .utf8) {
            jsonText = text
            errorMessage = nil
        } else {
            jsonText = "[]"
            errorMessage = "无法生成 JSON"
        }
    }
    
    private func saveSnapshots() {
        guard let data = jsonText.data(using: .utf8) else {
            errorMessage = "JSON 编码失败"
            return
        }
        do {
            let decoder = JSONDecoder()
            let snapshots: [MCPServerConfigSnapshot]
            if let array = try? decoder.decode([MCPServerConfigSnapshot].self, from: data) {
                snapshots = array
            } else {
                let single = try decoder.decode(MCPServerConfigSnapshot.self, from: data)
                snapshots = [single]
            }
            
            let descriptor = FetchDescriptor<MCPServer>()
            let existing = (try? modelContext.fetch(descriptor)) ?? []
            var existingMap = Dictionary(uniqueKeysWithValues: existing.map { ($0.identifier, $0) })
            let incomingIdentifiers = Set(snapshots.map { $0.identifier })
            
            for snapshot in snapshots {
                if let server = existingMap[snapshot.identifier] {
                    snapshot.apply(to: server)
                    server.updatedAt = Date()
                } else {
                    let newServer = snapshot.makeServer()
                    modelContext.insert(newServer)
                }
            }
            
            for server in existing where !incomingIdentifiers.contains(server.identifier) {
                modelContext.delete(server)
            }
            
            try modelContext.save()
            manager.refreshServers(using: modelContext)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct MCPServerConfigSnapshot: Codable {
    var identifier: String
    var displayName: String
    var transportType: MCPTransportType
    var baseURL: String?
    var eventURL: String?
    var commandPath: String?
    var isEnabled: Bool
    var headers: [MCPHeader]
}

private extension MCPServerConfigSnapshot {
    init(from server: MCPServer) {
        self.identifier = server.identifier
        self.displayName = server.displayName
        self.transportType = server.transportType
        self.baseURL = server.baseURL
        self.eventURL = server.eventURL
        self.commandPath = server.commandPath
        self.isEnabled = server.isEnabled
        self.headers = server.headers
    }
    
    func apply(to server: MCPServer) {
        server.identifier = identifier
        server.displayName = displayName
        server.transportType = transportType
        server.baseURL = baseURL
        server.eventURL = eventURL
        server.commandPath = commandPath
        server.isEnabled = isEnabled
        server.headers = headers
    }
    
    func makeServer() -> MCPServer {
        MCPServer(
            identifier: identifier,
            displayName: displayName,
            transportType: transportType,
            baseURL: baseURL,
            eventURL: eventURL,
            commandPath: commandPath,
            isEnabled: isEnabled,
            customHeaders: headers
        )
    }
}
