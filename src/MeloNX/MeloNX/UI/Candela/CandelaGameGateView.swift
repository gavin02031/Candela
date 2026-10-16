// SPDX-License-Identifier: AGPL-3.0-or-later
// Candela game details; uses existing gameplay, controller, mods, DLC and settings entry points.
import SwiftUI

struct CandelaGameGateView: View {
    let game: GameInfo
    var onPlay: () -> Void

    @StateObject private var store = CandelaLibraryStore.shared
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @State private var cacheBytes: Int64 = 0
    @State private var selection = 0
    @State private var showMods = false
    @State private var showDLC = false
    @State private var showSettings = false
    @State private var showControls = false
    private var palette: CandelaPalette { CandelaPalette(dark: colorScheme == .dark) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    hero

                    Button {
                        dismiss()
                        onPlay()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "play.fill")
                            Text("Play \(game.titleName)")
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                        }
                        .font(.system(.headline, design: .rounded).weight(.heavy))
                        .frame(maxWidth: .infinity, minHeight: 52)
                    }
                    .buttonStyle(CandelaPrimaryButtonStyle())

                    HStack(spacing: 10) {
                        stat("Playtime", value: CandelaLibraryStore.playtimeDescription(store.secondsPlayed(for: game)), icon: "clock.fill")
                        stat("Sessions", value: "\(store.sessions(for: game))", icon: "play.rectangle.fill")
                        stat("Cache", value: cacheBytes > 0 ? "Ready" : "New", icon: "square.stack.3d.up.fill")
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Make it yours")
                                .font(.system(.title3, design: .rounded).weight(.heavy))
                                .foregroundColor(palette.ink)
                            Spacer()
                            Button {
                                store.toggleFavorite(game)
                            } label: {
                                Label(store.isFavorite(game) ? "Favorited" : "Favorite",
                                      systemImage: store.isFavorite(game) ? "heart.fill" : "heart")
                                    .font(.caption.weight(.bold))
                            }
                            .buttonStyle(.plain)
                            .tint(palette.rose)
                        }
                        HStack(spacing: 10) {
                            action("Controls", icon: "gamecontroller.fill") { showControls = true }
                            action("Mods", icon: "square.stack.fill") { showMods = true }
                            action("Settings", icon: "gearshape.fill") { showSettings = true }
                        }
                        HStack(spacing: 10) {
                            action("DLC", icon: "shippingbox.fill") { showDLC = true }
                            Text("Mods have limited compatibility and may not work with every game.")
                                .font(.caption2)
                                .foregroundColor(palette.inkSoft)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }

                    Picker("Game details", selection: $selection) {
                        Text("Overview").tag(0)
                        Text("Activity").tag(1)
                    }
                    .pickerStyle(.segmented)

                    if selection == 0 {
                        infoCard
                        cacheCard
                    } else {
                        activityCard
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Play session logs")
                                .font(.headline)
                                .foregroundColor(palette.ink)
                            List {
                                CandelaGameLogsSection(titleId: game.titleId)
                            }
                            .modifier(HiddenScrollBackground())
                            .frame(height: 265)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                        }
                    }
                }
                .padding(18)
                .padding(.bottom, 22)
            }
            .themedBackground()
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Game details")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                        .fontWeight(.semibold)
                        .tint(palette.ink)
                }
            }
            .onAppear { cacheBytes = Self.folderSize(URL.cacheFolderURL(for: game)) }
            .sheet(isPresented: $showMods) { ModsManagerSheet(game: game) }
            .sheet(isPresented: $showDLC) { DLCManagerSheet(game: game) }
            .sheet(isPresented: $showSettings) { PerGameSettingsView(game.titleId) }
            .fullScreenCover(isPresented: $showControls) {
                CandelaGameControllerView(game: game, isEditing: true)
                    .interactiveDismissDisabled(true)
            }
        }
    }

    private var hero: some View {
        VStack(spacing: 13) {
            CandelaArtView(game: game, cornerRadius: 23)
                .frame(width: 191, height: 191)
                .shadow(color: palette.rose.opacity(0.23), radius: 15, y: 8)
            Text(game.titleName)
                .font(.system(.title2, design: .rounded).weight(.heavy))
                .foregroundColor(palette.ink)
                .multilineTextAlignment(.center)
                .lineLimit(3)
            if !game.developer.isEmpty {
                Text(game.developer)
                    .font(.subheadline)
                    .foregroundColor(palette.inkSoft)
            }
            Text("YOUR GAME · YOUR WAY")
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .tracking(1.8)
                .foregroundColor(palette.rose)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(LinearGradient(
                    colors: [palette.card.opacity(0.92),
                             palette.roseSoft.opacity(0.30),
                             palette.skySoft.opacity(0.35)],
                    startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(RoundedRectangle(cornerRadius: 28).strokeBorder(palette.cardStroke))
        )
    }

    private func action(_ title: String, icon: String, perform: @escaping () -> Void) -> some View {
        Button(action: perform) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundColor(palette.rose)
                Text(title)
                    .font(.system(.caption, design: .rounded).weight(.bold))
                    .foregroundColor(palette.ink)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 68)
            .background(palette.card.opacity(0.86), in: RoundedRectangle(cornerRadius: 17))
            .overlay(RoundedRectangle(cornerRadius: 17).strokeBorder(palette.cardStroke))
        }
        .buttonStyle(.plain)
    }

    private func stat(_ name: String, value: String, icon: String) -> some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .foregroundColor(palette.rose)
            Text(value)
                .font(.system(.headline, design: .rounded).weight(.bold))
                .minimumScaleFactor(0.65)
                .lineLimit(1)
                .foregroundColor(palette.ink)
            Text(name)
                .font(.caption2)
                .foregroundColor(palette.inkSoft)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .candelaSurface(radius: 18)
    }

    private var activityCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            row("Tracked playtime", CandelaLibraryStore.playtimeDescription(store.secondsPlayed(for: game)))
            Divider()
            row("Sessions played", "\(store.sessions(for: game))")
            Divider()
            row("Last played", Self.lastPlayedText(store.lastPlayed[CandelaLibraryStore.key(for: game)]))
            Text("Tracking began with Candela's local stats update. Previous playtime was not imported.")
                .font(.caption2)
                .foregroundColor(palette.inkSoft)
        }
        .padding(17)
        .candelaSurface(radius: 19)
    }

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            row("Last played", Self.lastPlayedText(store.lastPlayed[CandelaLibraryStore.key(for: game)]))
            Divider()
            row("Title ID", game.titleId.uppercased())
        }
        .padding(17)
        .candelaSurface(radius: 19)
    }

    private var cacheCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            row("Shader cache", cacheBytes > 0
                ? ByteCountFormatter.string(fromByteCount: cacheBytes, countStyle: .file)
                : "Empty")
            Text(cacheBytes > 0
                 ? "Cached shaders from earlier sessions can reduce loading stutter."
                 : "Shaders are cached while you play. The first session may stutter more.")
                .font(.footnote)
                .foregroundColor(palette.inkSoft)
        }
        .padding(17)
        .candelaSurface(radius: 19)
    }

    private func row(_ title: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 14) {
            Text(title).foregroundColor(palette.inkSoft)
            Spacer(minLength: 7)
            Text(value)
                .foregroundColor(palette.ink)
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .font(.system(.subheadline, design: .rounded))
    }

    private static func lastPlayedText(_ stamp: Double?) -> String {
        guard let stamp else { return "Never" }
        return Date(timeIntervalSince1970: stamp).formatted(date: .abbreviated, time: .shortened)
    }

    private static func folderSize(_ url: URL) -> Int64 {
        guard let walker = FileManager.default.enumerator(
            at: url, includingPropertiesForKeys: [.fileSizeKey]) else { return 0 }
        var total: Int64 = 0
        for case let file as URL in walker {
            total += Int64((try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
        }
        return total
    }
}
