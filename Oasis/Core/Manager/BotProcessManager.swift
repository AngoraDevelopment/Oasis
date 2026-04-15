//
//  BotProcessManager.swift
//  Oasis
//
//  Created by Edgardo Ramos on 4/1/26.
//

import Foundation
import SwiftUI
internal import Combine

@MainActor
final class BotProcessManager: ObservableObject {
    @Published var isRunning = false
    @Published var logs: String = ""
    @Published var statusText: String = "Detenido"
    @Published var lastError: String?
    
    private var process: Process?
    private var stdoutPipe: Pipe?
    private var stderrPipe: Pipe?
    private weak var configStore: OasisConfigStore?

    let workingDirectory = "/Users/edgardoramos/Oasis"
    let nodePath = "/usr/local/bin/node"

    func setConfigStore(_ store: OasisConfigStore) {
        self.configStore = store
    }

    func toggle() {
        isRunning ? stop() : start()
    }

    func start() {
        guard !isRunning else { return }

        guard let configStore else {
            appendLog("[error] OasisConfigStore no está conectado.\n")
            statusText = "Config no disponible"
            return
        }

        configStore.saveAll()

        guard !configStore.telegramBotToken.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty else {
            appendLog("[error] Falta Telegram Bot Token.\n")
            statusText = "Token faltante"
            return
        }

        guard !configStore.config.telegram.allowedUserID.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty else {
            appendLog("[error] Falta Allow User ID.\n")
            statusText = "User ID faltante"
            return
        }

        guard FileManager.default.fileExists(atPath: workingDirectory) else {
            appendLog("[error] No existe la carpeta del bot: \(workingDirectory)\n")
            statusText = "Ruta inválida"
            lastError = "La carpeta del bot no existe."
            return
        }

        guard FileManager.default.fileExists(atPath: nodePath) else {
            appendLog("[error] No existe Node en: \(nodePath)\n")
            statusText = "Node no encontrado"
            lastError = "No se encontró Node en la ruta configurada."
            return
        }

        let task = Process()
        let outPipe = Pipe()
        let errPipe = Pipe()

        task.executableURL = URL(fileURLWithPath: "/bin/zsh")
        task.arguments = [
            "-lc",
            "cd \(quoted(workingDirectory)) && \(quoted(nodePath)) bot.js"
        ]
        task.standardOutput = outPipe
        task.standardError = errPipe

        var env = ProcessInfo.processInfo.environment
        env["PATH"] = "/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"

        for (key, value) in configStore.botEnvironment() {
            env[key] = value
        }

        task.environment = env

        stdoutPipe = outPipe
        stderrPipe = errPipe
        process = task
        logs = ""
        lastError = nil
        statusText = "Iniciando..."

        attachReader(to: outPipe, isError: false)
        attachReader(to: errPipe, isError: true)

        task.terminationHandler = { [weak self] proc in
            Task { @MainActor in
                guard let self else { return }

                self.isRunning = false
                self.stdoutPipe?.fileHandleForReading.readabilityHandler = nil
                self.stderrPipe?.fileHandleForReading.readabilityHandler = nil
                self.process = nil
                self.stdoutPipe = nil
                self.stderrPipe = nil

                if proc.terminationStatus == 0 {
                    self.statusText = "Detenido"
                    self.appendLog("\n Proceso finalizado correctamente.\n")
                } else {
                    self.statusText = "Error"
                    self.appendLog("\n El proceso termino con código \(proc.terminationStatus).\n")
                }
            }
        }

        do {
            try task.run()
            isRunning = true
            statusText = "Activo"
            appendLog("Bot iniciado en: \(workingDirectory)\n")
        } catch {
            isRunning = false
            statusText = "Error al iniciar"
            lastError = error.localizedDescription
            appendLog("[error] No se pudo iniciar el bot: \(error.localizedDescription)\n")
        }
    }

    func stop() {
        guard let process else { return }

        if process.isRunning {
            statusText = "Deteniendo..."
            appendLog("Deteniendo bot...\n")
            process.terminate()
        } else {
            isRunning = false
            statusText = "Detenido"
        }
    }

    private func attachReader(to pipe: Pipe, isError: Bool) {
        pipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty else { return }

            if let text = String(data: data, encoding: .utf8), !text.isEmpty {
                Task { @MainActor in
                    self?.appendLog(text, prefixError: isError)
                    self?.updateStatusFromLog(text)
                }
            }
        }
    }

    private func appendLog(_ text: String, prefixError: Bool = false) {
        let prefix = prefixError ? "[stderr] " : ""
        logs += prefix + text

        if logs.count > 140_000 {
            logs = String(logs.suffix(90_000))
        }
    }

    private func updateStatusFromLog(_ text: String) {
        let lower = text.lowercased()

        if lower.contains("error") || lower.contains("failed") || lower.contains("not permitted") {
            statusText = "Error en ejecución"
        } else if lower.contains("config cargada desde la app") || lower.contains("mensaje recibido") {
            statusText = "Activo"
        }
    }

    private func quoted(_ value: String) -> String {
        "'\(value.replacingOccurrences(of: "'", with: "'\\''"))'"
    }
}
