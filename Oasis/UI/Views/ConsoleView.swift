//
//  ConsoleView.swift
//  Oasis
//
//  Created by Edgardo Ramos on 4/1/26.
//

import SwiftUI

struct ConsoleView: View {
    @StateObject private var manager = ServicesManager()
    @State private var commandText: String = ""
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider()
                .overlay(Color.white.opacity(0.08))

            terminalBody

            Divider()
                .overlay(Color.white.opacity(0.08))

            commandBar
        }
        .background(
            Color(nsColor: NSColor(calibratedRed: 0.06, green: 0.06, blue: 0.07, alpha: 1))
        )
        .onAppear {
            manager.appendSystemLog("Oasis console ready.")
            manager.appendSystemLog("Type 'help' to see available commands.")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isInputFocused = true
            }
        }
    }

    private var header: some View {
        HStack {
            Text("Oasis")
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.85))

            Spacer()

            Text(manager.overallStatusText)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.45))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.18))
    }

    private var terminalBody: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    ForEach(manager.consoleLines) { line in
                        Text(line.text)
                            .font(.system(size: 12, weight: .regular, design: .monospaced))
                            .foregroundStyle(color(for: line.kind))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                            .id(line.id)
                    }

                    Color.clear
                        .frame(height: 1)
                        .id("BOTTOM")
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }
            .background(Color.black.opacity(0.24))
            .onChange(of: manager.consoleLines.count) { _, _ in
                scrollToBottom(proxy)
            }
            .onAppear {
                scrollToBottom(proxy)
            }
        }
    }

    private var commandBar: some View {
        HStack(spacing: 10) {
            Text("Oasis %")
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color.green.opacity(0.95))

            TextField("Enter command...", text: $commandText)
                .textFieldStyle(.plain)
                .font(.system(size: 13, weight: .regular, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.92))
                .focused($isInputFocused)
                .onSubmit {
                    submitCommand()
                }

            if !commandText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Button("Run") {
                    submitCommand()
                }
                .buttonStyle(.plain)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color.black)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.9))
                )
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.18))
    }

    private func submitCommand() {
        let trimmed = commandText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        manager.handleCommand(trimmed)
        commandText = ""

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
            isInputFocused = true
        }
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) {
            withAnimation(.easeOut(duration: 0.15)) {
                proxy.scrollTo("BOTTOM", anchor: .bottom)
            }
        }
    }

    private func color(for kind: ConsoleLine.Kind) -> Color {
        switch kind {
        case .input:
            return Color.green.opacity(0.95)
        case .system:
            return Color.white.opacity(0.80)
        case .success:
            return Color.green.opacity(0.90)
        case .warning:
            return Color.yellow.opacity(0.90)
        case .error:
            return Color.red.opacity(0.92)
        case .service:
            return Color.white.opacity(0.68)
        }
    }
}

#Preview {
    ConsoleView()
}
