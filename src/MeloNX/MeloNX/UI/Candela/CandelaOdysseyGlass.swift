// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Candela V2 · Odyssey Glass Controls
// A lightweight, UIKit-backed input surface with SwiftUI artwork. No changes to
// MeloNX, Melo-Controller, signing, title settings, or Xcode project structure.
import Foundation
import SwiftUI
import UIKit
import Combine
import Melo_Controller

private enum OdysseyGlassKey: String, CaseIterable, Identifiable {
    case stick, rightStick, zl, l, zr, r, throwHat, capture, dive, jump, map, pause, snapshot
    case a, b, x, y
    var id: String { rawValue }

    var label: String {
        switch self {
        case .stick: return "Move"
        case .rightStick: return "Camera"
        case .zl: return "ZL"
        case .l: return "L"
        case .zr: return "ZR"
        case .r: return "R"
        case .throwHat: return "Throw"
        case .capture: return "Capture"
        case .dive: return "Dive / Roll"
        case .jump: return "Jump"
        case .map: return "Map"
        case .pause: return "Pause"
        case .snapshot: return "Snapshot"
        case .a: return "A"
        case .b: return "B"
        case .x: return "X"
        case .y: return "Y"
        }
    }

    var symbol: String {
        switch self {
        case .stick, .rightStick: return "circle.fill"
        case .throwHat: return "arrow.triangle.2.circlepath"
        case .capture: return "sparkles"
        case .dive: return "arrow.down.forward.and.arrow.up.backward"
        case .jump: return "figure.run"
        case .map: return "safari.fill"
        case .pause: return "pause.fill"
        case .snapshot: return "camera.fill"
        case .a, .b, .x, .y: return ""
        case .zl, .l, .zr, .r: return ""
        }
    }

    var isStick: Bool { self == .stick || self == .rightStick }
    var isMenuButton: Bool { self == .a || self == .b || self == .x || self == .y }
    var isShoulder: Bool { self == .zl || self == .l || self == .zr || self == .r }
    var isUtility: Bool { self == .map || self == .pause || self == .snapshot }

    var baseWidth: CGFloat {
        switch self {
        case .stick: return 158
        case .rightStick: return 105
        case .jump: return 114
        case .capture: return 93
        case .throwHat, .dive: return 86
        case .zl, .l, .zr, .r: return 78
        case .map, .pause, .snapshot: return 49
        case .a, .b, .x, .y: return 40
        }
    }
    var baseHeight: CGFloat { isShoulder ? 45 : baseWidth }

    var buttons: [VirtualControllerButton] {
        switch self {
        case .zl: return [.leftTrigger]
        case .l: return [.leftShoulder]
        case .zr: return [.rightTrigger]
        case .r: return [.rightShoulder]
        case .throwHat, .capture: return [.Y]
        case .dive: return [.leftTrigger, .Y]
        case .jump: return [.B]
        case .map: return [.back]
        case .pause: return [.start]
        case .snapshot: return [.dPadDown]
        case .a: return [.A]
        case .b: return [.B]
        case .x: return [.X]
        case .y: return [.Y]
        case .stick, .rightStick: return []
        }
    }
}

private struct OdysseyGlassPoint: Codable {
    var x: Double
    var y: Double
}

private struct OdysseyGlassProfile: Codable {
    var version: Int = 1
    var points: [String: OdysseyGlassPoint] = [:]
    var scales: [String: Double] = [:]
    var opacity: Double = 0.88
    var showCameraStick: Bool = false
    // Optional for backwards-compatible decoding of previously saved V2 layouts.
    var showMenuABXY: Bool? = nil

    static let standard: OdysseyGlassProfile = {
        var p = OdysseyGlassProfile()
        // Portrait layout uses the original Melo-Controller editor; these are
        // normalized landscape positions for iPhone.
        let positions: [(OdysseyGlassKey, Double, Double)] = [
            (.stick, 0.145, 0.73),
            (.rightStick, 0.60, 0.78),
            (.zl, 0.085, 0.25), (.l, 0.085, 0.37),
            (.zr, 0.917, 0.25), (.r, 0.917, 0.355),
            (.throwHat, 0.773, 0.595),
            (.capture, 0.901, 0.54),
            (.dive, 0.748, 0.815),
            (.jump, 0.901, 0.84),
            (.map, 0.79, 0.103),
            (.pause, 0.865, 0.103),
            (.snapshot, 0.94, 0.103),
            (.y, 0.425, 0.109), (.b, 0.475, 0.109),
            (.a, 0.525, 0.109), (.x, 0.575, 0.109)
        ]
        for (key, x, y) in positions {
            p.points[key.id] = OdysseyGlassPoint(x: x, y: y)
        }
        return p
    }()

    func point(for key: OdysseyGlassKey) -> OdysseyGlassPoint {
        points[key.id] ?? Self.standard.points[key.id] ?? OdysseyGlassPoint(x: 0.5, y: 0.5)
    }
    func scale(for key: OdysseyGlassKey) -> Double {
        min(1.4, max(0.65, scales[key.id] ?? 1))
    }

    func normalized() -> OdysseyGlassProfile {
        var clean = self
        clean.version = 1
        clean.opacity = clean.opacity.isFinite ? min(1, max(0.35, clean.opacity)) : 0.88
        clean.points = [:]
        clean.scales = [:]
        for key in OdysseyGlassKey.allCases {
            let point = self.point(for: key)
            let fallback = Self.standard.point(for: key)
            clean.points[key.id] = OdysseyGlassPoint(
                x: point.x.isFinite ? min(0.98, max(0.02, point.x)) : fallback.x,
                y: point.y.isFinite ? min(0.98, max(0.02, point.y)) : fallback.y
            )
            clean.scales[key.id] = self.scale(for: key)
        }
        return clean
    }
}

private enum OdysseyGlassStorage {
    static func key(_ titleID: String) -> String {
        "candela.touchstudio.odyssey.glass.v2." +
            (titleID.isEmpty ? "odyssey" : titleID)
    }
    static func load(_ titleID: String) -> OdysseyGlassProfile {
        guard let data = UserDefaults.standard.data(forKey: key(titleID)),
              let decoded = try? JSONDecoder().decode(OdysseyGlassProfile.self, from: data),
              decoded.version == 1 else { return .standard }
        return decoded.normalized()
    }
    static func save(_ profile: OdysseyGlassProfile, titleID: String) {
        guard let data = try? JSONEncoder().encode(profile.normalized()) else { return }
        UserDefaults.standard.set(data, forKey: key(titleID))
    }
}

/// Tracks sources separately so releasing Capture doesn't accidentally release
/// Throw or a separately held ZL trigger. Multi-button combos are reference-counted.
@MainActor
private final class OdysseyGlassInput {
    private var held: [OdysseyGlassKey: [VirtualControllerButton]] = [:]
    private var counts: [String: Int] = [:]
    private var activeLeft = false
    private var activeRight = false

    func down(_ key: OdysseyGlassKey) {
        guard held[key] == nil, !key.isStick else { return }
        let buttons = key.buttons
        held[key] = buttons
        for button in buttons {
            let prior = counts[button.id, default: 0]
            counts[button.id] = prior + 1
            if prior == 0 { VirtualControllerManager.shared.buttonPressed(button) }
        }
    }

    func up(_ key: OdysseyGlassKey) {
        guard let buttons = held.removeValue(forKey: key) else { return }
        for button in buttons {
            let remaining = max(0, counts[button.id, default: 0] - 1)
            if remaining == 0 {
                counts.removeValue(forKey: button.id)
                VirtualControllerManager.shared.buttonReleased(button)
            } else {
                counts[button.id] = remaining
            }
        }
    }

    func move(_ point: CGPoint, right: Bool) {
        if right { activeRight = true } else { activeLeft = true }
        VirtualControllerManager.shared.joystickMoved(position: point, right: right)
    }

    func releaseAll() {
        for key in Array(held.keys) { up(key) }
        if activeLeft {
            VirtualControllerManager.shared.joystickMoved(position: .zero, right: false)
            activeLeft = false
        }
        if activeRight {
            VirtualControllerManager.shared.joystickMoved(position: .zero, right: true)
            activeRight = false
        }
    }
}

/// Individual UIKit hit targets, rather than one full-screen gesture, keep
/// multitouch responsive and allow uncovered parts of MetalView to receive taps.
private final class OdysseyGlassPressView: UIView {
    var down: (() -> Void)?
    var up: (() -> Void)?
    var circular = true
    private var heldTouches: Set<UITouch> = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isMultipleTouchEnabled = true
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear
        isMultipleTouchEnabled = true
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard circular else { return super.point(inside: point, with: event) }
        guard bounds.width > 0, bounds.height > 0 else { return false }
        let dx = (point.x - bounds.midX) / (bounds.width / 2)
        let dy = (point.y - bounds.midY) / (bounds.height / 2)
        return dx * dx + dy * dy <= 1
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let wasEmpty = heldTouches.isEmpty
        heldTouches.formUnion(touches)
        if wasEmpty && !heldTouches.isEmpty { down?() }
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        finish(touches)
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        finish(touches)
    }
    private func finish(_ touches: Set<UITouch>) {
        heldTouches.subtract(touches)
        if heldTouches.isEmpty { up?() }
    }
    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window == nil && !heldTouches.isEmpty {
            heldTouches.removeAll()
            up?()
        }
    }
}

private struct OdysseyGlassPressTarget: UIViewRepresentable {
    var circular: Bool
    let down: () -> Void
    let up: () -> Void

    func makeUIView(context: Context) -> OdysseyGlassPressView {
        let view = OdysseyGlassPressView(frame: .zero)
        configure(view)
        return view
    }
    func updateUIView(_ uiView: OdysseyGlassPressView, context: Context) {
        configure(uiView)
    }
    private func configure(_ view: OdysseyGlassPressView) {
        view.circular = circular
        view.down = down
        view.up = up
    }
}

/// A single finger owns each stick. UIKit coordinates match the upstream
/// Melo-Controller convention (positive Y is down; BaseController flips it).
private final class OdysseyGlassJoystickView: UIView {
    var onChange: ((CGPoint) -> Void)?
    private weak var activeTouch: UITouch?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isMultipleTouchEnabled = true
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear
        isMultipleTouchEnabled = true
    }
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let radius = min(bounds.width, bounds.height) / 2
        let dx = point.x - bounds.midX, dy = point.y - bounds.midY
        return radius > 0 && dx * dx + dy * dy <= radius * radius
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard activeTouch == nil, let touch = touches.first else { return }
        activeTouch = touch
        update(touch)
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let activeTouch, touches.contains(activeTouch) else { return }
        update(activeTouch)
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let activeTouch, touches.contains(activeTouch) else { return }
        reset()
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let activeTouch, touches.contains(activeTouch) else { return }
        reset()
    }
    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window == nil && activeTouch != nil { reset() }
    }
    private func reset() {
        activeTouch = nil
        onChange?(.zero)
    }
    private func update(_ touch: UITouch) {
        let position = touch.location(in: self)
        let radius = max(1, min(bounds.width, bounds.height) * 0.43)
        var dx = (position.x - bounds.midX) / radius
        var dy = (position.y - bounds.midY) / radius
        let length = hypot(dx, dy)
        if length > 1 { dx /= length; dy /= length }
        if length < 0.075 { dx = 0; dy = 0 }
        onChange?(CGPoint(x: dx, y: dy))
    }
}

private struct OdysseyGlassJoystickTarget: UIViewRepresentable {
    let onChange: (CGPoint) -> Void

    func makeUIView(context: Context) -> OdysseyGlassJoystickView {
        let view = OdysseyGlassJoystickView(frame: .zero)
        view.onChange = onChange
        return view
    }
    func updateUIView(_ view: OdysseyGlassJoystickView, context: Context) {
        view.onChange = onChange
    }
}

private struct OdysseyGlassArtwork: View {
    let kind: OdysseyGlassKey
    let size: CGSize
    let alpha: Double
    let pressed: Bool
    let thumb: CGPoint

    var body: some View {
        ZStack {
            if kind.isShoulder {
                RoundedRectangle(cornerRadius: size.height * 0.47, style: .continuous)
                    .fill(glass)
                    .overlay {
                        RoundedRectangle(cornerRadius: size.height * 0.47)
                            .strokeBorder(.white.opacity(0.82), lineWidth: 1.7)
                    }
                Text(kind.label)
                    .font(.system(size: size.height * 0.39, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.18), radius: 1)
            } else if kind.isStick {
                Circle()
                    .fill(glass)
                    .overlay(Circle().strokeBorder(.white.opacity(0.82), lineWidth: 2.8))
                Circle()
                    .strokeBorder(.white.opacity(0.28), lineWidth: 1.2)
                    .padding(size.width * 0.13)
                if kind == .stick {
                    Image(systemName: "arrowtriangle.up.fill")
                        .offset(y: -size.height * 0.36)
                    Image(systemName: "arrowtriangle.down.fill")
                        .offset(y: size.height * 0.36)
                    Image(systemName: "arrowtriangle.left.fill")
                        .offset(x: -size.width * 0.36)
                    Image(systemName: "arrowtriangle.right.fill")
                        .offset(x: size.width * 0.36)
                }
                Circle()
                    .fill(RadialGradient(colors: [.white.opacity(0.94), Color(candelaHex: 0xD8C3DD).opacity(0.84)],
                                         center: .topLeading, startRadius: 0, endRadius: size.width * 0.54))
                    .overlay(Circle().strokeBorder(.white.opacity(0.95), lineWidth: 2))
                    .frame(width: size.width * 0.48, height: size.height * 0.48)
                    .offset(x: thumb.x * size.width * 0.25,
                            y: thumb.y * size.height * 0.25)
                    .shadow(color: .black.opacity(0.15), radius: 6, y: 2)
            } else if kind.isMenuButton {
                Circle()
                    .fill(glass)
                    .overlay(Circle().strokeBorder(.white.opacity(0.92), lineWidth: 1.5))
                Text(kind.label)
                    .font(.system(size: size.height * 0.46, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.35), radius: 2)
            } else {
                Circle()
                    .fill(glass)
                    .overlay(Circle().strokeBorder(.white.opacity(0.88), lineWidth: 2.2))
                VStack(spacing: max(1, size.height * 0.035)) {
                    Image(systemName: kind.symbol)
                        .font(.system(size: kind.isUtility ? size.height * 0.38 : size.height * 0.29, weight: .bold))
                        .symbolRenderingMode(.hierarchical)
                    if !kind.isUtility {
                        Text(kind.label)
                            .font(.system(size: max(7, size.height * 0.135), weight: .semibold, design: .rounded))
                            .lineLimit(1)
                            .minimumScaleFactor(0.65)
                    }
                }
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.20), radius: 1)
                .padding(.horizontal, 2)
            }
        }
        .font(.system(size: max(6, size.width * 0.08), weight: .bold))
        .foregroundColor(.white.opacity(0.70))
        .frame(width: size.width, height: size.height)
        .shadow(color: Color(candelaHex: 0x593B57).opacity(0.24), radius: 6, y: 3)
        .scaleEffect(pressed ? 0.94 : 1)
        .opacity(alpha)
        .accessibilityLabel(kind.label)
    }

    private var glass: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(pressed ? 0.72 : 0.58),
                Color(candelaHex: 0xE7BED8).opacity(0.62),
                Color(candelaHex: 0xA45B71).opacity(0.67)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

private struct OdysseyGlassCanvas: View {
    @Binding var profile: OdysseyGlassProfile
    let editing: Bool
    let selected: OdysseyGlassKey
    var select: (OdysseyGlassKey) -> Void = { _ in }
    var save: () -> Void = {}
    @State private var input = OdysseyGlassInput()
    @State private var pressed: Set<OdysseyGlassKey> = []
    @State private var leftThumb: CGPoint = .zero
    @State private var rightThumb: CGPoint = .zero

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(OdysseyGlassKey.allCases) { key in
                    if (key != .rightStick || profile.showCameraStick)
                        && (!key.isMenuButton || key == .a || profile.showMenuABXY == true) {
                        let size = dimensions(for: key, in: geo.size)
                        let point = placement(for: key, size: size, in: geo.size)
                        if editing {
                            OdysseyGlassArtwork(kind: key, size: size, alpha: profile.opacity,
                                                pressed: selected == key,
                                                thumb: .zero)
                                .overlay {
                                    if selected == key {
                                        outline(for: key, size: size)
                                    }
                                }
                                .position(point)
                                .gesture(
                                    DragGesture(minimumDistance: 1, coordinateSpace: .named("candela-glass-canvas"))
                                        .onChanged { value in
                                            select(key)
                                            guard geo.size.width > 0, geo.size.height > 0 else { return }
                                            profile.points[key.id] = OdysseyGlassPoint(
                                                x: Double(min(0.98, max(0.02, value.location.x / geo.size.width))),
                                                y: Double(min(0.98, max(0.02, value.location.y / geo.size.height)))
                                            )
                                        }
                                        .onEnded { _ in save() }
                                )
                                .onTapGesture { select(key) }
                        } else if key.isStick {
                            OdysseyGlassArtwork(kind: key, size: size, alpha: profile.opacity,
                                                pressed: false,
                                                thumb: key == .stick ? leftThumb : rightThumb)
                                .overlay {
                                    OdysseyGlassJoystickTarget { point in
                                        if key == .stick { leftThumb = point } else { rightThumb = point }
                                        input.move(point, right: key == .rightStick)
                                    }
                                }
                                .position(point)
                        } else {
                            OdysseyGlassArtwork(kind: key, size: size, alpha: profile.opacity,
                                                pressed: pressed.contains(key), thumb: .zero)
                                .overlay {
                                    OdysseyGlassPressTarget(circular: !key.isShoulder) {
                                        pressed.insert(key)
                                        input.down(key)
                                    } up: {
                                        pressed.remove(key)
                                        input.up(key)
                                    }
                                }
                                .position(point)
                        }
                    }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .coordinateSpace(name: "candela-glass-canvas")
        }
        .onDisappear { input.releaseAll() }
    }

    private func outline(for key: OdysseyGlassKey, size: CGSize) -> some View {
        Group {
            if key.isShoulder {
                RoundedRectangle(cornerRadius: size.height / 2)
                    .strokeBorder(Color.white, style: StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
            } else {
                Circle().strokeBorder(Color.white, style: StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
            }
        }
        .padding(-3)
        .allowsHitTesting(false)
    }

    private func dimensions(for key: OdysseyGlassKey, in extent: CGSize) -> CGSize {
        let factor = min(1.15, max(0.32, min(extent.width / 852, extent.height / 393)))
        let custom = CGFloat(profile.scale(for: key))
        return CGSize(width: key.baseWidth * factor * custom,
                      height: key.baseHeight * factor * custom)
    }

    private func placement(for key: OdysseyGlassKey, size: CGSize, in extent: CGSize) -> CGPoint {
        let p = profile.point(for: key)
        return CGPoint(
            x: min(max(size.width / 2 + 2, CGFloat(p.x) * extent.width), extent.width - size.width / 2 - 2),
            y: min(max(size.height / 2 + 2, CGFloat(p.y) * extent.height), extent.height - size.height / 2 - 2)
        )
    }
}

struct CandelaOdysseyGlassOverlay: View {
    let gameId: String
    @State private var profile: OdysseyGlassProfile = .standard
    var body: some View {
        GeometryReader { geo in
            if geo.size.width > geo.size.height {
                OdysseyGlassCanvas(profile: $profile, editing: false, selected: .jump)
            } else {
                // No untested portrait glass layout; use established emulator input.
                ControllerView(controller: VirtualControllerManager.shared,
                               isEditing: false, gameId: gameId)
            }
        }
        .onAppear { profile = OdysseyGlassStorage.load(gameId) }
    }
}

struct CandelaOdysseyGlassEditor: View {
    let gameId: String
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @State private var profile: OdysseyGlassProfile = .standard
    @State private var selected: OdysseyGlassKey = .jump

    private func save() { OdysseyGlassStorage.save(profile, titleID: gameId) }
    private var palette: CandelaPalette { CandelaPalette(dark: scheme == .dark) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Odyssey Glass")
                            .font(.system(.title, design: .rounded).weight(.heavy))
                        Text("Drag controls to rearrange · tap one to resize")
                            .font(.caption)
                            .foregroundColor(palette.inkSoft)
                    }
                    Spacer()
                    Button("Done") { save(); dismiss() }
                        .buttonStyle(CandelaPrimaryButtonStyle())
                }

                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 23)
                        .fill(LinearGradient(colors: [
                            Color(candelaHex: 0x8F91C1),
                            Color(candelaHex: 0xDFAEC5),
                            Color(candelaHex: 0xC8E5DA)
                        ], startPoint: .topLeading, endPoint: .bottomTrailing))
                    OdysseyGlassCanvas(profile: $profile, editing: true, selected: selected,
                                        select: { selected = $0 }, save: save)
                        .padding(4)
                }
                .aspectRatio(852.0 / 393.0, contentMode: .fit)

                Text("Touch controls stay independent from Bluetooth controller mappings.")
                    .font(.caption)
                    .foregroundColor(palette.inkSoft)

                Toggle("Optional right camera stick", isOn: $profile.showCameraStick)
                    .tint(palette.rose)
                    .onChange(of: profile.showCameraStick) { _, _ in save() }
                Toggle("Show all A/B/X/Y menu buttons", isOn: Binding(
                    get: { profile.showMenuABXY == true },
                    set: { profile.showMenuABXY = $0; save() }
                ))
                .tint(palette.rose)
                Text("A is always visible near the top center for menu confirmations. Enable all four buttons whenever a game menu needs them.")
                    .font(.caption).foregroundColor(palette.inkSoft)

                HStack {
                    Text("Control")
                    Spacer()
                    Picker("Control", selection: $selected) {
                        ForEach(OdysseyGlassKey.allCases) { key in
                            Text(key.label).tag(key)
                        }
                    }
                    .tint(palette.rose)
                }

                HStack {
                    Text("Selected size")
                    Spacer()
                    Text(String(format: "%.0f%%", profile.scale(for: selected) * 100))
                        .foregroundColor(palette.inkSoft)
                }
                Slider(value: Binding(
                    get: { profile.scale(for: selected) },
                    set: { profile.scales[selected.id] = $0; save() }
                ), in: 0.65...1.4)
                .tint(palette.rose)

                HStack {
                    Text("Glass opacity")
                    Spacer()
                    Text(String(format: "%.0f%%", profile.opacity * 100))
                        .foregroundColor(palette.inkSoft)
                }
                Slider(value: $profile.opacity, in: 0.35...1, onEditingChanged: { editing in
                    if !editing { save() }
                })
                .tint(palette.rose)

                HStack(spacing: 12) {
                    Button("Reset glass layout") {
                        profile = .standard
                        save()
                    }
                    .buttonStyle(CandelaSecondaryButtonStyle())
                    Spacer()
                    Button("Save") { save() }
                        .buttonStyle(CandelaPrimaryButtonStyle())
                }

                Text("Throw and Capture both send the game's hat-throw input. Dive/Roll holds ZL + Y. Map uses Minus; Snapshot uses D-pad Down. Test these actions in-game before relying on them.")
                    .font(.caption)
                    .foregroundColor(palette.inkSoft)
                    .padding(.bottom, 40)
            }
            .foregroundColor(palette.ink)
            .padding(20)
        }
        .background(CandelaBackdrop(dark: scheme == .dark).ignoresSafeArea())
        .onAppear { profile = OdysseyGlassStorage.load(gameId) }
        .onDisappear { save() }
    }
}
