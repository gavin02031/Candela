// SPDX-License-Identifier: AGPL-3.0-or-later
// Floating status pill and "Jump back in" card for the home screen.
import SwiftUI

struct CandelaStatusPill: View {
    @Environment(\.colorScheme) private var scheme
    let gameCount: Int
    var onMusic: () -> Void
    var onClassic: () -> Void

    @State private var battery: Float = -1
    @State private var charging = false

    var body: some View {
        let p = CandelaPalette(dark: scheme == .dark)
        HStack(spacing: 10) {
            CandelaMark(size: 30, dark: scheme == .dark)
            Text("Candela")
                .font(.system(.headline, design: .rounded).weight(.heavy)).lineLimit(1).fixedSize(horizontal: true, vertical: false)
                .foregroundColor(p.ink)
            Spacer(minLength: 4)
            TimelineView(.periodic(from: .now, by: 30)) { ctx in
                HStack(spacing: 6) {
                    Text(ctx.date, format: .dateTime.hour().minute())
                    Text("|").opacity(0.4)
                    Text(ctx.date, format: .dateTime.month(.defaultDigits).day())
                }
                .font(.system(.footnote, design: .rounded).weight(.bold)).lineLimit(1).fixedSize(horizontal: true, vertical: false)
                .foregroundColor(p.ink)
            }
            if battery >= 0 {
                HStack(spacing: 3) {
                    Image(systemName: charging ? "battery.100.bolt" : "battery.75")
                        .foregroundColor(charging ? p.good : p.inkSoft)
                    Text("\(Int(battery * 100))%")
                        .font(.system(.caption2, design: .rounded).weight(.bold)).lineLimit(1).fixedSize(horizontal: true, vertical: false)
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
                Button(action: onClassic) {
                    Label("Use classic library", systemImage: "arrow.uturn.backward")
                }
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

/// Big card for the most recent game, or a quiet placeholder when there is none.
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
            HStack(spacing: 14) {
                Group {
                    if let game {
                        CandelaArtView(game: game)
                            .aspectRatio(1, contentMode: .fit)
                    } else {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(p.rose)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(p.roseSoft.opacity(0.35))
                    }
                }
                .frame(width: 96, height: 96)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                VStack(alignment: .leading, spacing: 3) {
                    Text("Jump back in")
                        .font(.system(.title3, design: .rounded).weight(.heavy)).lineLimit(1).minimumScaleFactor(0.8)
                        .foregroundColor(p.ink)
                    Text(game?.titleName ?? "No recent game")
                        .font(.subheadline.weight(.medium)).minimumScaleFactor(0.85)
                        .foregroundColor(p.inkSoft)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    if let lastPlayed {
                        Text("Last played \(lastPlayed.formatted(.relative(presentation: .named)))")
                            .font(.caption).lineLimit(1).minimumScaleFactor(0.75)
                            .foregroundColor(p.inkSoft.opacity(0.85))
                    }
                }
                Spacer()
                if game != nil {
                    HStack(spacing: 6) {
                        Image(systemName: "play.fill")
                        Text("Resume")
                    }
                    .font(.system(.subheadline, design: .rounded).weight(.heavy)).lineLimit(1).fixedSize(horizontal: true, vertical: false)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 11)
                    .background(p.accentGradient, in: Capsule())
                }
            }
            .padding(14)
            .candelaSurface(radius: 26)
        }
        .buttonStyle(.plain)
        .disabled(game == nil)
    }
}
