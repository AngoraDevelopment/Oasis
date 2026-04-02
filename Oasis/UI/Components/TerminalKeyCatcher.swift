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

    func makeNSView(context: Context) -> KeyCatcherView {
        let view = KeyCatcherView()
        view.coordinator = context.coordinator
        return view
    }

    func updateNSView(_ nsView: KeyCatcherView, context: Context) {
        nsView.coordinator = context.coordinator

        if isFocused {
            DispatchQueue.main.async {
                nsView.window?.makeFirstResponder(nsView)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, isFocused: $isFocused, onSubmit: onSubmit)
    }

    final class Coordinator: NSObject {
        @Binding var text: String
        @Binding var isFocused: Bool
        let onSubmit: () -> Void

        init(text: Binding<String>, isFocused: Binding<Bool>, onSubmit: @escaping () -> Void) {
            self._text = text
            self._isFocused = isFocused
            self.onSubmit = onSubmit
        }

        func handle(event: NSEvent) {
            guard let characters = event.characters else { return }

            switch event.keyCode {
            case 36, 76: // return / enter
                onSubmit()

            case 51: // delete / backspace
                if !text.isEmpty {
                    text.removeLast()
                }

            case 53: // escape
                text = ""

            case 123, 124, 125, 126:
                // left, right, down, up
                break

            default:
                // Append only if all scalars are not control characters
                let controlSet = CharacterSet.controlCharacters
                if characters.unicodeScalars.allSatisfy({ !controlSet.contains($0) }) {
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

