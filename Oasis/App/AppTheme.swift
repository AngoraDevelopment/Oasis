//
//  AppTheme.swift
//  Oasis
//
//  Created by Edgardo Ramos on 4/2/26.
//

import SwiftUI

enum AppTheme {
    static let shellBackground = Color(nsColor: NSColor(calibratedRed: 0.015, green: 0.025, blue: 0.055, alpha: 1))
    static let sidebarBackground = Color(nsColor: NSColor(calibratedRed: 0.018, green: 0.028, blue: 0.060, alpha: 1))
    static let topbarBackground = Color(nsColor: NSColor(calibratedRed: 0.020, green: 0.030, blue: 0.062, alpha: 0.98))

    static let panelBackground = Color(nsColor: NSColor(calibratedRed: 0.060, green: 0.075, blue: 0.120, alpha: 1))
    static let panelBackgroundSoft = Color(nsColor: NSColor(calibratedRed: 0.075, green: 0.088, blue: 0.135, alpha: 1))

    static let border = Color.white.opacity(0.06)
    static let borderStrong = Color.white.opacity(0.10)

    static let textPrimary = Color.white.opacity(0.50)
    static let textSecondary = Color.white.opacity(0.44)
    static let textMuted = Color.black.opacity(0.82)
    
    static let accent = Color(nsColor: NSColor(calibratedRed: 0.20, green: 0.55, blue: 1.00, alpha: 1))
    
    static let blueAccent = Color(nsColor: NSColor(calibratedRed: 0.20, green: 0.55, blue: 1.00, alpha: 1))
    static let blueAccentSoft = Color(nsColor: NSColor(calibratedRed: 0.08, green: 0.14, blue: 0.24, alpha: 1))
    static let blueAccentBorder = Color(nsColor: NSColor(calibratedRed: 0.25, green: 0.45, blue: 0.85, alpha: 0.9))

    static let greenStatus = Color(nsColor: NSColor(calibratedRed: 0.13, green: 0.80, blue: 0.38, alpha: 1))
    
    static let sucessTagColor = Color(nsColor: NSColor(calibratedRed: 0.60, green: 0.84, blue: 0.19, alpha: 1))
    static let sucessTextColor = Color(nsColor: NSColor(calibratedRed: 0.80, green: 0.90, blue: 0.68, alpha: 1))
    
    static let warningTagColor = Color(nsColor: NSColor(calibratedRed: 0.97, green: 0.79, blue: 0.23, alpha: 1))
    static let warningTextColor = Color(nsColor: NSColor(calibratedRed: 0.93, green: 0.86, blue: 0.64, alpha: 1))
    
    static let errorTagColor = Color(nsColor: NSColor(calibratedRed: 0.96, green: 0.41, blue: 0.34, alpha: 1))
    static let errorTextColor = Color(nsColor: NSColor(calibratedRed: 0.95, green: 0.71, blue: 0.66, alpha: 1))
    
    static let systemTagColor = Color.white.opacity(0.48)
    static let systemTextColor = Color.white.opacity(0.66)
    
    static let shieldTagColor = Color.white.opacity(0.48)
    static let shieldTextColor = Color.white.opacity(0.66)
    
    static let servicesTextColor = Color.white.opacity(0.72)
    
    static let errorSymbol = "􀃱"
    static let warningSymbol = "􀇿"
    static let runSymbol = "􀆅"
    static let sucessSymbol = "􀇻"
    static let stopSymbol = "􀇽"
    static let shieldSymbol = "􀙨"
    static let eyeSymbol = "􀋮"
}
