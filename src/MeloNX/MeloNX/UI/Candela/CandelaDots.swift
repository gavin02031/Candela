// SPDX-License-Identifier: AGPL-3.0-or-later
// Soft dotted backdrop layer and the shared pieces of the card-based layout language:
// floating Back pill, pill tabs, and icon rows with a subtitle and a trailing control.
import SwiftUI

struct CandelaDots: View {
    let dark: Bool

    var body: some View {
        let p = CandelaPalette(dark: dark)
        Canvas { ctx, size in
            let step: CGFloat = 26
            let color = p.sky.opacity(dark ? 0.16 : 0.22)
            var y: CGFloat = step / 2
            while y < size.height {
                var x: CGFloat = step / 2
                while x < size.width {
                    ctx.fill(Path(ellipseIn: CGRect(x: x - 1.4, y: y - 1.4, width: 2.8, height: 2.8)), with: .color(color))
                    x += step
                }
                y += step
            }
        }
        .allowsHitTesting(false)
    }
}

/// Floating "Back" pill used at the bottom of settings pages.
struct CandelaBackPill: View {
    @Environment(\.colorScheme) private var scheme
    var title: String = "Back"
    var action: () -> Void

    var body: some View {
        let p = CandelaPalette(dark: scheme == .dark)
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .bold))
                Text(title)
                    .font(.system(.title3, design: .rounded).weight(.heavy))
            }
            .foregroundColor(p.ink)
            .padding(.horizontal, 30)
            .padding(.vertical, 14)
            .background(Capsule().fill(p.card))
            .overlay(Capsule().stroke(p.cardStroke, lineWidth: 1))
            .shadow(color: p.rose.opacity(scheme == .dark ? 0 : 0.18), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(.plain)
    }
}

/// A row with an icon tile, a bold title, an optional subtitle, and a trailing control.
struct CandelaRow<Trailing: View>: View {
    @Environment(\.colorScheme) private var scheme
    let icon: String
    let title: String
    var subtitle: String? = nil
    var tint: Color? = nil
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        let p = CandelaPalette(dark: scheme == .dark)
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(tint ?? p.sky)
                .frame(width: 38, height: 38)
                .background((tint ?? p.sky).opacity(0.16), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.body, design: .rounded).weight(.bold))
                    .foregroundColor(p.ink)
                    .fixedSize(horizontal: false, vertical: true)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(p.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 8)
            trailing()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(p.field.opacity(scheme == .dark ? 0.9 : 0.75)))
    }
}

/// Pill tab strip: the selected tab is a soft raised capsule.
struct CandelaPillTabs<T: Hashable>: View {
    @Environment(\.colorScheme) private var scheme
    let items: [(T, String, String)] // value, title, icon
    @Binding var selection: T

    var body: some View {
        let p = CandelaPalette(dark: scheme == .dark)
        HStack(spacing: 6) {
            ForEach(items.indices, id: \.self) { i in
                let item = items[i]
                let on = item.0 == selection
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) { selection = item.0 }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: item.2).font(.system(size: 14, weight: .semibold))
                        Text(item.1)
                            .font(.system(.footnote, design: .rounded).weight(.bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .foregroundColor(on ? p.ink : p.inkSoft)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(
                        Capsule().fill(on ? p.roseSoft.opacity(scheme == .dark ? 0.25 : 0.7) : Color.clear)
                    )
                    .overlay(Capsule().stroke(on ? p.rose.opacity(0.5) : Color.clear, lineWidth: 1.5))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .candelaSurface(radius: 26)
    }
}
