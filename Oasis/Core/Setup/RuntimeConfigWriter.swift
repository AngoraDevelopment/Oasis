//
//  RuntimeConfigWriter.swift
//  Oasis
//
//  Created by Edgardo Ramos on 4/5/26.
//

import Foundation
internal import Combine

enum RuntimeConfigWriter {
    static let rootPath = "/Users/edgardoramos/Oasis"
    static let stateDirectory = "\(rootPath)/state"
    static let runtimeConfigPath = "\(stateDirectory)/runtime-config.json"

    static func write(from setupData: SetupDataFile, configStore: OasisConfigStore?) throws {
        try FileManager.default.createDirectory(
            atPath: stateDirectory,
            withIntermediateDirectories: true
        )

        let primaryModel: String
        let fallbackModels: [String]
        let model = setupData.modelName.isEmpty ? "phi4-mini:latest" : setupData.modelName
        
        if let configStore {
            primaryModel = configStore.config.ollama.primaryModel.replacingOccurrences(of: "ollama/", with: "")
            fallbackModels = configStore.config.ollama.fallbackModels.map {
                $0.replacingOccurrences(of: "ollama/", with: "")
            }
        } else {
            primaryModel = "mistral:latest"
            fallbackModels = ["phi4-mini:latest"]
        }

        let payload = RuntimeConfigFile(
            telegramBotToken: setupData.telegramBotToken,
            allowedUserID: setupData.allowedUserID,
            ollamaModel: model,
            ollamaUrl: "http://127.0.0.1:11434/api/chat",
            ollamaFallbackModels: [model]
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(payload)
        try data.write(to: URL(fileURLWithPath: runtimeConfigPath), options: .atomic)

        if let configStore {
            configStore.telegramBotToken = setupData.telegramBotToken
            configStore.config.telegram.allowedUserID = setupData.allowedUserID
            configStore.saveConfig()
        }
    }
}
