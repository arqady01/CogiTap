//
//  MCPClient.swift
//  CogiTap
//
//  Created by mengfs on 11/7/25.
//

import Foundation

@MainActor
final class MCPClient: ObservableObject {
    let server: MCPServer
    
    @Published private(set) var status: MCPConnectionStatus = .idle
    
    init(server: MCPServer) {
        self.server = server
    }
    
    func connect() async throws {
        guard status != .connecting else { return }
        status = .connecting
        do {
            _ = try rpcEndpointURL()
            status = .connected(toolCount: server.tools?.filter { $0.isEnabled }.count ?? 0)
        } catch {
            status = .error(message: error.localizedDescription)
            throw error
        }
    }
    
    func disconnect() {
        status = .idle
    }
    
    func listTools() async throws -> [MCPToolDescriptor] {
        let result = try await sendRPCRequest(method: "tools/list", params: [:])
        let toolPayloads: [[String: Any]]
        if let dict = result as? [String: Any] {
            toolPayloads =
                dict["tools"] as? [[String: Any]] ??
                dict["items"] as? [[String: Any]] ??
                []
        } else if let array = result as? [[String: Any]] {
            toolPayloads = array
        } else {
            throw MCPError.protocolViolation
        }
        
        guard !toolPayloads.isEmpty else {
            return []
        }
        
        return toolPayloads.compactMap { payload in
            guard let name = payload["name"] as? String else { return nil }
            let description = payload["description"] as? String ?? "未提供描述"
            let schemaSource = payload["input_schema"] ?? payload["schema"]
            let schemaJSON = schemaJSONString(from: schemaSource)
            let descriptor = MCPToolDescriptor(
                identifier: MCPToolIdentifier(serverID: server.id, toolName: name),
                toolName: name,
                description: description,
                jsonSchema: schemaJSON
            )
            return descriptor
        }
    }
    
    func invokeTool(
        name: String,
        arguments: [String: Any]
    ) async throws -> String {
        let result = try await sendRPCRequest(
            method: "tools/call",
            params: [
                "name": name,
                "arguments": arguments
            ]
        )
        return try stringifyResult(result)
    }
}

// MARK: - JSON-RPC helpers

private extension MCPClient {
    func rpcEndpointURL() throws -> URL {
        if let command = server.commandPath,
           !command.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let trimmed = command.trimmingCharacters(in: .whitespacesAndNewlines)
            if let directURL = URL(string: trimmed), directURL.scheme != nil {
                return directURL
            }
            if let base = server.baseURL,
               let baseURL = URL(string: base),
               let relativeURL = URL(string: trimmed, relativeTo: baseURL) {
                return relativeURL.absoluteURL
            }
        }
        
        if let base = server.baseURL,
           let baseURL = URL(string: base) {
            return baseURL
        }
        throw MCPError.invalidConfiguration
    }
    
    func makeRPCRequest(method: String, params: [String: Any]) throws -> URLRequest {
        let url = try rpcEndpointURL()
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        for header in server.headers {
            request.setValue(header.value, forHTTPHeaderField: header.key)
        }
        let payload: [String: Any] = [
            "jsonrpc": "2.0",
            "id": UUID().uuidString,
            "method": method,
            "params": params
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        return request
    }
    
    func sendRPCRequest(method: String, params: [String: Any]) async throws -> Any {
        let request = try makeRPCRequest(method: method, params: params)
        let (data, response) = try await URLSession.shared.data(for: request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
        guard (200..<300).contains(statusCode) else {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorPayload = json["error"] as? [String: Any] {
                let code = errorPayload["code"] as? Int ?? statusCode
                let message = errorPayload["message"] as? String ?? "未知错误"
                throw MCPJSONRPCError(code: code, message: message)
            }
            let bodySnippet = String(data: data, encoding: .utf8)
            throw MCPHTTPError(statusCode: statusCode, body: bodySnippet)
        }
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw MCPError.protocolViolation
        }
        if let errorPayload = json["error"] as? [String: Any] {
            let code = errorPayload["code"] as? Int ?? -32000
            let message = errorPayload["message"] as? String ?? "未知错误"
            throw MCPJSONRPCError(code: code, message: message)
        }
        guard let result = json["result"] else {
            throw MCPError.protocolViolation
        }
        return result
    }
    
    func schemaJSONString(from object: Any?) -> String {
        if let string = object as? String, !string.isEmpty {
            return string
        }
        if let dict = object as? [String: Any],
           let data = try? JSONSerialization.data(withJSONObject: dict, options: [.sortedKeys]),
           let string = String(data: data, encoding: .utf8) {
            return string
        }
        if let array = object as? [Any],
           let data = try? JSONSerialization.data(withJSONObject: array, options: [.sortedKeys]),
           let string = String(data: data, encoding: .utf8) {
            return string
        }
        return MCPManager.defaultSchemaJSONString
    }
    
    func stringifyResult(_ result: Any) throws -> String {
        if let string = result as? String {
            return string
        }
        if let number = result as? NSNumber {
            return number.stringValue
        }
        if result is NSNull {
            return ""
        }
        if JSONSerialization.isValidJSONObject(result) {
            let data = try JSONSerialization.data(withJSONObject: result, options: [.prettyPrinted])
            return String(data: data, encoding: .utf8) ?? ""
        }
        return "\(result)"
    }
}

// MARK: - Errors

struct MCPJSONRPCError: LocalizedError {
    let code: Int
    let message: String
    
    var errorDescription: String? {
        "JSON-RPC(\(code)): \(message)"
    }
}

struct MCPHTTPError: LocalizedError {
    let statusCode: Int
    let body: String?
    
    var errorDescription: String? {
        var base = statusCode == -1 ? "服务器无响应" : "服务器返回状态码 \(statusCode)"
        if let body, !body.isEmpty {
            let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                base += "：\(trimmed.prefix(140))"
            }
        }
        return base
    }
}
