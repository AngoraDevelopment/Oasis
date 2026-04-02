//
//  SetupManager.swift
//  Oasis
//
//  Created by Edgardo Ramos on 4/2/26.
//

import Foundation

struct OasisSetupConfig: Codable {
    struct Assistant: Codable {
        var name: String
        var language: String
    }

    struct User: Codable {
        var displayName: String
        var addressName: String
    }

    struct Personality: Codable {
        var tone: String
        var style: String
        var verbosity: String
        var proactive: Bool
    }

    struct Models: Codable {
        var primary: String
        var fallbacks: [String]
    }

    struct Telegram: Codable {
        var enabled: Bool
        var token: String
        var allowedUserId: String
    }

    struct System: Codable {
        var timezone: String
        var firstRunCompleted: Bool
        var setupCompletedAt: String?
    }

    var assistant: Assistant
    var user: User
    var personality: Personality
    var models: Models
    var telegram: Telegram
    var system: System
}

final class SetupManager {

    static let shared = SetupManager()

    private init() {}

    private var configURL: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let oasisDir = dir.appendingPathComponent("Oasis", isDirectory: true)

        if !FileManager.default.fileExists(atPath: oasisDir.path) {
            try? FileManager.default.createDirectory(at: oasisDir, withIntermediateDirectories: true)
        }

        return oasisDir.appendingPathComponent("assistant.config.json")
    }

    func isFirstRun() -> Bool {
        guard FileManager.default.fileExists(atPath: configURL.path) else {
            return true
        }

        do {
            let data = try Data(contentsOf: configURL)
            let config = try JSONDecoder().decode(OasisSetupConfig.self, from: data)
            return !config.system.firstRunCompleted
        } catch {
            return true
        }
    }

    func save(config: OasisSetupConfig) {
        do {
            let data = try JSONEncoder().encode(config)
            try data.write(to: configURL)
        } catch {
            print("Error guardando config:", error)
        }
    }

    func detectTimezone() -> String {
        TimeZone.current.identifier
    }
}
