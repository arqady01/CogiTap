//
//  MemoryService.swift
//  CogiTap
//
//  Created by mengfs on 11/3/25.
//

import Foundation
import SwiftData

struct MemoryToolConfiguration: Decodable {
    let stopWords: [String]
    let stopCharacters: [String]
    let synonymGroups: [[String]]
}

struct MemoryRuntimeConfiguration {
    let stopWords: Set<String>
    let stopCharacterSet: CharacterSet
    let synonymMap: [String: Set<String>]
}

@MainActor
final class MemoryService {
    static let shared = MemoryService()
    
    private let runtimeConfig: MemoryRuntimeConfiguration
    
    private init() {
        runtimeConfig = MemoryService.loadRuntimeConfiguration()
    }
    
    // MARK: - Public API
    
    func getOrCreateConfig(using context: ModelContext) -> MemoryConfig {
        var descriptor = FetchDescriptor<MemoryConfig>()
        descriptor.fetchLimit = 1
        if let existing = try? context.fetch(descriptor), let first = existing.first {
            return first
        }
        let config = MemoryConfig()
        context.insert(config)
        try? context.save()
        return config
    }
    
    func saveMemory(
        content: String,
        conversation: Conversation?,
        context: ModelContext
    ) -> Bool {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        
        let normalized = trimmed.lowercased()
        let descriptor = FetchDescriptor<MemoryRecord>()
        let existing = (try? context.fetch(descriptor)) ?? []
        let config = getOrCreateConfig(using: context)
        guard config.isMemoryEnabled else { return false }

        let relevantRecords: [MemoryRecord]
        if config.isCrossChatEnabled {
            relevantRecords = existing
        } else if let conversationId = conversation?.id {
            relevantRecords = existing.filter { $0.conversationId == conversationId }
        } else {
            relevantRecords = []
        }
        
        if let duplicate = relevantRecords.first(where: { record in
            let recordContent = record.content.lowercased()
            if recordContent == normalized {
                return true
            }
            let distance = MemoryService.editDistanceBetween(recordContent, normalized)
            return distance <= 2
        }) {
            // 更新时间戳表示最近使用
            duplicate.updatedAt = Date()
            try? context.save()
            return false
        }
        
        let record = MemoryRecord(
            content: trimmed,
            conversationId: config.isCrossChatEnabled ? nil : conversation?.id
        )
        context.insert(record)
        try? context.save()
        return true
    }
    
    func updateMemory(
        originalContent: String,
        newContent: String,
        context: ModelContext
    ) -> String {
        let config = getOrCreateConfig(using: context)
        guard config.isMemoryEnabled else {
            return "记忆功能已关闭"
        }
        let descriptor = FetchDescriptor<MemoryRecord>()
        let matches = (try? context.fetch(descriptor))?.filter { $0.content == originalContent } ?? []
        guard !matches.isEmpty else {
            return "未找到匹配的记忆"
        }

        let now = Date()
        for record in matches {
            record.content = newContent
            record.updatedAt = now
        }
        try? context.save()
        return "已更新 \(matches.count) 条记忆"
    }
    
    func retrieveMemories(
        for query: String,
        conversation: Conversation?,
        context: ModelContext
    ) -> String {
        let keywords = query
            .split(separator: ";")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty }
        guard !keywords.isEmpty else { return "" }

        let fetchDescriptor = FetchDescriptor<MemoryRecord>()
        let allRecords = (try? context.fetch(fetchDescriptor)) ?? []

        let config = getOrCreateConfig(using: context)
        guard config.isMemoryEnabled else { return "" }
        let filtered: [MemoryRecord]
        if config.isCrossChatEnabled {
            filtered = allRecords
        } else if let conversationID = conversation?.id {
            filtered = allRecords.filter { record in
                record.conversationId == conversationID
            }
        } else {
            filtered = []
        }
        
        let scored = filtered
            .map { record -> (MemoryRecord, Int) in
                let score = scoreMemory(record, keywords: keywords)
                return (record, score)
            }
            .filter { $0.1 > 0 }
            .sorted { lhs, rhs in
                if lhs.1 == rhs.1 {
                    return lhs.0.updatedAt > rhs.0.updatedAt
                }
                return lhs.1 > rhs.1
            }
        
        guard !scored.isEmpty else { return "" }
        
        return scored
            .map { $0.0.content }
            .joined(separator: "\n\n")
    }
    
    func deleteMemory(_ record: MemoryRecord, context: ModelContext) {
        context.delete(record)
        try? context.save()
    }
    
    func clearAllMemories(context: ModelContext) -> Int {
        let descriptor = FetchDescriptor<MemoryRecord>()
        let records = (try? context.fetch(descriptor)) ?? []
        records.forEach { context.delete($0) }
        try? context.save()
        return records.count
    }

    // MARK: - Scoring
    
    private func scoreMemory(_ record: MemoryRecord, keywords: [String]) -> Int {
        let contentLower = record.content.lowercased()
        let memoryTokens = tokenize(contentLower)
        var totalScore = 0
        
        for keyword in keywords {
            if contentLower.contains(keyword) {
                totalScore += keyword.count * 4
                continue
            }
            
            let keywordTokens = tokenize(keyword)
            if keywordTokens.isEmpty {
                totalScore += characterOverlapScore(keyword: keyword, content: contentLower)
                continue
            }
            
            let editScore = editDistanceScore(keywordTokens: keywordTokens, memoryTokens: memoryTokens)
            if editScore > 0 {
                totalScore += editScore
                continue
            }
            
            let synonymScore = synonymMatchScore(keywordTokens: keywordTokens, memoryTokens: memoryTokens)
            if synonymScore > 0 {
                totalScore += synonymScore
                continue
            }
            
            let overlapScore = characterOverlapScore(keyword: keyword, content: contentLower)
            totalScore += overlapScore
        }
        
        return totalScore
    }
    
    private func editDistanceScore(keywordTokens: [String], memoryTokens: [String]) -> Int {
        guard !memoryTokens.isEmpty else { return 0 }
        var total = 0
        
        for keyword in keywordTokens {
            var best = 0
            for candidate in memoryTokens {
                let lengthDiff = abs(keyword.count - candidate.count)
                guard lengthDiff <= 2 else { continue }
                let distance = MemoryService.editDistanceBetween(keyword, candidate)
                guard distance <= 2, distance < keyword.count else { continue }
                let score = max(0, keyword.count - distance) * 2
                best = max(best, score)
            }
            total += best
        }
        
        return total
    }
    
    private func synonymMatchScore(keywordTokens: [String], memoryTokens: [String]) -> Int {
        guard !memoryTokens.isEmpty else { return 0 }
        var total = 0
        let memorySet = Set(memoryTokens)
        
        for keyword in keywordTokens {
            guard let synonyms = runtimeConfig.synonymMap[keyword], !synonyms.isEmpty else {
                continue
            }
            if !synonyms.isDisjoint(with: memorySet) {
                total += keyword.count
            }
        }
        
        return total
    }
    
    private func characterOverlapScore(keyword: String, content: String) -> Int {
        let filteredCharacters = keyword
            .lowercased()
            .unicodeScalars
            .filter { !runtimeConfig.stopCharacterSet.contains($0) }
        var seen = Set<Character>()
        var score = 0
        for scalar in filteredCharacters {
            let character = Character(scalar)
            if !seen.insert(character).inserted {
                continue
            }
            if content.contains(String(character)) {
                score += 1
            }
        }
        return score
    }
    
    private func tokenize(_ text: String) -> [String] {
        let lowered = text.lowercased()
        let components = lowered.components(separatedBy: runtimeConfig.stopCharacterSet)
        return components
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && !runtimeConfig.stopWords.contains($0) }
    }
    
    // MARK: - Configuration helpers
    
    private static func loadRuntimeConfiguration() -> MemoryRuntimeConfiguration {
        guard let url = Bundle.main.url(forResource: "memory_config", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let config = try? JSONDecoder().decode(MemoryToolConfiguration.self, from: data) else {
            return MemoryRuntimeConfiguration(
                stopWords: [],
                stopCharacterSet: MemoryService.defaultCharacterSet(),
                synonymMap: [:]
            )
        }
        
        let stopWords = Set(config.stopWords.map { $0.lowercased() })
        var characterSet = MemoryService.defaultCharacterSet()
        for item in config.stopCharacters {
            characterSet.formUnion(CharacterSet(charactersIn: item))
        }
        
        var synonymMap: [String: Set<String>] = [:]
        for group in config.synonymGroups {
            let lowered = group.map { $0.lowercased() }
            for source in lowered {
                var targets = synonymMap[source] ?? Set<String>()
                for target in lowered where target != source {
                    targets.insert(target)
                    var reverseTargets = synonymMap[target] ?? Set<String>()
                    reverseTargets.insert(source)
                    synonymMap[target] = reverseTargets
                }
                synonymMap[source] = targets
            }
        }
        
        return MemoryRuntimeConfiguration(
            stopWords: stopWords,
            stopCharacterSet: characterSet,
            synonymMap: synonymMap
        )
    }
    
    private static func defaultCharacterSet() -> CharacterSet {
        var set = CharacterSet.whitespacesAndNewlines
        set.formUnion(.punctuationCharacters)
        set.formUnion(CharacterSet(charactersIn: "；;:,，。.!?？、\"'()[]{}"))
        return set
    }
    
    // MARK: - Utilities
    
    static func editDistanceBetween(_ lhs: String, _ rhs: String) -> Int {
        let lhsArray = Array(lhs)
        let rhsArray = Array(rhs)
        let m = lhsArray.count
        let n = rhsArray.count
        
        if m == 0 { return n }
        if n == 0 { return m }
        
        var dp = Array(repeating: Array(repeating: 0, count: n + 1), count: m + 1)
        for i in 0...m { dp[i][0] = i }
        for j in 0...n { dp[0][j] = j }
        
        for i in 1...m {
            for j in 1...n {
                if lhsArray[i - 1] == rhsArray[j - 1] {
                    dp[i][j] = dp[i - 1][j - 1]
                } else {
                    let insertion = dp[i][j - 1] + 1
                    let deletion = dp[i - 1][j] + 1
                    let substitution = dp[i - 1][j - 1] + 1
                    dp[i][j] = min(insertion, deletion, substitution)
                }
            }
        }
        
        return dp[m][n]
    }
}
