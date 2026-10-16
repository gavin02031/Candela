// SPDX-License-Identifier: AGPL-3.0-or-later
// Candela's Touch Studio deliberately reuses Melo-Controller's saved layouts and live input.
import SwiftUI
import Melo_Controller

struct CandelaGameControllerView: View {
    let game: GameInfo
    let isEditing: Bool
    @AppStorage("candela.touch.odyssey.enhanced.v1") private var enhancedOdyssey = false

    var body: some View {
        Group {
            if enhancedOdyssey && game.titleName.localizedCaseInsensitiveContains("super mario odyssey") {
                ControllerView(
                    controller: VirtualControllerManager.shared,
                    isEditing: isEditing,
                    gameId: game.titleId + ".candelaOdyssey",
                    gameName: game.titleName + " · Candela"
                ) { button, joystick, portrait in
                    CandelaOdysseyControls(button: button, joystick: joystick, portrait: portrait)
                }
            } else {
                ControllerView(
                    controller: VirtualControllerManager.shared,
                    isEditing: isEditing,
                    gameId: game.titleId,
                    gameName: game.titleName
                )
            }
        }
    }
}

private struct CandelaOdysseyControls: View {
    let button: SubView
    let joystick: JoystickSubView
    let portrait: Bool
    @State private var leftActive = false
    @State private var rightActive = false
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        Group {
            if portrait {
                VStack(spacing: 9) {
                    Spacer(minLength: 0)
                    HStack(alignment: .bottom, spacing: 5) {
                        leftGroup
                        Spacer(minLength: 0)
                        rightGroup
                    }
                    HStack(spacing: 40) {
                        button(.back)
                        button(.start)
                    }
                }
            } else {
                HStack(alignment: .bottom, spacing: 6) {
                    leftGroup
                    Spacer(minLength: 4)
                    HStack(spacing: 14) {
                        button(.back)
                        button(.start)
                    }
                    Spacer(minLength: 4)
                    rightGroup
                }
            }
        }
        .padding(.horizontal, 5)
        .padding(.bottom, 9)
    }

    private var leftGroup: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                button(.leftTrigger)
                button(.leftShoulder)
            }
            joystick("leftJoystick", false, $leftActive)
                .frame(width: 150, height: 150)
        }
    }
    private var rightGroup: some View {
        VStack(spacing: 7) {
            HStack(spacing: 6) {
                button(.rightShoulder)
                button(.rightTrigger)
            }
            if portrait {
                joystick("rightJoystick", true, $rightActive)
                    .frame(width: 135, height: 135)
                actions
            } else {
                HStack(alignment: .bottom, spacing: 4) {
                    joystick("rightJoystick", true, $rightActive)
                        .frame(width: 140, height: 140)
                    actions
                }
            }
        }
    }
    private var actions: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                labeled(.Y, "THROW")
                labeled(.X, "THROW")
            }
            HStack(spacing: 4) {
                labeled(.B, "JUMP")
                labeled(.A, "JUMP")
            }
        }
    }
    private func labeled(_ input: VirtualControllerButton, _ title: String) -> some View {
        VStack(spacing: 2) {
            button(input)
            Text(title)
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundColor(CandelaPalette(dark: scheme == .dark).ink)
                .allowsHitTesting(false)
        }
    }
}

struct CandelaTouchStudioHub: View {
    @ObservedObject private var controller = RyujinxController.shared
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dismiss) private var dismiss
    @State private var editing: GameInfo?
    @AppStorage("candela.touch.odyssey.enhanced.v1") private var enhancedOdyssey = false

    private var palette: CandelaPalette { CandelaPalette(dark: scheme == .dark) }
    private var games: [GameInfo] {
        controller.games.sorted {
            let a = priority($0.titleName), b = priority($1.titleName)
            return a == b ? $0.titleName.localizedCompare($1.titleName) == .orderedAscending : a < b
        }
    }
    private func priority(_ name: String) -> Int {
        if name.localizedCaseInsensitiveContains("super mario odyssey") { return 0 }
        if name.localizedCaseInsensitiveContains("tomodachi life") { return 1 }
        if name.localizedCaseInsensitiveContains("tears of the kingdom") { return 2 }
        return 3
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {
                CandelaMark(size: 47, dark: scheme == .dark)
                Text("Touch Studio")
                    .font(.system(.largeTitle, design: .rounded).weight(.heavy))
                Text("Your games. Your controls.")
                    .foregroundColor(palette.inkSoft)
                VStack(alignment: .leading, spacing: 9) {
                    Label("Super Mario Odyssey", systemImage: "sparkles")
                        .font(.headline)
                    Toggle("Enhanced jump + Cappy layout", isOn: $enhancedOdyssey)
                        .tint(palette.rose)
                    Text("Opt-in. Your original controller layout remains unchanged.")
                        .font(.caption).foregroundColor(palette.inkSoft)
                }
                .padding(16)
                .candelaSurface(radius: 24)
                Text("Per-game layouts")
                    .font(.title3.weight(.bold))
                if games.isEmpty {
                    Text("Import your owned game files to customize their controls here.")
                        .foregroundColor(palette.inkSoft)
                        .padding(17).candelaSurface(radius: 20)
                }
                ForEach(games) { game in
                    Button { editing = game } label: {
                        HStack(spacing: 12) {
                            Group {
                                if let icon = game.icon {
                                    Image(uiImage: icon).resizable().scaledToFit()
                                } else {
                                    Image(systemName: "gamecontroller.fill")
                                        .resizable().scaledToFit().padding(9)
                                }
                            }
                            .frame(width: 54, height: 54)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            VStack(alignment: .leading, spacing: 3) {
                                Text(game.titleName)
                                    .font(.subheadline.weight(.semibold))
                                Text("Move, resize and save controls")
                                    .font(.caption).foregroundColor(palette.inkSoft)
                            }
                            Spacer()
                            Image(systemName: "slider.horizontal.3").foregroundColor(palette.rose)
                        }
                        .padding(12).candelaSurface(radius: 20)
                    }
                    .buttonStyle(.plain)
                }
                Text("Touch Studio uses the existing Melo-Controller editor. Physical-controller mappings and direct emulated touchscreen input are not modified.")
                    .font(.footnote).foregroundColor(palette.inkSoft)
                    .padding(.bottom, 65)
            }
            .foregroundColor(palette.ink)
            .padding(20)
        }
        .background(CandelaBackdrop(dark: scheme == .dark).ignoresSafeArea())
        .navigationBarHidden(true)
        .overlay(alignment: .bottom) {
            Button { dismiss() } label: {
                Label("Back", systemImage: "chevron.left")
                    .padding(.horizontal, 18).padding(.vertical, 12)
                    .candelaSurface(radius: 24)
            }
            .buttonStyle(.plain)
            .padding(.bottom, 18)
        }
        .fullScreenCover(item: $editing) { game in
            CandelaGameControllerView(game: game, isEditing: true)
                .interactiveDismissDisabled(true)
        }
    }
}

struct CandelaThemeGallery: View {
    @Environment(\.colorScheme) private var scheme
    @AppStorage("candela.theme.style.v1") private var selected = CandelaThemeStyle.pastelDream.rawValue

    var body: some View {
        let palette = CandelaPalette(dark: scheme == .dark)
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {
                Text("Choose your glow").font(.largeTitle.bold())
                Text("Pastel Dream is Candela's signature look.")
                    .foregroundColor(palette.inkSoft)
                ForEach(CandelaThemeStyle.allCases) { style in
                    Button { selected = style.rawValue } label: {
                        HStack(spacing: 14) {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(LinearGradient(colors: style.colors, startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 85, height: 62)
                            Text(style.title).font(.headline)
                            Spacer()
                            Image(systemName: selected == style.rawValue ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(palette.rose)
                        }
                        .padding(14).candelaSurface(radius: 19)
                    }.buttonStyle(.plain)
                }
            }
            .padding(20)
            .foregroundColor(palette.ink)
        }
        .background(CandelaBackdrop(dark: scheme == .dark).ignoresSafeArea())
        .navigationTitle("Themes")
    }
}
