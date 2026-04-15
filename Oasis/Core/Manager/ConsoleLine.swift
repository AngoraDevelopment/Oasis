//
//  ConsoleLine.swift
//  Oasis
//
//  Created by Edgardo Ramos on 4/5/26.
//
import SwiftUI

struct ConsoleLine: Identifiable, Equatable {
    enum Kind {
        case input
        case system
        case success
        case warning
        case error
        case info
        case stop
        case service

        var symbol: String? {
            switch self {
            case .input: return nil
            case .system: return AppTheme.eyeSymbol
            case .success: return AppTheme.sucessSymbol
            case .warning: return AppTheme.warningSymbol
            case .error: return AppTheme.errorSymbol
            case .info: return AppTheme.shieldSymbol
            case .stop: return AppTheme.stopSymbol
            case .service: return nil
            }
        }

        var tagColor: Color {
            switch self {
            case .input:
                return Color.white.opacity(0.9)
            case .system:
                return AppTheme.systemTagColor
            case .success:
                return AppTheme.sucessTagColor
            case .warning:
                return AppTheme.warningTagColor
            case .error:
                return AppTheme.errorTagColor
            case .info:
                return AppTheme.shieldTagColor
            case .stop:
                return AppTheme.errorTagColor
            case .service:
                return Color.white.opacity(0.72)
            }
        }

        var textColor: Color {
            switch self {
            case .input:
                return Color.white.opacity(0.9)
            case .system:
                return AppTheme.systemTextColor
            case .success:
                return AppTheme.sucessTextColor
            case .warning:
                return AppTheme.warningTextColor
            case .error:
                return AppTheme.errorTextColor
            case .info:
                return AppTheme.shieldTextColor
            case .stop:
                return AppTheme.errorTextColor
            case .service:
                return Color.white.opacity(0.72)
            }
        }
    }

    let id = UUID()
    let text: String
    let kind: Kind
    let createdAt: Date

    init(text: String, kind: Kind, createdAt: Date = Date()) {
        self.text = text
        self.kind = kind
        self.createdAt = createdAt
    }
}
