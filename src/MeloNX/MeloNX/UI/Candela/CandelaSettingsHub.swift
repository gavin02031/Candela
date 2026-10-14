// SPDX-License-Identifier: AGPL-3.0-or-later
// Settings home for iPhone: a hub with a status card, three one-tap play styles, and large category rows that
// open their own pages. It replaces the old strip of tabs above one long form. The forms themselves are reused.
import SwiftUI

extension SettingsView {
    private enum PlayStyle: String, CaseIterable, Identifiable {
        case cool = "Cool"
        case balanced = "Balanced"
        case sharp = "Sharp"

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
            case .cool: return "Runs cooler, softer picture"
            case .balanced: return "Good mix for most games"
            case .sharp: return "Cleanest picture, runs warmest"
            }
        }
    }

    var candelaHub: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    candelaHubStatusCard
                    candelaHubPlayStyle
                    candelaHubRows
                    Text("Candela \(CandelaVersion.display)  -  AGPL-3.0-or-later")
                        .font(.footnote)
                        .foregroundColor(CandelaPalette(dark: colorScheme == .dark).inkSoft)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 4)
                        .padding(.bottom, 90)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .background(CandelaBackdrop(dark: colorScheme == .dark).ignoresSafeArea())
            .navigationTitle("Settings")
        }
    }

    private var candelaHubStatusCard: some View {
        let p = CandelaPalette(dark: colorScheme == .dark)
        let jit = ryujinxController.isJITEnabled
        return HStack(spacing: 14) {
            CandelaMark()
                .frame(width: 46, height: 46)
            VStack(alignment: .leading, spacing: 4) {
                Text("Candela")
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundColor(p.ink)
                HStack(spacing: 6) {
                    Circle().fill(jit ? p.good : p.warn).frame(width: 8, height: 8)
                    Text(jit ? "JIT ready" : "JIT not acquired")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(jit ? p.good : p.warn)
                }
                Text("\(UIDevice.modelName)  -  \(UIDevice.current.systemName) \(UIDevice.current.systemVersion)")
                    .font(.caption)
                    .foregroundColor(p.inkSoft)
            }
            Spacer()
            Text("v\(CandelaVersion.display)")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(p.inkSoft)
        }
        .padding(16)
        .candelaSurface(radius: 22)
    }

    private var candelaHubPlayStyle: some View {
        let p = CandelaPalette(dark: colorScheme == .dark)
        let current = config.wrappedValue.resScale
        return VStack(alignment: .leading, spacing: 10) {
            CandelaSectionTitle("Play style")
            HStack(spacing: 10) {
                ForEach(PlayStyle.allCases) { style in
                    let on = abs(current - style.scale) < 0.01
                    Button {
                        var o = config.wrappedValue
                        o.resScale = style.scale
                        o.enableAsyncShaderCompilation = true
                        config.wrappedValue = o
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: style.icon)
                                .font(.system(size: 20, weight: .medium))
                            Text(style.rawValue)
                                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            Text(style.blurb)
                                .font(.system(size: 10))
                                .multilineTextAlignment(.center)
                                .lineLimit(3)
                                .opacity(0.85)
                        }
                        .frame(maxWidth: .infinity, minHeight: 112)
                        .padding(.horizontal, 6)
                        .foregroundColor(on ? .white : p.ink)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(on ? AnyShapeStyle(p.accentGradient) : AnyShapeStyle(p.card.opacity(0.85)))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(on ? Color.clear : p.cardStroke, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            Text("Sets resolution to \(config.wrappedValue.resScale.toOneDecimalString())x of 720p and turns on background shader building. Games with their own saved settings keep them.")
                .font(.caption)
                .foregroundColor(p.inkSoft)
        }
    }

    private struct HubRow: Identifiable {
        let id: String
        let title: String
        let subtitle: String
        let icon: String
        let tint: Color
        let category: SettingsCategory
    }

    private var candelaHubRows: some View {
        let p = CandelaPalette(dark: colorScheme == .dark)
        let rows: [HubRow] = [
            HubRow(id: "pic", title: "Picture and speed", subtitle: "Resolution \(config.wrappedValue.resScale.toOneDecimalString())x, filtering, frame pacing", icon: "paintbrush.fill", tint: p.rose, category: .graphics),
            HubRow(id: "ctl", title: "Controls", subtitle: "Controllers, on-screen layout, opacity", icon: "gamecontroller.fill", tint: p.sky, category: .input),
            HubRow(id: "sys", title: "System", subtitle: "Language, region, memory mode", icon: "gearshape.fill", tint: p.rose, category: .system),
            HubRow(id: "lib", title: "Library and look", subtitle: "Theme, app icon, library view, folders, network", icon: "square.grid.2x2.fill", tint: p.sky, category: .misc),
            HubRow(id: "adv", title: "Advanced and logs", subtitle: "Logs, thermal governor, developer options", icon: "terminal.fill", tint: p.rose, category: .advanced),
        ]
        return VStack(alignment: .leading, spacing: 10) {
            CandelaSectionTitle("Everything else")
            VStack(spacing: 10) {
                ForEach(rows) { row in
                    NavigationLink {
                        row.category.formView(for: self)
                            .modifier(HiddenScrollBackground())
                            .background(CandelaBackdrop(dark: colorScheme == .dark).ignoresSafeArea())
                            .navigationTitle(row.title)
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: row.icon)
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 38, height: 38)
                                .background(row.tint, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(row.title)
                                    .font(.system(.body, design: .rounded).weight(.semibold))
                                    .foregroundColor(p.ink)
                                Text(row.subtitle)
                                    .font(.caption)
                                    .foregroundColor(p.inkSoft)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.footnote.weight(.semibold))
                                .foregroundColor(p.inkSoft)
                        }
                        .padding(14)
                        .candelaSurface(radius: 18)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
