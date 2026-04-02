//
//  ServicesManager.swift
//  Oasis
//
//  Created by Edgardo Ramos on 4/1/26.
//

import Foundation
internal import Combine

struct ConsoleLine: Identifiable, Equatable {
    enum Kind {
        case input
        case system
        case success
        case warning
        case error
        case service
    }

    let id = UUID()
    let text: String
    let kind: Kind
}

@MainActor
final class ServicesManager: ObservableObject {
    @Published var bot = BotService()
    @Published var runtime = RuntimeService()
    @Published var consoleLines: [ConsoleLine] = []

    private var cancellables: Set<AnyCancellable> = []
    private var lastBotLogLength: Int = 0
    private var lastRuntimeLogLength: Int = 0

    init() {
        bindServiceLogs()
    }

    var overallStatusText: String {
        let botState = bot.isRunning ? "bot:on" : "bot:off"
        let runtimeState = runtime.isRunning ? "runtime:on" : "runtime:off"
        return "\(botState)  \(runtimeState)"
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

        case "start all":
            startAll()

        case "stop all":
            stopAll()

        case "restart all":
            stopAll()
            startAll()

        case "start runtime":
            startRuntime()

        case "stop runtime":
            stopRuntime()

        case "restart runtime":
            stopRuntime()
            startRuntime()

        case "start bot":
            startBot()

        case "stop bot":
            stopBot()

        case "restart bot":
            stopBot()
            startBot()

        case "doctor":
            doctor()

        default:
            appendLine("Unknown command: \(command)", kind: .error)
            appendLine("Type 'help' to see available commands.", kind: .warning)
        }
    }

    func appendSystemLog(_ text: String) {
        appendLine(text, kind: .system)
    }

    func startAll() {
        startRuntime()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.startBot()
        }
    }

    func stopAll() {
        stopBot()
        stopRuntime()
    }

    func startRuntime() {
        if runtime.isRunning {
            appendLine("Skill runtime is already running.", kind: .warning)
            return
        }

        runtime.start()
        appendLine("Starting skill runtime...", kind: .success)
    }

    func stopRuntime() {
        if !runtime.isRunning {
            appendLine("Skill runtime is already stopped.", kind: .warning)
            return
        }

        runtime.stop()
        appendLine("Stopping skill runtime...", kind: .warning)
    }

    func startBot() {
        do {
            try RuntimeConfigWriter.writeBotRuntimeConfig()
            appendLine("runtime-config.json written successfully.", kind: .success)
        } catch {
            appendLine("Failed to write runtime-config.json: \(error.localizedDescription)", kind: .error)
            return
        }

        if !runtime.isRunning {
            appendLine("Runtime not running. Starting runtime first...", kind: .warning)
            runtime.start()

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.bot.start()
                self.appendLine("Starting bot...", kind: .success)
            }
            return
        }

        if bot.isRunning {
            appendLine("Bot is already running.", kind: .warning)
            return
        }

        bot.start()
        appendLine("Starting bot...", kind: .success)
    }

    func stopBot() {
        if !bot.isRunning {
            appendLine("Bot is already stopped.", kind: .warning)
            return
        }

        bot.stop()
        appendLine("Stopping bot...", kind: .warning)
    }

    func doctor() {
        appendLine("Doctor report:", kind: .system)
        appendLine("  Root path: \(OasisConfig.rootPath)", kind: .service)
        appendLine("  Node path: \(OasisConfig.nodePath)", kind: .service)
        appendLine("  Node exists: \(FileManager.default.isExecutableFile(atPath: OasisConfig.nodePath) ? "yes" : "no")", kind: .service)
        appendLine("  bot.js exists: \(FileManager.default.fileExists(atPath: "\(OasisConfig.rootPath)/bot.js") ? "yes" : "no")", kind: .service)
        appendLine("  runtime server exists: \(FileManager.default.fileExists(atPath: "\(OasisConfig.rootPath)/skill-runtime/server.js") ? "yes" : "no")", kind: .service)
        appendLine("  runtime-config exists: \(FileManager.default.fileExists(atPath: "\(OasisConfig.rootPath)/state/runtime-config.json") ? "yes" : "no")", kind: .service)
        appendLine("  Bot running: \(bot.isRunning ? "yes" : "no")", kind: .service)
        appendLine("  Runtime running: \(runtime.isRunning ? "yes" : "no")", kind: .service)
    }

    private func printHelp() {
        appendLine("Available commands:", kind: .system)
        appendLine("  help", kind: .service)
        appendLine("  clear", kind: .service)
        appendLine("  status", kind: .service)
        appendLine("  doctor", kind: .service)
        appendLine("  start all", kind: .service)
        appendLine("  stop all", kind: .service)
        appendLine("  restart all", kind: .service)
        appendLine("  start runtime", kind: .service)
        appendLine("  stop runtime", kind: .service)
        appendLine("  restart runtime", kind: .service)
        appendLine("  start bot", kind: .service)
        appendLine("  stop bot", kind: .service)
        appendLine("  restart bot", kind: .service)
    }

    private func printStatus() {
        appendLine("Current status:", kind: .system)
        appendLine("  Bot: \(bot.isRunning ? "Running" : "Stopped")", kind: .service)
        appendLine("  Runtime: \(runtime.isRunning ? "Running" : "Stopped")", kind: .service)
        appendLine("  Bot status text: \(bot.status)", kind: .service)
        appendLine("  Runtime status text: \(runtime.status)", kind: .service)
    }

    private func bindServiceLogs() {
        bot.$logs
            .receive(on: RunLoop.main)
            .sink { [weak self] newValue in
                self?.consumeServiceLogs(
                    serviceName: "bot",
                    fullText: newValue,
                    lastLength: &self!.lastBotLogLength
                )
            }
            .store(in: &cancellables)

        runtime.$logs
            .receive(on: RunLoop.main)
            .sink { [weak self] newValue in
                self?.consumeServiceLogs(
                    serviceName: "runtime",
                    fullText: newValue,
                    lastLength: &self!.lastRuntimeLogLength
                )
            }
            .store(in: &cancellables)
    }

    private func consumeServiceLogs(serviceName: String, fullText: String, lastLength: inout Int) {
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

        if consoleLines.count > 1200 {
            consoleLines.removeFirst(consoleLines.count - 1200)
        }
    }
}
