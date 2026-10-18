// SPDX-License-Identifier: AGPL-3.0-or-later
// Settings > JIT setup for Candela's built-in JIT (beta). StikDebug stays available as the fallback:
// pick "Built-in (Candela)" in the JIT Enabler picker to use this, or any other entry to keep the old flow.
import SwiftUI
import UniformTypeIdentifiers
import Security

/// Pairing file lives in the Keychain (this device only, readable when unlocked), not in Documents.
enum CandelaPairingStore {
    private static var base: [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: "candela.jit.pairing",
         kSecAttrAccount as String: "pairingFile"]
    }
    static func save(_ data: Data) {
        SecItemDelete(base as CFDictionary)
        var add = base
        add[kSecValueData as String] = data
        add[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        SecItemAdd(add as CFDictionary, nil)
    }
    static func load() -> Data? {
        var get = base
        get[kSecReturnData as String] = true
        get[kSecMatchLimit as String] = kSecMatchLimitOne
        var out: CFTypeRef?
        return SecItemCopyMatching(get as CFDictionary, &out) == errSecSuccess ? out as? Data : nil
    }
    static func clear() { SecItemDelete(base as CFDictionary) }
}

struct CandelaJITSettingsView: View {
    @State private var hasPairing = CandelaPairingStore.load() != nil
    @State private var status = "Not checked"
    @State private var busy = false
    @State private var importing = false
    @State private var diagnostics = ""
    @ObservedObject private var pairing = CandelaOnDevicePairing.shared

    var body: some View {
        Form {
            Section {
                Text("Built-in JIT is a beta. To use it, choose \"Built-in (Candela)\" as the JIT Enabler in Settings. StikDebug keeps working if you choose it there instead.")
                    .font(.footnote).foregroundStyle(.secondary)
                if let why = CandelaBuiltInJIT.unavailableReason {
                    Text(why).font(.footnote).foregroundStyle(.orange)
                }
            }
            Section("Pair on this iPhone (iOS 27)") {
                if !CandelaOnDevicePairing.isSupported {
                    Text("Needs iOS 27 or later. On older iOS, import a pairing file below.")
                        .font(.footnote).foregroundStyle(.secondary)
                } else {
                    switch pairing.phase {
                    case .idle:
                        Text("Allow Local Network access, then open Settings > Privacy & Security > Developer Mode, scroll down, tap \"Pair with Candela\" and enter the code shown here.")
                            .font(.footnote).foregroundStyle(.secondary)
                    case .waiting:
                        Label("Waiting for you to tap \"Pair with Candela\" in Settings", systemImage: "hourglass")
                    case .pin(let code):
                        Label("Code: \(code)", systemImage: "number").font(.title3.monospacedDigit())
                    case .paired(let device):
                        Label("Paired with \(device)", systemImage: "checkmark.circle")
                    case .failed(let message):
                        Text(message).font(.footnote).foregroundStyle(.red)
                    }
                    if pairing.backgroundLimited && pairing.active {
                        Text("iOS did not allow Candela to keep running in the background (a re-signed bundle ID can cause this). Open Settings right away and pair within about 30 seconds.")
                            .font(.footnote).foregroundStyle(.orange)
                    }
                    if pairing.active {
                        Button("Cancel pairing", role: .cancel) { pairing.cancel() }
                    } else {
                        Button("Start pairing") { pairing.reset(); pairing.start() }
                    }
                }
            }
            .onReceive(pairing.$phase) { phase in
                if case .paired = phase { hasPairing = CandelaPairingStore.load() != nil; status = "Not checked" }
            }
            Section("Pairing") {
                Label(hasPairing ? "Pairing file saved" : "No pairing file",
                      systemImage: hasPairing ? "checkmark.circle" : "xmark.circle")
                Button("Import pairing file") { importing = true }
                if hasPairing {
                    Button("Export pairing file") { CandelaLogTools.exportPairing() }
                    Button("Remove pairing file", role: .destructive) {
                        CandelaPairingStore.clear(); hasPairing = false; status = "Not checked"
                    }
                }
            }
            Section("Setup") {
                Text("Needs LocalDevVPN connected, Developer Mode on, and an install signed with get-task-allow.")
                    .font(.footnote).foregroundStyle(.secondary)
                Button("Check setup") { run(.prepare) }.disabled(busy || !hasPairing)
                Button("Enable JIT now") { run(.enable) }.disabled(busy || !hasPairing)
                Button("Reset Developer Disk Image", role: .destructive) { run(.resetDDI) }.disabled(busy || !hasPairing)
                Text(status).font(.footnote)
            }
            Section("Helper diagnostics") {
                Text("If the helper will not start, make the report and send it to whoever is helping you. It is also saved as CandelaJITDiagnostics.txt in Candela's Files folder.")
                    .font(.footnote).foregroundStyle(.secondary)
                Button("Make report") { diagnostics = CandelaJITDiagnostics.generate() }
                if !diagnostics.isEmpty {
                    Text(diagnostics).font(.system(.caption2, design: .monospaced)).textSelection(.enabled)
                    Button("Copy report") { UIPasteboard.general.string = diagnostics }
                }
            }
        }
        .navigationTitle("Built-in JIT")
        .fileImporter(isPresented: $importing, allowedContentTypes: [.propertyList, .data]) { result in
            guard case .success(let url) = result else { return }
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            if let data = try? Data(contentsOf: url), !data.isEmpty {
                CandelaPairingStore.save(data); hasPairing = true; status = "Not checked"
            } else {
                status = "That file could not be read."
            }
        }
    }

    /// Adds the fix to the helper's raw reachability errors. A timeout to 10.7.0.1 means the
    /// LocalDevVPN tunnel was down, so say what to do instead of only showing the address.
    private static func friendlyStatus(_ message: String) -> String {
        if message.localizedCaseInsensitiveContains("timed out connecting") || message.contains("10.7.0.1") {
            return message + " LocalDevVPN does not seem to be connected. Open LocalDevVPN, tap Connect, then come back and try again."
        }
        return message
    }

    private func run(_ op: CandelaJITRequest.Operation) {
        guard let pairing = CandelaPairingStore.load() else { return }
        busy = true; status = "Working..."
        let request = CandelaJITRequest(operation: op, pairingData: pairing, targetPID: getpid(),
                                        scriptBase64: op == .enable ? EnableJIT.builtInScript : nil)
        CandelaBuiltInJIT.send(request) { result in
            busy = false
            switch result {
            case .success(let r): status = Self.friendlyStatus(r.message)
            case .failure(let e): status = e.localizedDescription + " [\((e as NSError).domain) \((e as NSError).code)]"
            }
            CandelaJITDiagnostics.lastResult = status
        }
    }
}
