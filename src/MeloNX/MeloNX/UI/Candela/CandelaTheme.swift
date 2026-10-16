//
//  CandelaTheme.swift
//  Candela
//
//  Candela's own visual language: soft blush pink and powder blue, quiet surfaces,
//  rounded type, and one flame mark. Everything in here depends on SwiftUI only,
//  so it also compiles in the CI preview renderer.
//

import SwiftUI

// MARK: - Persistent Candela theme selection
enum CandelaThemeStyle: String, CaseIterable, Identifiable {
    case pastelDream, classicBlush, arcticGlass, sunsetPop, obsidianEmber
    var id: String { rawValue }
    var title: String {
        switch self {
        case .pastelDream: return "Pastel Dream"
        case .classicBlush: return "Classic Blush"
        case .arcticGlass: return "Arctic Glass"
        case .sunsetPop: return "Sunset Pop"
        case .obsidianEmber: return "Obsidian Ember"
        }
    }
    var colors: [Color] {
        switch self {
        case .pastelDream: return [Color(candelaHex: 0xE9D3FA), Color(candelaHex: 0xC8E9DD), Color(candelaHex: 0xF7D5E8)]
        case .classicBlush: return [Color(candelaHex: 0xF4C6D7), Color(candelaHex: 0xC6D8F3)]
        case .arcticGlass: return [Color(candelaHex: 0xD2EDFF), Color(candelaHex: 0xB2DAF2)]
        case .sunsetPop: return [Color(candelaHex: 0xF9BCA9), Color(candelaHex: 0xD8C6F7)]
        case .obsidianEmber: return [Color(candelaHex: 0x30243B), Color(candelaHex: 0xDDA787)]
        }
    }
}

// MARK: - Palette

/// Colour tokens. `dark` picks the Dusk variant; light is Blush.
struct CandelaPalette {
    let dark: Bool
    private var style: CandelaThemeStyle {
        CandelaThemeStyle(rawValue: UserDefaults.standard.string(forKey: "candela.theme.style.v1") ?? "") ?? .pastelDream
    }
    private var isClassic: Bool { style == .classicBlush }
    private var first: Color { style.colors[0] }
    private var second: Color { style.colors[1] }

    // Brand
    // Keep subtle pastel fills for backgrounds but use deeper accents for readable text/icons.
    private var strongAccent: Color {
        switch style {
        case .pastelDream: return Color(candelaHex: 0x9360A2)
        case .classicBlush: return Color(candelaHex: 0xB4527C)
        case .arcticGlass: return Color(candelaHex: 0x417C9E)
        case .sunsetPop: return Color(candelaHex: 0xAC6474)
        case .obsidianEmber: return Color(candelaHex: 0x9C6944)
        }
    }
    var rose: Color { isClassic ? (dark ? Color(candelaHex: 0xF2A9C4) : Color(candelaHex: 0xC9648C)) : (dark ? first.opacity(0.95) : strongAccent) }
    var primaryButtonInk: Color {
        style == .obsidianEmber ? .white : Color(candelaHex: 0x352941)
    }
    var roseSoft: Color { isClassic ? (dark ? Color(candelaHex: 0xF7C6D8) : Color(candelaHex: 0xF4C6D7)) : first.opacity(0.72) }
    var sky: Color { isClassic ? (dark ? Color(candelaHex: 0x93B8F0) : Color(candelaHex: 0x6F97D6)) : second }
    var skySoft: Color { isClassic ? (dark ? Color(candelaHex: 0xB5CEF6) : Color(candelaHex: 0xC6D8F3)) : second.opacity(0.75) }

    // Surfaces
    var backgroundTop: Color { isClassic ? (dark ? Color(candelaHex: 0x1D1826) : Color(candelaHex: 0xFCF2F6)) : (dark ? Color(candelaHex: 0x241C32) : Color(candelaHex: 0xFCF7FF)) }
    var backgroundBottom: Color { isClassic ? (dark ? Color(candelaHex: 0x141A28) : Color(candelaHex: 0xEAF1FB)) : (dark ? Color(candelaHex: 0x17252B) : Color(candelaHex: 0xEAF8F3)) }
    var card: Color { dark ? Color(candelaHex: 0x2A2436) : Color.white }
    var cardStroke: Color { dark ? Color(candelaHex: 0x3C3550) : Color(candelaHex: 0xF0DCE5) }
    var field: Color { dark ? Color(candelaHex: 0x241F30) : Color(candelaHex: 0xF6EEF4) }

    // Text
    var ink: Color { dark ? Color(candelaHex: 0xF4EEF8) : Color(candelaHex: 0x3A3450) }
    var inkSoft: Color { dark ? Color(candelaHex: 0xB4ABC6) : Color(candelaHex: 0x7A7290) }

    // Status. Muted so they sit with the pastels instead of shouting.
    var good: Color { dark ? Color(candelaHex: 0x8FD6B4) : Color(candelaHex: 0x3F9E7B) }
    var warn: Color { dark ? Color(candelaHex: 0xF2CB8F) : Color(candelaHex: 0xC98A3A) }
    var bad: Color { dark ? Color(candelaHex: 0xF2968F) : Color(candelaHex: 0xC5524D) }

    var accentGradient: LinearGradient {
        LinearGradient(colors: isClassic ? [rose, sky] : style.colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

extension Color {
    /// 0xRRGGBB
    init(candelaHex hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}

// MARK: - Backdrop

/// Full-screen background: a pink to blue wash with two soft glows.
struct CandelaBackdrop: View {
    let dark: Bool

    var body: some View {
        let p = CandelaPalette(dark: dark)
        ZStack {
            LinearGradient(colors: [p.backgroundTop, p.backgroundBottom], startPoint: .top, endPoint: .bottom)
            RadialGradient(
                colors: [p.roseSoft.opacity(dark ? 0.14 : 0.45), .clear],
                center: .topLeading, startRadius: 0, endRadius: 360
            )
            RadialGradient(
                colors: [p.skySoft.opacity(dark ? 0.14 : 0.5), .clear],
                center: .bottomTrailing, startRadius: 0, endRadius: 420
            )
            CandelaDots(dark: dark)
        }
    }
}

// MARK: - Mark

/// The Candela flame: a teardrop with a pink to blue fill. Drawn, so it needs no asset.
struct CandelaFlame: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width, h = rect.height
        path.move(to: CGPoint(x: rect.minX + w * 0.5, y: rect.minY))
        path.addCurve(
            to: CGPoint(x: rect.minX + w * 0.86, y: rect.minY + h * 0.64),
            control1: CGPoint(x: rect.minX + w * 0.58, y: rect.minY + h * 0.26),
            control2: CGPoint(x: rect.minX + w * 0.86, y: rect.minY + h * 0.4)
        )
        path.addCurve(
            to: CGPoint(x: rect.minX + w * 0.5, y: rect.maxY),
            control1: CGPoint(x: rect.minX + w * 0.86, y: rect.minY + h * 0.86),
            control2: CGPoint(x: rect.minX + w * 0.7, y: rect.maxY)
        )
        path.addCurve(
            to: CGPoint(x: rect.minX + w * 0.14, y: rect.minY + h * 0.64),
            control1: CGPoint(x: rect.minX + w * 0.3, y: rect.maxY),
            control2: CGPoint(x: rect.minX + w * 0.14, y: rect.minY + h * 0.86)
        )
        path.addCurve(
            to: CGPoint(x: rect.minX + w * 0.5, y: rect.minY),
            control1: CGPoint(x: rect.minX + w * 0.14, y: rect.minY + h * 0.4),
            control2: CGPoint(x: rect.minX + w * 0.42, y: rect.minY + h * 0.26)
        )
        path.closeSubpath()
        return path
    }
}

struct CandelaMark: View {
    var size: CGFloat = 96
    var dark: Bool = false

    var body: some View {
        let p = CandelaPalette(dark: dark)
        ZStack {
            Circle()
                .fill(p.roseSoft.opacity(dark ? 0.18 : 0.55))
                .frame(width: size * 1.5, height: size * 1.5)
                .blur(radius: size * 0.22)
            CandelaFlame()
                .fill(LinearGradient(colors: [p.roseSoft, p.rose, p.sky], startPoint: .top, endPoint: .bottom))
                .frame(width: size * 0.62, height: size * 0.86)
            CandelaFlame()
                .fill(Color.white.opacity(dark ? 0.35 : 0.7))
                .frame(width: size * 0.2, height: size * 0.3)
                .offset(y: size * 0.16)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Components

private struct CandelaSurfaceModifier: ViewModifier {
    @Environment(\.colorScheme) private var scheme
    var radius: CGFloat

    func body(content: Content) -> some View {
        let p = CandelaPalette(dark: scheme == .dark)
        content
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(p.card.opacity(scheme == .dark ? 0.92 : 0.78))
                    .overlay(
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .stroke(p.cardStroke, lineWidth: 1)
                    )
                    .shadow(color: p.rose.opacity(scheme == .dark ? 0 : 0.10), radius: 14, x: 0, y: 6)
            )
    }
}

extension View {
    /// A soft rounded surface with a thin blush border.
    func candelaSurface(radius: CGFloat = 20) -> some View {
        modifier(CandelaSurfaceModifier(radius: radius))
    }
}

struct CandelaPrimaryButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        let p = CandelaPalette(dark: scheme == .dark)
        configuration.label
            .font(.system(.headline, design: .rounded))
            .foregroundColor(isEnabled ? p.primaryButtonInk : p.inkSoft)
            .padding(.vertical, 14)
            .padding(.horizontal, 28)
            .background(
                Capsule(style: .continuous)
                    .fill(isEnabled ? AnyShapeStyle(p.accentGradient) : AnyShapeStyle(p.inkSoft.opacity(0.35)))
            )
            .shadow(color: p.rose.opacity(isEnabled && scheme != .dark ? 0.3 : 0), radius: 10, x: 0, y: 5)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct CandelaSecondaryButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var scheme

    func makeBody(configuration: Configuration) -> some View {
        let p = CandelaPalette(dark: scheme == .dark)
        configuration.label
            .font(.system(.subheadline, design: .rounded).weight(.semibold))
            .foregroundColor(p.rose)
            .padding(.vertical, 10)
            .padding(.horizontal, 18)
            .background(
                Capsule(style: .continuous)
                    .fill(p.roseSoft.opacity(scheme == .dark ? 0.12 : 0.35))
                    .overlay(Capsule(style: .continuous).stroke(p.roseSoft.opacity(0.7), lineWidth: 1))
            )
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

/// Small caps-style heading for a group of rows.
struct CandelaSectionTitle: View {
    @Environment(\.colorScheme) private var scheme
    let text: String

    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.system(.footnote, design: .rounded).weight(.semibold))
            .tracking(0.6)
            .textCase(.uppercase)
            .foregroundColor(CandelaPalette(dark: scheme == .dark).inkSoft)
    }
}

/// Pill used for small facts, such as "3 games" or "Entitled".
struct CandelaChip: View {
    @Environment(\.colorScheme) var scheme
    let text: String
    var tint: Color? = nil

    var body: some View {
        let p = CandelaPalette(dark: scheme == .dark)
        let color = tint ?? p.sky
        Text(text)
            .font(.system(.caption, design: .rounded).weight(.semibold))
            .foregroundColor(color)
            .padding(.vertical, 4)
            .padding(.horizontal, 10)
            .background(Capsule(style: .continuous).fill(color.opacity(0.14)))
    }
}

// MARK: - Status colours for places without a colour scheme at hand

extension Color {
    static let candelaGood = Color(candelaHex: 0x4FA886)
    static let candelaWarn = Color(candelaHex: 0xD39A4A)
    static let candelaBad = Color(candelaHex: 0xCF5F5A)
}

// MARK: - Step page (first-launch setup)

/// One page of the first-launch setup: progress, a round icon, a title, a short
/// explanation, optional content, and a pinned action bar.
struct CandelaStepPage<Content: View>: View {
    @Environment(\.colorScheme) var scheme

    let step: Int
    let total: Int
    let symbol: String
    let title: String
    let message: String
    let primaryTitle: String
    let primaryEnabled: Bool
    let primaryAction: () -> Void
    let secondaryTitle: String?
    let secondaryAction: (() -> Void)?
    let content: () -> Content
    @Environment(\.candelaStaticLayout) var staticLayout

    init(
        step: Int, of total: Int,
        symbol: String, title: String, message: String,
        primaryTitle: String, primaryEnabled: Bool = true, primaryAction: @escaping () -> Void,
        secondaryTitle: String? = nil, secondaryAction: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.step = step
        self.total = total
        self.symbol = symbol
        self.title = title
        self.message = message
        self.primaryTitle = primaryTitle
        self.primaryEnabled = primaryEnabled
        self.primaryAction = primaryAction
        self.secondaryTitle = secondaryTitle
        self.secondaryAction = secondaryAction
        self.content = content
    }

    var body: some View {
        let p = CandelaPalette(dark: scheme == .dark)
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                HStack(spacing: 6) {
                    ForEach(1...max(total, 1), id: \.self) { i in
                        Capsule(style: .continuous)
                            .fill(i <= step ? AnyShapeStyle(p.accentGradient) : AnyShapeStyle(p.inkSoft.opacity(0.2)))
                            .frame(height: 5)
                    }
                }
                Text("Step \(step) of \(total)")
                    .font(.system(.footnote, design: .rounded).weight(.semibold))
                    .foregroundColor(p.inkSoft)
            }
            .padding(.horizontal, 28)
            .padding(.top, 24)

            scrolling {
                VStack(spacing: 16) {
                    ZStack {
                        Circle().fill(p.roseSoft.opacity(scheme == .dark ? 0.16 : 0.5)).frame(width: 112, height: 112)
                        Circle().stroke(p.accentGradient, lineWidth: 2).frame(width: 112, height: 112)
                        Image(systemName: symbol)
                            .font(.system(size: 44, weight: .regular))
                            .foregroundStyle(p.accentGradient)
                    }
                    .padding(.top, 28)
                    Text(title)
                        .font(.system(.title, design: .rounded).weight(.bold))
                        .foregroundColor(p.ink)
                        .multilineTextAlignment(.center)
                    Text(message)
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(p.inkSoft)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    content()
                        .padding(.top, 4)
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 24)
            }

            VStack(spacing: 10) {
                Button(primaryTitle, action: primaryAction)
                    .buttonStyle(CandelaPrimaryButtonStyle())
                    .disabled(!primaryEnabled)
                if let secondaryTitle, let secondaryAction {
                    Button(secondaryTitle, action: secondaryAction)
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundColor(p.inkSoft)
                        .buttonStyle(.plain)
                }
            }
            .padding(.top, 12)
            .padding(.bottom, 28)
            .frame(maxWidth: .infinity)
        }
    }
}

/// The preview renderer cannot draw scroll views, so it turns them off.
private struct CandelaStaticLayoutKey: EnvironmentKey { static let defaultValue = false }
extension EnvironmentValues {
    var candelaStaticLayout: Bool {
        get { self[CandelaStaticLayoutKey.self] }
        set { self[CandelaStaticLayoutKey.self] = newValue }
    }
}

extension CandelaStepPage {
    @ViewBuilder
    func scrolling<Inner: View>(@ViewBuilder _ inner: () -> Inner) -> some View {
        if staticLayout {
            VStack { inner(); Spacer(minLength: 0) }
        } else {
            ScrollView { inner() }
        }
    }
}

/// A labelled row for step content: icon, text, and a trailing status chip.
struct CandelaStatusRow: View {
    @Environment(\.colorScheme) var scheme
    var symbol: String
    var title: String
    var detail: String? = nil
    var chip: String? = nil
    var chipTint: Color? = nil

    var body: some View {
        let p = CandelaPalette(dark: scheme == .dark)
        HStack(spacing: 12) {
            Image(systemName: symbol).foregroundColor(p.rose).frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(.body, design: .rounded)).foregroundColor(p.ink)
                if let detail {
                    Text(detail).font(.footnote).foregroundColor(p.inkSoft)
                }
            }
            Spacer(minLength: 8)
            if let chip { CandelaChip(text: chip, tint: chipTint) }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .candelaSurface(radius: 18)
    }
}
