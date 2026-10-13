//
//  CandelaArt.swift
//  Candela
//
//  Artwork loading for the new home screen. Today it uses the icon embedded in
//  the game file (the same image the classic library shows). Extra art sources,
//  such as SteamGridDB, can be added to CandelaArtRegistry without touching the views.
//

import SwiftUI

/// An optional extra source of artwork. Return nil to fall back to the next source.
@MainActor
protocol CandelaArtSource {
    func artwork(for game: GameInfo) async -> UIImage?
}

@MainActor
final class CandelaArtRegistry {
    static let shared = CandelaArtRegistry()

    /// Extra sources, checked in order before the embedded icon.
    /// Empty for now. A SteamGridDB source will be added here later.
    var sources: [CandelaArtSource] = []

    private init() {}

    func artwork(for game: GameInfo) async -> UIImage? {
        for source in sources {
            if let image = await source.artwork(for: game) {
                return image
            }
        }
        return nil
    }
}

struct CandelaArtView: View {
    let game: GameInfo
    var cornerRadius: CGFloat = 18

    @State private var customArt: UIImage?

    var body: some View {
        ZStack {
            if let image = customArt ?? game.icon {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                LinearGradient(
                    colors: [Color.indigo.opacity(0.7), Color.purple.opacity(0.5)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Text(String(game.titleName.prefix(1)).uppercased())
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.85))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .task(id: game.id) {
            customArt = await CandelaArtRegistry.shared.artwork(for: game)
        }
    }
}
