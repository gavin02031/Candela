// SPDX-License-Identifier: AGPL-3.0-or-later
// Helper diagnostics for Candela's built-in JIT: a plain-text report of what this installation
// actually contains, so a failed helper launch can be told apart from a missing or unsigned helper.
import Foundation
import UIKit

enum CandelaJITDiagnostics {
    /// The text of the last built-in JIT result shown on screen, set by the setup view.
    static var lastResult: String = "(no request made yet)"

    @MainActor
    static func report() -> String {
        let fm = FileManager.default
        var lines: [String] = []
        let device = UIDevice.current
        lines.append("Candela JIT diagnostics")
        lines.append("iOS \(device.systemVersion), \(device.model)")
        lines.append("App bundle ID: \(Bundle.main.bundleIdentifier ?? "none")")
        lines.append("get-task-allow: \(checkAppEntitlement("get-task-allow") ? "yes" : "no")")
        lines.append("Increased memory limit: \(checkAppEntitlement("com.apple.developer.kernel.increased-memory-limit") ? "yes" : "no")")
        lines.append("Built-in JIT available: \(CandelaBuiltInJIT.unavailableReason ?? "yes")")
        lines.append("Helper bundle ID (from its Info.plist): \(CandelaBuiltInJIT.helperIdentifier ?? "not found")")
        lines.append("Pairing file saved: \(CandelaPairingStore.load().map { "yes, \($0.count) bytes" } ?? "no")")
        lines.append("Memory helper supported: \(RamDonor.isSupported ? "yes" : "no")")
        lines.append("Memory helper status: \(RamDonor.lastStatus)")
        lines.append("Last JIT result: \(lastResult)")
        lines.append("")

        if let plugIns = Bundle.main.builtInPlugInsURL {
            let items = (try? fm.contentsOfDirectory(atPath: plugIns.path)) ?? []
            lines.append("PlugIns: \(items.isEmpty ? "(none)" : items.sorted().joined(separator: ", "))")
            for name in items.sorted() where name.hasSuffix(".appex") {
                let url = plugIns.appendingPathComponent(name)
                lines.append("- \(name)")
                let bundle = Bundle(url: url)
                lines.append("    bundle ID: \(bundle?.bundleIdentifier ?? "unreadable")")
                let exec = bundle?.executableURL
                lines.append("    executable: \(exec.map { fm.fileExists(atPath: $0.path) ? "present (\($0.lastPathComponent))" : "MISSING (\($0.lastPathComponent))" } ?? "not declared")")
                if let info = bundle?.infoDictionary {
                    let ext = info["NSExtension"] as? [String: Any]
                    lines.append("    extension point: \(ext?["NSExtensionPointIdentifier"] as? String ?? "none")")
                    lines.append("    principal class: \(ext?["NSExtensionPrincipalClass"] as? String ?? "none")")
                    lines.append("    package type: \(info["CFBundlePackageType"] as? String ?? "none")")
                    lines.append("    XPCService keys: \((info["XPCService"] as? [String: Any]).map { $0.keys.sorted().joined(separator: ", ") } ?? "none")")
                    lines.append("    minimum iOS: \(info["MinimumOSVersion"] as? String ?? "none")")
                }
                let signature = url.appendingPathComponent("_CodeSignature/CodeResources")
                lines.append("    code signature: \(fm.fileExists(atPath: signature.path) ? "present" : "MISSING")")
                lines.append("    embedded profile: \(fm.fileExists(atPath: url.appendingPathComponent("embedded.mobileprovision").path) ? "present" : "none")")
                let frameworks = (try? fm.contentsOfDirectory(atPath: url.appendingPathComponent("Frameworks").path)) ?? []
                lines.append("    own Frameworks: \(frameworks.isEmpty ? "(none)" : frameworks.sorted().joined(separator: ", "))")
            }
        } else {
            lines.append("PlugIns: folder missing")
        }
        lines.append("")
        if let frameworksURL = Bundle.main.privateFrameworksURL {
            let items = (try? fm.contentsOfDirectory(atPath: frameworksURL.path)) ?? []
            lines.append("App Frameworks: \(items.isEmpty ? "(none)" : items.sorted().joined(separator: ", "))")
            let stik = frameworksURL.appendingPathComponent("StikJIT.framework")
            lines.append("StikJIT.framework in app: \(fm.fileExists(atPath: stik.path) ? "present" : "MISSING")")
            lines.append("StikJIT signature: \(fm.fileExists(atPath: stik.appendingPathComponent("_CodeSignature/CodeResources").path) ? "present" : "MISSING")")
        } else {
            lines.append("App Frameworks: folder missing")
        }
        return lines.joined(separator: "\n")
    }

    /// Builds the report, writes it to Documents/CandelaJITDiagnostics.txt and returns the text.
    @MainActor
    static func generate() -> String {
        let text = report()
        if let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            try? text.write(to: docs.appendingPathComponent("CandelaJITDiagnostics.txt"), atomically: true, encoding: .utf8)
        }
        return text
    }
}
