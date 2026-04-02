//
//  OasisApp.swift
//  Oasis
//
//  Created by Edgardo Ramos on 4/1/26.
//

import SwiftUI

@main
struct OasisApp: App {
    
    @State private var needsSetup = SetupManager.shared.isFirstRun()
    
    var body: some Scene {
        WindowGroup {
                    if needsSetup {
                        SetupWizardView {
                            needsSetup = false
                        }
                    } else {
                        ConsoleView()
                    }
                }
    }
}
