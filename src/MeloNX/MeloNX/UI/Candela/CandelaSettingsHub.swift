// SPDX-License-Identifier: AGPL-3.0-or-later
// Settings home for iPhone. One rounded card per page, pill tabs on top, icon rows with a subtitle and a
// trailing control, and a floating Back pill on pushed pages. The older long forms are reached from "All ... options".
import SwiftUI

extension SettingsView {
    var candelaHub: some View {
        NavigationStack {
            CandelaHubScreen(
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
