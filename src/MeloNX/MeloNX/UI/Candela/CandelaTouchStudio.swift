// SPDX-License-Identifier: AGPL-3.0-or-later
// Candela's Touch Studio deliberately reuses Melo-Controller's saved layouts and live input.
import SwiftUI
import Melo_Controller

struct CandelaGameControllerView: View {
    @Environment(\.dismiss) private var dismiss
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
                .overlay(alignment: .topTrailing) {
                    if isEditing {
                        Button { dismiss() } label: {
                            Label("Done", systemImage: "checkmark.circle.fill")
                                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                .padding(.horizontal, 15)
                                .padding(.vertical, 10)
                                .background(.regularMaterial, in: Capsule())
                        }
                        .tint(CandelaPalette(dark: false).rose)
                        .padding(.top, 15)
                        .padding(.trailing, 16)
                        .accessibilityLabel("Close controller editor")
                    }
                }
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

// MARK: - App-wide appearance gallery
// The same selected preset drives SwiftUI, native navigation, surfaces and music.

struct CandelaThemeGallery: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @ObservedObject private var themeManager = ThemeManager.shared

    private let columns = [GridItem(.adaptive(minimum: 145, maximum: 210), spacing: 13)]

    var body: some View {
        let palette = CandelaPalette(dark: scheme == .dark)
        ScrollView {
            VStack(alignment: .leading, spacing: 19) {
                VStack(alignment: .leading, spacing: 7) {
                    Text("Make Candela yours.")
                        .font(.system(size: 29, weight: .heavy, design: .rounded))
                        .foregroundColor(palette.ink)
                    Text("One look across Home, games, Music and Settings.")
                        .font(.system(size: 13, design: .rounded))
                        .foregroundColor(palette.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack(spacing: 11) {
                    Image(systemName: "paintpalette.fill")
                        .foregroundStyle(palette.accentGradient)
                        .font(.system(size: 24))
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Active theme")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(palette.inkSoft)
                        Text(themeManager.currentTheme.name)
                            .font(.system(size: 18, weight: .heavy, design: .rounded))
                            .foregroundColor(palette.ink)
                    }
                    Spacer()
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(palette.rose)
                }
                .padding(17)
                .candelaSurface(radius: 22)

                LazyVGrid(columns: columns, spacing: 13) {
                    ForEach(CandelaThemeStyle.allCases) { style in
                        themeCard(style)
                    }
                }

                Label("Your choice is saved automatically and stays in sync across the app.",
                      systemImage: "checkmark.shield")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(palette.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 4)
            }
            .padding(19)
            .padding(.bottom, 26)
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

    private func themeCard(_ style: CandelaThemeStyle) -> some View {
        let chosen = themeManager.currentTheme.id == style.rawValue
        let palette = CandelaPalette(dark: scheme == .dark)

        return Button {
            themeManager.selectCandela(style)
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                CandelaThemeScenePreview(style: style)
                    .frame(height: 132)
                    .clipped()

                HStack(alignment: .center, spacing: 7) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(style.title)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(palette.ink)
                            .lineLimit(1)
                            .minimumScaleFactor(0.76)
                        Text(style.subtitle)
                            .font(.system(size: 10, design: .rounded))
                            .foregroundColor(palette.inkSoft)
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: chosen ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 18))
                        .foregroundColor(chosen ? palette.rose : palette.inkSoft.opacity(0.52))
                }
                .padding(.horizontal, 11)
                .padding(.vertical, 11)
                .frame(minHeight: 65)
                .background(palette.card)
            }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(chosen ? palette.rose : palette.cardStroke,
                                  lineWidth: chosen ? 2.5 : 1)
            }
            .shadow(color: chosen ? palette.rose.opacity(0.15) : .clear, radius: 13, y: 5)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(style.title + (chosen ? ", selected" : ", apply theme"))
        .accessibilityAddTraits(chosen ? [.isSelected] : [])
    }
}

private struct CandelaThemeScenePreview: View {
    let style: CandelaThemeStyle

    private var foreground: Color {
        style.isDark ? .white : Color(candelaHex: 0x332C4C)
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: style.colors, startPoint: .topLeading, endPoint: .bottomTrailing)
            Circle()
                .fill(.white.opacity(style.isDark ? 0.10 : 0.45))
                .frame(width: 110)
                .blur(radius: 24)
                .offset(x: 67, y: -50)
            VStack(spacing: 8) {
                HStack(spacing: 5) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Candela")
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                    Spacer()
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundColor(foreground)
                HStack(spacing: 9) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 11)
                            .fill(.white.opacity(style.isDark ? 0.14 : 0.66))
                        Image(systemName: "gamecontroller.fill")
                            .font(.system(size: 25))
                            .foregroundColor(foreground)
                    }
                    .frame(width: 62, height: 56)
                    VStack(alignment: .leading, spacing: 5) {
                        Capsule().fill(foreground.opacity(0.74)).frame(width: 53, height: 6)
                        Capsule().fill(foreground.opacity(0.33)).frame(width: 38, height: 5)
                        Capsule()
                            .fill(Color(candelaHex: UInt32(style.accentHex.dropFirst(), radix: 16) ?? 0x9360A2))
                            .frame(width: 55, height: 15)
                    }
                    Spacer(minLength: 0)
                }
                .padding(8)
                .background(.white.opacity(style.isDark ? 0.10 : 0.48),
                            in: RoundedRectangle(cornerRadius: 14))
                Spacer(minLength: 0)
                HStack(spacing: 16) {
                    Image(systemName: "house.fill")
                    Image(systemName: "square.grid.2x2")
                    Image(systemName: "gearshape")
                }
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(foreground)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 5)
                .background(.white.opacity(style.isDark ? 0.13 : 0.36), in: Capsule())
            }
            .padding(12)
        }
        .accessibilityHidden(true)
    }
}
