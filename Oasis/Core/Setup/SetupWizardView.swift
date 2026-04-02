//
//  SetupWizardView.swift
//  Oasis
//
//  Created by Edgardo Ramos on 4/2/26.
//

import SwiftUI

struct SetupWizardView: View {

    @StateObject private var vm = SetupViewModel()
    var onFinish: () -> Void

    var body: some View {
        VStack {
            header

            Divider()

            content

            Divider()

            footer
        }
        .frame(minWidth: 600, minHeight: 400)
        .padding()
    }

    private var header: some View {
        VStack(alignment: .leading) {
            Text("OASIS Setup")
                .font(.title.bold())

            Text("Paso \(vm.phase.rawValue + 1) de \(SetupViewModel.Phase.allCases.count)")
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch vm.phase {

        case .welcome:
            Text("Bienvenido a OASIS. Vamos a configurarlo.")

        case .assistant:
            VStack {
                TextField("Nombre del asistente", text: $vm.config.assistant.name)
                TextField("Idioma (es/en)", text: $vm.config.assistant.language)
            }

        case .user:
            VStack {
                TextField("Tu nombre", text: $vm.config.user.displayName)
                TextField("Cómo quieres que te llame", text: $vm.config.user.addressName)
            }

        case .personality:
            VStack {
                TextField("Tono", text: $vm.config.personality.tone)
                TextField("Estilo", text: $vm.config.personality.style)

                Toggle("Proactivo", isOn: $vm.config.personality.proactive)
            }

        case .model:
            VStack {
                TextField("Modelo principal", text: $vm.config.models.primary)
                TextField("Fallbacks (coma)", text: Binding(
                    get: { vm.config.models.fallbacks.joined(separator: ",") },
                    set: { vm.config.models.fallbacks = $0.split(separator: ",").map { String($0) } }
                ))
            }

        case .telegram:
            VStack {
                Toggle("Activar Telegram", isOn: $vm.config.telegram.enabled)

                if vm.config.telegram.enabled {
                    SecureField("Token", text: $vm.config.telegram.token)
                    TextField("User ID", text: $vm.config.telegram.allowedUserId)
                }
            }

        case .confirm:
            ScrollView {
                Text(String(data: try! JSONEncoder().encode(vm.config), encoding: .utf8)!)
                    .font(.system(.body, design: .monospaced))
            }
        }
    }

    private var footer: some View {
        HStack {
            Button("Atrás") {
                vm.back()
            }
            .disabled(vm.phase == .welcome)

            Spacer()

            if vm.phase == .confirm {
                Button("Finalizar") {
                    vm.completeSetup()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            onFinish()
                        }
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button("Siguiente") {
                    vm.next()
                }
            }
        }
    }
}
