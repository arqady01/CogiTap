//
//  MCPTransport.swift
//  CogiTap
//
//  Created by mengfs on 11/7/25.
//

import Foundation

protocol MCPTransport: AnyObject {
    var server: MCPServer { get }
    func connect() async throws
    func disconnect()
    func sendRequest(_ payload: Data) async throws -> Data
    func eventStream() -> AsyncStream<Data>
}

final class MCPServerSentEventsTransport: MCPTransport {
    let server: MCPServer
    
    init(server: MCPServer) {
        self.server = server
    }
    
    func connect() async throws {
        throw MCPError.notImplemented
    }
    
    func disconnect() {}
    
    func sendRequest(_ payload: Data) async throws -> Data {
        throw MCPError.notImplemented
    }
    
    func eventStream() -> AsyncStream<Data> {
        AsyncStream { continuation in
            continuation.finish()
        }
    }
}

final class MCPStreamableHTTPTransport: MCPTransport {
    let server: MCPServer
    
    init(server: MCPServer) {
        self.server = server
    }
    
    func connect() async throws {
        throw MCPError.notImplemented
    }
    
    func disconnect() {}
    
    func sendRequest(_ payload: Data) async throws -> Data {
        throw MCPError.notImplemented
    }
    
    func eventStream() -> AsyncStream<Data> {
        AsyncStream { continuation in
            continuation.finish()
        }
    }
}

final class MCPLocalProcessTransport: MCPTransport {
    let server: MCPServer
    
    init(server: MCPServer) {
        self.server = server
    }
    
    func connect() async throws {
        throw MCPError.notImplemented
    }
    
    func disconnect() {}
    
    func sendRequest(_ payload: Data) async throws -> Data {
        throw MCPError.notImplemented
    }
    
    func eventStream() -> AsyncStream<Data> {
        AsyncStream { continuation in
            continuation.finish()
        }
    }
}

struct MCPTransportFactory {
    func makeTransport(for server: MCPServer) -> MCPTransport {
        switch server.transportType {
        case .sse:
            return MCPServerSentEventsTransport(server: server)
        case .streamableHttp:
            return MCPStreamableHTTPTransport(server: server)
        case .localProcess:
            return MCPLocalProcessTransport(server: server)
        }
    }
}
