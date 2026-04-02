//
//  RuntimeConfigWriter.swift
//  Oasis
//
//  Created by Edgardo Ramos on 4/1/26.
//

import Foundation

struct RuntimeConfigPayload: Codable {
    let telegramBotToken: String
    let ollamaModel: String
    let ollamaUrl: String
    let allowedUserID: String
    let ollamaFallbackModels: [String]
}

enum RuntimeConfigWriter {
    static func writeBotRuntimeConfig() throws {
        let stateDirectory = URL(fileURLWithPath: OasisConfig.rootPath)
            .appendingPathComponent("state")

        let configURL = stateDirectory
            .appendingPathComponent("runtime-config.json")

        try FileManager.default.createDirectory(
            at: stateDirectory,
            withIntermediateDirectories: true
        )

        let payload = RuntimeConfigPayload(
            telegramBotToken: OasisConfig.telegramBotToken,
            ollamaModel: OasisConfig.ollamaModel,
            ollamaUrl: OasisConfig.ollamaUrl,
            allowedUserID: OasisConfig.allowedUserID,
            ollamaFallbackModels: OasisConfig.ollamaFallbackModels
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let data = try encoder.encode(payload)
        try data.write(to: configURL, options: .atomic)
    }
}
