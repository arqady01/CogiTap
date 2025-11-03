//
//  ReasoningFlowView.swift
//  CogiTap
//
//  Created by Codex on 11/1/25.
//

import SwiftUI

/// Represents one node in the reasoning timeline.
private struct ReasoningStep: Identifiable {
    let id = UUID()
    let headline: String
    let detail: String?
}

/// Parses a raw reasoning string into presentable steps.
private enum ReasoningFlowParser {
    static func parse(_ reasoning: String) -> [ReasoningStep] {
        let normalized = reasoning
            .replacingOccurrences(of: "\r\n", with: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !normalized.isEmpty else { return [] }
        
        let doubleLineBreakBlocks = normalized
            .components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        if doubleLineBreakBlocks.count > 1 {
            return doubleLineBreakBlocks.map { makeStep(from: $0) }
        }
        
        let singleLineBreakBlocks = normalized
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        if singleLineBreakBlocks.count > 1 {
            return singleLineBreakBlocks.map { makeStep(from: $0) }
        }
        
        let sentenceCandidates = normalized
            .components(separatedBy: ". ")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        if sentenceCandidates.count > 1 {
            return sentenceCandidates.map { makeStep(from: $0) }
        }
        
        return [makeStep(from: normalized)]
    }
    
    private static func makeStep(from raw: String) -> ReasoningStep {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return ReasoningStep(headline: "…", detail: nil)
        }
        
        let headlineCandidates = trimmed
            .components(separatedBy: "\n")
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        if headlineCandidates.count > 1 {
            let headline = cleanLeadingMarkers(on: headlineCandidates[0])
            let detail = headlineCandidates.dropFirst().joined(separator: "\n")
            return ReasoningStep(
                headline: headline,
                detail: detail.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty()
            )
        }
        
        let colonSplit = trimmed.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: true)
        if colonSplit.count == 2 {
            let headline = cleanLeadingMarkers(on: String(colonSplit[0]))
            let detail = String(colonSplit[1]).trimmingCharacters(in: .whitespacesAndNewlines)
            return ReasoningStep(
                headline: headline,
                detail: detail.nilIfEmpty()
            )
        }
        
        return ReasoningStep(headline: cleanLeadingMarkers(on: trimmed), detail: nil)
    }
    
    private static func cleanLeadingMarkers(on text: String) -> String {
        var result = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let lowercased = result.lowercased()
        
        if lowercased.hasPrefix("step") || lowercased.hasPrefix("stage") {
            let offset = lowercased.hasPrefix("stage") ? 5 : 4
            var index = result.index(result.startIndex, offsetBy: min(offset, result.count))
            
            while index < result.endIndex, result[index].isWhitespace {
                index = result.index(after: index)
            }
            while index < result.endIndex, result[index].isNumber {
                index = result.index(after: index)
            }
            if index < result.endIndex, [":", "-", ".", ")"].contains(result[index]) {
                index = result.index(after: index)
            }
            while index < result.endIndex, result[index].isWhitespace {
                index = result.index(after: index)
            }
            result = index < result.endIndex ? String(result[index...]) : ""
        } else {
            while let first = result.first, first.isNumber || first == "." || first == ")" || first == "-" {
                result.removeFirst()
            }
        }
        
        let trimmed = result.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "…" : trimmed
    }
}

extension String {
    fileprivate func nilIfEmpty() -> String? {
        isEmpty ? nil : self
    }
}

struct ReasoningFlowView: View {
    private let steps: [ReasoningStep]
    private let reasoning: String
    
    @State private var revealedSteps = 0
    @State private var scheduledUpToStep = 0
    @State private var animationID = UUID()
    
    init(reasoning: String) {
        self.reasoning = reasoning
        self.steps = ReasoningFlowParser.parse(reasoning)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                ReasoningStepRow(
                    index: index + 1,
                    step: step,
                    isRevealed: index < revealedSteps,
                    isActive: index == revealedSteps - 1
                )
                .opacity(index < revealedSteps ? 1 : 0)
                .animation(
                    .spring(response: 0.55, dampingFraction: 0.8)
                        .delay(Double(index) * 0.08),
                    value: revealedSteps
                )
            }
            
            if steps.isEmpty {
                Text(reasoning)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .transition(.opacity)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(borderColor, lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 6)
        )
        .onAppear {
            handleReasoningChange(isInitial: true)
        }
        .onChange(of: reasoning) { _, _ in
            handleReasoningChange(isInitial: false)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("思考过程")
    }
    
    private var backgroundColor: Color {
        Color(.secondarySystemBackground)
    }
    
    private var borderColor: Color {
        Color.white.opacity(0.55)
    }
    
    private func handleReasoningChange(isInitial: Bool) {
        let trimmed = reasoning.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.isEmpty || steps.isEmpty {
            resetRevealState()
            return
        }
        
        let totalSteps = steps.count
        
        if totalSteps < revealedSteps {
            revealedSteps = totalSteps
        }
        if totalSteps < scheduledUpToStep {
            scheduledUpToStep = totalSteps
        }
        
        if revealedSteps == 0 {
            let animation = isInitial
            ? Animation.spring(response: 0.45, dampingFraction: 0.82)
            : Animation.spring(response: 0.35, dampingFraction: 0.85)
            withAnimation(animation) {
                revealedSteps = 1
            }
            scheduledUpToStep = max(scheduledUpToStep, 1)
        }
        
        if totalSteps > scheduledUpToStep {
            scheduleAdditionalReveals(from: scheduledUpToStep + 1, upTo: totalSteps)
            scheduledUpToStep = totalSteps
        }
    }
    
    private func resetRevealState() {
        animationID = UUID()
        revealedSteps = 0
        scheduledUpToStep = 0
    }
    
    private func scheduleAdditionalReveals(from start: Int, upTo end: Int) {
        guard start <= end else { return }
        let currentID = animationID
        let clampedStart = max(start, 2)
        let stepsRange = clampedStart...end
        
        for (offset, stepIndex) in stepsRange.enumerated() {
            let baseDelay: Double = stepIndex == 2 && offset == 0 ? 0.5 : 0.65
            let delay = baseDelay + Double(offset) * 0.55
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                guard animationID == currentID else { return }
                guard revealedSteps < stepIndex else { return }
                withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
                    revealedSteps = stepIndex
                }
            }
        }
    }
}

private struct ReasoningStepRow: View {
    let index: Int
    let step: ReasoningStep
    let isRevealed: Bool
    let isActive: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Step \(index)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .opacity(isRevealed ? 1.0 : 0.2)
            
            Text(step.headline)
                .font(.callout)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
                .transition(.move(edge: .leading).combined(with: .opacity))
            
            if let detail = step.detail {
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.opacity)
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(cardBorder, lineWidth: 1)
        )
        .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowYOffset)
        .scaleEffect(isActive ? 1.02 : 1.0)
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: isActive)
    }
    
    private var cardBackground: Color {
        if isActive {
            return Color.blue.opacity(0.08)
        } else if isRevealed {
            return Color(.systemBackground).opacity(0.98)
        } else {
            return Color(.systemGray6)
        }
    }
    
    private var cardBorder: Color {
        if isActive {
            return Color.blue.opacity(0.35)
        } else if isRevealed {
            return Color.primary.opacity(0.08)
        } else {
            return Color.primary.opacity(0.04)
        }
    }
    
    private var shadowColor: Color {
        isActive ? Color.primary.opacity(0.12) : Color.black.opacity(0.05)
    }
    
    private var shadowRadius: CGFloat {
        isActive ? 12 : 6
    }
    
    private var shadowYOffset: CGFloat {
        isActive ? 8 : 4
    }
}

#Preview {
    ReasoningFlowView(reasoning: """
    1. 确认用户的问题：识别出这是一个关于量子计算基础原理的概述请求。
    2. 回顾关键点：量子位的叠加态、量子干涉与纠缠是核心。
    3. 构建回答结构：先解释量子位，再说明叠加与干涉，最后引出量子算法带来的并行性优势。
    4. 核对流畅度：确保语言通俗，并补充实际应用示例帮助理解。
    """)
    .padding()
    .background(Color(.systemBackground))
}
