// SPDX-License-Identifier: AGPL-3.0-or-later
// Log and pairing-file sharing helpers: the newest emulator log shown in the crash alert and shared from it,
// and an export of the saved pairing file for other tools (it is device-sensitive; the user chooses where it goes).
import Foundation
import UIKit

enum CandelaLogTools {
    static func newestLogURL() -> URL? {
        let dir = URL.logsFolderURL
        let files = (try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.contentModificationDateKey])) ?? []
        return files.filter { $0.pathExtension == "log" }.max {
            let a = (try? $0.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            let b = (try? $1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            return a < b
        }
    }

    /// The last few lines of the newest log, ready to append to the crash alert. Empty when there is no log.
    static func crashDetail() -> String {
        guard let url = newestLogURL(), let handle = try? FileHandle(forReadingFrom: url) else {
            return "\n\nNo log file was written."
        }
        defer { try? handle.close() }
        let size = (try? handle.seekToEnd()) ?? 0
        try? handle.seek(toOffset: size > 4000 ? size - 4000 : 0)
        let text = String(decoding: (try? handle.readToEnd()) ?? Data(), as: UTF8.self)
        let lines = text.split(whereSeparator: \.isNewline).map { String($0).trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        var out = lines.suffix(8).map { $0.count > 140 ? String($0.prefix(140)) + "..." : $0 }.joined(separator: "\n")
        if out.count > 800 { out = String(out.suffix(800)) }
        return out.isEmpty ? "\n\nThe log file is empty." : "\n\nLast log lines:\n" + out
    }

    @MainActor
    static func share() {
        guard let url = newestLogURL() else { return }
        present(url)
    }

    @MainActor
    static func exportPairing() {
        guard let data = CandelaPairingStore.load() else { return }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("pairingFile.plist")
        guard (try? data.write(to: url, options: .atomic)) != nil else { return }
        present(url)
    }

    @MainActor
    private static func present(_ url: URL) {
        let scene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        var top = scene?.windows.first(where: { $0.isKeyWindow })?.rootViewController ?? scene?.windows.first?.rootViewController
        while let next = top?.presentedViewController { top = next }
        let sheet = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        sheet.popoverPresentationController?.sourceView = top?.view
        sheet.popoverPresentationController?.sourceRect = CGRect(x: top?.view.bounds.midX ?? 0, y: top?.view.bounds.midY ?? 0, width: 1, height: 1)
        top?.present(sheet, animated: true)
    }
}
