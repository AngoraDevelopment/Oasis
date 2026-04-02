//
//  InvisibleTerminalInput.swift
//  Oasis
//
//  Created by Edgardo Ramos on 4/2/26.
//

import SwiftUI
import AppKit

struct InvisibleTerminalInput: NSViewRepresentable {
    @Binding var text: String
    @Binding var isFocused: Bool
    var onSubmit: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, isFocused: $isFocused, onSubmit: onSubmit)
    }

    func makeNSView(context: Context) -> NSTextField {
        let textField = NoFocusRingTextField()
        textField.delegate = context.coordinator
        textField.isBezeled = false
        textField.isBordered = false
        textField.drawsBackground = false
        textField.backgroundColor = .clear
        textField.textColor = .clear
        textField.focusRingType = .none
        textField.font = .monospacedSystemFont(ofSize: 13, weight: .medium)
        textField.isEditable = true
        textField.isSelectable = false
        textField.stringValue = text
        return textField
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        if nsView.stringValue != text {
            nsView.stringValue = text
        }

        if isFocused, nsView.window?.firstResponder !== nsView {
            DispatchQueue.main.async {
                nsView.window?.makeFirstResponder(nsView)
            }
        }
    }

    final class Coordinator: NSObject, NSTextFieldDelegate {
        @Binding var text: String
        @Binding var isFocused: Bool
        let onSubmit: () -> Void

        init(text: Binding<String>, isFocused: Binding<Bool>, onSubmit: @escaping () -> Void) {
            self._text = text
            self._isFocused = isFocused
            self.onSubmit = onSubmit
        }

        func controlTextDidChange(_ obj: Notification) {
            guard let field = obj.object as? NSTextField else { return }
            text = field.stringValue
        }

        func controlTextDidBeginEditing(_ obj: Notification) {
            isFocused = true
        }

        func controlTextDidEndEditing(_ obj: Notification) {
            isFocused = false
        }

        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                onSubmit()
                return true
            }
            return false
        }
    }
}

final class NoFocusRingTextField: NSTextField {
    override var focusRingType: NSFocusRingType {
        get { .none }
        set { }
    }

    override func drawFocusRingMask() {}

    override var focusRingMaskBounds: NSRect {
        .zero
    }
}
