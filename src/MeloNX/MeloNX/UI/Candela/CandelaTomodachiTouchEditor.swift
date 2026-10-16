// SPDX-License-Identifier: AGPL-3.0-or-later
// Candela Tomodachi Touch Studio: pastel editor, per-game saved layout and mode previews.
import SwiftUI
import Melo_Controller

struct CandelaTomodachiTouchEditor: View {
    let gameId: String
    let gameName: String

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var profile = TomodachiTouchLayout.standard
    @State private var mode: TomodachiTouchMode = .island
    @State private var selected: TomodachiTouchKey = .a
    @State private var showClassicEditor = false
    @State private var showResetAlert = false

    private var p: CandelaPalette { CandelaPalette(dark: scheme == .dark) }

    private func save() { TomodachiTouchStorage.save(profile, id: gameId) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 21) {
                header
                preview
                presets
                modes
                customization
                actions
                facts
            }
            .padding(.horizontal, 18)
            .padding(.top, 16)
            .padding(.bottom, 36)
        }
        .background(CandelaBackdrop(dark: scheme == .dark).ignoresSafeArea())
        .onAppear {
            profile = TomodachiTouchStorage.load(gameId)
            mode = profile.mode
        }
        .onDisappear { save() }
        .fullScreenCover(isPresented: $showClassicEditor) {
            ControllerView(controller: VirtualControllerManager.shared,
                           isEditing: true, gameId: gameId, gameName: gameName)
                .interactiveDismissDisabled(true)
        }
        .alert("Reset Tomodachi Touch?", isPresented: $showResetAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                profile = .standard
                mode = .island
                selected = .a
                save()
            }
        } message: {
            Text("This resets the Tomodachi preset, bubble positions and appearance. The original emulator controller layout is not affected.")
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(LinearGradient(colors: [
                        Color(candelaHex: 0xFDE4D5),
                        Color(candelaHex: 0xDCC8F4),
                        Color(candelaHex: 0xD0F3E3)
                    ], startPoint: .topLeading, endPoint: .bottomTrailing))
                Image(systemName: "house.lodge.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Color(candelaHex: 0x795890))
            }
            .frame(width: 51, height: 51)
            VStack(alignment: .leading, spacing: 4) {
                Text("Tomodachi Touch")
                    .font(.system(size: 25, weight: .heavy, design: .rounded))
                    .foregroundColor(p.ink)
                Text("Living the Dream · Made for your iPhone")
                    .font(.system(size: 12))
                    .foregroundColor(p.inkSoft)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            Spacer(minLength: 2)
            Button {
                save()
                dismiss()
            } label: {
                Text("Done")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(p.primaryButtonInk)
                    .padding(.horizontal, 17)
                    .frame(height: 42)
                    .background(p.accentGradient, in: Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    private var preview: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                title("Live layout preview")
                Spacer()
                Text("LANDSCAPE")
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .tracking(1.2)
                    .foregroundColor(p.inkSoft)
            }
            ZStack {
                RoundedRectangle(cornerRadius: 21, style: .continuous)
                    .fill(LinearGradient(colors: [
                        Color(candelaHex: 0xA2D9EE),
                        Color(candelaHex: 0xE4D1F5),
                        Color(candelaHex: 0xF7E2C3),
                        Color(candelaHex: 0xC7EBDD)
                    ], startPoint: .topLeading, endPoint: .bottomTrailing))
                decorativeIsland
                    .allowsHitTesting(false)
                    .clipShape(RoundedRectangle(cornerRadius: 21))
                if profile.preset == .classic {
                    VStack(spacing: 6) {
                        Image(systemName: "gamecontroller.fill")
                            .font(.system(size: 31))
                        Text("Original Melo-Controller")
                            .font(.system(size: 14, weight: .heavy, design: .rounded))
                        Text("Preserves existing control positions")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(p.ink)
                    .padding(15)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
                } else {
                    TomodachiTouchCanvas(profile: $profile, mode: $mode, isEditing: true,
                                         selected: selected,
                                         onSelect: { selected = $0 },
                                         onSave: save)
                        .padding(3)
                }
            }
            .aspectRatio(852.0 / 393.0, contentMode: .fit)
            .overlay(RoundedRectangle(cornerRadius: 21)
                .strokeBorder(.white.opacity(0.81), lineWidth: 1.6))
            .shadow(color: p.rose.opacity(0.18), radius: 11, y: 5)

            HStack(spacing: 6) {
                Image(systemName: "hand.draw")
                    .foregroundColor(p.rose)
                Text(profile.preset == .classic
                     ? "Choose Edit original controls to customize the classic controller."
                     : "Drag bubbles to arrange them. Only shown buttons receive input.")
                    .foregroundColor(p.inkSoft)
            }
            .font(.system(size: 11))
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var decorativeIsland: some View {
        GeometryReader { geo in
            ZStack {
                Ellipse()
                    .fill(Color.white.opacity(0.55))
                    .frame(width: geo.size.width * 0.36, height: geo.size.height * 0.18)
                    .offset(x: geo.size.width * 0.1, y: geo.size.height * 0.24)
                Image(systemName: "cloud.fill")
                    .font(.system(size: 55))
                    .foregroundColor(.white.opacity(0.5))
                    .position(x: geo.size.width * 0.68, y: geo.size.height * 0.23)
                Image(systemName: "building.2.fill")
                    .font(.system(size: min(geo.size.width * 0.21, 80), weight: .ultraLight))
                    .foregroundColor(Color(candelaHex: 0xFFF4EE).opacity(0.75))
                    .position(x: geo.size.width * 0.46, y: geo.size.height * 0.55)
                Image(systemName: "leaf.fill")
                    .font(.system(size: 35))
                    .foregroundColor(Color(candelaHex: 0x82C8AE).opacity(0.6))
                    .position(x: geo.size.width * 0.57, y: geo.size.height * 0.83)
            }
        }
    }

    private var presets: some View {
        VStack(alignment: .leading, spacing: 11) {
            title("Choose your vibe")
            HStack(spacing: 9) {
                ForEach(TomodachiTouchPreset.allCases) { value in
                    Button {
                        if reduceMotion { profile.preset = value }
                        else {
                            withAnimation(.easeOut(duration: 0.17)) {
                                profile.preset = value
                            }
                        }
                        save()
                    } label: {
                        VStack(spacing: 7) {
                            Image(systemName: value == .casual ? "hand.tap.fill" :
                                    (value == .hybrid ? "gamecontroller.fill" : "gamecontroller"))
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(p.rose)
                                .frame(height: 24)
                            Text(value.title)
                                .font(.system(size: 14, weight: .heavy, design: .rounded))
                                .foregroundColor(p.ink)
                            Text(value.detail)
                                .font(.system(size: 10))
                                .foregroundColor(p.inkSoft)
                                .lineLimit(2)
                                .minimumScaleFactor(0.82)
                        }
                        .frame(maxWidth: .infinity, minHeight: 92)
                        .padding(.horizontal, 4)
                        .background(profile.preset == value ? p.roseSoft.opacity(0.57) : p.card.opacity(0.85),
                                    in: RoundedRectangle(cornerRadius: 19))
                        .overlay(RoundedRectangle(cornerRadius: 19)
                            .strokeBorder(profile.preset == value ? p.rose.opacity(0.65) : p.cardStroke,
                                          lineWidth: profile.preset == value ? 1.6 : 1))
                    }
                    .buttonStyle(.plain)
                }
            }
            if profile.preset == .classic {
                Button {
                    showClassicEditor = true
                } label: {
                    Label("Edit original controller", systemImage: "slider.horizontal.3")
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .foregroundColor(p.ink)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .candelaSurface(radius: 17)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var modes: some View {
        VStack(alignment: .leading, spacing: 11) {
            title("Mode previews")
            Text("Pick these modes manually. The emulator can't reliably detect when Tomodachi changes scenes.")
                .font(.system(size: 11))
                .foregroundColor(p.inkSoft)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 9) {
                    ForEach(TomodachiTouchMode.allCases) { value in
                        Button {
                            mode = value
                            profile.mode = value
                            save()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: value.symbol)
                                Text(value.title)
                            }
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(mode == value ? p.ink : p.inkSoft)
                            .padding(.horizontal, 12)
                            .frame(height: 39)
                            .background(mode == value ? p.roseSoft.opacity(0.65) : p.card.opacity(0.83),
                                        in: Capsule())
                            .overlay(Capsule().strokeBorder(mode == value ? p.rose.opacity(0.56) : p.cardStroke))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            Text(mode.hint)
                .font(.system(size: 11))
                .foregroundColor(p.inkSoft)
                .padding(.top, 1)
        }
    }

    private var customization: some View {
        VStack(alignment: .leading, spacing: 12) {
            title("Overlay settings")
            VStack(spacing: 5) {
                toggled("Show button labels", icon: "tag.fill", state: $profile.showLabels)
                toggled("Left-handed layout", icon: "hand.raised.fill", state: $profile.leftHanded)
                toggled("Focus mode (less clutter)", icon: "eye.slash.fill", state: $profile.focusMode)
                toggled("Show shoulder buttons", icon: "rectangle.topthird.inset.filled", state: $profile.showShoulders)
                toggled("Show D-pad", icon: "dpad.fill", state: $profile.showDPad)
                toggled("Optional camera stick", icon: "camera.fill", state: $profile.showCameraStick)
                Divider().padding(.horizontal, 8)
                slider("Bubble size", value: $profile.scale, range: 0.67...1.30,
                       description: "\(Int(profile.scale * 100))%")
                slider("Glass opacity", value: $profile.opacity, range: 0.28...1,
                       description: "\(Int(profile.opacity * 100))%")
            }
            .padding(14)
            .background(p.card.opacity(0.84), in: RoundedRectangle(cornerRadius: 23))
            .overlay(RoundedRectangle(cornerRadius: 23).strokeBorder(p.cardStroke))
        }
    }

    private func toggled(_ text: String, icon: String, state: Binding<Bool>) -> some View {
        HStack(spacing: 11) {
            Image(systemName: icon)
                .font(.system(size: 17))
                .foregroundColor(p.rose)
                .frame(width: 29)
            Text(text)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(p.ink)
            Spacer(minLength: 6)
            Toggle(text, isOn: Binding(
                get: { state.wrappedValue },
                set: { state.wrappedValue = $0; save() }
            ))
            .labelsHidden()
            .tint(p.rose)
        }
        .frame(minHeight: 42)
    }

    private func slider(_ title: String, value: Binding<Double>,
                        range: ClosedRange<Double>, description: String) -> some View {
        VStack(spacing: 5) {
            HStack {
                Text(title)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                Spacer()
                Text(description)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(p.inkSoft)
            }
            .foregroundColor(p.ink)
            Slider(value: Binding(
                get: { value.wrappedValue },
                set: { value.wrappedValue = $0; save() }
            ), in: range)
            .tint(p.rose)
        }
        .padding(.vertical, 7)
    }

    private var actions: some View {
        HStack(spacing: 11) {
            Button {
                showResetAlert = true
            } label: {
                Label("Reset layout", systemImage: "arrow.uturn.backward")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .frame(maxWidth: .infinity, minHeight: 45)
            }
            .buttonStyle(CandelaSecondaryButtonStyle())

            Button {
                profile.mode = mode
                save()
                dismiss()
            } label: {
                Label("Save preset", systemImage: "checkmark")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .frame(maxWidth: .infinity, minHeight: 45)
            }
            .buttonStyle(CandelaPrimaryButtonStyle())
        }
    }

    private var facts: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("A = Confirm · B = Back · X = Game Menu · Y = Secondary action",
                  systemImage: "gamecontroller")
            Label("Mii creation and Palette House are among the scenes that support direct touch.",
                  systemImage: "hand.draw")
            Label("Your original gamepad mapping and Odyssey Glass settings stay intact.",
                  systemImage: "lock.shield")
        }
        .font(.system(size: 11))
        .foregroundColor(p.inkSoft)
        .padding(.horizontal, 5)
        .padding(.bottom, 20)
    }

    private func title(_ value: String) -> some View {
        Text(value)
            .font(.system(size: 19, weight: .heavy, design: .rounded))
            .foregroundColor(p.ink)
    }
}
