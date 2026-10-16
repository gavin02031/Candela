//
//  EmulationView.swift
//  Candela
//
//  Created by Stossy11 on 23/4/2026.
//

import SwiftUI
import Melo_Controller
import Combine

struct EmulationView: View {
    init(game: GameInfo) { self.game = game }

    var game: GameInfo
    @EnvironmentObject var ryujinxController: RyujinxController
    @ObservedObject var menuViewHandler: InGameConfigView_MenuView = .shared
    @StateObject var controllerManager: ControllerManager = .shared
    @StateObject var statisticsHandler: StatisticsHandler = .init()
    @StateObject private var nativeSettingsManager: NativeSettingsManager = .shared
    @StateObject private var libraryStats = CandelaLibraryStore.shared
    @Environment(\.scenePhase) private var scenePhase
    private var air = Air.shared
    
    @State var isConnected = false
    @State private var achievementToastVisible = false
    @ObservedObject private var achievements = CandelaAchievements.shared
    
    @ViewBuilder
    func emulationView(_ airplay: Bool = false) -> some View {
        if airplay { MetalViewRepresentable(showView: true).ignoresSafeArea().frame(maxWidth: .infinity, maxHeight: .infinity) } else {
            MetalViewContainer(showView: !isConnected, airplay: airplay, ryujinxController: ryujinxController, statisticsHandler: statisticsHandler, nativeSettingsManager: nativeSettingsManager)
                .overlay {
                    if controllerManager.hasVirtualController() && !airplay {
                        CandelaGameControllerView(game: game, isEditing: false)
                            .opacity(nativeSettingsManager.setting(forKey: "On-ScreenControllerOpacity", default: 1.0).value)
                            .ignoresSafeArea(.all, edges: .vertical)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    var body: some View {
        Group {
            emulationView()
                .overlay(alignment: .top) { CandelaThermalPill() }
                .overlay(alignment: .topLeading) { CandelaLeaveButton() }
                .overlay(alignment: .topTrailing) {
                    if achievementToastVisible {
                        CandelaAchievementToast()
                            .padding(.top, 48)
                            .padding(.trailing, 12)
                            .allowsHitTesting(false)
                            .zIndex(20)
                    }
                }
                .onReceive(achievements.$recentUnlock) { achievement in
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.84)) {
                        achievementToastVisible = achievement != nil
                    }
                }
                .overlay {
                    if ryujinxController.isStopping {
                        ZStack {
                            Color.black.opacity(0.60).ignoresSafeArea()
                            VStack(spacing: 16) {
                                ProgressView()
                                    .tint(.white)
                                    .scaleEffect(1.3)
                                Text("Leaving game…")
                                    .font(.system(.headline, design: .rounded).weight(.bold))
                                Text(ryujinxController.shutdownTakingLong
                                     ? "Shutdown is taking longer than expected. Please share the latest Candela log."
                                     : "Finishing emulator cleanup")
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 24)
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.76))
                            }
                            .foregroundStyle(.white)
                        }
                        .accessibilityLabel("Leaving game, please wait")
                    }
                }
                .onAppear() {
                    achievements.beginSession(gameID: game.titleId)
                    libraryStats.startSession(game)
                    if scenePhase != .active { libraryStats.pauseSession() }
                    statisticsHandler.registerPush()
                    
                    self.isConnected = Air.shared.connected
                    Air.shared.connectionCallbacks.append { self.isConnected = $0 }
                    
                    Air.play(AnyView(emulationView(true)))
                }
                .onDisappear {
                    libraryStats.endSession()
                    achievements.endSession()
                }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active { libraryStats.resumeSession() }
                    else { libraryStats.pauseSession() }
                }
                .onChange(of: ryujinxController.isStopping) { _, stopping in
                    if stopping { libraryStats.pauseSession() }
                }
                .if(!statisticsHandler.started) { view in
                    view
                        .overlay {
                            LoadingOverlayView(game:  game, showLogs: false)
                                .onDisappear() {
                                    menuViewHandler.triggerButton()
                                }
                        }
                }
        }
    }
}
