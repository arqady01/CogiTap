//
//  AppearancePreferences.swift
//  CogiTap
//
//  Created by Codex on 11/1/25.
//

import SwiftUI

enum AppearanceStorageKey {
    static let userBubbleColor = "appearance.userBubbleColor"
    static let userMessageFont = "appearance.userMessageFont"
    static let reasoningFont = "appearance.reasoningFont"
    static let assistantMessageFont = "appearance.assistantMessageFont"
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

    var accentButtonColor: Color {
        switch self {
        case .white:
            return Color(red: 90 / 255, green: 134 / 255, blue: 255 / 255)
        case .blue:
            return Color(red: 54 / 255, green: 107 / 255, blue: 250 / 255)
        case .cyan:
            return Color(red: 24 / 255, green: 156 / 255, blue: 220 / 255)
        case .yellow:
            return Color(red: 255 / 255, green: 170 / 255, blue: 56 / 255)
        case .green:
            return Color(red: 12 / 255, green: 134 / 255, blue: 92 / 255)
        case .pink:
            return Color(red: 216 / 255, green: 56 / 255, blue: 136 / 255)
        case .red:
            return Color(red: 196 / 255, green: 38 / 255, blue: 67 / 255)
        case .orange:
            return Color(red: 226 / 255, green: 98 / 255, blue: 30 / 255)
        case .purple:
            return Color(red: 143 / 255, green: 73 / 255, blue: 215 / 255)
        }
    }
    
    static var `default`: ChatBubbleColorOption { .blue }
}

enum ChatFontSizeOption: String, CaseIterable, Identifiable {
    case xsmall
    case small
    case medium
    case large
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .xsmall: return "特小"
        case .small: return "小"
        case .medium: return "默认"
        case .large: return "大"
        }
    }
    
    var userMessageSize: CGFloat {
        switch self {
        case .xsmall: return 14
        case .small: return 16
        case .medium: return 17
        case .large: return 19
        }
    }
    
    var reasoningSize: CGFloat {
        switch self {
        case .xsmall: return 12
        case .small: return 13
        case .medium: return 14
        case .large: return 16
        }
    }
    
    var assistantMessageSize: CGFloat {
        switch self {
        case .xsmall: return 15
        case .small: return 16
        case .medium: return 17
        case .large: return 19
        }
    }
    
    static var `default`: ChatFontSizeOption { .medium }
}
