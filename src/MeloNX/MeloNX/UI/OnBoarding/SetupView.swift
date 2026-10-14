//
//  SetupView.swift
//  MeloNX
//
//  Created by Stossy11 on 6/7/2026.
//

import SwiftUI

enum SetupPage: String, Identifiable, CaseIterable {
    case welcome
    case jit
    case keys
    case firmware
    case folder

    var id: String { rawValue }

    static var first: Self = .welcome
}

struct SetupView: View {
    var finishSetup: () -> Void
    private let pages = SetupPage.allCases
    
    @State var currentPage: SetupPage = .first
    
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let p = CandelaPalette(dark: scheme == .dark)
        VStack(spacing: 12) {
            HStack {
                if currentPage != .first {
                    CandelaBackPill { goBack() }
                        .transition(.opacity)
                }
                Spacer()
                HStack(spacing: 6) {
                    ForEach(pages) { page in
                        Capsule()
                            .fill(page == currentPage ? p.rose : p.rose.opacity(0.22))
                            .frame(width: page == currentPage ? 22 : 8, height: 8)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .frame(minHeight: 44)
            pageStack
                .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
                .candelaSurface(radius: 34)
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
        }
        .themedBackground()
    }

    func goBack() {
        withAnimation {
            switch currentPage {
            case .welcome: break
            case .jit: currentPage = .welcome
            case .keys: currentPage = .jit
            case .firmware: currentPage = .keys
            case .folder: currentPage = .firmware
            }
        }
    }

    private var pageStack: some View {
        ZStack {
            switch currentPage {
            case .welcome: WelcomeView(goForward: goForward, finish: finishSetup).transition(.backslide)
            case .jit: JITSetupView(goForward: goForward).transition(.backslide)
            case .keys: KeysView(goForward: goForward).transition(.backslide)
            case .firmware: FirmwareView(goForward: goForward).transition(.backslide)
            case .folder: RomFolderView(finish: finishSetup).transition(.backslide)
            }
        }
    }
    
    func goForward() {
        withAnimation {
            switch currentPage {
            case .welcome:
                currentPage = .jit
            case .jit:
                currentPage = .keys
            case .keys:
                currentPage = .firmware
            case .firmware:
                currentPage = .folder
            case .folder:
                finishSetup()
            }
        }
    }
}

struct ContinueButton: View {
    var text: LocalizedStringKey
    var action: () -> Void
    
    var success: Bool = false
    @Binding var enabled: Bool
    @Environment(\.colorScheme) var colorScheme
    
    var showCheckmark: Bool = true
    
    var baseColor: Color = .candelaGood
    
    func doAction() {
        if enabled { action() }
    }
    
    var body: some View {
        let palette = CandelaPalette(dark: colorScheme == .dark)
        Button(action: doAction) {
            Text(success && showCheckmark ? "✓" : text)
                .font(.system(.headline, design: .rounded))
                .padding(.vertical, 14)
                .padding(.horizontal, 36)
                .foregroundStyle(success ? baseColor : (enabled ? (colorScheme == .dark ? Color(candelaHex: 0x2A1A24) : Color.white) : palette.inkSoft))
                .background {
                    Capsule(style: .continuous)
                        .fill(success ? AnyShapeStyle(baseColor.opacity(0.16)) : (enabled ? AnyShapeStyle(palette.accentGradient) : AnyShapeStyle(palette.inkSoft.opacity(0.18))))
                        .overlay(Capsule(style: .continuous).stroke(success ? baseColor : Color.clear, lineWidth: 1))
                }
                .shadow(color: palette.rose.opacity(enabled && !success && colorScheme != .dark ? 0.3 : 0), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}

extension Image {
    init(appIconBundle: Bundle) {
        self.init(uiImage: UIImage(named: Self.appIcon(in: appIconBundle)) ?? UIImage())
    }
    
    
    static func appIcon(in bundle: Bundle = .main) -> String {
        guard let icons = bundle.object(forInfoDictionaryKey: "CFBundleIcons") as? [String: Any],
              
              let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
              
              let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
              
              let iconFileName = iconFiles.last else {

            // print("Could not find icons in bundle")
            return ""
        }

        return iconFileName
    }
}

extension Bundle {
    var versionNumber: String {
        object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
    }
}

extension AnyTransition {
    static var backslide: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing),
            removal: .move(edge: .leading)
        )
    }
}
