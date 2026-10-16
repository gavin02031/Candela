// SPDX-License-Identifier: AGPL-3.0-or-later
// Candela · Tomodachi Touch V2. Native-looking *controller* input for Living the Dream.
// Nintendo documents button-first gameplay, with real touch only in some Mii/Palette scenes.
// No game-state detection or fictional game commands; every bubble emits a Switch input.
import SwiftUI
import UIKit
import Combine
import Melo_Controller

enum TomodachiTouchPreset: String, CaseIterable, Codable, Identifiable {
    case casual, hybrid, classic
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var detail: String {
        switch self {
        case .casual: return "Minimal bubbles"
        case .hybrid: return "Stick + touch helpers"
        case .classic: return "Original controller"
        }
    }
}

enum TomodachiTouchMode: String, CaseIterable, Codable, Identifiable {
    case island, interaction, shop, activity, touchScene
    var id: String { rawValue }
    var title: String {
        switch self {
        case .island: return "Island"
        case .interaction: return "Interaction"
        case .shop: return "Shop"
        case .activity: return "Activity"
        case .touchScene: return "Touch scene"
        }
    }
    var symbol: String {
        switch self {
        case .island: return "map.fill"
        case .interaction: return "bubble.left.and.bubble.right.fill"
        case .shop: return "storefront.fill"
        case .activity: return "sparkles.rectangle.stack.fill"
        case .touchScene: return "hand.draw.fill"
        }
    }
    var hint: String {
        switch self {
        case .island: return "Navigate the island with real A/B/X/Y buttons."
        case .interaction: return "Select residents and use the game's own interaction menu."
        case .shop: return "Use A to select, B to back out, and the stick to browse."
        case .activity: return "Shows additional buttons for minigames and special scenes."
        case .touchScene: return "Clears the overlay for touch-supported Mii/Palette scenes."
        }
    }
}

enum TomodachiTouchKey: String, CaseIterable, Identifiable {
    case stick, cameraStick, a, b, x, y, plus, l, r, zl, zr, up, down, left, right
    var id: String { rawValue }
    var isStick: Bool { self == .stick || self == .cameraStick }
    var isDPad: Bool { self == .up || self == .down || self == .left || self == .right }
    var isShoulder: Bool { self == .l || self == .r || self == .zl || self == .zr }
    var button: VirtualControllerButton? {
        switch self {
        case .a: return .A
        case .b: return .B
        case .x: return .X
        case .y: return .Y
        case .plus: return .start
        case .l: return .leftShoulder
        case .r: return .rightShoulder
        case .zl: return .leftTrigger
        case .zr: return .rightTrigger
        case .up: return .dPadUp
        case .down: return .dPadDown
        case .left: return .dPadLeft
        case .right: return .dPadRight
        case .stick, .cameraStick: return nil
        }
    }
    var symbol: String {
        switch self {
        case .stick: return "circle.circle.fill"
        case .cameraStick: return "camera.metering.center.weighted"
        case .a: return "checkmark"
        case .b: return "arrow.uturn.backward"
        case .x: return "line.3.horizontal"
        case .y: return "arrow.up.right"
        case .plus: return "plus"
        case .l, .r, .zl, .zr: return ""
        case .up: return "arrowtriangle.up.fill"
        case .down: return "arrowtriangle.down.fill"
        case .left: return "arrowtriangle.left.fill"
        case .right: return "arrowtriangle.right.fill"
        }
    }
    func label(in mode: TomodachiTouchMode) -> String {
        switch self {
        case .stick: return "Move"
        case .cameraStick: return "Camera"
        case .a:
            switch mode {
            case .island: return "Select"
            case .interaction: return "Interact"
            case .shop: return "Select"
            case .activity: return "A"
            case .touchScene: return "A"
            }
        case .b: return "Back"
        case .x: return "Menu"
        case .y: return "Y"
        case .plus: return "Options"
        case .l: return "L"
        case .r: return "R"
        case .zl: return "ZL"
        case .zr: return "ZR"
        case .up: return "Up"
        case .down: return "Down"
        case .left: return "Left"
        case .right: return "Right"
        }
    }
    var tint: Color {
        switch self {
        case .a: return Color(candelaHex: 0x5DBEA6)
        case .b: return Color(candelaHex: 0xAE8ACD)
        case .x: return Color(candelaHex: 0xCE92BD)
        case .y: return Color(candelaHex: 0xEBA36F)
        case .plus: return Color(candelaHex: 0x8DCAD1)
        case .l, .r, .zl, .zr: return Color(candelaHex: 0xB9A2DD)
        default: return Color(candelaHex: 0xC2B4DD)
        }
    }
    var diameter: CGFloat {
        switch self {
        case .stick: return 148
        case .cameraStick: return 94
        case .a: return 84
        case .b: return 67
        case .x, .y: return 59
        case .plus: return 47
        case .l, .r, .zl, .zr: return 43
        case .up, .down, .left, .right: return 35
        }
    }
}

struct TomodachiTouchPoint: Codable {
    var x: Double
    var y: Double
}

struct TomodachiTouchLayout: Codable {
    var version = 2
    var preset: TomodachiTouchPreset = .hybrid
    var mode: TomodachiTouchMode = .island
    var opacity = 0.88
    var scale = 1.0
    var leftHanded = false
    var showLabels = true
    var showShoulders = false
    var showDPad = false
    var showCameraStick = false
    var focusMode = false
    var points: [String: TomodachiTouchPoint] = [:]

    static var standard: TomodachiTouchLayout {
        var item = TomodachiTouchLayout()
        let places: [(TomodachiTouchKey, Double, Double)] = [
            (.stick, 0.138, 0.745), (.cameraStick, 0.51, 0.80),
            (.a, 0.905, 0.56), (.b, 0.906, 0.77),
            (.x, 0.810, 0.59), (.y, 0.81, 0.79),
            (.plus, 0.895, 0.24),
            (.l, 0.21, 0.24), (.r, 0.72, 0.24),
            (.zl, 0.21, 0.39), (.zr, 0.72, 0.39),
            (.up, 0.36, 0.65), (.down, 0.36, 0.83),
            (.left, 0.315, 0.74), (.right, 0.405, 0.74)
        ]
        for (key, x, y) in places {
            item.points[key.rawValue] = TomodachiTouchPoint(x: x, y: y)
        }
        return item
    }

    func position(_ key: TomodachiTouchKey) -> TomodachiTouchPoint {
        let point = points[key.rawValue]
        return point ?? Self.standard.points[key.rawValue] ?? TomodachiTouchPoint(x: 0.5, y: 0.5)
    }

    func validated() -> TomodachiTouchLayout {
        var clean = self
        clean.version = 2
        clean.opacity = opacity.isFinite ? min(1, max(0.28, opacity)) : 0.88
        clean.scale = scale.isFinite ? min(1.30, max(0.67, scale)) : 1
        clean.points = [:]
        for control in TomodachiTouchKey.allCases {
            let value = position(control)
            let normal = Self.standard.position(control)
            clean.points[control.rawValue] = TomodachiTouchPoint(
                x: value.x.isFinite ? min(0.98, max(0.02, value.x)) : normal.x,
                y: value.y.isFinite ? min(0.98, max(0.02, value.y)) : normal.y
            )
        }
        return clean
    }

    func visible(_ control: TomodachiTouchKey, mode override: TomodachiTouchMode? = nil) -> Bool {
        let scene = override ?? mode
        if preset == .classic { return false }
        if scene == .touchScene { return control == .a || control == .b }
        if control == .stick { return preset == .hybrid }
        if control == .cameraStick { return preset == .hybrid && showCameraStick && !focusMode }
        if control.isShoulder { return (showShoulders || scene == .activity) && !focusMode }
        if control.isDPad { return (showDPad || scene == .activity) && !focusMode }
        if control == .x || control == .y { return !focusMode || scene == .activity }
        if control == .plus { return !focusMode }
        return true
    }
}

enum TomodachiTouchStorage {
    static func key(_ titleId: String) -> String {
        "candela.tomodachi.touch.layout.v2." + titleId
    }
    static func load(_ titleId: String) -> TomodachiTouchLayout {
        guard let data = UserDefaults.standard.data(forKey: key(titleId)),
              let value = try? JSONDecoder().decode(TomodachiTouchLayout.self, from: data),
              value.version == 2 else { return .standard }
        return value.validated()
    }
    static func save(_ value: TomodachiTouchLayout, id: String) {
        guard let data = try? JSONEncoder().encode(value.validated()) else { return }
        UserDefaults.standard.set(data, forKey: key(id))
    }
}

/// Mirrors Odyssey Glass's proven input mechanism. The input source is separate
/// from physical-controller mapping; button events go to the existing manager.
@MainActor
private final class TomodachiInput: ObservableObject {
    private var held: Set<TomodachiTouchKey> = []
    private var leftMoved = false
    private var rightMoved = false

    func press(_ key: TomodachiTouchKey) {
        guard let button = key.button, held.insert(key).inserted else { return }
        VirtualControllerManager.shared.buttonPressed(button)
    }
    func release(_ key: TomodachiTouchKey) {
        guard let button = key.button, held.remove(key) != nil else { return }
        VirtualControllerManager.shared.buttonReleased(button)
    }
    func move(_ point: CGPoint, camera: Bool) {
        if camera { rightMoved = true } else { leftMoved = true }
        VirtualControllerManager.shared.joystickMoved(position: point, right: camera)
    }
    func releaseAll() {
        for key in Array(held) { release(key) }
        if leftMoved {
            VirtualControllerManager.shared.joystickMoved(position: .zero, right: false)
            leftMoved = false
        }
        if rightMoved {
            VirtualControllerManager.shared.joystickMoved(position: .zero, right: true)
            rightMoved = false
        }
    }
}

private final class TomodachiPressArea: UIView {
    var began: (() -> Void)?
    var ended: (() -> Void)?
    private var touchesHeld: Set<UITouch> = []
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
        let halfWidth = max(1, bounds.width / 2), halfHeight = max(1, bounds.height / 2)
        let x = (point.x - bounds.midX) / halfWidth
        let y = (point.y - bounds.midY) / halfHeight
        return x*x + y*y <= 1
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let first = touchesHeld.isEmpty
        touchesHeld.formUnion(touches)
        if first && !touchesHeld.isEmpty { began?() }
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) { finish(touches) }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) { finish(touches) }
    private func finish(_ touches: Set<UITouch>) {
        touchesHeld.subtract(touches)
        if touchesHeld.isEmpty { ended?() }
    }
    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window == nil && !touchesHeld.isEmpty {
            touchesHeld.removeAll()
            ended?()
        }
    }
}

private struct TomodachiPressTarget: UIViewRepresentable {
    let began: () -> Void
    let ended: () -> Void
    func makeUIView(context: Context) -> TomodachiPressArea {
        let view = TomodachiPressArea(frame: .zero)
        view.began = began
        view.ended = ended
        return view
    }
    func updateUIView(_ uiView: TomodachiPressArea, context: Context) {
        uiView.began = began
        uiView.ended = ended
    }
}

private final class TomodachiAnalogArea: UIView {
    var onChange: ((CGPoint) -> Void)?
    private weak var tracked: UITouch?
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
        let r = min(bounds.width, bounds.height) / 2
        let dx = point.x - bounds.midX, dy = point.y - bounds.midY
        return r > 0 && dx*dx + dy*dy <= r*r
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard tracked == nil, let touch = touches.first else { return }
        tracked = touch
        update(touch)
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let tracked, touches.contains(tracked) else { return }
        update(tracked)
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let tracked, touches.contains(tracked) else { return }
        reset()
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let tracked, touches.contains(tracked) else { return }
        reset()
    }
    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window == nil && tracked != nil { reset() }
    }
    private func reset() {
        tracked = nil
        onChange?(.zero)
    }
    private func update(_ touch: UITouch) {
        let center = touch.location(in: self)
        let r = max(1, min(bounds.width, bounds.height) * 0.43)
        var dx = (center.x - bounds.midX) / r
        var dy = (center.y - bounds.midY) / r
        let length = hypot(dx, dy)
        if length > 1 { dx /= length; dy /= length }
        if length < 0.07 { dx = 0; dy = 0 }
        onChange?(CGPoint(x: dx, y: dy))
    }
}

private struct TomodachiAnalogTarget: UIViewRepresentable {
    let onChange: (CGPoint) -> Void
    func makeUIView(context: Context) -> TomodachiAnalogArea {
        let view = TomodachiAnalogArea(frame: .zero)
        view.onChange = onChange
        return view
    }
    func updateUIView(_ uiView: TomodachiAnalogArea, context: Context) {
        uiView.onChange = onChange
    }
}

/// Pastel glass game art without third-party textures or copyrighted assets.
private struct TomodachiBubble: View {
    let key: TomodachiTouchKey
    let mode: TomodachiTouchMode
    let size: CGFloat
    let opacity: Double
    let labels: Bool
    let pressed: Bool
    let thumb: CGPoint
    private var accent: Color { key.tint }

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(colors: [
                        .white.opacity(0.76),
                        accent.opacity(0.62),
                        Color(candelaHex: 0xFAE6F0).opacity(0.44)
                    ], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .overlay(Circle().strokeBorder(.white.opacity(0.88), lineWidth: 2.0))
            if key.isStick {
                Circle()
                    .strokeBorder(.white.opacity(0.37), lineWidth: 1.5)
                    .padding(size * 0.12)
                Circle()
                    .fill(RadialGradient(colors: [
                        Color.white.opacity(0.96), accent.opacity(0.57)
                    ], center: .topLeading, startRadius: 0, endRadius: size * 0.52))
                    .overlay(Circle().strokeBorder(.white.opacity(0.96), lineWidth: 2.0))
                    .frame(width: size * 0.46, height: size * 0.46)
                    .offset(x: thumb.x * size * 0.27, y: thumb.y * size * 0.27)
                    .shadow(color: .black.opacity(0.15), radius: 5, y: 3)
            } else {
                VStack(spacing: 2) {
                    Image(systemName: key.symbol)
                        .font(.system(size: size * (key.isShoulder ? 0.16 : 0.28),
                                      weight: .bold))
                        .frame(height: size * 0.30)
                    if labels && !key.isDPad {
                        Text(key.label(in: mode))
                            .font(.system(size: max(8, size * 0.14),
                                          weight: .bold, design: .rounded))
                            .minimumScaleFactor(0.58)
                            .lineLimit(1)
                    }
                }
                .foregroundColor(Color(candelaHex: 0x433956))
                .padding(.horizontal, 3)
            }
        }
        .frame(width: size, height: size)
        .shadow(color: accent.opacity(0.22), radius: 8, y: 4)
        .scaleEffect(pressed ? 0.94 : 1)
        .opacity(opacity)
        .accessibilityLabel("\(key.label(in: mode)), Switch \(key.rawValue.uppercased())")
    }
}

struct TomodachiTouchCanvas: View {
    @Binding var profile: TomodachiTouchLayout
    @Binding var mode: TomodachiTouchMode
    let isEditing: Bool
    let selected: TomodachiTouchKey
    let onSelect: (TomodachiTouchKey) -> Void
    let onSave: () -> Void

    @StateObject private var input = TomodachiInput()
    @Environment(\.scenePhase) private var scenePhase
    @State private var pressed: Set<TomodachiTouchKey> = []
    @State private var leftThumb: CGPoint = .zero
    @State private var rightThumb: CGPoint = .zero

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                ForEach(TomodachiTouchKey.allCases) { key in
                    if profile.visible(key, mode: mode) {
                        let dimension = diameter(key, in: geometry.size)
                        let location = position(key, radius: dimension / 2, canvas: geometry.size)
                        if isEditing {
                            TomodachiBubble(key: key, mode: mode, size: dimension,
                                            opacity: profile.opacity,
                                            labels: profile.showLabels, pressed: selected == key,
                                            thumb: .zero)
                                .overlay {
                                    if selected == key {
                                        Circle()
                                            .strokeBorder(Color(candelaHex: 0x8D5B9B),
                                                          style: StrokeStyle(lineWidth: 2, dash: [4, 3]))
                                            .padding(-3)
                                            .allowsHitTesting(false)
                                    }
                                }
                                .position(location)
                                .gesture(DragGesture(minimumDistance: 2,
                                                     coordinateSpace: .named("tomodachiTouch"))
                                    .onChanged { value in
                                        onSelect(key)
                                        guard geometry.size.width > 0, geometry.size.height > 0 else { return }
                                        profile.points[key.rawValue] = TomodachiTouchPoint(
                                            x: Double(min(0.98, max(0.02, value.location.x / geometry.size.width))),
                                            y: Double(min(0.98, max(0.02, value.location.y / geometry.size.height)))
                                        )
                                    }
                                    .onEnded { _ in onSave() })
                                .onTapGesture { onSelect(key) }
                        } else if key.isStick {
                            TomodachiBubble(key: key, mode: mode, size: dimension,
                                            opacity: profile.opacity,
                                            labels: profile.showLabels, pressed: false,
                                            thumb: key == .stick ? leftThumb : rightThumb)
                                .overlay {
                                    TomodachiAnalogTarget { position in
                                        if key == .stick { leftThumb = position }
                                        else { rightThumb = position }
                                        input.move(position, camera: key == .cameraStick)
                                    }
                                }
                                .position(location)
                        } else {
                            TomodachiBubble(key: key, mode: mode, size: dimension,
                                            opacity: profile.opacity,
                                            labels: profile.showLabels,
                                            pressed: pressed.contains(key), thumb: .zero)
                                .overlay {
                                    TomodachiPressTarget {
                                        pressed.insert(key)
                                        input.press(key)
                                    } ended: {
                                        pressed.remove(key)
                                        input.release(key)
                                    }
                                }
                                .position(location)
                        }
                    }
                }

                if !isEditing {
                    Menu {
                        ForEach(TomodachiTouchMode.allCases) { value in
                            Button {
                                input.releaseAll()
                                mode = value
                                profile.mode = value
                            } label: {
                                Label(value.title, systemImage: value.symbol)
                            }
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: mode.symbol)
                            Text(mode.title)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 9, weight: .bold))
                        }
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(Color(candelaHex: 0x453753))
                        .padding(.horizontal, 13)
                        .frame(height: 35)
                        .background(.regularMaterial, in: Capsule())
                        .overlay(Capsule().strokeBorder(.white.opacity(0.8), lineWidth: 1))
                    }
                    .position(x: geometry.size.width * 0.34,
                              y: geometry.size.height * 0.12)
                    .accessibilityLabel("Choose Tomodachi touch mode")
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .coordinateSpace(name: "tomodachiTouch")
        }
        .onDisappear { input.releaseAll() }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { input.releaseAll() }
        }
        .onChange(of: profile.preset) { _, _ in input.releaseAll() }
    }

    private func diameter(_ key: TomodachiTouchKey, in bounds: CGSize) -> CGFloat {
        let base = min(1.12, max(0.42, min(bounds.width / 852, bounds.height / 393)))
        return key.diameter * base * CGFloat(profile.scale)
    }
    private func position(_ key: TomodachiTouchKey, radius: CGFloat, canvas: CGSize) -> CGPoint {
        let p = profile.position(key)
        // Left-handed mode mirrors gameplay buttons, not the two analog sticks.
        let x = profile.leftHanded && !key.isStick ? 1 - p.x : p.x
        return CGPoint(
            x: min(max(radius + 2, CGFloat(x) * canvas.width), canvas.width - radius - 2),
            y: min(max(radius + 2, CGFloat(p.y) * canvas.height), canvas.height - radius - 2)
        )
    }
}

struct CandelaTomodachiTouchOverlay: View {
    let gameId: String
    let gameName: String
    @State private var profile = TomodachiTouchLayout.standard
    @State private var currentMode: TomodachiTouchMode = .island

    var body: some View {
        GeometryReader { bounds in
            if profile.preset == .classic || bounds.size.height >= bounds.size.width {
                ControllerView(controller: VirtualControllerManager.shared,
                               isEditing: false, gameId: gameId, gameName: gameName)
            } else {
                TomodachiTouchCanvas(profile: $profile, mode: $currentMode, isEditing: false,
                                     selected: .a, onSelect: { _ in },
                                     onSave: { TomodachiTouchStorage.save(profile, id: gameId) })
            }
        }
        .onAppear {
            profile = TomodachiTouchStorage.load(gameId)
            currentMode = profile.mode
        }
    }
}
