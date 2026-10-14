// SPDX-License-Identifier: AGPL-3.0-or-later
//
//  JITSetupView.swift
//  Candela
//
//  First-launch step: set up JIT. The built-in flow pairs with this device from
//  iOS Settings; StikDebug stays available as the fallback.
//

import SwiftUI
import UniformTypeIdentifiers

struct JITSetupView: View {
    var goForward: () -> Void

    @ObservedObject private var pairing = CandelaOnDevicePairing.shared
    @State private var hasPairing = CandelaPairingStore.load() != nil
    @State private var importing = false
    @State private var importFailed = false
    @Environment(\.colorScheme) private var scheme

    private var device: String { CandelaOnDevicePairing.deviceKind }

    var body: some View {
        let p = CandelaPalette(dark: scheme == .dark)
        CandelaStepPage(
            step: 1, of: 4,
            symbol: "bolt.horizontal.circle",
            title: "Set up JIT",
            message: "Candela needs JIT to run games at full speed. Pair once and Candela can turn it on by itself. You can also skip this and use StikDebug.",
            primaryTitle: hasPairing ? "Continue" : "Continue without pairing",
            primaryAction: goForward,
            secondaryTitle: nil,
            secondaryAction: nil
        ) {
            VStack(spacing: 12) {
                CandelaStatusRow(
                    symbol: "network",
                    title: "LocalDevVPN",
                    detail: "Keep it connected while you pair and play.",
                    chip: "Required"
                )

                if hasPairing {
                    CandelaStatusRow(
                        symbol: "checkmark.seal",
                        title: "Paired",
                        detail: "Candela will use the built-in JIT.",
                        chip: "Ready",
                        chipTint: .candelaGood
                    )
                } else if CandelaOnDevicePairing.isSupported {
                    pairOnDevice(p)
                } else {
                    CandelaStatusRow(
                        symbol: "iphone",
                        title: "Pair on this \(device)",
                        detail: "Needs iOS 27 or later. Import a pairing file instead, or use StikDebug.",
                        chip: "Unavailable",
                        chipTint: p.inkSoft
                    )
                }

                if !hasPairing {
                    Button("Import a pairing file") { importing = true }
                        .buttonStyle(CandelaSecondaryButtonStyle())
                }

                if importFailed {
                    Text("That file could not be read.")
                        .font(.footnote)
                        .foregroundColor(.candelaBad)
                }

                Text("You can change this later in Settings, under JIT.")
                    .font(.footnote)
                    .foregroundColor(p.inkSoft)
            }
        }
        .onReceive(pairing.$phase) { phase in
            if case .paired = phase {
                hasPairing = CandelaPairingStore.load() != nil
                if hasPairing { NativeSettingsManager.shared.jitProvider(JITProvider.disabled).projectedValue.wrappedValue = .builtin }
            }
        }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.propertyList, .data]) { result in
            guard case .success(let url) = result else { return }
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            if let data = try? Data(contentsOf: url), !data.isEmpty {
                CandelaPairingStore.save(data)
                hasPairing = true
                importFailed = false
                NativeSettingsManager.shared.jitProvider(JITProvider.disabled).projectedValue.wrappedValue = .builtin
            } else {
                importFailed = true
            }
        }
    }

    @ViewBuilder
    private func pairOnDevice(_ p: CandelaPalette) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            switch pairing.phase {
            case .idle:
                Text("Allow Local Network access, then open iOS Settings > Privacy & Security > Developer Mode, scroll down and tap \"Pair with Candela\".")
                    .font(.footnote)
                    .foregroundColor(p.inkSoft)
                Button("Start pairing") { pairing.reset(); pairing.start() }
                    .buttonStyle(CandelaPrimaryButtonStyle())
            case .waiting:
                Label("Waiting for you to tap \"Pair with Candela\" in Settings", systemImage: "hourglass")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(p.ink)
                Button("Cancel") { pairing.cancel() }
                    .buttonStyle(CandelaSecondaryButtonStyle())
            case .pin(let code):
                Text("Enter this code on your \(device)")
                    .font(.footnote)
                    .foregroundColor(p.inkSoft)
                Text(code)
                    .font(.system(size: 40, weight: .bold, design: .rounded).monospacedDigit())
                    .tracking(6)
                    .foregroundColor(p.rose)
                    .frame(maxWidth: .infinity)
            case .paired(let name):
                Label("Paired with \(name)", systemImage: "checkmark.circle")
                    .foregroundColor(.candelaGood)
            case .failed(let message):
                Text(message).font(.footnote).foregroundColor(.candelaBad)
                Button("Try again") { pairing.reset(); pairing.start() }
                    .buttonStyle(CandelaSecondaryButtonStyle())
            }
            if pairing.backgroundLimited && pairing.active {
                Text("iOS did not let Candela keep running in the background. Open Settings right away and pair within about 30 seconds.")
                    .font(.footnote)
                    .foregroundColor(.candelaWarn)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .candelaSurface(radius: 18)
    }
}
