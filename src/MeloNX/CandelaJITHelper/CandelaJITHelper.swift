// SPDX-License-Identifier: GPL-3.0-or-later
// Structure adapted from willfaust/Madeira (GPL-3.0-or-later, Dan Perks). Candela is AGPLv3-or-later.
// The helper uses StikJIT (MPL-2.0), unmodified.
import Foundation
import StikJIT

private enum CandelaJITWork {
    static let queue = DispatchQueue(label: "candela.jit-helper") // StikJIT calls block: one serial queue

    static func handle(_ request: CandelaJITRequest) -> CandelaJITRequest.Response {
        let fm = FileManager.default
        let root = fm.urls(for: .libraryDirectory, in: .userDomainMask)[0].appendingPathComponent("StikJIT", isDirectory: true)
        let paths = DDIPaths.default(in: root)
        do {
            try fm.createDirectory(at: root, withIntermediateDirectories: true)
            if request.operation == .resetDDI {
                try StikJIT.resetCachedDDI(at: paths)
                return .init(success: true, message: "Developer Disk Image cache reset.", txmPresent: StikJIT.isTXMPresent)
            }
            guard let pairing = request.pairingData, !pairing.isEmpty else {
                return .init(success: false, message: "No pairing file was provided.", txmPresent: nil)
            }
            let tmp = root.appendingPathComponent("pairing-\(UUID().uuidString).plist")
            try pairing.write(to: tmp, options: .atomic)
            defer { try? fm.removeItem(at: tmp) }

            switch request.operation {
            case .prepare:
                switch StikJIT.prepareDevice(pairingFile: tmp, paths: paths, progress: { NSLog("[CandelaJIT] prepare %@", String(describing: $0)) }) {
                case .ready(let s): return .init(success: true, message: "Ready.", txmPresent: s.isTXMPresent)
                case .unreachable(let r), .preparationFailed(let r): return .init(success: false, message: r, txmPresent: StikJIT.isTXMPresent)
                @unknown default: return .init(success: false, message: "Unknown StikJIT state.", txmPresent: nil)
                }
            case .enable:
                guard let pid = request.targetPID else {
                    return .init(success: false, message: "Missing target process.", txmPresent: nil)
                }
                try StikJIT.enableJIT(targetPID: pid, pairingFile: tmp, ddiPaths: paths,
                                      script: request.scriptBase64.flatMap { $0.isEmpty ? nil : StikJIT.Script.customBase64($0) } ?? .universal, forceScript: true,
                                      preparationProgress: { NSLog("[CandelaJIT] prepare %@", String(describing: $0)) },
                                      progress: { NSLog("[CandelaJIT] %@", $0) })
                return .init(success: true, message: "JIT enabled.", txmPresent: StikJIT.isTXMPresent)
            case .resetDDI: preconditionFailure()
            }
        } catch {
            return .init(success: false, message: error.localizedDescription, txmPresent: StikJIT.isTXMPresent)
        }
    }
}

@objc(CandelaJITHelperHandler)
final class CandelaJITHelperHandler: NSObject, NSExtensionRequestHandling {
    func beginRequest(with context: NSExtensionContext) {
        let data = ((context.inputItems.first as? NSExtensionItem)?.userInfo?[CandelaJITRequest.itemKey]) as? Data
        CandelaJITWork.queue.async {
            let response: CandelaJITRequest.Response
            if let data, let req = try? JSONDecoder().decode(CandelaJITRequest.self, from: data) {
                response = CandelaJITWork.handle(req)
            } else {
                response = .init(success: false, message: "The JIT helper received no request.", txmPresent: nil)
            }
            let item = NSExtensionItem()
            item.userInfo = [CandelaJITRequest.Response.itemKey: (try? JSONEncoder().encode(response)) ?? Data()]
            context.completeRequest(returningItems: [item], completionHandler: nil)
        }
    }
}
