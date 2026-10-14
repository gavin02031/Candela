// SPDX-License-Identifier: AGPL-3.0-or-later
// Log and pairing-file sharing helpers: the newest emulator log shown in the crash alert and shared from it,
// and an export of the saved pairing file for other tools (it is device-sensitive; the user chooses where it goes).
import Foundation
import UIKit

enum CandelaLogTools {
    static let stampFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyyMMdd-HHmmss"
        return f
    }()

    /// Per-game log files are named Candela-Log-<TITLEID>-<timestamp>.log, so each session knows which game it came from.
    static func prefix(for titleId: String) -> String { "Candela-Log-\(titleId.uppercased())-" }

    /// Saved sessions for one game, newest first.
    static func logs(for titleId: String) -> [URL] {
        let pre = prefix(for: titleId)
        let files = (try? FileManager.default.contentsOfDirectory(at: URL.logsFolderURL, includingPropertiesForKeys: [.contentModificationDateKey])) ?? []
        return files.filter { $0.lastPathComponent.hasPrefix(pre) && $0.pathExtension == "log" }.sorted {
            let a = (try? $0.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            let b = (try? $1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            return a > b
        }
    }

    @MainActor
    static func share(_ url: URL) { present(exportTail(of: url) ?? url) }

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
        guard let url = newestLogURL(), let tail = exportTail(of: url) else { return }
        present(tail)
    }

    /// Largest piece of a log that is ever shared. The end of a session is what matters for tuning.
    static let shareLimit = 8 * 1024 * 1024

    /// Copies the last few MB of a log (including the rotated earlier segment) into a small temporary file.
    static func exportTail(of url: URL) -> URL? {
        var parts: [URL] = []
        let earlier = URL(fileURLWithPath: url.path + ".1")
        if FileManager.default.fileExists(atPath: earlier.path) { parts.append(earlier) }
        parts.append(url)
        var chunks: [Data] = []
        var remaining = shareLimit
        for part in parts.reversed() {
            guard remaining > 0, let handle = try? FileHandle(forReadingFrom: part) else { continue }
            defer { try? handle.close() }
            let size = Int((try? handle.seekToEnd()) ?? 0)
            let take = min(size, remaining)
            try? handle.seek(toOffset: UInt64(size - take))
            chunks.insert((try? handle.read(upToCount: take)) ?? Data(), at: 0)
            remaining -= take
        }
        let out = FileManager.default.temporaryDirectory.appendingPathComponent(url.deletingPathExtension().lastPathComponent + "-tail.log")
        try? FileManager.default.removeItem(at: out)
        guard (try? chunks.reduce(into: Data()) { $0.append($1) }.write(to: out, options: .atomic)) != nil else { return nil }
        return out
    }

    /// Deletes every saved log. Returns how many bytes were freed.
    @discardableResult
    static func deleteAllLogs() -> Int64 {
        let files = (try? FileManager.default.contentsOfDirectory(at: URL.logsFolderURL, includingPropertiesForKeys: [.fileSizeKey])) ?? []
        var freed: Int64 = 0
        for f in files {
            freed += Int64((try? f.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
            try? FileManager.default.removeItem(at: f)
        }
        return freed
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
