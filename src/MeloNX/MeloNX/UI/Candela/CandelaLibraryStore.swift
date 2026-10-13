//
//  CandelaLibraryStore.swift
//  Candela
//
//  Small local store behind the new Candela home screen: favorites and
//  last-played times. It only reads the game list; it never touches emulation.
//

import SwiftUI
import Combine

final class CandelaLibraryStore: ObservableObject {
    static let shared = CandelaLibraryStore()

    private let favoritesKey = "candela.home.favorites"
    private let lastPlayedKey = "candela.home.lastPlayed"

    @Published private(set) var favorites: Set<String>
    @Published private(set) var lastPlayed: [String: Double]

    private var addedDateCache: [URL: Date] = [:]

    private init() {
        let defaults = UserDefaults.standard
        favorites = Set(defaults.stringArray(forKey: favoritesKey) ?? [])
        lastPlayed = (defaults.dictionary(forKey: lastPlayedKey) as? [String: Double]) ?? [:]
    }

    /// Title ID when the game has one, otherwise the file name (homebrew).
    static func key(for game: GameInfo) -> String {
        game.titleId.isEmpty ? game.fileURL.lastPathComponent : game.titleId
    }

    func isFavorite(_ game: GameInfo) -> Bool {
        favorites.contains(Self.key(for: game))
    }

    func toggleFavorite(_ game: GameInfo) {
        let key = Self.key(for: game)
        if favorites.contains(key) {
            favorites.remove(key)
        } else {
            favorites.insert(key)
        }
        UserDefaults.standard.set(Array(favorites), forKey: favoritesKey)
    }

    func markPlayed(_ game: GameInfo) {
        lastPlayed[Self.key(for: game)] = Date().timeIntervalSince1970
        UserDefaults.standard.set(lastPlayed, forKey: lastPlayedKey)
    }

    func continuePlaying(from games: [GameInfo], limit: Int = 10) -> [GameInfo] {
        let played = games.filter { lastPlayed[Self.key(for: $0)] != nil }
        let sorted = played.sorted {
            (lastPlayed[Self.key(for: $0)] ?? 0) > (lastPlayed[Self.key(for: $1)] ?? 0)
        }
        return Array(sorted.prefix(limit))
    }

    func favoriteGames(from games: [GameInfo]) -> [GameInfo] {
        games.filter { isFavorite($0) }
    }

    /// Newest files first, using the file's creation date. If a date cannot be read
    /// the game sorts last, so the order falls back to the library order.
    func recentlyAdded(from games: [GameInfo], limit: Int = 10) -> [GameInfo] {
        let sorted = games.sorted { addedDate(for: $0) > addedDate(for: $1) }
        return Array(sorted.prefix(limit))
    }

    private func addedDate(for game: GameInfo) -> Date {
        if let cached = addedDateCache[game.fileURL] {
            return cached
        }
        let date = (try? game.fileURL.resourceValues(forKeys: [.creationDateKey]))?.creationDate
            ?? Date.distantPast
        addedDateCache[game.fileURL] = date
        return date
    }
}
