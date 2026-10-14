// SPDX-License-Identifier: AGPL-3.0-or-later
// Saved play-session logs for one game, shown in the game's details so a session can be shared for tuning.
import SwiftUI

struct CandelaGameLogsSection: View {
    let titleId: String
    @State private var logs: [URL] = []

    var body: some View {
        Section {
            if logs.isEmpty {
                Text("No saved sessions yet. Play this game once and its log will appear here.")
                    .foregroundColor(.secondary)
            }
            ForEach(logs, id: \.self) { url in
                Button {
                    CandelaLogTools.share(url)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(Self.title(for: url))
                            Text(Self.size(of: url)).font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        } header: {
            Text("Saved logs")
        } footer: {
            Text("The last 5 sessions of this game are kept. Share one to get the game tuned.")
        }
        .onAppear { logs = CandelaLogTools.logs(for: titleId) }
    }

    private static func title(for url: URL) -> String {
        let stamp = url.deletingPathExtension().lastPathComponent.split(separator: "-").suffix(2).joined(separator: "-")
        if let date = CandelaLogTools.stampFormatter.date(from: stamp) {
            return date.formatted(date: .abbreviated, time: .shortened)
        }
        return url.lastPathComponent
    }

    private static func size(of url: URL) -> String {
        let bytes = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
        return ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
    }
}
