//
//  PersonaFilesWriter.swift
//  Oasis
//
//  Created by Edgardo Ramos on 4/5/26.
//

import Foundation

enum PersonaFilesWriter {
    static let rootPath = "/Users/edgardoramos/Oasis"
    static let personaDirectory = "\(rootPath)/persona"

    static func write(from setupData: SetupDataFile) throws {
        try FileManager.default.createDirectory(
            atPath: personaDirectory,
            withIntermediateDirectories: true
        )

        try write(
            fileName: "IDENTITY.md",
            content: identityContent(from: setupData)
        )

        try write(
            fileName: "USER.md",
            content: userContent(from: setupData)
        )

        try write(
            fileName: "SOUL.md",
            content: soulContent(from: setupData)
        )

        try write(
            fileName: "MEMORY.md",
            content: memoryContent(from: setupData)
        )
    }

    private static func write(fileName: String, content: String) throws {
        let path = "\(personaDirectory)/\(fileName)"
        try content.write(to: URL(fileURLWithPath: path), atomically: true, encoding: .utf8)
    }

    private static func identityContent(from data: SetupDataFile) -> String {
        """
        # IDENTITY.md

        - Bot name: \(data.botName)
        - Main language: \(data.mainLanguage)
        - Identity mode: personal assistant
        """
    }

    private static func userContent(from data: SetupDataFile) -> String {
        """
        # USER.md

        - Call the user: \(data.userCallName)
        - Preferred language: \(data.mainLanguage)
        """
    }

    private static func soulContent(from data: SetupDataFile) -> String {
        """
        # SOUL.md

        ## Base tone
        - \(data.assistantTone)

        ## Response discipline
        - Be clear
        - Be useful
        - Do not invent information
        - Prefer concrete steps
        """
    }

    private static func memoryContent(from data: SetupDataFile) -> String {
        """
        # MEMORY.md

        ## Long-term memory
        - Assistant name: \(data.botName)
        - User call name: \(data.userCallName)
        - Main language: \(data.mainLanguage)

        ## Active setup
        - Telegram enabled: \(data.telegramEnabled ? "yes" : "no")
        - Selected skills: \(data.selectedSkills.joined(separator: ", "))
        """
    }
}
