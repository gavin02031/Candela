// SPDX-License-Identifier: AGPL-3.0-or-later
// Local Candela launcher profile. It is not a Nintendo account or cloud identity.
import SwiftUI

/// Reusable launcher avatar. No external account or artwork permissions required.
struct CandelaProfileAvatar: View {
    var size: CGFloat = 44
    @AppStorage("candela.profile.icon.v1") private var icon = "gamecontroller.fill"
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        Image(systemName: icon)
            .font(.system(size: size * 0.43, weight: .semibold, design: .rounded))
            .foregroundColor(CandelaPalette(dark: scheme == .dark).ink)
            .frame(width: size, height: size)
            .background(
                LinearGradient(colors: [
                    Color(candelaHex: 0xEDCEF4),
                    Color(candelaHex: 0xBFE7DD),
                    Color(candelaHex: 0xF8D6E6)
                ], startPoint: .topLeading, endPoint: .bottomTrailing),
                in: Circle()
            )
            .overlay(Circle().strokeBorder(.white.opacity(0.86), lineWidth: 2))
            .shadow(color: Color(candelaHex: 0xC59BC2).opacity(0.24), radius: 10, y: 4)
            .accessibilityLabel("Candela profile")
    }
}

struct CandelaProfileView: View {
    let games: [GameInfo]
    var showsDoneButton: Bool = true
    @StateObject private var store = CandelaLibraryStore.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @AppStorage("candela.profile.name.v1") private var nickname = "Player"
    @AppStorage("candela.profile.icon.v1") private var icon = "gamecontroller.fill"
    @State private var showSwitchUsers = false

    private var palette: CandelaPalette { CandelaPalette(dark: scheme == .dark) }
    private var playedGames: [GameInfo] {
        games.filter { store.sessions(for: $0) > 0 }
            .sorted { store.secondsPlayed(for: $0) > store.secondsPlayed(for: $1) }
    }

    private var shareText: String {
        "My Candela library: \(games.count) games, \(CandelaLibraryStore.playtimeDescription(store.totalPlaytimeSeconds)) played, \(store.totalSessions) sessions. Tracked locally in Candela."
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 23) {
                    profileCard
                    summary
                    gameHistory
                    connections
                }
                .padding(18)
                .padding(.bottom, 28)
            }
            .background(CandelaBackdrop(dark: scheme == .dark).ignoresSafeArea())
            .navigationTitle("My Candela")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if showsDoneButton {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { dismiss() }
                            .fontWeight(.semibold)
                            .tint(palette.ink)
                    }
                }
            }
            .sheet(isPresented: $showSwitchUsers) {
                AccountManagerView()
            }
        }
    }

    private var profileCard: some View {
        VStack(spacing: 15) {
            CandelaProfileAvatar(size: 88)
            VStack(spacing: 5) {
                Text("YOUR CANDLELIT CORNER")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .tracking(2.1)
                    .foregroundColor(palette.inkSoft)
                TextField("Profile nickname", text: $nickname)
                    .font(.system(.title, design: .rounded).weight(.heavy))
                    .multilineTextAlignment(.center)
                    .foregroundColor(palette.ink)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .onChange(of: nickname) { _, value in
                        if value.count > 24 { nickname = String(value.prefix(24)) }
                    }
                Text("Local player profile · stays on this iPhone")
                    .font(.caption)
                    .foregroundColor(palette.inkSoft)
            }
            HStack(spacing: 15) {
                ForEach(["gamecontroller.fill", "person.crop.circle.fill", "sparkles", "flame.fill", "moon.stars.fill"], id: \.self) { symbol in
                    Button { icon = symbol } label: {
                        Image(systemName: symbol)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(palette.ink)
                            .frame(width: 42, height: 42)
                            .background(icon == symbol ? palette.roseSoft : palette.card.opacity(0.65), in: Circle())
                            .overlay(Circle().strokeBorder(icon == symbol ? palette.rose : palette.cardStroke, lineWidth: icon == symbol ? 2 : 1))
                    }
                    .accessibilityLabel("Choose \(symbol) avatar")
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 27, style: .continuous)
                .fill(
                    LinearGradient(colors: [
                        palette.card.opacity(0.98),
                        palette.roseSoft.opacity(0.28),
                        palette.skySoft.opacity(0.28)
                    ], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .overlay(RoundedRectangle(cornerRadius: 27).strokeBorder(palette.cardStroke, lineWidth: 1))
        )
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: 13) {
            sectionLabel("Your journey", caption: "Based on actual Candela sessions")
            HStack(spacing: 9) {
                statCard("Games", value: "\(games.count)", symbol: "square.stack.fill")
                statCard("Playtime", value: CandelaLibraryStore.playtimeDescription(store.totalPlaytimeSeconds), symbol: "clock.fill")
                statCard("Sessions", value: "\(store.totalSessions)", symbol: "play.rectangle.fill")
            }
            Text("Playtime tracking started with this Candela update. Earlier playtime is not estimated; only foreground emulation time is counted.")
                .font(.caption2)
                .foregroundColor(palette.inkSoft)
        }
    }

    private func statCard(_ title: String, value: String, symbol: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(palette.rose)
            Text(value)
                .font(.system(.title3, design: .rounded).weight(.bold))
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(title)
                .font(.caption2.weight(.medium))
                .foregroundColor(palette.inkSoft)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 17)
        .background(palette.card.opacity(0.86), in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(palette.cardStroke, lineWidth: 1))
    }

    private var gameHistory: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Most played", caption: "Your game history")
            if playedGames.isEmpty {
                Label("Your playtime will appear after you play a game.", systemImage: "clock.arrow.circlepath")
                    .font(.subheadline)
                    .foregroundColor(palette.inkSoft)
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .candelaSurface(radius: 18)
            } else {
                ForEach(playedGames.prefix(8)) { game in
                    HStack(spacing: 12) {
                        CandelaArtView(game: game, cornerRadius: 12)
                            .frame(width: 55, height: 55)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(game.titleName)
                                .font(.subheadline.weight(.semibold))
                                .lineLimit(1)
                            Text("\(store.sessions(for: game)) sessions")
                                .font(.caption)
                                .foregroundColor(palette.inkSoft)
                        }
                        Spacer(minLength: 8)
                        Text(CandelaLibraryStore.playtimeDescription(store.secondsPlayed(for: game)))
                            .font(.subheadline.weight(.bold))
                            .foregroundColor(palette.inkSoft)
                    }
                    .padding(11)
                    .candelaSurface(radius: 17)
                }
            }
        }
    }

    private var connections: some View {
        VStack(alignment: .leading, spacing: 13) {
            sectionLabel("Connections", caption: "Share without requiring an account")
            ShareLink(item: shareText) {
                Label("Share my Candela stats", systemImage: "square.and.arrow.up")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .candelaSurface(radius: 18)
            }
            .tint(palette.ink)

            Button { showSwitchUsers = true } label: {
                HStack {
                    Label("Switch game-user profiles", systemImage: "person.2.fill")
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .font(.subheadline.weight(.semibold))
                .padding(16)
                .candelaSurface(radius: 18)
            }
            .buttonStyle(.plain)

            Label("Discord account linking is not connected yet. Sharing uses the iOS share sheet, which may include Discord if installed.", systemImage: "message.badge")
                .font(.caption)
                .foregroundColor(palette.inkSoft)
            Label("Nintendo online services and multiplayer are not enabled by this launcher profile.", systemImage: "network")
                .font(.caption)
                .foregroundColor(palette.inkSoft)
        }
    }

    private func sectionLabel(_ name: String, caption: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name)
                .font(.system(.title2, design: .rounded).weight(.heavy))
                .foregroundColor(palette.ink)
            Text(caption)
                .font(.caption)
                .foregroundColor(palette.inkSoft)
        }
    }
}
