//
//  ConsoleModelView.swift
//  Oasis
//
//  Created by Edgardo Ramos on 4/5/26.
//
import SwiftUI
import AppKit
internal import Combine

func parseConsolePrefixes(from rawText: String) -> (sourceTag: String?, message: String) {
    var text = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
    var detectedTag: String?

    let knownTags = ["[runtime]", "[bot]", "[stderr]"]

    for tag in knownTags {
        if text.hasPrefix(tag) {
            detectedTag = tag
            text = text.replacingOccurrences(of: tag, with: "", options: [.anchored])
                .trimmingCharacters(in: .whitespacesAndNewlines)
            break
        }
    }

    return (detectedTag, text)
}

func resolveEffectiveKind(
    originalKind: ConsoleLine.Kind,
    message: String,
    sourceTag: String?
) -> ConsoleLine.Kind {
    let lower = message.lowercased()

    if sourceTag == "[stderr]" {
        return .error
    }

    if originalKind == .error || lower.contains("error") || lower.contains("failed") || lower.contains("exception") {
        return .error
    }

    if originalKind == .warning || lower.contains("warning") || lower.contains("deteniendo") || lower.contains("termino") || lower.contains("aviso") {
        return .warning
    }

    if originalKind == .success || lower.contains("success") || lower.contains("iniciado") || lower.contains("activo") || lower.contains("ready") || lower.contains("finalizado") {
        return .success
    }
    
    if originalKind == .info || lower.contains("info") || lower.contains("informacion") {
        return .info
    }

    return originalKind
}

func colorForSourceTag(_ tag: String, kind: ConsoleLine.Kind) -> Color {
    switch tag {
    case "[runtime]":
        if kind == .error {
            return Color(nsColor: NSColor(calibratedRed: 0.96, green: 0.41, blue: 0.34, alpha: 1))
        }
        if kind == .warning {
            return Color(nsColor: NSColor(calibratedRed: 0.97, green: 0.79, blue: 0.23, alpha: 1))
        }
        return Color(nsColor: NSColor(calibratedRed: 0.48, green: 0.75, blue: 0.96, alpha: 1))

    case "[bot]":
        if kind == .error {
            return Color(nsColor: NSColor(calibratedRed: 0.96, green: 0.41, blue: 0.34, alpha: 1))
        }
        if kind == .warning {
            return Color(nsColor: NSColor(calibratedRed: 0.97, green: 0.79, blue: 0.23, alpha: 1))
        }
        return Color(nsColor: NSColor(calibratedRed: 0.57, green: 0.86, blue: 0.42, alpha: 1))

    case "[stderr]":
        return Color(nsColor: NSColor(calibratedRed: 0.96, green: 0.41, blue: 0.34, alpha: 1))

    default:
        return kind.tagColor
    }
}

func colorForMessage(kind: ConsoleLine.Kind, sourceTag: String?) -> Color {
    if sourceTag == "[stderr]" {
        return Color(nsColor: NSColor(calibratedRed: 0.95, green: 0.71, blue: 0.66, alpha: 1))
    }

    switch sourceTag {
    case "[runtime]":
        switch kind {
        case .error:
            return Color(nsColor: NSColor(calibratedRed: 0.95, green: 0.71, blue: 0.66, alpha: 1))
        case .warning:
            return Color(nsColor: NSColor(calibratedRed: 0.93, green: 0.86, blue: 0.64, alpha: 1))
        default:
            return Color(nsColor: NSColor(calibratedRed: 0.76, green: 0.86, blue: 0.92, alpha: 1))
        }

    case "[bot]":
        switch kind {
        case .error:
            return Color(nsColor: NSColor(calibratedRed: 0.95, green: 0.71, blue: 0.66, alpha: 1))
        case .warning:
            return Color(nsColor: NSColor(calibratedRed: 0.93, green: 0.86, blue: 0.64, alpha: 1))
        default:
            return Color(nsColor: NSColor(calibratedRed: 0.84, green: 0.91, blue: 0.82, alpha: 1))
        }

    default:
        return kind.textColor
    }
}
