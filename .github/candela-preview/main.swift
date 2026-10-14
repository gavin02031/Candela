// Renders mock-ups of the Candela screens from the real design tokens in
// UI/Candela/CandelaTheme.swift. These are layout mock-ups, not screenshots of the app.
import SwiftUI
import AppKit

let dark = CommandLine.arguments.contains("dark")
let scheme: ColorScheme = dark ? .dark : .light
let W: CGFloat = 393, H: CGFloat = 852

struct Tile: View {
    let title: String
    let a: UInt32, b: UInt32
    var size: CGFloat = 128
    var body: some View {
        let p = CandelaPalette(dark: dark)
        VStack(alignment: .leading, spacing: 6) {
            ZStack {
                LinearGradient(colors: [Color(candelaHex: a), Color(candelaHex: b)], startPoint: .topLeading, endPoint: .bottomTrailing)
                Text(String(title.prefix(1))).font(.system(size: 44, weight: .bold, design: .rounded)).foregroundColor(Color(candelaHex: 0x3A3450).opacity(0.7))
            }
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: p.rose.opacity(dark ? 0 : 0.25), radius: 8, x: 0, y: 4)
            Text(title).font(.system(.footnote, design: .rounded).weight(.semibold)).foregroundColor(p.ink).frame(width: size, alignment: .leading).lineLimit(2)
        }
    }
}

struct HomeMock: View {
    var body: some View {
        let p = CandelaPalette(dark: dark)
        ZStack {
            CandelaBackdrop(dark: dark)
            VStack {
                VStack(alignment: .leading, spacing: 26) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 8) {
                                CandelaMark(size: 34, dark: dark)
                                Text("Candela").font(.system(size: 34, weight: .bold, design: .rounded)).foregroundColor(p.ink)
                            }
                            CandelaChip(text: "6 games")
                        }
                        Spacer()
                        Image(systemName: "ellipsis.circle").font(.title2).foregroundColor(p.rose)
                    }.padding(.horizontal)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Continue Playing").font(.system(.title3, design: .rounded).weight(.semibold)).foregroundColor(p.ink).padding(.horizontal)
                        HStack(spacing: 14) {
                            Tile(title: "Game One", a: 0xF4C6D7, b: 0xC6D8F3, size: 168)
                            Tile(title: "Game Two", a: 0xC6D8F3, b: 0xF4C6D7, size: 168)
                        }.padding(.horizontal)
                    }
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Library").font(.system(.title3, design: .rounded).weight(.semibold)).foregroundColor(p.ink).padding(.horizontal)
                        VStack(alignment: .leading, spacing: 18) {
                            HStack(spacing: 14) {
                                Tile(title: "Game One", a: 0xF4C6D7, b: 0xC6D8F3, size: 108)
                                Tile(title: "Game Two", a: 0xC6D8F3, b: 0xF4C6D7, size: 108)
                                Tile(title: "Game Three", a: 0xF7D4E0, b: 0xB9CDEE, size: 108)
                            }
                            HStack(spacing: 14) {
                                Tile(title: "Game Four", a: 0xB9CDEE, b: 0xF7D4E0, size: 108)
                                Tile(title: "Game Five", a: 0xF4C6D7, b: 0xB9CDEE, size: 108)
                                Tile(title: "Game Six", a: 0xC6D8F3, b: 0xF7D4E0, size: 108)
                            }
                        }.padding(.horizontal)
                    }
                }.padding(.top, 60)
                Spacer()
            }
        }.frame(width: W, height: H).environment(\.colorScheme, scheme)
    }
}

struct WelcomeMock: View {
    var body: some View {
        let p = CandelaPalette(dark: dark)
        ZStack {
            CandelaBackdrop(dark: dark)
            VStack(spacing: 14) {
                Spacer()
                ZStack {
                    RoundedRectangle(cornerRadius: 40, style: .continuous).fill(p.card)
                    CandelaMark(size: 110, dark: dark)
                }
                .frame(width: 200, height: 200)
                .overlay(RoundedRectangle(cornerRadius: 40, style: .continuous).stroke(p.accentGradient, lineWidth: 2))
                .shadow(color: p.rose.opacity(dark ? 0 : 0.28), radius: 18, x: 0, y: 8)
                Text("Welcome to Candela").font(.system(.largeTitle, design: .rounded).weight(.bold)).foregroundColor(p.ink).padding(.top)
                Text("Light up your library.").font(.system(.title3, design: .rounded)).foregroundColor(p.inkSoft)
                Spacer()
                Button("Continue") {}.buttonStyle(CandelaPrimaryButtonStyle()).padding(.bottom, 50)
            }
        }.frame(width: W, height: H).environment(\.colorScheme, scheme)
    }
}

struct RowMock: View {
    let icon: String, title: String, sub: String
    var body: some View {
        let p = CandelaPalette(dark: dark)
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundColor(p.rose).frame(width: 30)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(.body, design: .rounded)).foregroundColor(p.ink)
                Text(sub).font(.footnote).foregroundColor(p.inkSoft)
            }
            Spacer()
            Toggle("", isOn: .constant(true)).labelsHidden().tint(p.rose)
        }
        .padding().candelaSurface(radius: 18).padding(.horizontal)
    }
}

struct SettingsMock: View {
    var body: some View {
        let p = CandelaPalette(dark: dark)
        ZStack(alignment: .top) {
            CandelaBackdrop(dark: dark)
            VStack(alignment: .leading, spacing: 14) {
                Text("Settings").font(.system(size: 34, weight: .bold, design: .rounded)).foregroundColor(p.ink).padding(.horizontal).padding(.top, 60)
                HStack(spacing: 8) {
                    ForEach(["System", "Graphics", "Input", "Audio"], id: \.self) { n in
                        Text(n).font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(n == "System" ? p.rose : p.field, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .foregroundColor(n == "System" ? (dark ? Color(candelaHex: 0x2A1A24) : .white) : p.ink)
                    }
                }.padding(.horizontal)
                HStack(spacing: 6) { Circle().fill(Color.candelaGood).frame(width: 8, height: 8); Text("JIT Enabled").foregroundColor(Color.candelaGood); Spacer(); CandelaChip(text: "Entitled", tint: .candelaGood) }.padding(.horizontal)
                CandelaSectionTitle("Memory").padding(.horizontal)
                RowMock(icon: "memorychip", title: "Increased memory", sub: "Uses the entitlement when present")
                RowMock(icon: "speedometer", title: "Frame pacing", sub: "Hold a steady rate")
                CandelaSectionTitle("Appearance").padding(.horizontal)
                RowMock(icon: "paintpalette", title: "Candela Blush", sub: "Theme")
                HStack { Button("Reset") {}.buttonStyle(CandelaSecondaryButtonStyle()); Button("Save") {}.buttonStyle(CandelaPrimaryButtonStyle()) }.padding(.horizontal)
                Spacer()
            }
        }.frame(width: W, height: H).environment(\.colorScheme, scheme)
    }
}

struct JITMock: View {
    var body: some View {
        ZStack {
            CandelaBackdrop(dark: dark)
            CandelaStepPage(step: 1, of: 4, symbol: "bolt.horizontal.circle", title: "Set up JIT",
                message: "Candela needs JIT to run games at full speed. Pair once and Candela can turn it on by itself. You can also skip this and use StikDebug.",
                primaryTitle: "Continue without pairing", primaryAction: {}) {
                VStack(spacing: 12) {
                    CandelaStatusRow(symbol: "network", title: "LocalDevVPN", detail: "Keep it connected while you pair and play.", chip: "Required")
                    CandelaStatusRow(symbol: "iphone", title: "Pair on this iPhone", detail: "Open iOS Settings, Developer Mode, then tap Pair with Candela.", chip: "Waiting")
                    Button("Import a pairing file") {}.buttonStyle(CandelaSecondaryButtonStyle())
                }
            }
        }.frame(width: W, height: H).environment(\.colorScheme, scheme).environment(\.candelaStaticLayout, true)
    }
}

struct KeysMock: View {
    var body: some View {
        ZStack {
            CandelaBackdrop(dark: dark)
            CandelaStepPage(step: 2, of: 4, symbol: "key", title: "Import your keys",
                message: "Candela needs prod.keys and title.keys, dumped from your own hardware. Pick both files at once.",
                primaryTitle: "Continue", primaryEnabled: false, primaryAction: {}) {
                VStack(spacing: 12) {
                    CandelaStatusRow(symbol: "key", title: "prod.keys", chip: "Added", chipTint: .candelaGood)
                    CandelaStatusRow(symbol: "key.horizontal", title: "title.keys", chip: "Missing")
                    Button("Choose key files") {}.buttonStyle(CandelaSecondaryButtonStyle())
                }
            }
        }.frame(width: W, height: H).environment(\.colorScheme, scheme).environment(\.candelaStaticLayout, true)
    }
}

struct FolderMock: View {
    var body: some View {
        ZStack {
            CandelaBackdrop(dark: dark)
            CandelaStepPage(step: 4, of: 4, symbol: "folder.badge.plus", title: "Pick a games folder",
                message: "Optional. If your games live in one folder, Candela can watch it. You can also skip this and add games from anywhere, any time.",
                primaryTitle: "Skip for now", primaryAction: {}) {
                VStack(spacing: 12) {
                    Button("Choose a folder") {}.buttonStyle(CandelaSecondaryButtonStyle())
                    Text("Folders can be changed in Settings.").font(.footnote).foregroundColor(CandelaPalette(dark: dark).inkSoft)
                }
            }
        }.frame(width: W, height: H).environment(\.colorScheme, scheme).environment(\.candelaStaticLayout, true)
    }
}

@MainActor func render<V: View>(_ v: V, _ name: String) {
    let r = ImageRenderer(content: v)
    r.scale = 2
    guard let ns = r.nsImage, let tiff = ns.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff), let png = rep.representation(using: .png, properties: [:]) else { print("render failed", name); return }
    try? png.write(to: URL(fileURLWithPath: "out/\(name)-\(dark ? "dusk" : "blush").png"))
    print("wrote", name)
}

MainActor.assumeIsolated {
    try? FileManager.default.createDirectory(atPath: "out", withIntermediateDirectories: true)
    render(WelcomeMock(), "welcome")
    render(HomeMock(), "home")
    render(SettingsMock(), "settings")
    render(JITMock(), "setup-jit")
    render(KeysMock(), "setup-keys")
    render(FolderMock(), "setup-folder")
}
