//
//  ThemeManager.swift
//  Candela
//
//  Created by Stossy11 on 8/6/2026.
//

import SwiftUI
import Combine

struct AppThemeKey: EnvironmentKey {
    static let defaultValue: AppTheme = .defaultTheme
}

extension EnvironmentValues {
    var appTheme: AppTheme {
        get { self[AppThemeKey.self] }
        set { self[AppThemeKey.self] = newValue }
    }
}

final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var currentTheme: AppTheme {
        didSet { persist() }
    }
    
    private let storageKey = "candela_selected_theme_id"
    
    private init() {
        let savedId = UserDefaults.standard.string(forKey: "candela_selected_theme_id") ?? UserDefaults.standard.string(forKey: "melonx_selected_theme_id") ?? "default"
        currentTheme = AppTheme.allBuiltIn.first { $0.id == savedId } ?? .defaultTheme
    }
    
    private func persist() {
        UserDefaults.standard.set(currentTheme.id, forKey: storageKey)
        applyUIKitAppearance()
    }
    
    func select(_ theme: AppTheme) {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentTheme = theme
        }
    }
    
    var interfaceStyle: UIUserInterfaceStyle { currentTheme.isDark ? .dark : .light }

    /// Pins every window to the theme's light or dark style, so nothing falls back to the phone's system setting.
    func applyInterfaceStyle() {
        let style = interfaceStyle
        for scene in UIApplication.shared.connectedScenes {
            guard let windowScene = scene as? UIWindowScene else { continue }
            for window in windowScene.windows { window.overrideUserInterfaceStyle = style }
        }
    }

    func applyUIKitAppearance() {
        let accentUI = UIColor(currentTheme.accent.primary)
        let palette = CandelaPalette(dark: currentTheme.isDark)

        let bar = UITabBarAppearance()
        bar.configureWithDefaultBackground()
        bar.backgroundColor = currentTheme.backgroundStyle == .oled ? .black : UIColor(palette.card).withAlphaComponent(0.86)
        bar.shadowColor = UIColor(palette.cardStroke)
        let item = UITabBarItemAppearance()
        item.normal.iconColor = UIColor(palette.inkSoft)
        item.normal.titleTextAttributes = [.foregroundColor: UIColor(palette.inkSoft)]
        item.selected.iconColor = accentUI
        item.selected.titleTextAttributes = [.foregroundColor: accentUI]
        bar.stackedLayoutAppearance = item
        bar.inlineLayoutAppearance = item
        bar.compactInlineLayoutAppearance = item
        UITabBar.appearance().standardAppearance = bar
        UITabBar.appearance().scrollEdgeAppearance = bar
        UITabBar.appearance().tintColor = accentUI
        UITabBar.appearance().unselectedItemTintColor = UIColor(palette.inkSoft)

        let nav = UINavigationBarAppearance()
        nav.configureWithTransparentBackground()
        nav.titleTextAttributes = [.foregroundColor: UIColor(palette.ink)]
        nav.largeTitleTextAttributes = [.foregroundColor: UIColor(palette.ink)]
        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
        UINavigationBar.appearance().tintColor = accentUI

        DispatchQueue.main.async { self.applyInterfaceStyle() }
    }
}

struct ThemedViewModifier: ViewModifier {
    @ObservedObject var manager: ThemeManager = .shared
    
    func body(content: Content) -> some View {
        content
            .environment(\.appTheme, manager.currentTheme)
            .accentColor(manager.currentTheme.accent.primary)
            .onAppear { manager.applyUIKitAppearance() }
            .preferredColorScheme(
                manager.currentTheme.isDark ? .dark : .light
            )
    }
}

extension View {
    func withAppTheme() -> some View {
        modifier(ThemedViewModifier())
    }
}


private struct ThemedBackgroundView: View {
    @ObservedObject private var manager: ThemeManager = .shared

    var body: some View {
        GeometryReader { geo in
            manager.currentTheme.backgroundStyle.makeBackground()
                .frame(width: geo.size.width, height: geo.size.height)
        }
        .ignoresSafeArea()
    }
}

extension View {
    func themedBackground() -> some View {
        self.background {
            ThemedBackgroundView()
        }
    }
}
