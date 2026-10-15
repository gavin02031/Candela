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
            HStack(spacing: 16) {
                Group {
                    if let game {
                        CandelaArtView(game: game, cornerRadius: 20)
                            .aspectRatio(1, contentMode: .fit)
                    } else {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundColor(p.rose)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(p.roseSoft.opacity(0.35))
                    }
                }
                .frame(width: 104, height: 104)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .shadow(color: Color.black.opacity(0.18), radius: 8, x: 0, y: 4)

                VStack(alignment: .leading, spacing: 4) {
                    Text("JUMP BACK IN")
                        .font(.system(.caption2, design: .rounded).weight(.heavy))
                        .tracking(1.2)
                        .lineLimit(1)
                        .foregroundColor(p.rose)
                    Text(game?.titleName ?? "No recent game")
                        .font(.system(.title3, design: .rounded).weight(.bold))
                        .foregroundColor(p.ink)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                        .multilineTextAlignment(.leading)
                    if let lastPlayed {
                        Text("Played \(lastPlayed.formatted(.relative(presentation: .named)))")
                            .font(.caption)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .foregroundColor(p.inkSoft.opacity(0.9))
                    }
                    if game != nil {
                        HStack(spacing: 6) {
                            Image(systemName: "play.fill")
                            Text("Resume")
                        }
                        .font(.system(.subheadline, design: .rounded).weight(.heavy))
                        .lineLimit(1)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .frame(minHeight: 36)
                        .background(p.accentGradient, in: Capsule())
                        .padding(.top, 6)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(14)
            .candelaSurface(radius: 26)
            .overlay {
                // Soft wash of the game's own art behind the card, so each game tints its card.
                if let game {
                    CandelaArtView(game: game, cornerRadius: 26)
                        .blur(radius: 28)
                        .opacity(0.12)
                        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                        .allowsHitTesting(false)
                }
            }
        }
        .buttonStyle(CandelaPressStyle())
        .disabled(game == nil)
        .accessibilityLabel(game.map { "Resume \($0.titleName)" } ?? "No recent game")
    }
}
