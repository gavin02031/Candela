// SPDX-License-Identifier: AGPL-3.0-or-later
// Settings home for iPhone. One rounded card per page, pill tabs on top, icon rows with a subtitle and a
// trailing control, and a floating Back pill on pushed pages. The older long forms are reached from "All ... options".
import SwiftUI

extension SettingsView {
    var candelaHub: some View {
        NavigationStack {
            CandelaSettingsDashboard(
                config: config,
                isJIT: ryujinxController.isJITEnabled,
                destination: { AnyView($0.sectionsView(for: self)) }
            )
            .navigationBarHidden(true)
        }
    }
}

enum CandelaHubTab: Hashable {
    case play, controls, system, library, more
}

private enum CandelaPlayStyle: String, CaseIterable, Identifiable {
    case cool = "Cool"
    case balanced = "Balanced"
    case sharp = "Bright"

    var id: String { rawValue }
    var scale: Float {
        switch self {
        case .cool: return 0.7
        case .balanced: return 0.85
        case .sharp: return 1.0
        }
    }
    var icon: String {
        switch self {
        case .cool: return "snowflake"
        case .balanced: return "scale.3d"
        case .sharp: return "sparkles"
        }
    }
    var blurb: String {
        switch self {
        case .cool: return "Less heat, softer picture"
        case .balanced: return "A bit of both"
        case .sharp: return "Sharpest picture, runs warmer"
        }
    }
}

struct CandelaHubScreen: View {
    @Environment(\.colorScheme) private var scheme
    @ObservedObject private var thermal = CandelaThermal.shared
    let config: Binding<Options>
    let isJIT: Bool
    let destination: (SettingsView.SettingsCategory) -> AnyView  // returns the sections for a category

    @State private var tab: CandelaHubTab = .play
    @AppStorage("candela.theme.style.v1") private var selectedTheme = CandelaThemeStyle.pastelDream.rawValue
    @AppStorage("candela.mvkPerf") private var mvkPerf = false
    @AppStorage("candela.expCompress") private var expCompress = false
    @AppStorage("candela.expPrefill") private var expPrefill = false
    @AppStorage("candela.expWorkers") private var expWorkers = false

    var body: some View {
        let p = CandelaPalette(dark: scheme == .dark)
        ZStack {
            CandelaBackdrop(dark: scheme == .dark).ignoresSafeArea()
            VStack(spacing: 14) {
                VStack(spacing: 14) {
                    statusPill
                    CandelaPillTabs(items: [
                        (CandelaHubTab.play, "Play", "flame.fill"),
                        (CandelaHubTab.controls, "Controls", "gamecontroller.fill"),
                        (CandelaHubTab.system, "System", "gearshape.fill"),
                        (CandelaHubTab.library, "Library", "square.grid.2x2.fill"),
                        (CandelaHubTab.more, "More", "ellipsis"),
                    ], selection: $tab)
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                contentList
            }
        }
    }

    private var contentList: some View {
        let p = CandelaPalette(dark: scheme == .dark)
        let info = header(for: tab)
        return List {
            Section {
                HStack(spacing: 12) {
                    Image(systemName: info.icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 46, height: 46)
                        .background(p.accentGradient, in: Circle())
                    VStack(alignment: .leading, spacing: 1) {
                        Text(info.title)
                            .font(.system(.title2, design: .rounded).weight(.heavy))
                            .foregroundColor(p.ink)
                        Text(info.subtitle)
                            .font(.footnote)
                            .foregroundColor(p.inkSoft)
                    }
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
            }
            if tab == .play || tab == .system || tab == .more {
                Section {
                    rows
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                        .listRowSeparator(.hidden)
                }
            }
            if tab == .controls || tab == .library {
                Section {
                    NavigationLink {
                        if tab == .controls {
                            CandelaTouchStudioHub()
                        } else {
                            CandelaThemeGallery()
                        }
                    } label: {
                        CandelaRow(
                            icon: tab == .controls ? "hand.draw.fill" : "paintpalette.fill",
                            title: tab == .controls ? "Touch Studio" : "Themes",
                            subtitle: tab == .controls ? "Customize controls for every game" : "Personalize Pastel Dream",
                            tint: p.rose
                        ) {
                            Image(systemName: "chevron.right").foregroundColor(p.inkSoft)
                        }
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(Color.clear)
                }
            }
            sections
            Section {
                Text("Candela \(CandelaVersion.display)  -  AGPL-3.0-or-later")
                    .font(.footnote)
                    .foregroundColor(p.inkSoft)
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                    .padding(.bottom, 90)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .fontDesign(.rounded)
        .tint(p.rose)
        .id(tab)
    }

    @ViewBuilder private var sections: some View {
        switch tab {
        case .play: destination(.graphics)
        case .controls: destination(.input)
        case .system: destination(.system)
        case .library: destination(.misc)
        case .more: destination(.advanced)
        }
    }

    // MARK: Status

    private var statusPill: some View {
        let p = CandelaPalette(dark: scheme == .dark)
        return HStack(spacing: 12) {
            CandelaMark(size: 30, dark: scheme == .dark)
            Text("Candela")
                .font(.system(.headline, design: .rounded).weight(.heavy))
                .foregroundColor(p.ink)
            Spacer()
            HStack(spacing: 6) {
                Circle().fill(isJIT ? p.good : p.warn).frame(width: 8, height: 8)
                Text(isJIT ? "JIT ready" : "JIT not acquired")
                    .font(.system(.footnote, design: .rounded).weight(.bold))
                    .foregroundColor(isJIT ? p.good : p.warn)
                    .lineLimit(1)
            }
            .layoutPriority(1)
            Text("v\(CandelaVersion.display)")
                .font(.system(.footnote, design: .rounded).weight(.bold))
                .foregroundColor(p.inkSoft)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .candelaSurface(radius: 28)
    }

    // MARK: Content

    private var contentCard: some View {
        let p = CandelaPalette(dark: scheme == .dark)
        let info = header(for: tab)
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: info.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 46, height: 46)
                    .background(p.accentGradient, in: Circle())
                VStack(alignment: .leading, spacing: 1) {
                    Text(info.title)
                        .font(.system(.title2, design: .rounded).weight(.heavy))
                        .foregroundColor(p.ink)
                    Text(info.subtitle)
                        .font(.footnote)
                        .foregroundColor(p.inkSoft)
                }
            }
            .padding(.bottom, 2)
            rows
        }
        .padding(16)
        .candelaSurface(radius: 28)
        .animation(.easeInOut(duration: 0.18), value: tab)
    }

    private func header(for tab: CandelaHubTab) -> (title: String, subtitle: String, icon: String) {
        switch tab {
        case .play: return ("Play", "How games look and run", "flame.fill")
        case .controls: return ("Controls", "Controllers and on-screen layout", "gamecontroller.fill")
        case .system: return ("System", "Sound, language, region, memory", "gearshape.fill")
        case .library: return ("Library", "Theme, icons, folders, network", "square.grid.2x2.fill")
        case .more: return ("More", "Logs, cooling and developer options", "ellipsis.circle.fill")
        }
    }

    @ViewBuilder private var rows: some View {
        switch tab {
        case .play: playRows
        case .system: systemRows
        case .more: moreRows
        default: EmptyView()
        }
    }

    // MARK: Play

    private var playRows: some View {
        let p = CandelaPalette(dark: scheme == .dark)
        let current = config.wrappedValue.resScale
        return VStack(spacing: 10) {
            HStack(spacing: 10) {
                ForEach(CandelaPlayStyle.allCases) { style in
                    let on = abs(current - style.scale) < 0.01
                    Button {
                        var o = config.wrappedValue
                        o.resScale = style.scale
                        o.enableAsyncShaderCompilation = true
                        config.wrappedValue = o
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        VStack(spacing: 5) {
                            Image(systemName: style.icon).font(.system(size: 19, weight: .medium))
                            Text(style.rawValue).font(.system(.subheadline, design: .rounded).weight(.heavy))
                            Text(style.blurb).font(.system(size: 10)).opacity(0.85)
                        }
                        .frame(maxWidth: .infinity, minHeight: 92)
                        .foregroundColor(on ? .white : p.ink)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(on ? AnyShapeStyle(p.accentGradient) : AnyShapeStyle(p.field.opacity(0.85)))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            Text("Applies to games with no saved settings of their own. Set one game on its game page.")
                .font(.caption)
                .foregroundColor(p.inkSoft)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)
            CandelaRow(icon: "thermometer.medium", title: "Thermal governor", subtitle: "Lowers resolution at next launch when the phone runs hot (\(thermal.step) of 2 steps)", tint: p.rose) {
                Toggle("", isOn: Binding(get: { thermal.enabled }, set: { thermal.enabled = $0 }))
                    .labelsHidden().tint(p.rose)
            }
        }
    }

    // MARK: System

    private var systemRows: some View {
        let p = CandelaPalette(dark: scheme == .dark)
        return VStack(spacing: 10) {
            CandelaRow(icon: "speaker.wave.2.fill", title: "Volume", subtitle: "Game audio level", tint: p.sky) {
                Slider(value: Binding(get: { Double(config.wrappedValue.audioVolume) },
                                      set: { config.wrappedValue.audioVolume = Float($0) }),
                       in: 0...1)
                    .frame(width: 120)
                    .tint(p.sky)
            }
        }
    }

    // MARK: More

    private var moreRows: some View {
        let p = CandelaPalette(dark: scheme == .dark)
        return VStack(spacing: 10) {
            CandelaRow(icon: "chart.xyaxis.line", title: "Timing report in logs", subtitle: "Adds graphics timing lines to the log. Restart the app to apply", tint: p.sky) {
                Toggle("", isOn: $mvkPerf)
                    .labelsHidden().tint(p.rose)
            }
            CandelaRow(icon: "flask.fill", title: "Test: compress shader memory", subtitle: "Experiment. Packs shader text in memory with LZ4. Restart to apply", tint: p.sky) {
                Toggle("", isOn: $expCompress).labelsHidden().tint(p.rose)
            }
            CandelaRow(icon: "flask.fill", title: "Test: prefill command buffers", subtitle: "Experiment. Encodes graphics work earlier, uses more memory. Restart to apply", tint: p.sky) {
                Toggle("", isOn: $expPrefill).labelsHidden().tint(p.rose)
            }
            CandelaRow(icon: "flask.fill", title: "Test: 3 shader build threads", subtitle: "Experiment. More background compiling, may use more heat. Restart to apply", tint: p.sky) {
                Toggle("", isOn: $expWorkers).labelsHidden().tint(p.rose)
            }
            Button { CandelaLogTools.share() } label: {
                CandelaRow(icon: "square.and.arrow.up", title: "Share latest log", subtitle: "Sends the last 8 MB of the newest log", tint: p.sky) { EmptyView() }
            }.buttonStyle(.plain)
            Button { CandelaLogTools.deleteAllLogs() } label: {
                CandelaRow(icon: "trash", title: "Delete saved logs", subtitle: "Frees space used by per-game logs", tint: p.rose) { EmptyView() }
            }.buttonStyle(.plain)
        }
    }

    // MARK: Pushed pages

    private func linkRow(_ category: SettingsView.SettingsCategory, icon: String, title: String, subtitle: String) -> some View {
        let p = CandelaPalette(dark: scheme == .dark)
        return NavigationLink {
            CandelaHubPage(title: title, content: destination(category))
        } label: {
            CandelaRow(icon: icon, title: title, subtitle: subtitle, tint: p.rose) {
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.bold))
                    .foregroundColor(p.inkSoft)
            }
        }
        .buttonStyle(.plain)
    }
}

/// A pushed page: the existing form on the Candela backdrop with a floating Back pill.
struct CandelaHubPage: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dismiss) private var dismiss
    let title: String
    let content: AnyView

    var body: some View {
        ZStack(alignment: .bottom) {
            CandelaBackdrop(dark: scheme == .dark).ignoresSafeArea()
            VStack(spacing: 0) {
                Text(title)
                    .font(.system(.title2, design: .rounded).weight(.heavy))
                    .foregroundColor(CandelaPalette(dark: scheme == .dark).ink)
                    .padding(.top, 14)
                    .padding(.bottom, 6)
                content
                    .modifier(HiddenScrollBackground())
            }
            CandelaBackPill { dismiss() }
                .padding(.bottom, 18)
        }
        .navigationBarHidden(true)
    }
}


// MARK: - Candela V4 / personalized settings dashboard
//
// A console-style landing screen influenced by visuals-first handheld frontends.
// Existing Graphics/Input/System/Misc/Advanced forms remain available and unchanged.
private struct CandelaSettingsDashboard: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ObservedObject private var thermal = CandelaThermal.shared
    @AppStorage("candela.theme.style.v1") private var themeChoice = CandelaThemeStyle.pastelDream.rawValue

    let config: Binding<Options>
    let isJIT: Bool
    let destination: (SettingsView.SettingsCategory) -> AnyView

    private var palette: CandelaPalette { CandelaPalette(dark: scheme == .dark) }
    private var selectedStyle: CandelaThemeStyle {
        CandelaThemeStyle(rawValue: themeChoice) ?? .pastelDream
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                titleBar
                themeFeature
                tools
                quickPerformance
                systemEssentials
                advanced
                Text("Candela \(CandelaVersion.display)  ·  AGPL-3.0-or-later")
                    .font(.system(size: 11, design: .rounded))
                    .foregroundColor(palette.inkSoft)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
            }
            .padding(.horizontal, 18)
            .padding(.top, 20)
            .padding(.bottom, 45)
        }
        .background(CandelaBackdrop(dark: scheme == .dark).ignoresSafeArea())
        .navigationBarHidden(true)
        .tint(palette.rose)
    }

    private var titleBar: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 10) {
                CandelaMark(size: 39, dark: scheme == .dark)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Your setup")
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                        .foregroundColor(palette.ink)
                    Text("Make every session feel yours.")
                        .font(.system(size: 13))
                        .foregroundColor(palette.inkSoft)
                }
                Spacer()
            }
            HStack(spacing: 9) {
                Label(isJIT ? "JIT ready" : "JIT unavailable",
                      systemImage: isJIT ? "checkmark.circle.fill" : "exclamationmark.circle")
                    .foregroundColor(isJIT ? palette.good : palette.warn)
                Spacer()
                Text("iPhone · Candela")
                    .foregroundColor(palette.inkSoft)
            }
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .padding(.horizontal, 15)
            .frame(height: 37)
            .background(palette.card.opacity(0.71), in: Capsule())
            .overlay(Capsule().strokeBorder(palette.cardStroke, lineWidth: 1))
        }
    }

    private var themeFeature: some View {
        NavigationLink {
            CandelaThemeGallery()
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 21, style: .continuous)
                        .fill(LinearGradient(colors: selectedStyle.colors,
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 106, height: 107)
                    CandelaMark(size: 52, dark: scheme == .dark)
                    Circle()
                        .fill(.white.opacity(0.68))
                        .frame(width: 15, height: 15)
                        .offset(x: 35, y: -32)
                }
                .overlay(RoundedRectangle(cornerRadius: 21)
                    .strokeBorder(.white.opacity(0.72), lineWidth: 1))
                VStack(alignment: .leading, spacing: 7) {
                    Text("YOUR LOOK")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .tracking(1.55)
                        .foregroundColor(palette.rose)
                    Text(selectedStyle.title)
                        .font(.system(size: 21, weight: .heavy, design: .rounded))
                        .foregroundColor(palette.ink)
                        .lineLimit(2)
                    Text("Themes, colors & glow")
                        .font(.system(size: 12))
                        .foregroundColor(palette.inkSoft)
                    HStack(spacing: 5) {
                        Text("Customize")
                        Image(systemName: "arrow.up.right")
                    }
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(palette.rose)
                }
                Spacer(minLength: 0)
            }
            .padding(13)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 27, style: .continuous)
                    .fill(palette.card.opacity(0.88))
                    .overlay {
                        RoundedRectangle(cornerRadius: 27, style: .continuous)
                            .fill(LinearGradient(colors: [
                                palette.roseSoft.opacity(0.16),
                                palette.skySoft.opacity(0.28)
                            ], startPoint: .topLeading, endPoint: .bottomTrailing))
                    }
            }
            .overlay(RoundedRectangle(cornerRadius: 27)
                .strokeBorder(palette.cardStroke.opacity(0.9), lineWidth: 1))
        }
        .buttonStyle(CandelaPressStyle())
        .accessibilityLabel("Customize Candela theme, selected \(selectedStyle.title)")
    }

    private var tools: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Your controls", subtitle: "Quick access to how Candela plays")
            NavigationLink {
                CandelaTouchStudioHub()
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: "hand.draw.fill")
                        .font(.system(size: 23, weight: .medium))
                        .foregroundColor(palette.rose)
                        .frame(width: 48, height: 48)
                        .background(palette.roseSoft.opacity(0.45), in: RoundedRectangle(cornerRadius: 15))
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Touch Studio")
                            .font(.system(.headline, design: .rounded).weight(.bold))
                            .foregroundColor(palette.ink)
                        Text("Per-game layouts & glass controls")
                            .font(.system(size: 12))
                            .foregroundColor(palette.inkSoft)
                    }
                    Spacer(minLength: 5)
                    Image(systemName: "arrow.up.right")
                        .foregroundColor(palette.inkSoft)
                }
                .padding(14)
                .candelaSurface(radius: 22)
            }
            .buttonStyle(CandelaPressStyle())

            HStack(spacing: 11) {
                settingDestination(.input, title: "Gamepads", subtitle: "Buttons & input",
                                   icon: "gamecontroller.fill", tint: palette.sky)
                settingDestination(.misc, title: "Library", subtitle: "Files & services",
                                   icon: "square.stack.3d.up.fill", tint: palette.rose)
            }
        }
    }

    private var quickPerformance: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionHeader("How games run", subtitle: "A quick tune-up for your iPhone")
                Spacer(minLength: 8)
                NavigationLink {
                    CandelaHubPage(title: "Graphics & performance", content: destination(.graphics))
                } label: {
                    Text("All options")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundColor(palette.rose)
            }
            HStack(spacing: 9) {
                ForEach(CandelaPlayStyle.allCases) { choice in
                    performanceTile(choice)
                }
            }
            Text("Sets the default resolution and enables asynchronous shaders. Saved per-game settings still take priority.")
                .font(.system(size: 11))
                .foregroundColor(palette.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 4)
        }
    }

    private func performanceTile(_ choice: CandelaPlayStyle) -> some View {
        let active = abs(config.wrappedValue.resScale - choice.scale) < 0.01
        return Button {
            var options = config.wrappedValue
            options.resScale = choice.scale
            options.enableAsyncShaderCompilation = true
            config.wrappedValue = options
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            VStack(spacing: 8) {
                Image(systemName: choice.icon)
                    .font(.system(size: 21, weight: .medium))
                Text(choice.rawValue)
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                Text(choice.blurb)
                    .font(.system(size: 10))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .opacity(0.83)
            }
            .foregroundColor(palette.ink)
            .frame(maxWidth: .infinity, minHeight: 112)
            .padding(.horizontal, 3)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(active
                        ? AnyShapeStyle(LinearGradient(colors: [
                            palette.roseSoft.opacity(0.91), palette.skySoft.opacity(0.74)
                        ], startPoint: .topLeading, endPoint: .bottomTrailing))
                        : AnyShapeStyle(palette.card.opacity(0.81)))
            }
            .overlay(RoundedRectangle(cornerRadius: 20)
                .strokeBorder(active ? palette.rose.opacity(0.65) : palette.cardStroke, lineWidth: active ? 1.6 : 1))
        }
        .buttonStyle(CandelaPressStyle())
        .accessibilityLabel("\(choice.rawValue) performance preset")
        .accessibilityAddTraits(active ? [.isSelected] : [])
    }

    private var systemEssentials: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Everyday essentials", subtitle: "Things you change most")
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    Image(systemName: "thermometer.medium")
                        .font(.system(size: 19))
                        .foregroundColor(palette.rose)
                        .frame(width: 38, height: 38)
                        .background(palette.roseSoft.opacity(0.34), in: RoundedRectangle(cornerRadius: 12))
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Thermal governor")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(palette.ink)
                        Text("Reduce next-launch heat · \(thermal.step) of 2 steps")
                            .font(.system(size: 11))
                            .foregroundColor(palette.inkSoft)
                    }
                    Spacer(minLength: 7)
                    Toggle("Thermal governor", isOn: Binding(
                        get: { thermal.enabled },
                        set: { thermal.enabled = $0 }
                    ))
                    .labelsHidden()
                    .tint(palette.rose)
                }
                .padding(14)
                Divider().padding(.leading, 62)
                HStack(spacing: 12) {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 19))
                        .foregroundColor(palette.sky)
                        .frame(width: 38, height: 38)
                        .background(palette.skySoft.opacity(0.31), in: RoundedRectangle(cornerRadius: 12))
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Game volume")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(palette.ink)
                        Text("Your default game audio")
                            .font(.system(size: 11))
                            .foregroundColor(palette.inkSoft)
                    }
                    Spacer(minLength: 7)
                    Slider(value: Binding(
                        get: { Double(config.wrappedValue.audioVolume) },
                        set: { config.wrappedValue.audioVolume = Float($0) }
                    ), in: 0...1)
                    .frame(width: 112)
                    .tint(palette.rose)
                }
                .padding(14)
            }
            .background(palette.card.opacity(0.84), in: RoundedRectangle(cornerRadius: 22))
            .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(palette.cardStroke, lineWidth: 1))
        }
    }

    private var advanced: some View {
        VStack(alignment: .leading, spacing: 11) {
            sectionHeader("Under the hood", subtitle: "Everything is still here when you need it")
            HStack(spacing: 11) {
                settingDestination(.system, title: "System", subtitle: "Audio & console", icon: "cpu", tint: palette.sky)
                settingDestination(.advanced, title: "Advanced", subtitle: "Logs & diagnostics", icon: "wrench.and.screwdriver.fill", tint: palette.rose)
            }
            Text("Advanced features are unchanged. No emulator or signing settings were removed.")
                .font(.system(size: 11))
                .foregroundColor(palette.inkSoft)
                .padding(.horizontal, 3)
        }
    }

    private func settingDestination(_ category: SettingsView.SettingsCategory,
                                    title: String,
                                    subtitle: String,
                                    icon: String,
                                    tint: Color) -> some View {
        NavigationLink {
            CandelaHubPage(title: title, content: destination(category))
        } label: {
            VStack(alignment: .leading, spacing: 9) {
                Image(systemName: icon)
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundColor(tint)
                    .frame(width: 40, height: 40)
                    .background(tint.opacity(0.13), in: RoundedRectangle(cornerRadius: 13))
                Text(title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(palette.ink)
                HStack {
                    Text(subtitle)
                        .font(.system(size: 11))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .foregroundColor(palette.inkSoft)
                    Spacer(minLength: 2)
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(tint)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(13)
            .frame(height: 129)
            .background(palette.card.opacity(0.82), in: RoundedRectangle(cornerRadius: 22))
            .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(palette.cardStroke, lineWidth: 1))
        }
        .buttonStyle(CandelaPressStyle())
    }

    private func sectionHeader(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundColor(palette.ink)
            Text(subtitle)
                .font(.system(size: 12))
                .foregroundColor(palette.inkSoft)
        }
    }
}
