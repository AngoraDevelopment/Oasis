//
//  SetupCommandManager.swift
//  Oasis
//
//  Created by Edgardo Ramos on 4/5/26.
//

import Foundation
internal import Combine

@MainActor
final class SetupCommandManager: ObservableObject {
    @Published private(set) var isRunning = false
    @Published private(set) var currentPrompt: SetupPrompt?

    private(set) var wizardSection: SetupWizardSection = .bot
    private var setupData = SetupDataFile()

    private weak var configStore: OasisConfigStore?

    init(configStore: OasisConfigStore? = nil) {
        self.configStore = configStore
    }

    func bindConfigStore(_ configStore: OasisConfigStore) {
        self.configStore = configStore
    }

    func start() throws -> [ConsoleLine] {
        try SetupStateStore.ensureStateFiles()

        setupData = SetupStateStore.readSetupData()
        isRunning = true
        wizardSection = .bot

        currentPrompt = makeBotNamePrompt()

        return [
            ConsoleLine(text: "Iniciando setup interactivo de Oasis...", kind: .system),
            ConsoleLine(text: "Sección 1/4 · Configuración del bot", kind: .system)
        ]
    }

    func cancel() -> [ConsoleLine] {
        isRunning = false
        currentPrompt = nil
        wizardSection = .finished

        return [
            ConsoleLine(text: "Setup cancelado.", kind: .warning)
        ]
    }

    func handleTextSubmit(_ text: String) throws -> [ConsoleLine] {
        guard isRunning, let prompt = currentPrompt else { return [] }

        switch prompt.kind {
        case .textInput(let key, _, _, _):
            saveTextInput(key: key, value: text)
            return try advanceAfterTextInput()

        case .singleSelection, .multiSelection:
            return [
                ConsoleLine(text: "Usa ↑ ↓ para moverte, Space para seleccionar y Enter para continuar.", kind: .warning)
            ]
        }
    }

    func moveUp() {
        guard isRunning, var prompt = currentPrompt else { return }

        switch prompt.kind {
        case .singleSelection, .multiSelection:
            prompt.highlightedIndex = max(0, prompt.highlightedIndex - 1)
            currentPrompt = prompt
        default:
            break
        }
    }

    func moveDown() {
        guard isRunning, var prompt = currentPrompt else { return }

        switch prompt.kind {
        case .singleSelection, .multiSelection:
            prompt.highlightedIndex = min(prompt.choices.count - 1, prompt.highlightedIndex + 1)
            currentPrompt = prompt
        default:
            break
        }
    }

    func toggleSelection() {
        guard isRunning, var prompt = currentPrompt else { return }

        switch prompt.kind {
        case .singleSelection:
            for index in prompt.choices.indices {
                prompt.choices[index].isSelected = index == prompt.highlightedIndex
            }
            currentPrompt = prompt

        case .multiSelection:
            guard prompt.choices.indices.contains(prompt.highlightedIndex) else { return }
            prompt.choices[prompt.highlightedIndex].isSelected.toggle()
            currentPrompt = prompt

        default:
            break
        }
    }

    func confirmSelection() throws -> [ConsoleLine] {
        guard isRunning, let prompt = currentPrompt else { return [] }

        switch prompt.kind {
        case .singleSelection(let key, _, _):
            if let selected = prompt.choices.first(where: { $0.isSelected })?.value {
                saveSelectionValue(key: key, selected: [selected])
            }
            return try advanceAfterSelection()

        case .multiSelection(let key, _, _):
            let selected = prompt.choices.filter(\.isSelected).map(\.value)
            saveSelectionValue(key: key, selected: selected)
            return try advanceAfterSelection()

        case .textInput:
            return [
                ConsoleLine(text: "Escribe el valor y presiona Enter.", kind: .warning)
            ]
        }
    }

    // MARK: - Private

    private func advanceAfterTextInput() throws -> [ConsoleLine] {
        switch wizardSection {
        case .bot:
            return try advanceBotSection()
        case .telegram:
            return try advanceTelegramSection()
        default:
            return []
        }
    }

    private func advanceAfterSelection() throws -> [ConsoleLine] {
        switch wizardSection {
        case .bot:
            return try advanceBotSection()
        case .integrations:
            return try advanceIntegrationsSection()
        case .skills:
            return try finishSkillsSection()
        default:
            return []
        }
    }

    private func advanceBotSection() throws -> [ConsoleLine] {
        let currentKey = currentPromptKey()

        switch currentKey {
        case "botName":
            currentPrompt = makeUserCallNamePrompt()
            return [ConsoleLine(text: "¿Cómo quieres que te llame el bot?", kind: .system)]

        case "userCallName":
            currentPrompt = makeTonePrompt()
            return [ConsoleLine(text: "Selecciona el tono del bot.", kind: .system)]

        case "assistantTone":
            currentPrompt = makeLanguagePrompt()
            return [ConsoleLine(text: "Selecciona el idioma principal.", kind: .system)]

        case "mainLanguage":
            try SetupStateStore.markPhaseCompleted("setup")
            wizardSection = .integrations
            currentPrompt = makeIntegrationsPrompt()
            return [
                ConsoleLine(text: "✔ Sección bot completada.", kind: .success),
                ConsoleLine(text: "Sección 2/3 · Integraciones", kind: .system)
            ]

        default:
            return []
        }
    }

    private func advanceIntegrationsSection() throws -> [ConsoleLine] {
        let telegramSelected = currentPrompt?.choices.contains(where: { $0.value == "Telegram" && $0.isSelected }) == true
        setupData.telegramEnabled = telegramSelected
        try SetupStateStore.writeSetupData(setupData)

        if telegramSelected {
            wizardSection = .telegram
            currentPrompt = makeTelegramTokenPrompt()

            return [
                ConsoleLine(text: "Telegram activado. Ahora introduce el Bot Token.", kind: .system)
            ]
        } else {
            wizardSection = .skills
            currentPrompt = makeSkillsPrompt()

            return [
                ConsoleLine(text: "Telegram omitido.", kind: .warning),
                ConsoleLine(text: "Sección 3/3 · Skills", kind: .system)
            ]
        }
    }

    private func advanceTelegramSection() throws -> [ConsoleLine] {
        let currentKey = currentPromptKey()

        switch currentKey {
        case "telegramBotToken":
            currentPrompt = makeAllowedUserIDPrompt()
            return [ConsoleLine(text: "Ahora introduce el Allowed User ID.", kind: .system)]

        case "allowedUserID":
            try RuntimeConfigWriter.write(from: setupData, configStore: configStore)
            try SetupStateStore.markPhaseCompleted("telegram")

            wizardSection = .modelProvider
            currentPrompt = makeModelProviderPrompt()

            return [
                ConsoleLine(text: "✔ Telegram configurado.", kind: .success),
                ConsoleLine(text: "Sección 3/4 · Model Provider", kind: .system)
            ]

        default:
            return []
        }
    }
    
    private func advanceModelSection() throws -> [ConsoleLine] {
        let key = currentPromptKey()

        switch key {

        case "modelProvider":
            setupData.modelProvider = selectedOptionID()
            currentPrompt = makeModelSelectionPrompt()

            return [
                ConsoleLine(text: "Provider seleccionado.", kind: .success),
                ConsoleLine(text: "Selecciona el modelo.", kind: .system)
            ]

        case "modelName":
            setupData.modelName = selectedOptionID()

            try SetupStateStore.writeSetupData(setupData)
            try RuntimeConfigWriter.write(from: setupData, configStore: configStore)

            wizardSection = .skills
            currentPrompt = makeSkillsPrompt()

            return [
                ConsoleLine(text: "✔ Modelo configurado: \(setupData.modelName)", kind: .success),
                ConsoleLine(text: "Sección 4/4 · Skills", kind: .system)
            ]

        default:
            return []
        }
    }
    
    private func makeModelProviderPrompt() -> SetupPrompt {
        let providers = ModelProviderManager.shared.availableProviders()

        return SetupPrompt(
            sectionTitle: "Model Provider",
            kind: .singleSelection(
                key: "modelProvider",
                title: "Selecciona el provider",
                options: providers.map {
                    SetupOption(id: $0.lowercased(), title: $0)
                }
            )
        )
    }
    
    private func makeModelSelectionPrompt() -> SetupPrompt {
        let models = ModelProviderManager.shared.fetchOllamaModels()

        let safeModels = models.isEmpty
            ? ["phi4-mini:latest"]
            : models

        return SetupPrompt(
            sectionTitle: "Model Selection",
            kind: .singleSelection(
                key: "modelName",
                title: "Selecciona el modelo",
                options: safeModels.map {
                    SetupOption(id: $0, title: $0)
                }
            )
        )
    }
    
    private func finishSkillsSection() throws -> [ConsoleLine] {
        SkillsConfigWriter.applySelection(selectedSkills: setupData.selectedSkills)
        try SetupStateStore.markPhaseCompleted("skills")
        try SetupStateStore.writeSetupData(setupData)
        try PersonaFilesWriter.write(from: setupData)

        isRunning = false
        wizardSection = .finished
        currentPrompt = nil

        return [
            ConsoleLine(text: "✔ Skills configuradas.", kind: .success),
            ConsoleLine(text: "✔ Archivos de persona y memoria generados.", kind: .success),
            ConsoleLine(text: "✔ Setup completado.", kind: .success)
        ]
    }

    private func saveTextInput(key: String, value: String) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)

        switch key {
        case "botName":
            setupData.botName = trimmed
        case "userCallName":
            setupData.userCallName = trimmed
        case "telegramBotToken":
            setupData.telegramBotToken = trimmed
        case "allowedUserID":
            setupData.allowedUserID = trimmed
        default:
            break
        }

        try? SetupStateStore.writeSetupData(setupData)
    }

    private func saveSelectionValue(key: String, selected: [String]) {
        switch key {
        case "assistantTone":
            setupData.assistantTone = selected.first ?? setupData.assistantTone
        case "mainLanguage":
            setupData.mainLanguage = selected.first ?? setupData.mainLanguage
        case "integrations":
            setupData.telegramEnabled = selected.contains("Telegram")
        case "skills":
            setupData.selectedSkills = selected
        default:
            break
        }

        try? SetupStateStore.writeSetupData(setupData)
    }

    private func currentPromptKey() -> String? {
        guard let prompt = currentPrompt else { return nil }

        switch prompt.kind {
        case .textInput(let key, _, _, _): return key
        case .singleSelection(let key, _, _): return key
        case .multiSelection(let key, _, _): return key
        }
    }

    // MARK: - Prompt builders

    private func makeBotNamePrompt() -> SetupPrompt {
        SetupPrompt(
            sectionTitle: "Bot",
            kind: .textInput(
                key: "botName",
                title: "Nombre del bot",
                placeholder: "Ejemplo: Iris"
            )
        )
    }

    private func makeUserCallNamePrompt() -> SetupPrompt {
        SetupPrompt(
            sectionTitle: "Bot",
            kind: .textInput(
                key: "userCallName",
                title: "Cómo te llamará",
                placeholder: "Ejemplo: Jefe"
            )
        )
    }

    private func makeTonePrompt() -> SetupPrompt {
        let options = ["Directo", "Casual", "Técnico", "Profesional"]
        return SetupPrompt(
            sectionTitle: "Bot",
            kind: .singleSelection(
                key: "assistantTone",
                title: "Tono del bot",
                options: options
            ),
            highlightedIndex: 0,
            choices: options.map { SetupChoice(value: $0, isSelected: $0 == setupData.assistantTone) }
        )
    }

    private func makeLanguagePrompt() -> SetupPrompt {
        let options = ["Español", "English"]
        return SetupPrompt(
            sectionTitle: "Bot",
            kind: .singleSelection(
                key: "mainLanguage",
                title: "Idioma principal",
                options: options
            ),
            highlightedIndex: 0,
            choices: options.map { SetupChoice(value: $0, isSelected: $0 == setupData.mainLanguage) }
        )
    }

    private func makeIntegrationsPrompt() -> SetupPrompt {
        let options = ["Telegram"]
        return SetupPrompt(
            sectionTitle: "Integraciones",
            kind: .multiSelection(
                key: "integrations",
                title: "Selecciona las apps para vincular",
                options: options
            ),
            highlightedIndex: 0,
            choices: options.map { SetupChoice(value: $0, isSelected: setupData.telegramEnabled) }
        )
    }

    private func makeTelegramTokenPrompt() -> SetupPrompt {
        SetupPrompt(
            sectionTitle: "Telegram",
            kind: .textInput(
                key: "telegramBotToken",
                title: "Telegram Bot Token",
                placeholder: "Pega aquí el token",
                secure: true
            )
        )
    }

    private func makeAllowedUserIDPrompt() -> SetupPrompt {
        SetupPrompt(
            sectionTitle: "Telegram",
            kind: .textInput(
                key: "allowedUserID",
                title: "Allowed User ID",
                placeholder: "Ejemplo: 123456789"
            )
        )
    }

    private func makeSkillsPrompt() -> SetupPrompt {
        let skills = SkillsConfigWriter.availableSkills()

        return SetupPrompt(
            sectionTitle: "Skills",
            kind: .multiSelection(
                key: "skills",
                title: "Selecciona las skills a activar",
                options: skills
            ),
            highlightedIndex: 0,
            choices: skills.map { skill in
                SetupChoice(
                    value: skill,
                    isSelected: setupData.selectedSkills.contains(skill)
                )
            }
        )
    }
}
