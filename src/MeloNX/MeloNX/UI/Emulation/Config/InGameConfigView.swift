//
//  InGameConfigView.swift
//  Candela
//
//  Created by Stossy11 on 7/7/2026.
//

import SwiftUI
import Melo_Controller
import Combine

class InGameConfigView_MenuView: ObservableObject {
    @Published var hideTask: Task<Void, Never>? = nil
    @Published var showButton: Bool = false
    
    static var shared: InGameConfigView_MenuView = .init()
    
    func triggerButton() {
        hideTask?.cancel()
        
        showButton = true
        
        hideTask = Task {
            try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
            if !Task.isCancelled {
                showButton = false
            }
        }
    }
}

struct InGameConfigView: View {
    @EnvironmentObject var ryujinxController: RyujinxController
    @ObservedObject var controllerManager: ControllerManager = .shared
    @StateObject var menuViewHandler: InGameConfigView_MenuView = .shared
    @State var rotationlock: Bool = false
    @State var showingKeyboardConfig: Bool = false
    @State var showControllerSettings: Bool = false
    @State private var showLeaveConfirm = false
    

    
    var body: some View {
        HStack(spacing: 0) {
            // The exit control now lives in CandelaLeaveButton, drawn above the on-screen controller.
            Color.clear.frame(width: 60, height: 40)
            gameMenu
        }
        .onReceive(NotificationCenter.default.publisher(for: .candelaLeaveRequest)) { _ in leaveGame() }
        .confirmationDialog("Leave game?", isPresented: $showLeaveConfirm, titleVisibility: .visible) {
            Button("Leave game", role: .destructive) { leaveGame() }
            Button("Keep playing", role: .cancel) { }
        } message: {
            Text("Progress since your last in-game save will be lost.")
        }
    }

    private func leaveGame() {
        ryujinxController.requestLeaveGame()
    }

    private var homeButton: some View {
        Button {
            menuViewHandler.triggerButton()
            showLeaveConfirm = true
        } label: {
            Image(systemName: "house.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(Circle().fill(Color.black.opacity(0.35)))
        }
        .padding(.leading)
        .opacity(menuViewHandler.showButton ? 1 : 0.55)
        .animation(.easeInOut(duration: 0.6), value: menuViewHandler.showButton)
    }

    private var gameMenu: some View {
        Menu {
            menuButton
        } label: {
            ButtonView(controller: VirtualControllerManager.shared, disabled: true, button: .guide, opacity: 0.4)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .padding()
        .opacity(menuViewHandler.showButton ? 1 : 0)
        .animation(.easeInOut(duration: 0.6), value: menuViewHandler.showButton)
        .sheet(isPresented: $showControllerSettings) {
            controllerSelection
        }
    }
    
    
    @ViewBuilder
    private var menuButton: some View {
        Button {
            ryujinxController.isPaused.toggle()
            ryujinxController.wasManuallyPaused = ryujinxController.isPaused
        } label: {
            Label {
                Text(ryujinxController.isPaused ? "Play" : "Pause")
            } icon: {
                Image(systemName: ryujinxController.isPaused ? "play.circle" : "pause.circle")
            }
        }
        
        Button {
            showControllerSettings = true
        } label: {
            Label {
                Text("Configure Controllers")
            } icon: {
                Image(systemName: "gamecontroller")
            }
        }
        
        if UIDevice.current.userInterfaceIdiom == .phone {
            Button {
                rotationlock.toggle()
                if rotationlock {
                    OrientationManager.lockCurrentOrientation(UIDevice.current.orientation)
                } else {
                    OrientationManager.lockOrientation(.all, rotateTo: UIDevice.current.orientation)
                }
            } label: {
                Label {
                    Text("Rotation Lock")
                } icon: {
                    Image(systemName: rotationlock ? "lock" : "lock.open")
                }
            }
        }
        
        
        Button(role: .destructive) {
            showLeaveConfirm = true
        } label: {
            Label {
                Text("Leave game")
            } icon: {
                Image(systemName: "x.circle")
            }
        }
         
    }
    
    @ViewBuilder
    private var controllerSelection: some View {
        List {
            Section("Controller Selection") {
                if controllerManager.selectedControllers.isEmpty {
                    Text("No controllers selected, keyboard will be used")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(Array(controllerManager.resolvedSelection.enumerated()), id: \.offset) { index, entry in
                        ControllerRow(index: index, controllerId: entry.id, controllerManager: controllerManager)
                    }
                }
                if hasAvailableControllers {
                    Menu {
                        ForEach(controllerManager.allControllers.filter {
                            !contains(controllerManager.selectedControllers, value: $0)
                        }) { controller in
                            Button(controller.name) {
                                controllerManager.selectedControllers.append(controller.id)
                            }
                        }
                    } label: {
                        Label("Add Controller", systemImage: "plus.circle.fill")
                    }
                }
            }
            
            
            if controllerManager.selectedControllers.isEmpty {
                Section {
                    Button("Map Keyboard") {
                        showingKeyboardConfig = true
                    }
                    .sheet(isPresented: $showingKeyboardConfig) {
                        KeyboardConfigView()
                    }
                }
            }
        }
        .padding(.top)
        .onAppear {
            controllerManager.refreshControllersList()
        }
        .onDisappear {
            controllerManager.refreshControllersList(true)
        }
    }
    
    private var hasAvailableControllers: Bool {
        !ControllerManager.shared.allControllers
            .filter { !contains(ControllerManager.shared.selectedControllers, value: $0) }
            .isEmpty
    }
    
    func contains(_ array: [String], value: BaseController) -> Bool {
        array.contains { $0 == value.id }
    }
}
