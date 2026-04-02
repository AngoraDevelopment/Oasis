//
//  OasisConfig.swift
//  Oasis
//
//  Created by Edgardo Ramos on 4/1/26.
//

import Foundation

struct TelegramConfig: Codable, Equatable {
    var allowedUserID: String = ""
}

struct OllamaConfig: Codable, Equatable {
    var primaryModel: String = "ollama/phi4-mini:latest"
    var fallbackModels: [String] = ["ollama/phi4-mini:latest"]
}

struct OasisConfig: Codable, Equatable {
    var telegram: TelegramConfig = .init()
    var ollama: OllamaConfig = .init()
}
