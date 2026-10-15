//
//  AppTheme.swift
//  Candela
//
//  Created by Stossy11 on 8/6/2026.
//

import SwiftUI
import Foundation

struct ThemeAccent: Equatable {
    let primary: Color
    let secondary: Color
}

enum BackgroundStyle: String, Codable, CaseIterable {
    case candelaBlush = "Blush"
    case candelaDusk  = "Dusk"
    case oled         = "OLED Black"

    var displayName: String { rawValue }

    @ViewBuilder
    func makeBackground() -> some View {
        switch self {
        case .candelaBlush:
            CandelaBackdrop(dark: false)
        case .candelaDusk:
            CandelaBackdrop(dark: true)
        case .oled:
            Color.black
        }
    }
}

extension BackgroundStyle {
    var ambientColor: UIColor {
        switch self {
        case .candelaBlush:
            return .average(hexes: ["#FCF2F6", "#EAF1FB"])
        case .candelaDusk:
            return .average(hexes: ["#1D1826", "#141A28"])
        case .oled:
            return .black
        }
    }
}


struct AppTheme: Identifiable, Equatable, Codable {
    let id: String
    let name: String
    let accentColorHex: String
    let accentSecondaryHex: String
    let backgroundStyle: BackgroundStyle
    let isDark: Bool

    var accent: ThemeAccent {
        ThemeAccent(
            primary: Color(hex: accentColorHex),
            secondary: Color(hex: accentSecondaryHex)
        )
    }

    init(
        id: String,
        name: String,
        accentColorHex: String,
        accentSecondaryHex: String,
        backgroundStyle: BackgroundStyle,
        isDark: Bool
    ) {
        self.id = id
        self.name = name
        self.accentColorHex = accentColorHex
        self.accentSecondaryHex = accentSecondaryHex
        self.backgroundStyle = backgroundStyle
        self.isDark = isDark
    }

    init(
        id: String,
        name: String,
        accent: ThemeAccent,
        backgroundStyle: BackgroundStyle,
        isDark: Bool
    ) {
        guard
            let primaryHex = accent.primary.toHex(),
            let secondaryHex = accent.secondary.toHex()
        else {
            assertionFailure(
                "ThemeAccent colours must be hex-constructible. " +
                "Do not use system/dynamic colours (e.g. .accentColor) here."
            )
            self.init(
                id: id, name: name,
                accentColorHex: "#000000", accentSecondaryHex: "#000000",
                backgroundStyle: backgroundStyle, isDark: isDark
            )
            return
        }
        self.init(
            id: id, name: name,
            accentColorHex: primaryHex, accentSecondaryHex: secondaryHex,
            backgroundStyle: backgroundStyle, isDark: isDark
        )
    }
}

extension AppTheme {

    static let allBuiltIn: [AppTheme] = [
        .candelaBlush,
        .candelaDusk,
        .oled
    ]

    /// Light pink and powder blue. The default.
    static let candelaBlush = AppTheme(
        id: "candela-blush",
        name: "Candela Blush",
        accentColorHex: "#C9648C",
        accentSecondaryHex: "#6F97D6",
        backgroundStyle: .candelaBlush,
        isDark: false
    )

    /// The same pink and blue, on a dusk-violet base.
    static let candelaDusk = AppTheme(
        id: "candela-dusk",
        name: "Candela Dusk",
        accentColorHex: "#F2A9C4",
        accentSecondaryHex: "#93B8F0",
        backgroundStyle: .candelaDusk,
        isDark: true
    )

    static let oled = AppTheme(
        id: "oled",
        name: "OLED Black",
        accentColorHex: "#F2A9C4",
        accentSecondaryHex: "#93B8F0",
        backgroundStyle: .oled,
        isDark: true
    )

    static let defaultTheme = candelaBlush
}
