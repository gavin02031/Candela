//
//  CandelaHomeView.swift
//  Candela
//
//  Beta home screen: shelves for Continue Playing, Recently Added and Favorites,
//  plus the full library grid. It launches games exactly like the classic library
//  (by setting LaunchGameHandler.currentGame) and does not touch emulation code.
//

import SwiftUI
import Melo_Controller

struct CandelaHomeView: View {
    @EnvironmentObject var ryujinxController: RyujinxController
    @StateObject private var store = CandelaLibraryStore.shared
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.appTheme) private var appTheme
    private var palette: CandelaPalette { CandelaPalette(dark: appTheme.isDark) }
    @State private var activeSheet: ActiveSheet?
    @State private var controllerEditor: GameInfo?
    @AppStorage("candela.theme.style.v1") private var selectedTheme = CandelaThemeStyle.pastelDream.rawValue
    @State private var gateGame: GameInfo?
    @State private var showMusic = false
    @State private var showProfile = false
    @State private var searchText = ""
    @State private var favoritesOnly = false
    @AppStorage("candela.profile.name.v1") private var nickname = "Player"
    @ObservedObject private var music = CandelaMusic.shared

    private let gridColumns = [GridItem(.adaptive(minimum: 148, maximum: 200), spacing: 14)]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    header

                    if ryujinxController.games.isEmpty {
                        emptyState
                    } else {
                        let continueGames = store.continuePlaying(from: ryujinxController.games)
                        let addedGames = store.recentlyAdded(from: ryujinxController.games)
                        let favoriteGames = store.favoriteGames(from: ryujinxController.games)

                        // The Jump back in card already shows the last game, so there is no separate Continue shelf.
                        // Recently Added only appears when the library is big enough for it to be new information.
                        if continueGames.count > 1 {
                            shelf(title: "Recent", games: Array(continueGames.dropFirst()), large: false)
                        }
                        if ryujinxController.games.count > 6, !addedGames.isEmpty {
                            shelf(title: "Recently Added", games: addedGames, large: false)
                        }
                        if !favoriteGames.isEmpty, favoriteGames.count < ryujinxController.games.count {
                            shelf(title: "Favorites", games: favoriteGames, large: false)
                        }
                        library
                    }
                }
                .padding(.vertical, 16)
                .padding(.bottom, 24)
            }
            .themedBackground()
            .safeAreaInset(edge: .bottom) {
                if music.hasItem {
                    CandelaMiniPlayer(music: music) { showMusic = true }
                        .padding(.bottom, 4)
                }
            }
        }
        .sheet(isPresented: $showMusic) { CandelaMusicView() }
        .sheet(isPresented: $showProfile) { CandelaProfileView(games: ryujinxController.games) }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .gameInfo(let game):
                GameInfoSheet(game: game)
            case .perGameSettings(let game):
                PerGameSettingsView(game.titleId)
            case .dlc(let game):
                DLCManagerSheet(game: game)
            case .update(let game):
                UpdateManagerSheet(game: game)
            case .mods(let game):
                ModsManagerSheet(game: game)
            case .account:
                AccountManagerView()
            }
        }
        .fullScreenCover(isPresented: bindingGame($controllerEditor)) {
            Group {
                if let game = controllerEditor {
                    CandelaGameControllerView(game: game, isEditing: true)
                }
            }
                .interactiveDismissDisabled(true)
        }
        .sheet(item: $gateGame) { game in
            CandelaGameGateView(game: game) {
                store.markPlayed(game)
                ryujinxController.startGame(game)
            }
        }
    }

    // MARK: - Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: 15) {
            CandelaStatusPill(
                gameCount: ryujinxController.games.count,
                onMusic: { showMusic = true },
                onAccount: { showProfile = true }
            )
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("YOUR PLAYGROUND")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .tracking(2.2)
                        .foregroundColor(palette.rose)
                    Text("Hey, \(nickname.isEmpty ? "Player" : nickname)! ✨")
                        .font(.system(.title2, design: .rounded).weight(.heavy))
                        .foregroundColor(palette.ink)
                    Text("Your next adventure is waiting.")
                        .font(.subheadline)
                        .foregroundColor(palette.inkSoft)
                }
                Spacer(minLength: 6)
                Button { showProfile = true } label: {
                    CandelaProfileAvatar(size: 57)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Open your Candela profile")
            }
            .padding(.horizontal, 5)
            CandelaJumpCard(
                game: store.continuePlaying(from: ryujinxController.games).first,
                gameCount: ryujinxController.games.count,
                lastPlayed: store.continuePlaying(from: ryujinxController.games).first.flatMap { g in
                    store.lastPlayed[CandelaLibraryStore.key(for: g)].map { Date(timeIntervalSince1970: $0) }
                },
                onPlay: { gateGame = $0 }
            )
            HStack(spacing: 9) {
                quickChip("gamecontroller.fill", "\(ryujinxController.games.count) games")
                quickChip("clock.fill", CandelaLibraryStore.playtimeDescription(store.totalPlaytimeSeconds))
                Button { showProfile = true } label: {
                    quickChip("chart.bar.fill", "My stats")
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
    }

    private func quickChip(_ icon: String, _ label: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(palette.rose)
            Text(label)
                .foregroundColor(palette.ink)
        }
        .font(.system(size: 11, weight: .semibold, design: .rounded))
        .lineLimit(1)
        .minimumScaleFactor(0.8)
        .padding(.horizontal, 11)
        .padding(.vertical, 9)
        .background(palette.card.opacity(0.74), in: Capsule())
        .overlay(Capsule().strokeBorder(palette.cardStroke.opacity(0.85), lineWidth: 1))
    }

    private var legacyHeader: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    CandelaMark(size: 34, dark: colorScheme == .dark)
                    Text("Candela")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(palette.ink)
                }
                CandelaChip(text: ryujinxController.games.count == 1 ? "1 game" : "\(ryujinxController.games.count) games")
            }
            Spacer()
            Button { showMusic = true } label: {
                Image(systemName: "music.note").font(.title2)
            }
            .padding(.trailing, 6)
            Menu {
                CandelaLibraryMenuItems(onAccount: { activeSheet = .account })
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title2)
            }
        }
        .padding(.horizontal)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            CandelaMark(size: 84, dark: colorScheme == .dark)
            Text("No games yet")
                .font(.system(.headline, design: .rounded))
                .foregroundColor(palette.ink)
            Text("Add your own game dumps with the Add game button, then they show up here.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button("Add game") {
                CandelaLibraryActions.addGame(ryujinxController)
            }
            .buttonStyle(CandelaSecondaryButtonStyle())
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .candelaSurface(radius: 28)
        .padding(.horizontal)
    }

    private func shelf(title: String, games: [GameInfo], large: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(.title3, design: .rounded).weight(.semibold))
                .foregroundColor(palette.ink)
                .padding(.horizontal)
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(alignment: .top, spacing: 14) {
                    ForEach(games) { game in
                        tile(for: game, size: large ? 168 : 128)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private var library: some View {
        let visibleGames = ryujinxController.games.filter { game in
            (!favoritesOnly || store.isFavorite(game))
                && (searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    || game.titleName.localizedCaseInsensitiveContains(searchText))
        }

        return VStack(alignment: .leading, spacing: 13) {
            HStack(alignment: .center, spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("My Library")
                        .font(.system(.title2, design: .rounded).weight(.heavy))
                        .foregroundColor(palette.ink)
                    Text("\(ryujinxController.games.count) games, all in one place")
                        .font(.caption)
                        .foregroundColor(palette.inkSoft)
                }
                Spacer()
                Button {
                    CandelaLibraryActions.addGame(ryujinxController)
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(palette.ink)
                        .frame(width: 38, height: 38)
                        .background(palette.roseSoft.opacity(0.72), in: Circle())
                }
                .accessibilityLabel("Add game")
            }

            HStack(spacing: 9) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(palette.inkSoft)
                TextField("Search your games", text: $searchText)
                    .font(.subheadline)
                    .foregroundColor(palette.ink)
                    .autocorrectionDisabled()
                if !searchText.isEmpty {
                    Button { searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(palette.inkSoft)
                    }
                    .accessibilityLabel("Clear search")
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 44)
            .background(palette.card.opacity(0.88), in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(palette.cardStroke, lineWidth: 1))

            HStack(spacing: 9) {
                libraryFilter("All Games", selected: !favoritesOnly) {
                    favoritesOnly = false
                }
                libraryFilter("Favorites", selected: favoritesOnly) {
                    favoritesOnly = true
                }
            }

            if visibleGames.isEmpty {
                Label(favoritesOnly ? "No matching favorites yet" : "No games match your search",
                      systemImage: "gamecontroller")
                    .font(.subheadline)
                    .foregroundColor(palette.inkSoft)
                    .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                LazyVGrid(columns: gridColumns, spacing: 14) {
                    ForEach(visibleGames) { game in
                        tile(for: game, size: nil)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
    }

    private func libraryFilter(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundColor(selected ? palette.ink : palette.inkSoft)
                .padding(.horizontal, 13)
                .padding(.vertical, 8)
                .background(selected ? palette.roseSoft.opacity(0.72) : palette.card.opacity(0.63), in: Capsule())
                .overlay(Capsule().strokeBorder(selected ? palette.rose.opacity(0.46) : palette.cardStroke, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Tile

    /// A fixed size is used on shelves. A nil size lets the tile fill its grid cell.
    private func tile(for game: GameInfo, size: CGFloat?) -> some View {
        Button {
            gateGame = game
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    CandelaArtView(game: game, cornerRadius: 17)
                        .aspectRatio(1, contentMode: .fit)
                        .shadow(color: palette.rose.opacity(colorScheme == .dark ? 0 : 0.14), radius: 7, y: 3)
                    if store.isFavorite(game) {
                        Image(systemName: "heart.fill")
                            .font(.caption2)
                            .foregroundColor(.pink)
                            .padding(8)
                            .background(.regularMaterial, in: Circle())
                            .padding(6)
                    }
                }
                Text(game.titleName)
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundColor(palette.ink)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if store.sessions(for: game) > 0 {
                    Label(CandelaLibraryStore.playtimeDescription(store.secondsPlayed(for: game)),
                          systemImage: "clock")
                        .font(.caption2)
                        .foregroundColor(palette.inkSoft)
                } else {
                    Text("Ready to play")
                        .font(.caption2)
                        .foregroundColor(palette.inkSoft)
                }
            }
            .padding(10)
            .frame(width: size, alignment: .leading)
            .frame(maxWidth: size == nil ? .infinity : nil, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(palette.card.opacity(0.83))
            )
            .overlay(RoundedRectangle(cornerRadius: 22)
                .strokeBorder(palette.cardStroke.opacity(0.75), lineWidth: 1))
        }
        .buttonStyle(CandelaPressStyle())
        .contextMenu {
            CandelaGameMenuItems(game: game, activeSheet: $activeSheet, controllerEditor: $controllerEditor)
            Button {
                store.toggleFavorite(game)
            } label: {
                Label(
                    store.isFavorite(game) ? "Remove from Favorites" : "Add to Favorites",
                    systemImage: store.isFavorite(game) ? "heart.slash" : "heart"
                )
            }
        }
    }
}
