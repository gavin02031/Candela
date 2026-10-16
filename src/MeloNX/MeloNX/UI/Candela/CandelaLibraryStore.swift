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
    private let playtimeKey = "candela.home.playtimeSeconds.v1"
    private let sessionsKey = "candela.home.sessionCounts.v1"

    @Published private(set) var favorites: Set<String>
    @Published private(set) var lastPlayed: [String: Double]
    /// Local, foreground-only tracking. Existing past sessions are not inferred.
    @Published private(set) var playtimeSeconds: [String: Double]
    @Published private(set) var sessionCounts: [String: Int]

    private var runningGameKey: String?
    private var activeSince: Date?

    private var addedDateCache: [URL: Date] = [:]

    private init() {
        let defaults = UserDefaults.standard
        favorites = Set(defaults.stringArray(forKey: favoritesKey) ?? [])
        lastPlayed = (defaults.dictionary(forKey: lastPlayedKey) as? [String: Double]) ?? [:]
        playtimeSeconds = (defaults.dictionary(forKey: playtimeKey) as? [String: Double]) ?? [:]
        sessionCounts = (defaults.dictionary(forKey: sessionsKey) as? [String: Int]) ?? [:]
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

    // MARK: Actual game-session tracking

    /// Call from the emulator's visible root, not when a game is merely selected.
    /// Resuming the same screen after backgrounding never increments the count.
    func startSession(_ game: GameInfo) {
        let key = Self.key(for: game)
        if runningGameKey == key {
            if activeSince == nil { activeSince = Date() }
            return
        }
        endSession()
        runningGameKey = key
        activeSince = Date()
        sessionCounts[key, default: 0] += 1
        UserDefaults.standard.set(sessionCounts, forKey: sessionsKey)
        markPlayed(game)
    }

    /// Background/inactive time must not inflate playtime.
    func pauseSession() {
        guard let key = runningGameKey, let since = activeSince else { return }
        let elapsed = max(0, Date().timeIntervalSince(since))
        if elapsed.isFinite {
            playtimeSeconds[key, default: 0] += elapsed
            UserDefaults.standard.set(playtimeSeconds, forKey: playtimeKey)
        }
        activeSince = nil
    }

    func resumeSession() {
        guard runningGameKey != nil, activeSince == nil else { return }
        activeSince = Date()
    }

    func endSession() {
        pauseSession()
        runningGameKey = nil
    }

    func secondsPlayed(for game: GameInfo) -> Double {
        let key = Self.key(for: game)
        let stored = playtimeSeconds[key] ?? 0
        if runningGameKey == key, let since = activeSince {
            return stored + max(0, Date().timeIntervalSince(since))
        }
        return stored
    }

    func sessions(for game: GameInfo) -> Int {
        sessionCounts[Self.key(for: game)] ?? 0
    }

    var totalPlaytimeSeconds: Double {
        playtimeSeconds.values.reduce(0, +) + (activeSince.map { max(0, Date().timeIntervalSince($0)) } ?? 0)
    }

    var totalSessions: Int {
        sessionCounts.values.reduce(0, +)
    }

    static func playtimeDescription(_ seconds: Double) -> String {
        let minutes = max(0, Int(seconds.isFinite ? seconds / 60 : 0))
        if minutes < 60 { return "\(minutes)m" }
        let hours = minutes / 60
        return minutes % 60 == 0 ? "\(hours)h" : "\(hours)h \(minutes % 60)m"
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
