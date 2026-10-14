//
//  CandelaTheme.swift
//  Candela
//
//  Candela's own visual language: soft blush pink and powder blue, quiet surfaces,
//  rounded type, and one flame mark. Everything in here depends on SwiftUI only,
//  so it also compiles in the CI preview renderer.
//

import SwiftUI

// MARK: - Palette

/// Colour tokens. `dark` picks the Dusk variant; light is Blush.
struct CandelaPalette {
    let dark: Bool

    // Brand
    var rose: Color { dark ? Color(candelaHex: 0xF2A9C4) : Color(candelaHex: 0xC9648C) }
    var roseSoft: Color { dark ? Color(candelaHex: 0xF7C6D8) : Color(candelaHex: 0xF4C6D7) }
    var sky: Color { dark ? Color(candelaHex: 0x93B8F0) : Color(candelaHex: 0x6F97D6) }
    var skySoft: Color { dark ? Color(candelaHex: 0xB5CEF6) : Color(candelaHex: 0xC6D8F3) }

    // Surfaces
    var backgroundTop: Color { dark ? Color(candelaHex: 0x1D1826) : Color(candelaHex: 0xFCF2F6) }
    var backgroundBottom: Color { dark ? Color(candelaHex: 0x141A28) : Color(candelaHex: 0xEAF1FB) }
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
        LinearGradient(colors: [rose, sky], startPoint: .topLeading, endPoint: .bottomTrailing)
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
            .foregroundColor(scheme == .dark ? Color(candelaHex: 0x2A1A24) : .white)
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
    @Environment(\.colorScheme) private var scheme
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
