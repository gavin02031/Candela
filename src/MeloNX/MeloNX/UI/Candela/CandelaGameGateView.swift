// SPDX-License-Identifier: AGPL-3.0-or-later
// The page shown when a game is tapped in the library: art, a big Play button, a few facts, cache status
// and the saved play-session logs for that game.
import SwiftUI

struct CandelaGameGateView: View {
    let game: GameInfo
    var onPlay: () -> Void

    @StateObject private var store = CandelaLibraryStore.shared
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @State private var cacheBytes: Int64 = 0
    private var palette: CandelaPalette { CandelaPalette(dark: colorScheme == .dark) }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 18) {
                    CandelaArtView(game: game)
                        .aspectRatio(1, contentMode: .fit)
                        .frame(maxWidth: 240)
                        .shadow(color: palette.rose.opacity(colorScheme == .dark ? 0 : 0.28), radius: 14, x: 0, y: 8)
                        .padding(.top, 8)

                    VStack(spacing: 4) {
                        Text(game.titleName)
                            .font(.system(.title2, design: .rounded).weight(.bold))
                            .foregroundColor(palette.ink)
                            .multilineTextAlignment(.center)
                        if !game.developer.isEmpty {
                            Text(game.developer).font(.footnote).foregroundColor(palette.inkSoft)
                        }
                    }

                    Button {
                        dismiss()
                        onPlay()
                    } label: {
                        Label("Play", systemImage: "play.fill")
                            .font(.system(.title3, design: .rounded).weight(.semibold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(CandelaPrimaryButtonStyle())
                    .padding(.horizontal)

                    HStack(spacing: 10) {
                        Button {
                            store.toggleFavorite(game)
                        } label: {
                            Label(store.isFavorite(game) ? "Favorited" : "Favorite",
                                  systemImage: store.isFavorite(game) ? "heart.fill" : "heart")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(CandelaSecondaryButtonStyle())
                    }
                    .padding(.horizontal)

                    infoCard
                    cacheCard

                    List {
                        CandelaGameLogsSection(titleId: game.titleId)
                    }
                    .modifier(HiddenScrollBackground())
                    .frame(height: 260)
                }
                .padding(.bottom, 24)
            }
            .themedBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
            }
            .onAppear { cacheBytes = Self.folderSize(URL.cacheFolderURL(for: game)) }
        }
    }

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            row("Last played", Self.lastPlayedText(store.lastPlayed[CandelaLibraryStore.key(for: game)]))
            Divider()
            row("Title ID", game.titleId.uppercased())
        }
        .padding()
        .candelaSurface(radius: 18)
        .padding(.horizontal)
    }

    private var cacheCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            row("Shader cache", cacheBytes > 0 ? ByteCountFormatter.string(fromByteCount: cacheBytes, countStyle: .file) : "Empty")
            Text(cacheBytes > 0
                 ? "Saved from earlier play. The first minutes of a game build it, so later sessions run smoother."
                 : "Builds while you play. The first session stutters most; later sessions reuse it.")
                .font(.footnote)
                .foregroundColor(palette.inkSoft)
        }
        .padding()
        .candelaSurface(radius: 18)
        .padding(.horizontal)
    }

    private func row(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title).foregroundColor(palette.inkSoft)
            Spacer()
            Text(value).foregroundColor(palette.ink)
        }
        .font(.system(.subheadline, design: .rounded))
    }

    private static func lastPlayedText(_ stamp: Double?) -> String {
        guard let stamp else { return "Never" }
        return Date(timeIntervalSince1970: stamp).formatted(date: .abbreviated, time: .shortened)
    }

    private static func folderSize(_ url: URL) -> Int64 {
        guard let walker = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey]) else { return 0 }
        var total: Int64 = 0
        for case let file as URL in walker {
            total += Int64((try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
        }
        return total
    }
}
