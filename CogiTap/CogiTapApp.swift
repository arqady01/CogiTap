//
//  CogiTapApp.swift
//  CogiTap
//
//  Created by mengfs on 11/1/25.
//

import SwiftUI
import SwiftData

@main
struct CogiTapApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            APIProvider.self,
            ChatModel.self,
            Conversation.self,
            Message.self,
            MemoryRecord.self,
            MemoryConfig.self,
        ])
        
        // 使用轻量级迁移策略
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // 如果迁移失败，删除旧数据库重新创建
            print("迁移失败，尝试删除旧数据: \(error)")
            
            // 删除旧的数据库文件
            let url = modelConfiguration.url
            try? FileManager.default.removeItem(at: url)
            try? FileManager.default.removeItem(at: url.deletingPathExtension().appendingPathExtension("sqlite-shm"))
            try? FileManager.default.removeItem(at: url.deletingPathExtension().appendingPathExtension("sqlite-wal"))
            
            // 重新创建容器
            do {
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                fatalError("无法创建ModelContainer: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
