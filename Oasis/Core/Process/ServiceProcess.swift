//
//  ServiceProcess.swift
//  Oasis
//
//  Created by Edgardo Ramos on 4/1/26.
//

import Foundation
internal import Combine

@MainActor
class ServiceProcess: ObservableObject {
    @Published var isRunning = false
    @Published var logs: String = ""
    @Published var status: String = "Stopped"

    private var process: Process?
    private var pipe = Pipe()

    let name: String
    let executable: String
    let arguments: [String]
    let workingDirectory: String

    init(
        name: String,
        executable: String,
        arguments: [String] = [],
        workingDirectory: String
    ) {
        self.name = name
        self.executable = executable
        self.arguments = arguments
        self.workingDirectory = workingDirectory
    }

    func start() {
        guard !isRunning else { return }

        guard FileManager.default.isExecutableFile(atPath: executable) else {
            status = "Error"
            appendLog(AppTheme.errorSymbol + " Executable not found for \(name): \(executable)\n")
            return
        }

        let task = Process()
        let outputPipe = Pipe()

        task.currentDirectoryURL = URL(fileURLWithPath: workingDirectory)
        task.executableURL = URL(fileURLWithPath: executable)
        task.arguments = arguments
        task.standardOutput = outputPipe
        task.standardError = outputPipe

        var env = ProcessInfo.processInfo.environment
        env["PATH"] = "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
        task.environment = env

        self.pipe = outputPipe
        self.process = task
        self.logs = ""
        self.status = "Starting..."

        outputPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty else { return }

            if let text = String(data: data, encoding: .utf8) {
                Task { @MainActor in
                    self?.logs += text
                }
            }
        }

        task.terminationHandler = { [weak self] proc in
            Task { @MainActor in
                guard let self else { return }

                self.isRunning = false
                self.pipe.fileHandleForReading.readabilityHandler = nil

                if proc.terminationStatus == 0 {
                    self.status = "Stopped"
                } else {
                    self.status = "Exited (\(proc.terminationStatus))"
                    self.appendLog(AppTheme.warningSymbol + " \(self.name) exited with code \(proc.terminationStatus)\n")
                }
            }
        }

        do {
            try task.run()
            isRunning = true
            status = "Running"
            appendLog(AppTheme.runSymbol + " \(name) started\n")
            appendLog("→ \(executable) \(arguments.joined(separator: " "))\n")
            appendLog("→ cwd: \(workingDirectory)\n")
        } catch {
            status = "Error"
            appendLog("Failed to start \(name): \(error.localizedDescription)\n")
        }
    }

    func stop() {
        guard let process else { return }

        process.terminate()
        isRunning = false
        status = "Stopped"
        appendLog(AppTheme.errorSymbol + " \(name) stopped\n")
    }

    func appendLog(_ text: String) {
        logs += text
    }
}
