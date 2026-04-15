//
//  SetupWizardModels.swift
//  Oasis
//
//  Created by Edgardo Ramos on 4/5/26.
//

import Foundation

struct SetupPhase: Codable, Identifiable, Equatable {
    let id: String
    let required: Bool
    var completed: Bool
}

struct SetupDataFile: Codable, Equatable {
    var botName: String = "Unnamed"
    var userCallName: String = "Maestro"
    var assistantTone: String = "Directo"
    var mainLanguage: String = "Español"

    var telegramEnabled: Bool = true
    var telegramBotToken: String = ""
    var allowedUserID: String = ""
    
    var modelProvider: String = "ollama"
    var modelName: String = ""
    
    var selectedSkills: [String] = []
}

struct SetupChoice: Identifiable, Equatable {
    let id = UUID()
    let value: String
    var isSelected: Bool
}

enum SetupPromptKind: Equatable {
    case textInput(
        key: String,
        title: String,
        placeholder: String,
        secure: Bool = false
    )

    case singleSelection(
        key: String,
        title: String,
        options: [String]
    )

    case multiSelection(
        key: String,
        title: String,
        options: [String]
    )
}

struct SetupPrompt: Equatable {
    let sectionTitle: String
    let kind: SetupPromptKind
    var highlightedIndex: Int = 0
    var choices: [SetupChoice] = []
}

enum SetupWizardSection: String, Equatable {
    case bot
    case integrations
    case telegram
    case modelProvider
    case modelSelection
    case skills
    case finished
}
