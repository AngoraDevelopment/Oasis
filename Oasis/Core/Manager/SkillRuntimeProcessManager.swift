//
//  SkillRuntimeProcessManager.swift
//  Oasis
//
//  Created by Edgardo Ramos on 4/1/26.
//

import Foundation
import SwiftUI
internal import Combine

@MainActor
final class SkillRuntimeProcessManager: ObservableObject {
    @Published var isRunning = false
    @Published var logs: String = ""
    @Published var statusText: String = "Detenido"
    @Published var lastError: String?

    private var process: Process?
    private var stdoutPipe: Pipe?
    private var stderrPipe: Pipe?

    private var pendingLogBuffer = ""
    private var logFlushWorkItem: DispatchWorkItem?

    let workingDirectory = "/Users/edgardoramos/Oasis"
    let runtimeScriptPath = "/Users/edgardoramos/Oasis/skill-runtime/server.js"
    let healthURL = URL(string: "http://127.0.0.1:4872/health")!

    private(set) var ownsRunningProcess = false

    deinit {
        if ownsRunningProcess {
            process?.terminate()
        }
    }

    func toggle() {
        isRunning ? stop() : start()
    }

    func start() {
        guard !isRunning else { return }

        Task {
            let alreadyRunning = await checkIfRuntimeAlreadyRunning()

            await MainActor.run {
                if alreadyRunning {
                    self.isRunning = true
                    self.ownsRunningProcess = false
                    self.statusText = "Activo"
                    self.appendLogImmediately(AppTheme.shieldSymbol + " Ya había un skill runtime corriendo en 127.0.0.1:4872.\n")
                    return
                }

                self.startOwnedProcess()
            }
        }
    }

    private func startOwnedProcess() {
        guard FileManager.default.fileExists(atPath: workingDirectory) else {
            appendLogImmediately(AppTheme.errorSymbol + " No existe la carpeta base: \(workingDirectory)\n")
            statusText = "Ruta inválida"
            lastError = "La carpeta base no existe."
            return
        }

        guard FileManager.default.fileExists(atPath: runtimeScriptPath) else {
            appendLogImmediately(AppTheme.errorSymbol + " No existe skill-runtime/server.js en: \(runtimeScriptPath)\n")
            statusText = "Runtime no encontrado"
            lastError = "No se encontró server.js del skill runtime."
            return
        }

        let task = Process()
        let outPipe = Pipe()
        let errPipe = Pipe()

        task.executableURL = URL(fileURLWithPath: "/bin/zsh")
        task.arguments = [
            "-lc",
            "cd \(quoted(workingDirectory)) && /usr/bin/env node \(quoted(runtimeScriptPath))"
        ]
        task.standardOutput = outPipe
        task.standardError = errPipe

        var env = ProcessInfo.processInfo.environment
        env["PATH"] = "/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"
        task.environment = env

        stdoutPipe = outPipe
        stderrPipe = errPipe
        process = task
        logs = ""
        lastError = nil
        pendingLogBuffer = ""
        logFlushWorkItem?.cancel()
        statusText = "Iniciando..."
        ownsRunningProcess = true

        attachReader(to: outPipe, isError: false)
        attachReader(to: errPipe, isError: true)

        task.terminationHandler = { [weak self] proc in
            Task { @MainActor in
                guard let self else { return }

                self.flushPendingLogs()

                self.isRunning = false
                self.ownsRunningProcess = false
                self.stdoutPipe?.fileHandleForReading.readabilityHandler = nil
                self.stderrPipe?.fileHandleForReading.readabilityHandler = nil
                self.process = nil
                self.stdoutPipe = nil
                self.stderrPipe = nil

                if proc.terminationStatus == 0 {
                    self.statusText = "Detenido"
                    self.appendLogImmediately(AppTheme.sucessSymbol + "\n Skill runtime finalizado correctamente.\n")
                } else {
                    self.statusText = "Error"
                    self.appendLogImmediately(AppTheme.warningSymbol + "\n Skill runtime terminó con código \(proc.terminationStatus).\n")
                }
            }
        }

        do {
            try task.run()
            isRunning = true
            statusText = "Activo"

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { [weak self] in
                guard let self, self.isRunning else { return }
                self.appendLogImmediately(AppTheme.runSymbol + " Skill runtime gateway activo en http://127.0.0.1:4872\n")
            }
        } catch {
            isRunning = false
            ownsRunningProcess = false
            statusText = "Error al iniciar"
            lastError = error.localizedDescription
            appendLogImmediately(AppTheme.errorSymbol + "No se pudo iniciar el skill runtime: \(error.localizedDescription)\n")
        }
    }

    func stop() {
        guard let process else {
            isRunning = false
            statusText = "Detenido"
            ownsRunningProcess = false
            return
        }

        if process.isRunning {
            statusText = "Deteniendo..."
            appendLogImmediately(AppTheme.stopSymbol + " Deteniendo skill runtime...\n")
            process.terminate()
        } else {
            isRunning = false
            statusText = "Detenido"
            ownsRunningProcess = false
        }
    }

    func stopIfOwned() {
        guard ownsRunningProcess else { return }
        stop()
    }

    private func checkIfRuntimeAlreadyRunning() async -> Bool {
        var request = URLRequest(url: healthURL)
        request.timeoutInterval = 0.7

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse {
                return http.statusCode == 200
            }
            return false
        } catch {
            return false
        }
    }

    private func attachReader(to pipe: Pipe, isError: Bool) {
        pipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty else { return }

            if let text = String(data: data, encoding: .utf8), !text.isEmpty {
                Task { @MainActor in
                    self?.bufferLog(text, prefixError: isError)
                    self?.updateStatusFromLog(text)
                }
            }
        }
    }

    private func bufferLog(_ text: String, prefixError: Bool = false) {
        let prefix = prefixError ? "[stderr] " : ""
        pendingLogBuffer += prefix + text

        logFlushWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.flushPendingLogs()
        }

        logFlushWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08, execute: workItem)
    }

    private func flushPendingLogs() {
        guard !pendingLogBuffer.isEmpty else { return }

        logs += pendingLogBuffer
        pendingLogBuffer = ""

        if logs.count > 140_000 {
            logs = String(logs.suffix(90_000))
        }
    }

    private func appendLogImmediately(_ text: String, prefixError: Bool = false) {
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
        } else if lower.contains("skill-runtime listening") || lower.contains("gateway activo") {
            statusText = "Activo"
        }
    }

    private func quoted(_ value: String) -> String {
        "'\(value.replacingOccurrences(of: "'", with: "'\\''"))'"
    }
}
