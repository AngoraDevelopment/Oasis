//
//  OasisConfig.swift
//  Oasis
//
//  Created by Edgardo Ramos on 4/1/26.
//

import Foundation

enum OasisConfig {
    static let rootPath = "/Users/edgardoramos/Oasis"
    static let nodePath = "/usr/local/bin/node"

    static let telegramBotToken = "PON_AQUI_TU_TOKEN"
    static let allowedUserID = "PON_AQUI_TU_USER_ID"

    static let ollamaModel = "phi4-mini:latest"
    static let ollamaUrl = "http://127.0.0.1:11434/api/chat"
    static let ollamaFallbackModels = [
        "mistral",
        "qwen2.5-coder:7b"
    ]
}
