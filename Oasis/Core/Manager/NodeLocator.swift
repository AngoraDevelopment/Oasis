//
//  NodeLocator.swift
//  Oasis
//
//  Created by Edgardo Ramos on 4/1/26.
//

import Foundation

enum NodeLocator {
    static func findNodeExecutable() -> String? {
        let candidates = directCandidates() + homebrewCellarCandidates()

        for candidate in candidates {
            if FileManager.default.isExecutableFile(atPath: candidate) {
                return candidate
            }
        }

        if let fromShell = shellResolveNode(),
           FileManager.default.isExecutableFile(atPath: fromShell) {
            return fromShell
        }

        return nil
    }

    private static func directCandidates() -> [String] {
        [
            "/opt/homebrew/bin/node",
            "/usr/local/bin/node",
            "/usr/bin/node",
            "/bin/node"
        ]
    }

    private static func homebrewCellarCandidates() -> [String] {
        let roots = [
            "/opt/homebrew/Cellar",
            "/usr/local/Cellar"
        ]

        var results: [String] = []

        for root in roots {
            guard let packages = try? FileManager.default.contentsOfDirectory(
                at: URL(fileURLWithPath: root),
                includingPropertiesForKeys: nil
            ) else { continue }

            let nodePackages = packages.filter {
                let name = $0.lastPathComponent.lowercased()
                return name == "node" || name.hasPrefix("node@")
            }

            for package in nodePackages {
                guard let versions = try? FileManager.default.contentsOfDirectory(
                    at: package,
                    includingPropertiesForKeys: nil
                ) else { continue }

                for version in versions {
                    let candidate = version.appendingPathComponent("bin/node").path
                    results.append(candidate)
                }
            }
        }

        return results
    }

    private static func shellResolveNode() -> String? {
        let commands = [
            "command -v node",
            "source ~/.zprofile >/dev/null 2>&1; command -v node",
            "source ~/.zshrc >/dev/null 2>&1; command -v node",
            "source ~/.bash_profile >/dev/null 2>&1; command -v node"
        ]

        for command in commands {
            if let result = runShell(command), !result.isEmpty {
                return result
            }
        }

        return nil
    }

    private static func runShell(_ command: String) -> String? {
        let task = Process()
        let pipe = Pipe()

        task.executableURL = URL(fileURLWithPath: "/bin/zsh")
        task.arguments = ["-lc", command]
        task.standardOutput = pipe
        task.standardError = Pipe()

        var env = ProcessInfo.processInfo.environment
        env["PATH"] = "/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"
        task.environment = env

        do {
            try task.run()
            task.waitUntilExit()

            guard task.terminationStatus == 0 else { return nil }

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines)

            return output?.isEmpty == false ? output : nil
        } catch {
            return nil
        }
    }
}
