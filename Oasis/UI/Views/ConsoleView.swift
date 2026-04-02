//
//  ConsoleView.swift
//  Oasis
//
//  Created by Edgardo Ramos on 4/1/26.
//

import SwiftUI
import AppKit
internal import Combine

struct ConsoleView: View {
    @StateObject private var manager = ServicesManager()

    @State private var input: String = ""
    @State private var showCursor = true
    @State private var isInputFocused = true

    private let cursorTimer = Timer.publish(every: 0.55, on: .main, in: .common).autoconnect()
    private let terminalPath = "Oasis % "
    private let botPath = ["bot:on", "bot:off"]

    var body: some View {
        ZStack{
            VStack(spacing: 0) {
                windowChrome
                terminalBody
            }
        }
        .frame(minWidth: 920, minHeight: 640)
        .background(terminalBackground)
        .onReceive(cursorTimer) { _ in
            showCursor.toggle()
        }
    }

    // MARK: - Window Chrome

    private var windowChrome: some View {
        HStack(spacing: 10) {
            Text("edgardoramos@Oasis:~/runtime_console")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppTheme.textPrimary)

            Spacer()

            HStack(spacing: 6) {
                Text("⌥⌘1")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            Color(AppTheme.blueAccentSoft)
        )
    }

    // MARK: - Terminal Body

    private var terminalBody: some View {
        ZStack(alignment: .bottomLeading) {
            VStack(spacing: 0) {
                topMetaBar

                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        LazyVStack(alignment: .leading, spacing: 2) {
                            ForEach(renderedHistory.indices, id: \.self) { index in
                                renderedHistoryRow(renderedHistory[index], isLast: false)
                            }

                            renderedHistoryRow(currentPromptRow, isLast: true)
                                .id("PROMPT_BOTTOM")

                            Color.clear
                                .frame(height: 8)
                        }
                        .padding(.horizontal, 8)
                        .padding(.top, 6)
                        .padding(.bottom, 14)
                    }
                    .onChange(of: manager.consoleLines.count) { _, _ in
                        scrollToBottom(proxy)
                    }
                    .onChange(of: input) { _, _ in
                        scrollToBottom(proxy)
                    }
                    .onAppear {
                        scrollToBottom(proxy)
                    }
                }
            }

            TerminalKeyCatcher(
                text: $input,
                isFocused: $isInputFocused
            ) {
                runCommand()
            }
            .frame(width: 1, height: 1)
            .opacity(0.001)
            .padding(.bottom, 8)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            isInputFocused = true
        }
        .onAppear {
            isInputFocused = true
        }
    }

    private var topMetaBar: some View {
        HStack {
            Text("Last login: \(formattedNow) on oasis-console")
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(AppTheme.textPrimary)
            
            Spacer()
        }
        .padding(.horizontal, 6)
        .padding(.top, 8)
        .padding(.bottom, 2)
    }

    // MARK: - History Rendering

    private var renderedHistory: [TerminalRow] {
        manager.consoleLines.map { line in
            if line.kind == .input {
                let command = line.text.replacingOccurrences(of: "Oasis % ", with: "")
                return .command(command: command, createdAt: line.createdAt)
            } else {
                return .log(styleForLine(line))
            }
        }
    }

    private var currentPromptRow: TerminalRow {
        .livePrompt(input: input, showCursor: showCursor, runtimeReady: manager.runtimeManager.isRunning)
    }

    @ViewBuilder
    private func renderedHistoryRow(_ row: TerminalRow, isLast: Bool) -> some View {
        switch row {
        case .command(let command, let createdAt):
            commandRow(command, createdAt: createdAt)

        case .log(let style):
            logRow(style)

        case .livePrompt(let currentInput, let cursorVisible, let runtimeReady):
            livePromptRow(currentInput, cursorVisible: cursorVisible, runtimeReady: runtimeReady)
        }
    }

    private func commandRow(_ command: String, createdAt: Date) -> some View {
        HStack(alignment: .center, spacing: 0) {
            HStack(spacing: 0) {
                segmentTag(
                    text: terminalPath,
                    image: "flame.fill",
                    fg: AppTheme.textMuted,
                    bg: Color(AppTheme.accent),
                    nextBG: Color(AppTheme.blueAccentSoft)
                )
                
                segmentTag(
                    text: manager.botManager.isRunning ? botPath[0] : botPath[1],
                    image: manager.botManager.isRunning ? "seal.fill" : "checkmark.seal.fill",
                    fg: AppTheme.textMuted,
                    bg: Color(AppTheme.blueAccentSoft),
                    nextBG: .clear
                )
                
                Text("  \(command)")
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color(nsColor: NSColor(calibratedRed: 0.81, green: 0.89, blue: 0.30, alpha: 1)))
                    .padding(.leading, 4)
                
                Spacer()
                
                segmentTag(
                    text: AppTheme.sucessSymbol,
                    fg: Color(AppTheme.greenStatus),
                    bg: Color(AppTheme.blueAccentSoft),
                    nextBG: Color(AppTheme.accent)
                )

                segmentTag(
                    text: formattedCommandTime(createdAt),
                    fg: AppTheme.textMuted,
                    bg: Color(AppTheme.accent),
                    nextBG: .clear
                )
            }
        }
        .padding(.vertical, 1)
    }
    
    
    
    private func livePromptRow(_ currentInput: String, cursorVisible: Bool, runtimeReady: Bool) -> some View {
        HStack(alignment: .center, spacing: 0) {
            HStack(spacing: 0) {
                segmentTag(
                    text: terminalPath,
                    image: "flame.fill",
                    fg: AppTheme.textMuted,
                    bg: Color(AppTheme.accent),
                    nextBG: Color(AppTheme.blueAccentSoft)
                )
                
                segmentTag(
                    text: manager.botManager.isRunning ? botPath[0] : botPath[1],
                    image: manager.botManager.isRunning ? "seal.fill" : "checkmark.seal.fill",
                    fg: AppTheme.textMuted,
                    bg: Color(AppTheme.blueAccentSoft),
                    nextBG: .clear
                )
                
                HStack(spacing: 0) {
                    Text("  \(currentInput)")
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.96))

                    Text(cursorVisible ? "▌" : " ")
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.96))
                }
                .padding(.leading, 4)
                
                Spacer()
                
                segmentTag(
                    text: AppTheme.sucessSymbol,
                    fg: Color(AppTheme.greenStatus),
                    bg: Color(AppTheme.blueAccentSoft),
                    nextBG: Color(AppTheme.accent)
                )

                segmentTag(
                    text: currentTimeOnly,
                    fg: AppTheme.textMuted,
                    bg: Color(AppTheme.accent),
                    nextBG: .clear
                )
            }
        }
        .padding(.vertical, 1)
    }

    private func logRow(_ style: StyledConsoleLine) -> some View {
        HStack(alignment: .top, spacing: 0) {
            leftLogColumn

            if let tag = style.tag {
                Text(tag)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(style.tagColor)
            }

            Text(style.message)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(style.textColor)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 1)
    }

    private var leftLogColumn: some View {
        HStack(spacing: 0) {
            Text(" ")
                .frame(width: 26, height: 16)
        }
        .padding(.trailing, 4)
    }

    private func segmentTag(text: String, fg: Color, bg: Color, nextBG: Color) -> some View {
        HStack(spacing: 0) {
            Text(" \(text) ")
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(fg)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(bg)

            PowerChevron()
                .fill(bg)
                .frame(width: 12, height: 19)
                .background(nextBG == .clear ? terminalBackground : nextBG)
        }
    }
    
    private func segmentTag(text: String, image: String, fg: Color, bg: Color, nextBG: Color) -> some View {
        HStack(spacing: 0) {
            levelView(text: text, image: image, fg: fg, bg: bg, nextBG: nextBG)
            
            PowerChevron()
                .fill(bg)
                .frame(width: 12, height: 19)
                .background(nextBG == .clear ? terminalBackground : nextBG)
        }
    }
    
    // MARK: - Helpers
    
    private func formattedCommandTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
    
    func levelView(
        text: String,
        image: String,
        fg: Color,
        bg: Color,
        nextBG: Color
    ) -> some View {
        HStack(spacing: 4) {
            Image(systemName: image)
                .font(.system(size: 12, weight: .semibold))
                .frame(height: 14)

            Text(text)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .lineLimit(1)
        }
        .foregroundStyle(fg)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(bg)
    }
    
    private func runCommand() {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            isInputFocused = true
            return
        }

        manager.handleCommand(trimmed)
        input = ""
        isInputFocused = true
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
            withAnimation(.easeOut(duration: 0.10)) {
                proxy.scrollTo("PROMPT_BOTTOM", anchor: .bottom)
            }
        }
    }

    private var formattedNow: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE MMM d HH:mm:ss"
        return formatter.string(from: Date())
    }

    private var currentTimeOnly: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: Date())
    }

    private var terminalBackground: Color {
        Color(AppTheme.shellBackground)
    }

    private func styleForLine(_ line: ConsoleLine) -> StyledConsoleLine {
        let parsed = parseConsolePrefixes(from: line.text)

        let effectiveKind = resolveEffectiveKind(
            originalKind: line.kind,
            message: parsed.message,
            sourceTag: parsed.sourceTag
        )

        if let sourceTag = parsed.sourceTag {
            return StyledConsoleLine(
                tag: sourceTag + " ",
                tagColor: colorForSourceTag(sourceTag, kind: effectiveKind),
                message: parsed.message,
                textColor: colorForMessage(kind: effectiveKind, sourceTag: sourceTag)
            )
        }

        return StyledConsoleLine(
            tag: effectiveKind.symbol,
            tagColor: effectiveKind.tagColor,
            message: parsed.message,
            textColor: effectiveKind.textColor
        )
    }
    
    //MARK: estilo
    
    private func parseConsolePrefixes(from rawText: String) -> (sourceTag: String?, message: String) {
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

    private func resolveEffectiveKind(
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

        if originalKind == .warning || lower.contains("warning") || lower.contains("deteniendo") || lower.contains("termino") {
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

    private func colorForSourceTag(_ tag: String, kind: ConsoleLine.Kind) -> Color {
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

    private func colorForMessage(kind: ConsoleLine.Kind, sourceTag: String?) -> Color {
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
}

private enum TerminalRow {
    case command(command: String, createdAt: Date)
    case log(StyledConsoleLine)
    case livePrompt(input: String, showCursor: Bool, runtimeReady: Bool)
}

private struct StyledConsoleLine {
    let tag: String?
    let tagColor: Color
    let message: String
    let textColor: Color
}

#Preview {
    ConsoleView()
}
