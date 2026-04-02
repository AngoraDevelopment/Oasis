//
//  OasisConfigStore.swift
//  Oasis
//
//  Created by Edgardo Ramos on 4/1/26.
//

import Foundation
import SwiftUI
internal import Combine

struct RuntimeConfigFile: Codable {
    let telegramBotToken: String
    let allowedUserID: String
    let ollamaModel: String
    let ollamaUrl: String
    let ollamaFallbackModels: [String]
}

@MainActor
final class OasisConfigStore: ObservableObject {
    @Published var config: OasisConfig
    @Published var telegramBotToken: String

    private let defaultsKey = "oasis_app_config"
    private let runtimeConfigPath = "/Users/edgardoramos/Oasis/state/runtime-config.json"

    init() {
        let savedConfig = Self.loadConfig(defaultsKey: defaultsKey) ?? OasisConfig()
        self.config = savedConfig
        self.telegramBotToken = ""

        loadRuntimeConfigIfAvailable()
    }

    func saveAll() {
        saveConfig()
        saveRuntimeConfigFile()
    }

    func saveConfig() {
        guard let data = try? JSONEncoder().encode(config) else { return }
        UserDefaults.standard.set(data, forKey: defaultsKey)
    }

    func botEnvironment() -> [String: String] {
        [
            "TELEGRAM_BOT_TOKEN": telegramBotToken,
            "ALLOWED_USER_ID": config.telegram.allowedUserID,
            "OLLAMA_MODEL": normalizedPrimaryModel(config.ollama.primaryModel),
            "OLLAMA_FALLBACK_MODELS": config.ollama.fallbackModels
                .map { $0.replacingOccurrences(of: "ollama/", with: "") }
                .joined(separator: ",")
        ]
    }

    private func normalizedPrimaryModel(_ raw: String) -> String {
        raw.replacingOccurrences(of: "ollama/", with: "")
    }

    private static func loadConfig(defaultsKey: String) -> OasisConfig? {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey) else { return nil }
        return try? JSONDecoder().decode(OasisConfig.self, from: data)
    }

    private func loadRuntimeConfigIfAvailable() {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: runtimeConfigPath)),
              let runtime = try? JSONDecoder().decode(RuntimeConfigFile.self, from: data) else {
            return
        }

        if !runtime.telegramBotToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            telegramBotToken = runtime.telegramBotToken
        }

        if !runtime.allowedUserID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            config.telegram.allowedUserID = runtime.allowedUserID
        }

        if !runtime.ollamaModel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            config.ollama.primaryModel = "ollama/\(runtime.ollamaModel)"
        }

        if !runtime.ollamaFallbackModels.isEmpty {
            config.ollama.fallbackModels = runtime.ollamaFallbackModels.map { "ollama/\($0)" }
        }
    }

    func saveRuntimeConfigFile() {
        let trimmedToken = telegramBotToken.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedUserID = config.telegram.allowedUserID.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedToken.isEmpty else {
            print("No se sobrescribió runtime-config.json porque telegramBotToken está vacío.")
            return
        }

        guard !trimmedUserID.isEmpty else {
            print("No se sobrescribió runtime-config.json porque allowedUserID está vacío.")
            return
        }

        let runtimeConfig = RuntimeConfigFile(
            telegramBotToken: trimmedToken,
            allowedUserID: trimmedUserID,
            ollamaModel: normalizedPrimaryModel(config.ollama.primaryModel),
            ollamaUrl: "http://127.0.0.1:11434/api/chat",
            ollamaFallbackModels: config.ollama.fallbackModels.map {
                $0.replacingOccurrences(of: "ollama/", with: "")
            }
        )

        let stateDirectory = "/Users/edgardoramos/Oasis/state"
        let filePath = "\(stateDirectory)/runtime-config.json"

        do {
            try FileManager.default.createDirectory(
                atPath: stateDirectory,
                withIntermediateDirectories: true
            )

            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(runtimeConfig)
            try data.write(to: URL(fileURLWithPath: filePath), options: .atomic)

            print("runtime-config.json guardado correctamente en \(filePath)")
        } catch {
            print("No se pudo guardar runtime-config.json: \(error.localizedDescription)")
        }
    }
}
