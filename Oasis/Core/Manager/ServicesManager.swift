//
//  ServicesManager.swift
//  Oasis
//
//  Created by Edgardo Ramos on 4/1/26.
//

import Foundation
internal import Combine

import SwiftUI

struct ConsoleLine: Identifiable, Equatable {
    enum Kind {
        case input
        case system
        case success
        case warning
        case error
        case info
        case stop
        case service

        var symbol: String? {
            switch self {
            case .input: return nil
            case .system: return AppTheme.eyeSymbol
            case .success: return AppTheme.sucessSymbol
            case .warning: return AppTheme.warningSymbol
            case .error: return AppTheme.errorSymbol
            case .info: return AppTheme.shieldSymbol
            case .stop: return AppTheme.stopSymbol
            case .service: return nil
            }
        }

        var tagColor: Color {
            switch self {
            case .input:
                return Color.white.opacity(0.9)
            case .system:
                return AppTheme.systemTagColor
            case .success:
                return AppTheme.sucessTagColor
            case .warning:
                return AppTheme.warningTagColor
            case .error:
                return AppTheme.errorTagColor
            case .info:
                return AppTheme.shieldTagColor
            case .stop:
                return AppTheme.errorTagColor
            case .service:
                return Color.white.opacity(0.72)
            }
        }

        var textColor: Color {
            switch self {
            case .input:
                return Color.white.opacity(0.9)
            case .system:
                return AppTheme.systemTextColor
            case .success:
                return AppTheme.sucessTextColor
            case .warning:
                return AppTheme.warningTextColor
            case .error:
                return AppTheme.errorTextColor
            case .info:
                return AppTheme.shieldTextColor
            case .stop:
                return AppTheme.errorTextColor
            case .service:
                return Color.white.opacity(0.72)
            }
        }
    }

    let id = UUID()
    let text: String
    let kind: Kind
    let createdAt: Date

    init(text: String, kind: Kind, createdAt: Date = Date()) {
        self.text = text
        self.kind = kind
        self.createdAt = createdAt
    }
}

@MainActor
final class ServicesManager: ObservableObject {
    @Published var consoleLines: [ConsoleLine] = []

    let configStore: OasisConfigStore
    let botManager: BotProcessManager
    let runtimeManager: SkillRuntimeProcessManager

    private var cancellables: Set<AnyCancellable> = []
    private var lastBotLogLength: Int = 0
    private var lastRuntimeLogLength: Int = 0

    @MainActor
    init(
        configStore: OasisConfigStore,
        botManager: BotProcessManager,
        runtimeManager: SkillRuntimeProcessManager
    ) {
        self.configStore = configStore
        self.botManager = botManager
        self.runtimeManager = runtimeManager

        self.botManager.setConfigStore(configStore)

        bindServiceLogs()
    }

    @MainActor
    convenience init() {
        let configStore = OasisConfigStore()
        let botManager = BotProcessManager()
        let runtimeManager = SkillRuntimeProcessManager()
        self.init(
            configStore: configStore,
            botManager: botManager,
            runtimeManager: runtimeManager
        )
    }

    var overallStatusText: String {
        let bot = botManager.isRunning ? "bot:on" : "bot:off"
        let runtime = runtimeManager.isRunning ? "runtime:on" : "runtime:off"
        return "\(bot)  \(runtime)"
    }

    func handleCommand(_ raw: String) {
        let command = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !command.isEmpty else { return }

        appendLine("Oasis % \(command)", kind: .input)

        switch command.lowercased() {
        case "help":
            printHelp()

        case "clear":
            consoleLines.removeAll()
            appendSystemLog("Console cleared.")

        case "status":
            printStatus()

        case "doctor":
            doctor()

        case "start runtime":
            startRuntime()

        case "stop runtime":
            stopRuntime()

        case "restart runtime":
            restartRuntime()

        case "start bot":
            startBot()

        case "stop bot":
            stopBot()

        case "restart bot":
            restartBot()

        case "start all":
            startAll()

        case "stop all":
            stopAll()

        case "restart all":
            restartAll()

        default:
            appendLine(" Unknown command: \(command)", kind: .error)
            appendLine(" Type 'help' to see available commands.", kind: .warning)
        }
    }

    func appendSystemLog(_ text: String) {
        appendLine(text, kind: .system)
    }

    func startRuntime() {
        if runtimeManager.isRunning {
            appendLine(" Skill runtime is already running.", kind: .warning)
            return
        }

        runtimeManager.start()
        appendLine(" Starting skill runtime...", kind: .success)
    }

    func stopRuntime() {
        if !runtimeManager.isRunning {
            appendLine(" Skill runtime is already stopped.", kind: .warning)
            return
        }

        runtimeManager.stop()
        appendLine(" Stopping skill runtime...", kind: .warning)
    }

    func restartRuntime() {
        appendLine(" Restarting skill runtime...", kind: .warning)
        runtimeManager.stop()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            self.runtimeManager.start()
            self.appendLine(" Skill runtime restarted.", kind: .success)
        }
    }

    func startBot() {
        configStore.saveAll()

        guard !configStore.telegramBotToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            appendLine(" Missing TELEGRAM_BOT_TOKEN in OasisConfigStore.", kind: .error)
            return
        }

        guard !configStore.config.telegram.allowedUserID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            appendLine(" Missing allowedUserID in OasisConfigStore.", kind: .error)
            return
        }

        if botManager.isRunning {
            appendLine(" Bot is already running.", kind: .warning)
            return
        }

        if !runtimeManager.isRunning {
            appendLine(" Runtime not running. Starting runtime first...", kind: .warning)
            runtimeManager.start()

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                self.configStore.saveAll()
                self.botManager.start()
                self.appendLine(" Starting bot...", kind: .success)
            }
            return
        }

        botManager.start()
        appendLine(" Starting bot...", kind: .success)
    }

    func stopBot() {
        if !botManager.isRunning {
            appendLine(" Bot is already stopped.", kind: .warning)
            return
        }

        botManager.stop()
        appendLine(" Stopping bot...", kind: .warning)
    }

    func restartBot() {
        appendLine(" Restarting bot...", kind: .warning)
        botManager.stop()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            self.configStore.saveAll()
            self.botManager.start()
            self.appendLine(" Bot restarted.", kind: .success)
        }
    }

    func startAll() {
        appendLine(" Starting all services...", kind: .system)
        configStore.saveAll()

        if !runtimeManager.isRunning {
            runtimeManager.start()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            if !self.botManager.isRunning {
                self.botManager.start()
            }
            self.appendLine(" All services started.", kind: .success)
        }
    }

    func stopAll() {
        appendLine(" Stopping all services...", kind: .system)

        if botManager.isRunning {
            botManager.stop()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            if self.runtimeManager.isRunning {
                self.runtimeManager.stop()
            }
            self.appendLine(" All services stopped.", kind: .warning)
        }
    }

    func restartAll() {
        appendLine(" Restarting all services...", kind: .system)
        stopAll()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            self.startAll()
        }
    }

    private func printHelp() {
        appendLine(" Available commands:", kind: .system)
        appendLine("  help", kind: .service)
        appendLine("  clear", kind: .service)
        appendLine("  status", kind: .service)
        appendLine("  doctor", kind: .service)
        appendLine("  start runtime", kind: .service)
        appendLine("  stop runtime", kind: .service)
        appendLine("  restart runtime", kind: .service)
        appendLine("  start bot", kind: .service)
        appendLine("  stop bot", kind: .service)
        appendLine("  restart bot", kind: .service)
        appendLine("  start all", kind: .service)
        appendLine("  stop all", kind: .service)
        appendLine("  restart all", kind: .service)
    }

    private func printStatus() {
        appendLine(" Current status:", kind: .system)
        appendLine("  Runtime running: \(runtimeManager.isRunning ? "yes" : "no")", kind: .service)
        appendLine("  Runtime status: \(runtimeManager.statusText)", kind: .service)
        appendLine("  Bot running: \(botManager.isRunning ? "yes" : "no")", kind: .service)
        appendLine("  Bot status: \(botManager.statusText)", kind: .service)
    }

    private func doctor() {
        appendLine(" Doctor report:", kind: .system)
        appendLine("  Root path: /Users/edgardoramos/Oasis", kind: .service)
        appendLine("  Node path: /usr/local/bin/node", kind: .service)
        appendLine("  Node exists: \(FileManager.default.isExecutableFile(atPath: "/usr/local/bin/node") ? "yes" : "no")", kind: .service)
        appendLine("  bot.js exists: \(FileManager.default.fileExists(atPath: "/Users/edgardoramos/Oasis/bot.js") ? "yes" : "no")", kind: .service)
        appendLine("  runtime server exists: \(FileManager.default.fileExists(atPath: "/Users/edgardoramos/Oasis/skill-runtime/server.js") ? "yes" : "no")", kind: .service)
        appendLine("  runtime-config exists: \(FileManager.default.fileExists(atPath: "/Users/edgardoramos/Oasis/state/runtime-config.json") ? "yes" : "no")", kind: .service)
        appendLine("  telegram token present: \(configStore.telegramBotToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "no" : "yes")", kind: .service)
        appendLine("  allowed user id present: \(configStore.config.telegram.allowedUserID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "no" : "yes")", kind: .service)
        appendLine("  Runtime running: \(runtimeManager.isRunning ? "yes" : "no")", kind: .service)
        appendLine("  Bot running: \(botManager.isRunning ? "yes" : "no")", kind: .service)
    }

    private func bindServiceLogs() {
        botManager.$logs
            .receive(on: RunLoop.main)
            .sink { [weak self] newValue in
                guard let self else { return }
                self.consumeServiceLogs(
                    serviceName: "bot",
                    fullText: newValue,
                    lastLength: &self.lastBotLogLength
                )
            }
            .store(in: &cancellables)

        runtimeManager.$logs
            .receive(on: RunLoop.main)
            .sink { [weak self] newValue in
                guard let self else { return }
                self.consumeServiceLogs(
                    serviceName: "runtime",
                    fullText: newValue,
                    lastLength: &self.lastRuntimeLogLength
                )
            }
            .store(in: &cancellables)
    }

    private func consumeServiceLogs(
        serviceName: String,
        fullText: String,
        lastLength: inout Int
    ) {
        guard fullText.count >= lastLength else {
            lastLength = fullText.count
            return
        }

        let startIndex = fullText.index(fullText.startIndex, offsetBy: lastLength)
        let newChunk = String(fullText[startIndex...])
        lastLength = fullText.count

        let lines = newChunk
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        for line in lines {
            appendLine("[\(serviceName)] \(line)", kind: .service)
        }
    }

    private func appendLine(_ text: String, kind: ConsoleLine.Kind) {
        consoleLines.append(ConsoleLine(text: text, kind: kind))

        if consoleLines.count > 1500 {
            consoleLines.removeFirst(consoleLines.count - 1500)
        }
    }
}

