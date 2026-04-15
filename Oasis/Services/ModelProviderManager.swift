//
//  ModelProviderManager.swift
//  Oasis
//
//  Created by Edgardo Ramos on 4/5/26.
//

import Foundation

final class ModelProviderManager {

    static let shared = ModelProviderManager()

    private init() {}

    // MARK: - Providers disponibles (futuro: OpenAI, LMStudio, etc)
    func availableProviders() -> [String] {
        return ["Ollama"]
    }

    // MARK: - Obtener modelos de Ollama
    func fetchOllamaModels() -> [String] {
        let task = Process()
        let pipe = Pipe()

        task.executableURL = URL(fileURLWithPath: "/bin/zsh")
        task.arguments = ["-lc", "ollama list"]
        task.standardOutput = pipe
        task.standardError = Pipe()

        do {
            try task.run()
            task.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let output = String(data: data, encoding: .utf8) else {
                return []
            }

            return parseOllamaList(output)

        } catch {
            return []
        }
    }

    // MARK: - Parseo de "ollama list"
    private func parseOllamaList(_ raw: String) -> [String] {
        let lines = raw.split(separator: "\n")

        // saltamos header
        return lines.dropFirst().compactMap { line in
            let parts = line.split(separator: " ", omittingEmptySubsequences: true)
            return parts.first.map { String($0) }
        }
    }
}
