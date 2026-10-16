// SPDX-License-Identifier: AGPL-3.0-or-later
// Candela's Touch Studio deliberately reuses Melo-Controller's saved layouts and live input.
import SwiftUI
import Melo_Controller

struct CandelaGameControllerView: View {
    let game: GameInfo
    let isEditing: Bool
    @AppStorage("candela.touch.odyssey.enhanced.v1") private var enhancedOdyssey = false
    @AppStorage("candela.touch.tomodachi.enabled.v2") private var tomodachiTouch = true

    var body: some View {
        Group {
            if enhancedOdyssey && game.titleName.localizedCaseInsensitiveContains("super mario odyssey") {
                if isEditing {
                    CandelaOdysseyGlassEditor(gameId: game.titleId)
                } else {
                    CandelaOdysseyGlassOverlay(gameId: game.titleId)
                }
            } else if tomodachiTouch && game.titleName.localizedCaseInsensitiveContains("tomodachi life") && game.titleName.localizedCaseInsensitiveContains("dream") {
                if isEditing {
                    CandelaTomodachiTouchEditor(gameId: game.titleId, gameName: game.titleName)
                } else {
                    CandelaTomodachiTouchOverlay(gameId: game.titleId, gameName: game.titleName)
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

struct CandelaTouchStudioHub: View {
    @ObservedObject private var controller = RyujinxController.shared
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dismiss) private var dismiss
    @State private var editing: GameInfo?
    @AppStorage("candela.touch.odyssey.enhanced.v1") private var enhancedOdyssey = false
    @AppStorage("candela.touch.tomodachi.enabled.v2") private var tomodachiTouch = true

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
                    Toggle("Odyssey Glass · native-style controls", isOn: $enhancedOdyssey)
                        .tint(palette.rose)
                    Text("Opt-in glass joystick, Jump, Throw, Capture and Dive/Roll. Original controls remain available.")
                        .font(.caption).foregroundColor(palette.inkSoft)
                }
                .padding(16)
                .candelaSurface(radius: 24)
                VStack(alignment: .leading, spacing: 10) {
                    Label("Tomodachi Life: Living the Dream", systemImage: "heart.text.square.fill")
                        .font(.headline)
                    Toggle("Tomodachi Touch · pastel native controls", isOn: $tomodachiTouch)
                        .tint(palette.rose)
                    Text("Casual, Hybrid and Classic presets. Touch Scene clears buttons for supported touch-enabled scenes. Use the game tile below to edit the layout.")
                        .font(.caption)
                        .foregroundColor(palette.inkSoft)
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
                                Text("Customize touch controls")
                                    .font(.caption).foregroundColor(palette.inkSoft)
                            }
                            Spacer()
                            Image(systemName: "slider.horizontal.3").foregroundColor(palette.rose)
                        }
                        .padding(12).candelaSurface(radius: 20)
                    }
                    .buttonStyle(.plain)
                }
                Text("Odyssey Glass and Tomodachi Touch use Candela layouts layered over MeloNX. Other games retain the existing Melo-Controller editor. Bluetooth mappings and emulated touchscreen forwarding are preserved.")
                    .font(.footnote).foregroundColor(palette.inkSoft)
                    .padding(.bottom, 65)
            }
            .foregroundColor(palette.ink)
            .padding(20)
        }
        .background(CandelaBackdrop(dark: scheme == .dark).ignoresSafeArea())
        .navigationBarHidden(false)
        .navigationTitle("Touch Studio")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { dismiss() } label: {
                    Label("Settings", systemImage: "chevron.left")
                }
                .tint(palette.rose)
                .accessibilityLabel("Back to settings")
            }
        }
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
    @Environment(\.dismiss) private var dismiss
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
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { dismiss() } label: {
                    Label("Settings", systemImage: "chevron.left")
                }
                .tint(palette.rose)
                .accessibilityLabel("Back to settings")
            }
        }
    }
}
