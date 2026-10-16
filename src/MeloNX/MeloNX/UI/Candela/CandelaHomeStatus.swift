// SPDX-License-Identifier: AGPL-3.0-or-later
// Mockup-inspired game-first header and compact featured card. Uses only owned game metadata.
import SwiftUI

struct CandelaStatusPill: View {
    @Environment(\.colorScheme) private var scheme
    let gameCount: Int
    var onMusic: () -> Void
    var onAccount: () -> Void

    var body: some View {
        let p = CandelaPalette(dark: scheme == .dark)
        HStack(spacing: 11) {
            CandelaMark(size: 35, dark: scheme == .dark)
            VStack(alignment: .leading, spacing: 1) {
                Text("Candela")
                    .font(.system(size: 19, weight: .heavy, design: .rounded))
                    .foregroundColor(p.ink)
                Text(gameCount == 1 ? "YOUR GAME LIBRARY · 1 GAME" : "YOUR GAME LIBRARY · \(gameCount) GAMES")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .tracking(0.9)
                    .foregroundColor(p.inkSoft)
            }
            Spacer(minLength: 5)
            Button(action: onMusic) {
                Image(systemName: "music.note")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(p.ink)
                    .frame(width: 39, height: 39)
                    .background(p.roseSoft.opacity(0.46), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Music")
            Menu {
                CandelaLibraryMenuItems(onAccount: onAccount)
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundColor(p.ink)
                    .frame(width: 39, height: 39)
                    .background(p.card.opacity(0.64), in: Circle())
            }
            .accessibilityLabel("Library menu")
        }
        .padding(.leading, 14)
        .padding(.trailing, 8)
        .padding(.vertical, 9)
        .background {
            Capsule().fill(.regularMaterial)
                .overlay(Capsule().fill(p.card.opacity(0.62)))
        }
        .overlay(Capsule().strokeBorder(p.cardStroke.opacity(0.94), lineWidth: 1))
        .shadow(color: p.rose.opacity(scheme == .dark ? 0.05 : 0.11), radius: 13, y: 4)
    }
}

struct CandelaPressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(!reduceMotion && configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.91 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.13), value: configuration.isPressed)
    }
}

/// Artwork-anchored hero: the background art is explicitly constrained to the
/// card's dimensions, so it cannot inflate the layout on real devices.
struct CandelaJumpCard: View {
    @Environment(\.colorScheme) private var scheme
    let game: GameInfo?
    let gameCount: Int
    var lastPlayed: Date? = nil
    var onPlay: (GameInfo) -> Void

    var body: some View {
        let p = CandelaPalette(dark: scheme == .dark)
        Button {
            if let game { onPlay(game) }
        } label: {
            HStack(alignment: .center, spacing: 16) {
                Group {
                    if let game {
                        CandelaArtView(game: game, cornerRadius: 17)
                            .aspectRatio(1, contentMode: .fill)
                    } else {
                        Image(systemName: "sparkles.tv")
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundColor(p.rose)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(p.roseSoft.opacity(0.30))
                    }
                }
                .frame(width: 112, height: 112)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 17).strokeBorder(.white.opacity(0.78), lineWidth: 1))
                .shadow(color: .black.opacity(0.12), radius: 9, y: 5)

                VStack(alignment: .leading, spacing: 7) {
                    Text("CONTINUE PLAYING")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .tracking(1.4)
                        .foregroundColor(p.rose)
                        .lineLimit(1)

                    Text(game?.titleName ?? "Ready for an adventure?")
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .foregroundColor(p.ink)
                        .lineLimit(2)
                        .minimumScaleFactor(0.78)
                        .multilineTextAlignment(.leading)

                    if let lastPlayed {
                        Text("Last played \(lastPlayed.formatted(.relative(presentation: .named)))")
                            .font(.system(size: 12))
                            .foregroundColor(p.inkSoft)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    } else {
                        Text(gameCount == 0 ? "Import a game to begin" : "Pick up where you left off")
                            .font(.system(size: 12))
                            .foregroundColor(p.inkSoft)
                            .lineLimit(1)
                    }

                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 10, weight: .heavy))
                        Text(game == nil ? "Explore" : "Play now")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(p.primaryButtonInk)
                    .padding(.horizontal, 17)
                    .frame(height: 34)
                    .background(p.accentGradient, in: Capsule())
                    .overlay(Capsule().strokeBorder(.white.opacity(0.80), lineWidth: 1))
                    .padding(.top, 2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(15)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 153)
            .background {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                p.card.opacity(0.98),
                                p.roseSoft.opacity(scheme == .dark ? 0.20 : 0.40),
                                p.skySoft.opacity(scheme == .dark ? 0.14 : 0.38)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay {
                        GeometryReader { bounds in
                            if let game {
                                CandelaArtView(game: game, cornerRadius: 0)
                                    .frame(width: bounds.size.width, height: bounds.size.height)
                                    .clipped()
                                    .blur(radius: 30)
                                    .opacity(scheme == .dark ? 0.09 : 0.065)
                            }
                        }
                        .allowsHitTesting(false)
                        .clipShape(RoundedRectangle(cornerRadius: 26))
                    }
            }
            .overlay(RoundedRectangle(cornerRadius: 26).strokeBorder(p.cardStroke.opacity(0.90), lineWidth: 1))
            .shadow(color: p.rose.opacity(scheme == .dark ? 0.02 : 0.13), radius: 17, y: 6)
        }
        .buttonStyle(CandelaPressStyle())
        .disabled(game == nil)
        .accessibilityLabel(game.map { "Play \($0.titleName)" } ?? "No recent game")
    }
}
