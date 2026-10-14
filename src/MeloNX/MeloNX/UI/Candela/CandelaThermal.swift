// SPDX-License-Identifier: AGPL-3.0-or-later
// Thermal governor. When the phone reports serious or critical heat during a session, Candela shows a small
// pill and lowers the render resolution one step for the next launch. Resolution cannot be changed safely while
// a game is running, so the step-down applies at launch. Steps fade after a few cool hours and can be reset.
import SwiftUI
import Combine

@MainActor
final class CandelaThermal: ObservableObject {
    static let shared = CandelaThermal()

    @Published private(set) var state: ProcessInfo.ThermalState = ProcessInfo.processInfo.thermalState
    @Published private(set) var escalatedThisSession = false

    private let enabledKey = "candela.thermalAuto"
    private let stepKey = "candela.thermalStep"
    private let stampKey = "candela.thermalStamp"
    private var inSession = false

    var enabled: Bool {
        get { UserDefaults.standard.object(forKey: enabledKey) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: enabledKey); objectWillChange.send() }
    }

    var step: Int {
        get { UserDefaults.standard.integer(forKey: stepKey) }
        set { UserDefaults.standard.set(max(0, min(2, newValue)), forKey: stepKey); objectWillChange.send() }
    }

    private init() {
        NotificationCenter.default.addObserver(forName: ProcessInfo.thermalStateDidChangeNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.thermalChanged() }
        }
    }

    /// Call right before a game starts. Fades old step-downs and returns the scale to use.
    func beginSession(scale: Float) -> Float {
        inSession = true
        escalatedThisSession = false
        state = ProcessInfo.processInfo.thermalState
        let stamp = UserDefaults.standard.double(forKey: stampKey)
        if step > 0, state == .nominal, Date().timeIntervalSince1970 - stamp > 6 * 3600 {
            step -= 1
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: stampKey)
        }
        guard enabled, step > 0 else { return scale }
        return max(0.5, scale * Float(pow(0.85, Double(step))))
    }

    func endSession() { inSession = false }

    func reset() { step = 0 }

    private func thermalChanged() {
        state = ProcessInfo.processInfo.thermalState
        guard inSession, enabled, !escalatedThisSession else { return }
        if state == .serious || state == .critical {
            escalatedThisSession = true
            step += 1
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: stampKey)
        }
    }
}

/// Small pill shown at the top of the game while the phone is running hot.
struct CandelaThermalPill: View {
    @ObservedObject private var thermal = CandelaThermal.shared

    var body: some View {
        if thermal.enabled, thermal.state == .serious || thermal.state == .critical {
            HStack(spacing: 6) {
                Image(systemName: "thermometer.medium")
                Text(thermal.state == .critical ? "Very warm - cooling down" : "Running warm")
                    .font(.footnote.weight(.semibold))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial, in: Capsule())
            .padding(.top, 8)
            .allowsHitTesting(false)
            .transition(.opacity)
        }
    }
}

/// Settings rows for the governor.
struct CandelaThermalSettingsRows: View {
    @ObservedObject private var thermal = CandelaThermal.shared

    var body: some View {
        Toggle(isOn: Binding(get: { thermal.enabled }, set: { thermal.enabled = $0 })) {
            Label("Thermal governor", systemImage: "thermometer.medium")
        }
        Text("When the phone runs hot, lowers the render resolution a step at the next launch. Currently \(thermal.step) of 2 steps.")
            .font(.footnote)
            .foregroundStyle(.secondary)
        if thermal.step > 0 {
            Button { thermal.reset() } label: {
                Label("Reset cooling steps", systemImage: "arrow.counterclockwise")
            }
        }
    }
}
