//
//  SetupStateStore.swift
//  Oasis
//
//  Created by Edgardo Ramos on 4/5/26.
//

import Foundation

enum SetupStateStore {
    static let rootPath = "/Users/edgardoramos/Oasis"
    static let stateDirectory = "\(rootPath)/state"
    static let setupPath = "\(stateDirectory)/setup.json"
    static let setupDataPath = "\(stateDirectory)/setupData.json"

    static func ensureStateFiles() throws {
        try FileManager.default.createDirectory(
            atPath: stateDirectory,
            withIntermediateDirectories: true
        )

        if !FileManager.default.fileExists(atPath: setupPath) {
            let phases = defaultPhases()
            try writePhases(phases)
        }

        if !FileManager.default.fileExists(atPath: setupDataPath) {
            let data = SetupDataFile()
            try writeSetupData(data)
        }
    }

    static func defaultPhases() -> [SetupPhase] {
        [
            .init(id: "setup", required: true, completed: false),
            .init(id: "telegram", required: true, completed: false),
            .init(id: "skills", required: true, completed: false)
        ]
    }

    static func readPhases() -> [SetupPhase] {
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: setupPath))
            return try JSONDecoder().decode([SetupPhase].self, from: data)
        } catch {
            return defaultPhases()
        }
    }

    static func writePhases(_ phases: [SetupPhase]) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(phases)
        try data.write(to: URL(fileURLWithPath: setupPath), options: .atomic)
    }

    static func readSetupData() -> SetupDataFile {
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: setupDataPath))
            return try JSONDecoder().decode(SetupDataFile.self, from: data)
        } catch {
            return SetupDataFile()
        }
    }

    static func writeSetupData(_ file: SetupDataFile) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(file)
        try data.write(to: URL(fileURLWithPath: setupDataPath), options: .atomic)
    }

    static func markPhaseCompleted(_ id: String) throws {
        var phases = readPhases()

        if let index = phases.firstIndex(where: { $0.id == id }) {
            phases[index].completed = true
        }

        try writePhases(phases)
    }

    static func resetAllPhases() throws {
        try writePhases(defaultPhases())
    }
}
