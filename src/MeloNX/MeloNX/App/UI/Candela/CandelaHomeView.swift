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
    @EnvironmentObject var gameHandler: LaunchGameHandler
    @EnvironmentObject var ryujinx: Ryujinx
    @StateObject private var store = CandelaLibraryStore.shared
    @AppStorage("candelaNewHome") private var useNewHome = false

    private let gridColumns = [GridItem(.adaptive(minimum: 104, maximum: 140), spacing: 14)]

    var body: some View {
        iOSNav {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    header

                    if ryujinx.games.isEmpty {
                        emptyState
                    } else {
                        let continueGames = store.continuePlaying(from: ryujinx.games)
                        let addedGames = store.recentlyAdded(from: ryujinx.games)
                        let favoriteGames = store.favoriteGames(from: ryujinx.games)

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
            .background(
                LinearGradient(
                    colors: [Color.indigo.opacity(0.22), Color(.systemBackground)],
                    startPoint: .top,
                    endPoint: .center
                )
                .ignoresSafeArea()
            )
        }
        .onReceive(gameHandler.$currentGame) { game in
            if let game = game {
                store.markPlayed(game)
            }
        }
    }

    // MARK: - Sections

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Candela")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                Text("\(ryujinx.games.count) games")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
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
            Image(systemName: "gamecontroller")
                .font(.system(size: 44))
                .foregroundColor(.secondary)
            Text("No games yet")
                .font(.headline)
            Text("Add games and set up keys in the classic library, then they will show up here.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button("Use classic library") {
                useNewHome = false
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
    }

    private func shelf(title: String, games: [Game], large: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title3.weight(.semibold))
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
                .font(.title3.weight(.semibold))
                .padding(.horizontal)
            LazyVGrid(columns: gridColumns, spacing: 18) {
                ForEach(ryujinx.games) { game in
                    tile(for: game, size: nil)
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Tile

    /// A fixed size is used on shelves. A nil size lets the tile fill its grid cell.
    private func tile(for game: Game, size: CGFloat?) -> some View {
        Button {
            gameHandler.currentGame = game
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                ZStack(alignment: .topTrailing) {
                    CandelaArtView(game: game)
                        .aspectRatio(1, contentMode: .fit)
                        .shadow(color: Color.black.opacity(0.25), radius: 6, x: 0, y: 3)
                    if store.isFavorite(game) {
                        Image(systemName: "heart.fill")
                            .font(.caption)
                            .foregroundColor(.pink)
                            .padding(6)
                    }
                }
                Text(game.titleName)
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(.primary)
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
