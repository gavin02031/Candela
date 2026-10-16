// SPDX-License-Identifier: AGPL-3.0-or-later
// Floating status pill and "Jump back in" card for the home screen.
import SwiftUI

struct CandelaStatusPill: View {
    @Environment(\.colorScheme) private var scheme
    let gameCount: Int
    var onMusic: () -> Void
    var onAccount: () -> Void

    @State private var battery: Float = -1
    @State private var charging = false

    var body: some View {
        let p = CandelaPalette(dark: scheme == .dark)
        HStack(spacing: 8) {
            CandelaMark(size: 30, dark: scheme == .dark)
            Text("Candela")
                .font(.system(.headline, design: .rounded).weight(.heavy)).lineLimit(1).minimumScaleFactor(0.7)
                .foregroundColor(p.ink)
            Spacer(minLength: 4)
            TimelineView(.periodic(from: .now, by: 30)) { ctx in
                HStack(spacing: 6) {
                    Text(ctx.date, format: .dateTime.hour().minute())
                }
                .font(.system(.footnote, design: .rounded).weight(.bold)).lineLimit(1).minimumScaleFactor(0.7)
                .foregroundColor(p.ink)
            }
            if battery >= 0 {
                HStack(spacing: 3) {
                    Image(systemName: charging ? "battery.100.bolt" : "battery.75")
                        .foregroundColor(charging ? p.good : p.inkSoft)
                    Text("\(Int(battery * 100))%")
                        .font(.system(.caption2, design: .rounded).weight(.bold)).lineLimit(1).minimumScaleFactor(0.7)
                        .foregroundColor(p.inkSoft)
                }
            }
            Button(action: onMusic) {
                Image(systemName: "music.note")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(p.rose)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(p.roseSoft.opacity(scheme == .dark ? 0.25 : 0.6)))
            }
            Menu {
                CandelaLibraryMenuItems(onAccount: onAccount)
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(p.inkSoft)
                    .frame(width: 32, height: 32)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .candelaSurface(radius: 30)
        .onAppear {
            UIDevice.current.isBatteryMonitoringEnabled = true
            battery = UIDevice.current.batteryLevel
            charging = UIDevice.current.batteryState == .charging || UIDevice.current.batteryState == .full
        }
    }
}

/// Press feedback for the big cards: a small, quick scale so taps feel physical without a heavy animation.
struct CandelaPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

/// Big card for the most recent game, or a quiet placeholder when there is none.
/// Layout: art on the left, a small "Jump back in" label, the game title as the main line,
/// then last-played time and a Resume button stacked underneath. Stacking gives the title the
/// full row width, so nothing shrinks or truncates next to the button.
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
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                p.card.opacity(0.95),
                                p.roseSoft.opacity(scheme == .dark ? 0.18 : 0.44),
                                p.skySoft.opacity(scheme == .dark ? 0.18 : 0.38)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                if let game {
                    CandelaArtView(game: game, cornerRadius: 0)
                        .blur(radius: 38)
                        .opacity(scheme == .dark ? 0.13 : 0.10)
                        .clipped()
                        .allowsHitTesting(false)
                }
                HStack(alignment: .center, spacing: 16) {
                    Group {
                        if let game {
                            CandelaArtView(game: game, cornerRadius: 20)
                        } else {
                            Image(systemName: "play.rectangle.fill")
                                .font(.system(size: 37))
                                .foregroundColor(p.rose)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(p.roseSoft.opacity(0.4))
                        }
                    }
                    .frame(width: 114, height: 136)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .shadow(color: .black.opacity(0.14), radius: 10, y: 5)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("JUMP BACK IN")
                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                            .tracking(1.8)
                            .foregroundColor(p.rose)
                        Text(game?.titleName ?? "Your next adventure")
                            .font(.system(.title3, design: .rounded).weight(.heavy))
                            .lineLimit(3)
                            .minimumScaleFactor(0.83)
                            .foregroundColor(p.ink)
                            .multilineTextAlignment(.leading)
                        if let lastPlayed {
                            Text("Played \(lastPlayed.formatted(.relative(presentation: .named)))")
                                .font(.caption)
                                .foregroundColor(p.inkSoft)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        } else {
                            Text(gameCount == 0 ? "Add your first game to begin" : "Choose a game to play")
                                .font(.caption)
                                .foregroundColor(p.inkSoft)
                        }
                        HStack(spacing: 7) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 11, weight: .heavy))
                            Text(game == nil ? "Explore" : "Resume")
                                .font(.system(.subheadline, design: .rounded).weight(.heavy))
                        }
                        .foregroundColor(Color(candelaHex: 0x3A3450))
                        .frame(minWidth: 104, minHeight: 39)
                        .background(p.accentGradient, in: Capsule())
                        .overlay(Capsule().strokeBorder(.white.opacity(0.8), lineWidth: 1))
                        .padding(.top, 4)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(16)
            }
            .frame(minHeight: 170)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 28).strokeBorder(p.cardStroke, lineWidth: 1.1))
            .shadow(color: p.rose.opacity(scheme == .dark ? 0 : 0.14), radius: 18, y: 7)
        }
        .buttonStyle(CandelaPressStyle())
        .disabled(game == nil)
        .accessibilityLabel(game.map { "Resume \($0.titleName)" } ?? "No recent game")
    }
}
