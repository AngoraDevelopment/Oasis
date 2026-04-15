//
//  TerminalKeyCatcher.swift
//  Oasis
//
//  Created by Edgardo Ramos on 4/2/26.
//

import SwiftUI
import AppKit
internal import Combine

struct TerminalKeyCatcher: NSViewRepresentable {
    @Binding var text: String
    @Binding var isFocused: Bool

    var onSubmit: () -> Void
    var onArrowUp: () -> Bool
    var onArrowDown: () -> Bool
    var onSpace: () -> Bool
    var onCopy: () -> Void
    var onClear: () -> Void

    func makeNSView(context: Context) -> KeyCatcherView {
        let view = KeyCatcherView()
        view.coordinator = context.coordinator
        return view
    }

    func updateNSView(_ nsView: KeyCatcherView, context: Context) {
        nsView.coordinator = context.coordinator

        if isFocused {
            DispatchQueue.main.async {
                if nsView.window?.firstResponder !== nsView {
                    nsView.window?.makeFirstResponder(nsView)
                }
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            text: $text,
            isFocused: $isFocused,
            onSubmit: onSubmit,
            onArrowUp: onArrowUp,
            onArrowDown: onArrowDown,
            onSpace: onSpace,
            onCopy: onCopy,
            onClear: onClear
        )
    }

    final class Coordinator: NSObject {
        @Binding var text: String
        @Binding var isFocused: Bool

        let onSubmit: () -> Void
        let onArrowUp: () -> Bool
        let onArrowDown: () -> Bool
        let onSpace: () -> Bool
        let onCopy: () -> Void
        let onClear: () -> Void

        init(
            text: Binding<String>,
            isFocused: Binding<Bool>,
            onSubmit: @escaping () -> Void,
            onArrowUp: @escaping () -> Bool,
            onArrowDown: @escaping () -> Bool,
            onSpace: @escaping () -> Bool,
            onCopy: @escaping () -> Void,
            onClear: @escaping () -> Void
        ) {
            self._text = text
            self._isFocused = isFocused
            self.onSubmit = onSubmit
            self.onArrowUp = onArrowUp
            self.onArrowDown = onArrowDown
            self.onSpace = onSpace
            self.onCopy = onCopy
            self.onClear = onClear
        }

        func handle(event: NSEvent) {
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

            if flags.contains(.command) {
                switch event.keyCode {
                case 9: // Cmd+V
                    if let pasted = NSPasteboard.general.string(forType: .string) {
                        text.append(pasted)
                    }
                    return

                case 8: // Cmd+C
                    onCopy()
                    return

                case 37: // Cmd+L
                    onClear()
                    return

                case 7, 0: // Cmd+X / Cmd+A
                    return

                default:
                    return
                }
            }

            guard let characters = event.charactersIgnoringModifiers else { return }

            switch event.keyCode {
            case 36, 76: // Enter / Return
                onSubmit()

            case 49: // Space
                let handled = onSpace()
                if !handled {
                    text.append(" ")
                }

            case 51: // Backspace
                if !text.isEmpty {
                    text.removeLast()
                }

            case 53: // Escape
                text = ""

            case 126: // Up
                let handled = onArrowUp()
                if !handled {
                    // no-op, lo resuelve ConsoleView externamente
                }

            case 125: // Down
                let handled = onArrowDown()
                if !handled {
                    // no-op, lo resuelve ConsoleView externamente
                }

            case 123, 124: // Left / Right
                break

            default:
                let scalars = characters.unicodeScalars
                if scalars.allSatisfy({ !CharacterSet.controlCharacters.contains($0) }) {
                    text.append(characters)
                }
            }
        }
    }
}

final class KeyCatcherView: NSView {
    weak var coordinator: TerminalKeyCatcher.Coordinator?

    override var acceptsFirstResponder: Bool { true }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.window?.makeFirstResponder(self)
            self.coordinator?.isFocused = true
        }
    }

    override func becomeFirstResponder() -> Bool {
        coordinator?.isFocused = true
        return true
    }

    override func resignFirstResponder() -> Bool {
        coordinator?.isFocused = false
        return true
    }

    override func keyDown(with event: NSEvent) {
        coordinator?.handle(event: event)
    }
}
