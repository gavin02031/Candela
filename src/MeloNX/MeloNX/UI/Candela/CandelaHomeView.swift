//
//  CandelaHomeView.swift
//  Candela
//
//  Beta home screen: shelves for Continue Playing, Recently Added and Favorites,
//  plus the full library grid. It launches games exactly like the classic library
//  (by setting LaunchGameHandler.currentGame) and does not touch emulation code.
//

import SwiftUI

struct CandelaHomeView: View {
    @EnvironmentObject var ryujinxController: RyujinxController
    @StateObject private var store = CandelaLibraryStore.shared
    @Environment(\.colorScheme) private var colorScheme
    private var palette: CandelaPalette { CandelaPalette(dark: colorScheme == .dark) }
    @AppStorage("candelaNewHome") private var useNewHome = true
    @State private var gateGame: GameInfo?
    @State private var showMusic = false
    @ObservedObject private var music = CandelaMusic.shared

    private let gridColumns = [GridItem(.adaptive(minimum: 104, maximum: 140), spacing: 14)]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    header

                    if ryujinxController.games.isEmpty {
                        emptyState
                    } else {
                        let continueGames = store.continuePlaying(from: ryujinxController.games)
                        let addedGames = store.recentlyAdded(from: ryujinxController.games)
                        let favoriteGames = store.favoriteGames(from: ryujinxController.games)

                        if !continueGames.isEmpty {
                            shelf(title: "Continue Playing", games: continueGames, large: true)
                        }
                        if !addedGames.isEmpty {
                            shelf(title: "Recently Added", games: addedGames, large: false)
                        }
                        if !favoriteGames.isEmpty {
                            shelf(title: "Favorites", games: favoriteGames, large: false)
                        }
                        library
                    }
                }
                .padding(.vertical, 16)
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
        .sheet(item: $gateGame) { game in
            CandelaGameGateView(game: game) {
                store.markPlayed(game)
                ryujinxController.startGame(game)
            }
        }
    }

    // MARK: - Sections

    private var header: some View {
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
                Button {
                    useNewHome = false
                } label: {
                    Label("Use classic library", systemImage: "arrow.uturn.backward")
                }
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
            Text("Add games and set up keys in the classic library, then they will show up here.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button("Use classic library") {
                useNewHome = false
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
        VStack(alignment: .leading, spacing: 12) {
            Text("Library")
                .font(.system(.title3, design: .rounded).weight(.semibold))
                .foregroundColor(palette.ink)
                .padding(.horizontal)
            LazyVGrid(columns: gridColumns, spacing: 18) {
                ForEach(ryujinxController.games) { game in
                    tile(for: game, size: nil)
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Tile

    /// A fixed size is used on shelves. A nil size lets the tile fill its grid cell.
    private func tile(for game: GameInfo, size: CGFloat?) -> some View {
        Button {
            gateGame = game
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                ZStack(alignment: .topTrailing) {
                    CandelaArtView(game: game)
                        .aspectRatio(1, contentMode: .fit)
                        .shadow(color: palette.rose.opacity(colorScheme == .dark ? 0.0 : 0.25), radius: 8, x: 0, y: 4)
                    if store.isFavorite(game) {
                        Image(systemName: "heart.fill")
                            .font(.caption)
                            .foregroundColor(palette.rose)
                            .padding(6)
                    }
                }
                Text(game.titleName)
                    .font(.system(.footnote, design: .rounded).weight(.semibold))
                    .foregroundColor(palette.ink)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .frame(width: size)
        }
        .buttonStyle(.plain)
        .contextMenu {
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
