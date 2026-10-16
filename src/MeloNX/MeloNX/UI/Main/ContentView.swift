//
//  ContentView.swift
//  Candela
//
//  Created by Stossy11 on 4/4/2026.
//

import SwiftUI
import MetalKit
import Melo_Controller

struct EnvironmentVariable: Codable, Hashable {
    let string: String
    var value: String
    
    func set() {
        setenv(string, value, 1)
    }
    
    static func set(_ env: EnvironmentVariable) {
        setenv(env.string, env.value, 1)
    }
}



struct ContentView: View {
    @EnvironmentObject var ryujinxController: RyujinxController
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject public var nativeSettingsManager = NativeSettingsManager.shared
    @StateObject var controllerManager: ControllerManager = .shared
    @State private var selectedTab: Tab = .games
    @Environment(\.appTheme) var theme
    
    var tabView: some View {
        TabView(selection: $selectedTab) {
            CandelaLibraryRootView()
                .toolbar(.hidden, for: .tabBar)
                .tabItem { Label("Library", systemImage: "gamecontroller.fill") }
                .tag(Tab.games)

            CandelaProfileView(games: ryujinxController.games, showsDoneButton: false)
                .toolbar(.hidden, for: .tabBar)
                .tabItem { Label("Profile", systemImage: "person.crop.circle.fill") }
                .tag(Tab.profile)

            SettingsView()
                .toolbar(.hidden, for: .tabBar)
                .tabItem { Label("Settings", systemImage: "gear") }
                .tag(Tab.settings)
        }
        .toolbar(.hidden, for: .tabBar)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            CandelaFloatingTabBar(selection: $selectedTab)
                .padding(.horizontal, 25)
                .padding(.top, 5)
                .padding(.bottom, 6)
        }
        .accentColor(theme.accent.primary)
        .onAppear { NativeSettingsManager.setShared() }
        .task {
            ryujinxController.loadConfig()

            if ryujinxController.lastGameLaunched == nil {
                EnableJIT.enableJIT(nativeSettingsManager.jitProvider(JITProvider.disabled).value)
            }
            
            _ = ryujinxController.attemptToMapDualMapping()
            
            ryujinxController.loadGames()
            
            try? await Task.sleep(nanoseconds: 100_000_000)
            
            controllerManager.initAll()
            
            MetalViewRepresentable.createView()
            
            AlertHandlers.register()
            
            Air.play(AnyView(AirplayView().environmentObject(ryujinxController)))
            
            try? await Task.sleep(nanoseconds: 500_000_000)
            
            if let gameId = ryujinxController.lastGameLaunched, let game = ryujinxController.games.first(where: { $0.titleId == gameId }) {
                ryujinxController.startGame(game)
            } else {
                ryujinxController.lastGameLaunched = nil
            }
        }
    }
    
    @ViewBuilder
    func emulationView(game: GameInfo, state: StartedState) -> some View {
        switch state {
        case .none:
            EmulationView(game: game)
        case .entitlement:
            ControllerView(controller: VirtualControllerManager.shared, isEditing: false)
                .allowsHitTesting(false)
                .frame(width: .infinity, height: .infinity)
                .alert(isPresented: .constant(ryujinxController.isRunning.isEntitlement())) {
                    Alert(
                        title: Text("Entitlement"),
                        message: Text(LocalizedStringKey("Candela **REQUIRES** the Increased Memory Limit entitlement, Please follow the instructions on how to Install Candela and Enable the Entitlement.")),
                        primaryButton: .default(Text("Instructions")) {
                            UIApplication.shared.open(
                                URL(string: "https://github.com/gavin02031/VortexClub/tree/perf/iphone15-first-batch#installing")!,
                                options: [:],
                                completionHandler: nil
                            )
                            ryujinxController.isRunning = .stopped
                        },
                        secondaryButton: .cancel(Text("Cancel")) {
                            ryujinxController.isRunning = .stopped
                        }
                    )
                }
        case .noJIT:
            NoJITView(game: game)
                .onAppear() {
                    Air.play(AnyView(NoJITView(game: game).environmentObject(ryujinxController)))
                }
                .onDisappear() {
                    if case .started(game: _, state: let state) = ryujinxController.isRunning {
                        switch state {
                        case .entitlement, .extendedEntitlement:
                            Air.play(AnyView(EmptyView()))
                        case .usersList:
                            Air.play(AnyView(EmptyView()))
                        default: break
                        }
                    } else {
                        Air.play(AnyView(AirplayView().environmentObject(ryujinxController)))
                    }
                }
        case .extendedEntitlement:
            ControllerView(controller: VirtualControllerManager.shared, isEditing: false)
                .allowsHitTesting(false)
                .frame(width: .infinity, height: .infinity)
                .alert(isPresented: .constant(ryujinxController.isRunning.isEntitlement())) {
                    Alert(
                        title: Text("Extended Virtual Addressing"),
                        message: Text(LocalizedStringKey("The Extended Virtual Addressing entitlement is required for your device, Please read the Information on how to Install Candela and Enable the **PAID** Entitlement.")),
                        primaryButton: .default(Text("Information")) {
                            UIApplication.shared.open(
                                URL(string: "https://github.com/gavin02031/Candela#entitlements")!,
                                options: [:],
                                completionHandler: nil
                            )
                            ryujinxController.isRunning = .stopped
                        },
                        secondaryButton: .cancel(Text("Cancel")) {
                            ryujinxController.isRunning = .stopped
                        }
                    )
                }
        case .usersList:
            EmptyView() // TODO: Finish eventually™
        }
    }
    
    var body: some View {
        Group {
            switch ryujinxController.isRunning {
            case .stopped:
                tabView
            case .started(game: let game, state: let state):
                emulationView(game: game, state: state)
            case .crashed(result: let crashed):
                tabView
                    .alert(isPresented: .constant(ryujinxController.isRunning.hasCrashed())) {
                        Alert(
                            title: Text("Candela Crashed!"),
                            message: Text(verbatim: "Candela crashed with result: \(crashed)" + CandelaLogTools.crashDetail()),
                            primaryButton: .default(Text("Share log")) {
                                CandelaLogTools.share()
                                ryujinxController.isRunning = .stopped
                            },
                            secondaryButton: .cancel(Text("Close")) {
                                ryujinxController.isRunning = .stopped
                            }
                        )
                    }
            }
        }

    }
}





/// A lightweight, native-feeling replacement for the standard tab bar. Only
/// Candela's launcher uses it; gameplay and the emulation hierarchy are unchanged.
private struct CandelaFloatingTabBar: View {
    @Environment(\.appTheme) private var appTheme
    @Binding var selection: Tab
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var palette: CandelaPalette { CandelaPalette(dark: appTheme.isDark) }

    var body: some View {
        HStack(spacing: 5) {
            item(.games, title: "Library", symbol: "gamecontroller.fill")
            item(.profile, title: "Profile", symbol: "person.crop.circle.fill")
            item(.settings, title: "Settings", symbol: "gearshape.fill")
        }
        .padding(6)
        .background(
            Capsule(style: .continuous)
                .fill(.regularMaterial)
                .overlay {
                    Capsule(style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    palette.card.opacity(scheme == .dark ? 0.30 : 0.60),
                                    palette.skySoft.opacity(0.17)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
        )
        .overlay {
            Capsule(style: .continuous)
                .strokeBorder(scheme == .dark ? Color.white.opacity(0.17) : Color.white.opacity(0.85),
                              lineWidth: 1.4)
        }
        .shadow(color: palette.rose.opacity(scheme == .dark ? 0.05 : 0.18), radius: 18, y: 6)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Candela navigation")
    }

    private func item(_ tab: Tab, title: String, symbol: String) -> some View {
        let active = selection == tab
        return Button {
            if reduceMotion {
                selection = tab
            } else {
                withAnimation(.easeInOut(duration: 0.19)) { selection = tab }
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: symbol)
                    .font(.system(size: 21, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                Text(title)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.78)
                    .lineLimit(1)
            }
            .foregroundStyle(active ? palette.ink : palette.inkSoft)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 56)
            .padding(.horizontal, 4)
            .background {
                if active {
                    Capsule(style: .continuous)
                        .fill(
                            LinearGradient(colors: [
                                palette.roseSoft.opacity(0.78),
                                palette.skySoft.opacity(0.63)
                            ], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .overlay {
                            Capsule(style: .continuous)
                                .strokeBorder(Color.white.opacity(0.62), lineWidth: 0.9)
                        }
                }
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(active ? [.isSelected] : [])
    }
}

#Preview {
    ContentView()
}
