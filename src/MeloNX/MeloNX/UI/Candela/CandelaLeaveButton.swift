//
//  CandelaLeaveButton.swift
//  Candela
//
//  One dedicated in-game exit control for touch. It is drawn above the on-screen
//  controller (so the controller can never swallow the tap), always visible, and
//  works with a single tap: tap, then confirm. It does not depend on the
//  "Menu Button (in-game)" setting or on the auto-hiding menu.
//

import SwiftUI

struct CandelaLeaveButton: View {
    @EnvironmentObject var ryujinxController: RyujinxController
    @State private var confirming = false

    var body: some View {
        Button {
            confirming = true
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(Circle().fill(Color.black.opacity(0.45)))
                .overlay(Circle().stroke(Color.white.opacity(0.35), lineWidth: 1))
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .opacity(0.7)
        .padding(.leading, 12)
        .padding(.top, 8)
        .accessibilityLabel("Leave game")
        .confirmationDialog("Leave game?", isPresented: $confirming, titleVisibility: .visible) {
            Button("Leave game", role: .destructive) { leave() }
            Button("Keep playing", role: .cancel) { }
        } message: {
            Text("Progress since your last in-game save will be lost.")
        }
    }

    private func leave() {
        Ryujinx.stopEmulation()
        Ryujinx.emulationView = nil
        CandelaThermal.shared.endSession()
        ryujinxController.isRunning = .stopped
    }
}
