// SPDX-License-Identifier: AGPL-3.0-or-later
// Candela's local achievements catalogue. Unlocks must be reported by a verified
// game-specific event adapter. No time-based or launch-based fake achievements.
import SwiftUI
import Combine

struct CandelaAchievement: Identifiable, Hashable {
    let id: String
    let title: String
    let detail: String
    let points: Int
}

enum CandelaAchievementCatalogue {
    static let odyssey: [CandelaAchievement] = [
        .init(id: "odyssey.01", title: "First Steps", detail: "Complete the Cap Kingdom introduction", points: 5),
        .init(id: "odyssey.02", title: "Frog Leap", detail: "Capture a frog", points: 5),
        .init(id: "odyssey.03", title: "Cascade Explorer", detail: "Reach Cascade Kingdom", points: 5),
        .init(id: "odyssey.04", title: "Dino Power", detail: "Capture a T-Rex", points: 5),
        .init(id: "odyssey.05", title: "First Moon", detail: "Collect a Power Moon", points: 5),
        .init(id: "odyssey.06", title: "Moon Collector", detail: "Collect 10 Power Moons", points: 5),
        .init(id: "odyssey.07", title: "Moon Hunter", detail: "Collect 50 Power Moons", points: 5),
        .init(id: "odyssey.08", title: "Moon Veteran", detail: "Collect 100 Power Moons", points: 5),
        .init(id: "odyssey.09", title: "Moon Legend", detail: "Collect 500 Power Moons", points: 5),
        .init(id: "odyssey.10", title: "Moon Master", detail: "Collect 880 unique Power Moons", points: 5),
        .init(id: "odyssey.11", title: "Hat Trick", detail: "Defeat Topper", points: 10),
        .init(id: "odyssey.12", title: "Desert Traveler", detail: "Reach Sand Kingdom", points: 10),
        .init(id: "odyssey.13", title: "Sand Secrets", detail: "Find a hidden moon in Sand Kingdom", points: 10),
        .init(id: "odyssey.14", title: "Lake Visitor", detail: "Reach Lake Kingdom", points: 10),
        .init(id: "odyssey.15", title: "Forest Wanderer", detail: "Reach Wooded Kingdom", points: 10),
        .init(id: "odyssey.16", title: "Metro Arrival", detail: "Reach Metro Kingdom", points: 10),
        .init(id: "odyssey.17", title: "Festival Star", detail: "Complete the New Donk City Festival", points: 10),
        .init(id: "odyssey.18", title: "Seaside Explorer", detail: "Reach Seaside Kingdom", points: 10),
        .init(id: "odyssey.19", title: "Snow Traveler", detail: "Reach Snow Kingdom", points: 10),
        .init(id: "odyssey.20", title: "Luncheon Chef", detail: "Reach Luncheon Kingdom", points: 10),
        .init(id: "odyssey.21", title: "Ruined Explorer", detail: "Reach Ruined Kingdom", points: 15),
        .init(id: "odyssey.22", title: "Bowser's Guest", detail: "Reach Bowser's Kingdom", points: 15),
        .init(id: "odyssey.23", title: "Moon Landing", detail: "Reach Moon Kingdom", points: 15),
        .init(id: "odyssey.24", title: "Wedding Crasher", detail: "Defeat Bowser on the Moon", points: 15),
        .init(id: "odyssey.25", title: "Dark Side", detail: "Reach Dark Side", points: 15),
        .init(id: "odyssey.26", title: "Darker Side", detail: "Reach Darker Side", points: 15),
        .init(id: "odyssey.27", title: "Long Journey", detail: "Complete the Darker Side challenge", points: 15),
        .init(id: "odyssey.28", title: "Cap Collector", detail: "Purchase a new hat", points: 15),
        .init(id: "odyssey.29", title: "Fashion Forward", detail: "Collect 10 outfits", points: 15),
        .init(id: "odyssey.30", title: "Wardrobe Hero", detail: "Collect 20 outfits", points: 15),
        .init(id: "odyssey.31", title: "Sticker Fan", detail: "Buy a souvenir sticker", points: 25),
        .init(id: "odyssey.32", title: "Purple Coin Hunter", detail: "Collect 100 regional coins", points: 25),
        .init(id: "odyssey.33", title: "Regional Collector", detail: "Collect 500 regional coins", points: 25),
        .init(id: "odyssey.34", title: "Checkpoint Champion", detail: "Activate 25 checkpoints", points: 25),
        .init(id: "odyssey.35", title: "World Traveler", detail: "Visit 10 kingdoms", points: 25),
        .init(id: "odyssey.36", title: "Global Explorer", detail: "Visit every kingdom", points: 25),
        .init(id: "odyssey.37", title: "Koopa Racer", detail: "Win a Koopa Freerunning race", points: 25),
        .init(id: "odyssey.38", title: "Race Champion", detail: "Win 10 Koopa Freerunning races", points: 25),
        .init(id: "odyssey.39", title: "Balloon Finder", detail: "Find a balloon in Balloon World", points: 25),
        .init(id: "odyssey.40", title: "Balloon Hider", detail: "Hide a balloon in Balloon World", points: 25),
        .init(id: "odyssey.41", title: "Photo Tourist", detail: "Take a snapshot", points: 50),
        .init(id: "odyssey.42", title: "Capture Artist", detail: "Capture 10 distinct enemy types", points: 50),
        .init(id: "odyssey.43", title: "Capture Expert", detail: "Capture 25 distinct enemy types", points: 50),
        .init(id: "odyssey.44", title: "Goomba Tower", detail: "Stack 10 Goombas", points: 50),
        .init(id: "odyssey.45", title: "Fishing Trip", detail: "Catch a fish with Lakitu", points: 50),
        .init(id: "odyssey.46", title: "Music Lover", detail: "Unlock 10 music tracks", points: 50),
        .init(id: "odyssey.47", title: "Art Detective", detail: "Solve 10 hint art puzzles", points: 50),
        .init(id: "odyssey.48", title: "Moon Rock", detail: "Break open a Moon Rock", points: 50),
        .init(id: "odyssey.49", title: "8-Bit Adventurer", detail: "Complete 10 2D platforming sections", points: 50),
        .init(id: "odyssey.50", title: "Odyssey Complete", detail: "Finish the main story", points: 50)
    ]

    static let tomodachi: [CandelaAchievement] = [
        .init(id: "tomodachi.01", title: "Create Your First Mii", detail: "Create and save your first Mii", points: 5),
        .init(id: "tomodachi.02", title: "Growing Community", detail: "Have 5 islanders", points: 5),
        .init(id: "tomodachi.03", title: "Crowded Island", detail: "Have 20 islanders", points: 5),
        .init(id: "tomodachi.04", title: "Full House", detail: "Have 50 islanders", points: 5),
        .init(id: "tomodachi.05", title: "First Friend", detail: "Help two islanders become friends", points: 5),
        .init(id: "tomodachi.06", title: "Best Friends", detail: "Form a best-friend relationship", points: 5),
        .init(id: "tomodachi.07", title: "Social Butterfly", detail: "Have one islander make 10 friends", points: 5),
        .init(id: "tomodachi.08", title: "First Crush", detail: "Witness a romantic confession", points: 5),
        .init(id: "tomodachi.09", title: "Love Is in the Air", detail: "Form a couple", points: 5),
        .init(id: "tomodachi.10", title: "Heartbreak Hotel", detail: "Witness a rejected confession", points: 5),
        .init(id: "tomodachi.11", title: "Wedding Bells", detail: "Celebrate a wedding", points: 10),
        .init(id: "tomodachi.12", title: "Family Beginnings", detail: "Welcome a baby", points: 10),
        .init(id: "tomodachi.13", title: "Proud Parent", detail: "Help raise a child", points: 10),
        .init(id: "tomodachi.14", title: "New Generation", detail: "Watch a child grow up", points: 10),
        .init(id: "tomodachi.15", title: "Birthday Party", detail: "Celebrate an islander's birthday", points: 10),
        .init(id: "tomodachi.16", title: "Make a Wish", detail: "Grant an islander's wish", points: 10),
        .init(id: "tomodachi.17", title: "Wish Granter", detail: "Grant 25 wishes", points: 10),
        .init(id: "tomodachi.18", title: "Dream Maker", detail: "Grant 100 wishes", points: 10),
        .init(id: "tomodachi.19", title: "Problem Solver", detail: "Solve 10 islander problems", points: 10),
        .init(id: "tomodachi.20", title: "Island Helper", detail: "Solve 100 islander problems", points: 10),
        .init(id: "tomodachi.21", title: "Hungry Friend", detail: "Feed an islander a favorite food", points: 15),
        .init(id: "tomodachi.22", title: "Food Critic", detail: "Discover 10 favorite foods", points: 15),
        .init(id: "tomodachi.23", title: "Food Explorer", detail: "Try 50 different foods", points: 15),
        .init(id: "tomodachi.24", title: "Fashion Debut", detail: "Give an islander a new outfit", points: 15),
        .init(id: "tomodachi.25", title: "Fashion Icon", detail: "Collect 25 outfits", points: 15),
        .init(id: "tomodachi.26", title: "Interior Designer", detail: "Redecorate an islander's room", points: 15),
        .init(id: "tomodachi.27", title: "Home Makeover", detail: "Collect 20 interiors", points: 15),
        .init(id: "tomodachi.28", title: "Island Stylist", detail: "Give 10 islanders a makeover", points: 15),
        .init(id: "tomodachi.29", title: "Photo Moment", detail: "Take an island photo", points: 15),
        .init(id: "tomodachi.30", title: "Memory Album", detail: "Take 25 island photos", points: 15),
        .init(id: "tomodachi.31", title: "Music Debut", detail: "Watch an islander perform a song", points: 25),
        .init(id: "tomodachi.32", title: "Pop Star", detail: "Watch 10 musical performances", points: 25),
        .init(id: "tomodachi.33", title: "Concert Night", detail: "Host a group performance", points: 25),
        .init(id: "tomodachi.34", title: "Gift Giver", detail: "Give 10 gifts", points: 25),
        .init(id: "tomodachi.35", title: "Generous Spirit", detail: "Give 100 gifts", points: 25),
        .init(id: "tomodachi.36", title: "Level Up", detail: "Raise an islander's level", points: 25),
        .init(id: "tomodachi.37", title: "Island Veteran", detail: "Reach level 20 with an islander", points: 25),
        .init(id: "tomodachi.38", title: "Hobby Time", detail: "Help an islander discover a hobby", points: 25),
        .init(id: "tomodachi.39", title: "Game Night", detail: "Win a minigame", points: 25),
        .init(id: "tomodachi.40", title: "Champion Player", detail: "Win 25 minigames", points: 25),
        .init(id: "tomodachi.41", title: "Traveler", detail: "Send an islander on a trip", points: 50),
        .init(id: "tomodachi.42", title: "Souvenir Collector", detail: "Collect 10 souvenirs", points: 50),
        .init(id: "tomodachi.43", title: "Island Explorer", detail: "Visit every accessible island area", points: 50),
        .init(id: "tomodachi.44", title: "Night Owl", detail: "Visit the island at night", points: 50),
        .init(id: "tomodachi.45", title: "Early Bird", detail: "Visit the island in the morning", points: 50),
        .init(id: "tomodachi.46", title: "Community Spirit", detail: "Have 10 islanders attend an event", points: 50),
        .init(id: "tomodachi.47", title: "Happy Island", detail: "Have 10 happy islanders at once", points: 50),
        .init(id: "tomodachi.48", title: "Peacemaker", detail: "Help islanders reconcile after an argument", points: 50),
        .init(id: "tomodachi.49", title: "Island Celebrity", detail: "Reach a major island popularity milestone", points: 50),
        .init(id: "tomodachi.50", title: "Dream Island", detail: "Complete 50 unique island milestones", points: 50)
    ]

    static let totk: [CandelaAchievement] = [
        .init(id: "totk.01", title: "Into the Sky", detail: "Complete the opening sky-island journey", points: 5),
        .init(id: "totk.02", title: "A New Ability", detail: "Obtain Ultrahand", points: 5),
        .init(id: "totk.03", title: "Fuse Master", detail: "Obtain Fuse", points: 5),
        .init(id: "totk.04", title: "Ascend", detail: "Obtain Ascend", points: 5),
        .init(id: "totk.05", title: "Time Rewind", detail: "Obtain Recall", points: 5),
        .init(id: "totk.06", title: "Paraglider", detail: "Obtain the Paraglider", points: 5),
        .init(id: "totk.07", title: "First Shrine", detail: "Complete a shrine", points: 5),
        .init(id: "totk.08", title: "Shrine Seeker", detail: "Complete 10 shrines", points: 5),
        .init(id: "totk.09", title: "Shrine Explorer", detail: "Complete 50 shrines", points: 5),
        .init(id: "totk.10", title: "Shrine Hero", detail: "Complete 100 shrines", points: 5),
        .init(id: "totk.11", title: "Shrine Legend", detail: "Complete all 152 shrines", points: 10),
        .init(id: "totk.12", title: "Lightroot Discovery", detail: "Activate a Lightroot", points: 10),
        .init(id: "totk.13", title: "Depths Explorer", detail: "Activate 25 Lightroots", points: 10),
        .init(id: "totk.14", title: "Depths Illuminated", detail: "Activate all 120 Lightroots", points: 10),
        .init(id: "totk.15", title: "First Tower", detail: "Activate a Skyview Tower", points: 10),
        .init(id: "totk.16", title: "Cartographer", detail: "Activate all Skyview Towers", points: 10),
        .init(id: "totk.17", title: "Korok Friend", detail: "Find a Korok seed", points: 10),
        .init(id: "totk.18", title: "Korok Collector", detail: "Find 100 Korok seeds", points: 10),
        .init(id: "totk.19", title: "Korok Legend", detail: "Find all 1000 Korok seeds", points: 10),
        .init(id: "totk.20", title: "First Companion", detail: "Unlock a sage's power", points: 10),
        .init(id: "totk.21", title: "Wind Sage", detail: "Complete the Wind Temple", points: 15),
        .init(id: "totk.22", title: "Fire Sage", detail: "Complete the Fire Temple", points: 15),
        .init(id: "totk.23", title: "Water Sage", detail: "Complete the Water Temple", points: 15),
        .init(id: "totk.24", title: "Lightning Sage", detail: "Complete the Lightning Temple", points: 15),
        .init(id: "totk.25", title: "Spirit Sage", detail: "Complete the Spirit Temple", points: 15),
        .init(id: "totk.26", title: "Five Sages", detail: "Unlock all five sages", points: 15),
        .init(id: "totk.27", title: "Master Sword", detail: "Recover the Master Sword", points: 15),
        .init(id: "totk.28", title: "Dragon's Tears", detail: "Discover every Dragon's Tear", points: 15),
        .init(id: "totk.29", title: "Hyrule Castle", detail: "Complete the Hyrule Castle story sequence", points: 15),
        .init(id: "totk.30", title: "Demon King", detail: "Defeat Ganondorf", points: 15),
        .init(id: "totk.31", title: "True Ending", detail: "Complete the story with the full memory requirements", points: 25),
        .init(id: "totk.32", title: "First Construction", detail: "Build a working Ultrahand vehicle", points: 25),
        .init(id: "totk.33", title: "Engineer", detail: "Build 10 unique vehicles", points: 25),
        .init(id: "totk.34", title: "Flying Machine", detail: "Build a flying vehicle", points: 25),
        .init(id: "totk.35", title: "Autobuild", detail: "Unlock Autobuild", points: 25),
        .init(id: "totk.36", title: "Battery Upgrade", detail: "Upgrade your Energy Cell", points: 25),
        .init(id: "totk.37", title: "Battery Master", detail: "Fully upgrade your Energy Cell", points: 25),
        .init(id: "totk.38", title: "Armor Collector", detail: "Acquire 20 armor pieces", points: 25),
        .init(id: "totk.39", title: "Fashion of Hyrule", detail: "Acquire 50 armor pieces", points: 25),
        .init(id: "totk.40", title: "Armor Upgrade", detail: "Upgrade an armor piece at a Great Fairy", points: 25),
        .init(id: "totk.41", title: "Great Fairy", detail: "Unlock all four Great Fairies", points: 50),
        .init(id: "totk.42", title: "Cooking Class", detail: "Cook 10 distinct meals", points: 50),
        .init(id: "totk.43", title: "Master Chef", detail: "Cook 50 distinct meals", points: 50),
        .init(id: "totk.44", title: "Horse Friend", detail: "Register a horse", points: 50),
        .init(id: "totk.45", title: "Stable Traveler", detail: "Visit every stable", points: 50),
        .init(id: "totk.46", title: "Monster Hunter", detail: "Defeat a Lynel", points: 50),
        .init(id: "totk.47", title: "Gleeok Slayer", detail: "Defeat a Gleeok", points: 50),
        .init(id: "totk.48", title: "Frox Hunter", detail: "Defeat a Frox", points: 50),
        .init(id: "totk.49", title: "Coliseum Champion", detail: "Clear a Depths coliseum", points: 50),
        .init(id: "totk.50", title: "Hero of Hyrule", detail: "Complete every main quest", points: 50)
    ]
    static func forGame(_ gameName: String) -> [CandelaAchievement] {
        let name = gameName.lowercased()
        if name.contains("odyssey") { return odyssey }
        if name.contains("tomodachi") { return tomodachi }
        if name.contains("tears of the kingdom") { return totk }
        return []
    }
}

/// Event adapters call unlock only after a verified in-game milestone.
/// Future emulator memory hooks must be version-checked and opt-in.
@MainActor
final class CandelaAchievements: ObservableObject {
    static let shared = CandelaAchievements()
    @Published private(set) var unlocked: Set<String> = []
    @Published private(set) var recentUnlock: CandelaAchievement?
    private let storagePrefix = "candela.achievements.unlocked.v2."
    private var activeProfile = "default"
    private var activeGame = ""
    private var pending: [CandelaAchievement] = []
    private var toastGeneration = 0

    private init() {}

    private func selectedProfileID() -> String {
        let url = URL.documentsDirectory
            .appendingPathComponent("system")
            .appendingPathComponent("Profiles.json")
        guard let data = try? Data(contentsOf: url),
              let profiles = try? JSONDecoder().decode(Profiles.self, from: data) else {
            return "default"
        }
        return profiles.last_opened
    }

    private func storageKey(gameID: String) -> String {
        storagePrefix + activeProfile + "." + gameID
    }

    func beginSession(gameID: String) {
        activeProfile = selectedProfileID()
        activeGame = gameID
        unlocked = Set(UserDefaults.standard.stringArray(forKey: storageKey(gameID: gameID)) ?? [])
        pending.removeAll()
        recentUnlock = nil
        toastGeneration += 1
    }

    func endSession() {
        activeGame = ""
        pending.removeAll()
        recentUnlock = nil
        toastGeneration += 1
    }

    func unlock(_ achievement: CandelaAchievement, gameID: String) {
        guard activeGame == gameID,
              !unlocked.contains(achievement.id),
              !pending.contains(where: { $0.id == achievement.id }) else { return }
        unlocked.insert(achievement.id)
        UserDefaults.standard.set(Array(unlocked).sorted(), forKey: storageKey(gameID: gameID))
        pending.append(achievement)
        presentNext()
    }

    private func presentNext() {
        guard recentUnlock == nil, !pending.isEmpty else { return }
        recentUnlock = pending.removeFirst()
        toastGeneration += 1
        let generation = toastGeneration
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) { [weak self] in
            guard let self, self.toastGeneration == generation else { return }
            self.recentUnlock = nil
            self.presentNext()
        }
    }

    /// Game-specific adapters report verified game-state transitions only.
    func reportVerifiedTomodachiResidentCount(previous: Int, current: Int, gameID: String) {
        guard previous == 0, current >= 1,
              let firstMii = CandelaAchievementCatalogue.tomodachi.first else { return }
        unlock(firstMii, gameID: gameID)
    }

    func reportVerifiedOdysseyMoonCount(previous: Int, current: Int, gameID: String) {
        guard previous == 0, current >= 1,
              let firstMoon = CandelaAchievementCatalogue.odyssey.first(where: { $0.id == "odyssey.05" }) else { return }
        unlock(firstMoon, gameID: gameID)
    }

    func unlockedIDs(gameID: String) -> Set<String> {
        let profile = selectedProfileID()
        return Set(UserDefaults.standard.stringArray(forKey: storagePrefix + profile + "." + gameID) ?? [])
    }

    func dismissToast() {
        toastGeneration += 1
        recentUnlock = nil
        presentNext()
    }
}

struct CandelaAchievementsPage: View {
    let gameName: String
    let gameID: String
    @ObservedObject private var progress = CandelaAchievements.shared
    @Environment(\.colorScheme) private var scheme
    private var achievements: [CandelaAchievement] { CandelaAchievementCatalogue.forGame(gameName) }

    var body: some View {
        let palette = CandelaPalette(dark: scheme == .dark)
        let count = achievements.filter { progress.unlockedIDs(gameID: gameID).contains($0.id) }.count
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Achievements")
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundColor(palette.ink)
                Text(gameName).font(.subheadline).foregroundColor(palette.inkSoft)
                HStack {
                    Text("\(count) / \(achievements.count) unlocked")
                    Spacer()
                    Text("\(achievements.isEmpty ? 0 : Int(Double(count) / Double(achievements.count) * 100))%")
                }
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .foregroundColor(palette.rose)
                ProgressView(value: Double(count), total: Double(max(achievements.count, 1)))
                    .tint(palette.rose)
                if achievements.isEmpty {
                    Text("Achievements are not available for this game.")
                        .foregroundColor(palette.inkSoft)
                }
                ForEach(achievements) { achievement in
                    let earned = progress.unlockedIDs(gameID: gameID).contains(achievement.id)
                    HStack(spacing: 12) {
                        Image(systemName: earned ? "rosette" : "lock.fill")
                            .font(.system(size: 22))
                            .foregroundColor(earned ? palette.rose : palette.inkSoft)
                            .frame(width: 42, height: 42)
                            .background(palette.roseSoft.opacity(0.25), in: RoundedRectangle(cornerRadius: 12))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(achievement.title).font(.headline).foregroundColor(palette.ink)
                            Text(achievement.detail).font(.caption).foregroundColor(palette.inkSoft)
                        }
                        Spacer(minLength: 2)
                        Text("\(achievement.points) pts")
                            .font(.caption.bold())
                            .foregroundColor(palette.rose)
                    }
                    .padding(12)
                    .candelaSurface(radius: 17)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(achievement.title), \(earned ? "unlocked" : "locked")")
                }
                Text("Automatic unlock detection requires a verified game-specific integration. Progress will not be fabricated.")
                    .font(.footnote).foregroundColor(palette.inkSoft)
            }
            .padding(18)
        }
        .background(CandelaBackdrop(dark: scheme == .dark).ignoresSafeArea())
        .navigationTitle("Achievements")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Place in the existing gameplay overlay after game event adapters are implemented.
struct CandelaAchievementToast: View {
    @ObservedObject private var progress = CandelaAchievements.shared
    var body: some View {
        if let item = progress.recentUnlock {
            HStack(spacing: 10) {
                Image(systemName: "trophy.fill").foregroundColor(.yellow)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Achievement unlocked").font(.caption.bold())
                    Text(item.title).font(.subheadline.bold())
                }
                Spacer(minLength: 4)
                Text("+\(item.points)").font(.caption.bold())
            }
            .foregroundColor(.white)
            .padding(14)
            .background(Color.black.opacity(0.89), in: RoundedRectangle(cornerRadius: 16))
            .frame(maxWidth: 310)
            .transition(.move(edge: .trailing).combined(with: .opacity))
            .accessibilityAddTraits(.updatesFrequently)
        }
    }
}
