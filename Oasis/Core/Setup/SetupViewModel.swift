//
//  SetupViewModel.swift
//  Oasis
//
//  Created by Edgardo Ramos on 4/2/26.
//

import SwiftUI
internal import Combine

@MainActor
final class SetupViewModel: ObservableObject {

    enum Phase: Int, CaseIterable {
        case welcome
        case assistant
        case user
        case personality
        case model
        case telegram
        case confirm
    }

    @Published var phase: Phase = .welcome

    @Published var config = OasisSetupConfig(
        assistant: .init(name: "Oasis", language: "es"),
        user: .init(displayName: "", addressName: ""),
        personality: .init(tone: "directo", style: "natural", verbosity: "media", proactive: true),
        models: .init(primary: "phi4-mini:latest", fallbacks: []),
        telegram: .init(enabled: true, token: "", allowedUserId: ""),
        system: .init(
            timezone: SetupManager.shared.detectTimezone(),
            firstRunCompleted: false,
            setupCompletedAt: nil
        )
    )

    func next() {
        if let next = Phase(rawValue: phase.rawValue + 1) {
            phase = next
        }
    }

    func back() {
        if let prev = Phase(rawValue: phase.rawValue - 1) {
            phase = prev
        }
    }

    func completeSetup() {
        config.system.firstRunCompleted = true
        config.system.setupCompletedAt = ISO8601DateFormatter().string(from: Date())

        SetupManager.shared.save(config: config)
    }
}
