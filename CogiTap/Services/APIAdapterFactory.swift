//
//  APIAdapterFactory.swift
//  CogiTap
//
//  Created by mengfs on 11/1/25.
//

import Foundation

class APIAdapterFactory {
    static func createAdapter(for provider: APIProvider) -> APIAdapter {
        switch provider.type {
        case .openai, .openrouter, .custom:
            return OpenAIAdapter(provider: provider)
        case .anthropic:
            return AnthropicAdapter(provider: provider)
        case .gemini:
            return GeminiAdapter(provider: provider)
        }
    }
}
