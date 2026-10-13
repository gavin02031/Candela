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

    var body: some View {
        Form {
            Section {
                Text("Built-in JIT is a beta. To use it, choose \"Built-in (Candela)\" as the JIT Enabler in Settings. StikDebug keeps working if you choose it there instead.")
                    .font(.footnote).foregroundStyle(.secondary)
                if let why = CandelaBuiltInJIT.unavailableReason {
                    Text(why).font(.footnote).foregroundStyle(.orange)
                }
            }
            Section("Pairing") {
                Label(hasPairing ? "Pairing file saved" : "No pairing file",
                      systemImage: hasPairing ? "checkmark.circle" : "xmark.circle")
                Button("Import pairing file") { importing = true }
                if hasPairing {
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

    private func run(_ op: CandelaJITRequest.Operation) {
        guard let pairing = CandelaPairingStore.load() else { return }
        busy = true; status = "Working..."
        let request = CandelaJITRequest(operation: op, pairingData: pairing, targetPID: getpid(),
                                        scriptBase64: op == .enable ? EnableJIT.builtInScript : nil)
        CandelaBuiltInJIT.send(request) { result in
            busy = false
            switch result {
            case .success(let r): status = r.message
            case .failure(let e): status = e.localizedDescription
            }
        }
    }
}
