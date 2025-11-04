//
//  AppearancePreferences.swift
//  CogiTap
//
//  Created by Codex on 11/1/25.
//

import SwiftUI

enum AppearanceStorageKey {
    static let userBubbleColor = "appearance.userBubbleColor"
}

enum ChatBubbleColorOption: String, CaseIterable, Identifiable {
    case white
    case blue
    case cyan
    case yellow
    case green
    case pink
    case red
    case orange
    case purple
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .white: return "白色"
        case .blue: return "蓝色"
        case .cyan: return "青色"
        case .yellow: return "黄色"
        case .green: return "绿色"
        case .pink: return "粉红色"
        case .red: return "红色"
        case .orange: return "橙色"
        case .purple: return "紫色"
        }
    }
    
    var fillColor: Color {
        switch self {
        case .white:
            return Color.white
        case .blue:
            return Color(red: 56 / 255, green: 107 / 255, blue: 250 / 255)
        case .cyan:
            return Color.cyan
        case .yellow:
            return Color(red: 255 / 255, green: 214 / 255, blue: 76 / 255)
        case .green:
            return Color(red: 46 / 255, green: 176 / 255, blue: 105 / 255)
        case .pink:
            return Color(red: 233 / 255, green: 89 / 255, blue: 146 / 255)
        case .red:
            return Color(red: 231 / 255, green: 79 / 255, blue: 84 / 255)
        case .orange:
            return Color(red: 255 / 255, green: 149 / 255, blue: 69 / 255)
        case .purple:
            return Color(red: 168 / 255, green: 99 / 255, blue: 235 / 255)
        }
    }
    
    var textColor: Color {
        switch self {
        case .white, .yellow, .cyan:
            return Color.primary
        default:
            return Color.white
        }
    }
    
    var borderColor: Color {
        switch self {
        case .white, .yellow, .cyan:
            return Color.black.opacity(0.06)
        default:
            return Color.clear
        }
    }
    
    var needsBorder: Bool {
        switch self {
        case .white, .yellow, .cyan:
            return true
        default:
            return false
        }
    }
    
    static var `default`: ChatBubbleColorOption { .blue }
}
