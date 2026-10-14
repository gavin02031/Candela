//
//  AppIconSwitcher.swift
//  MeloNX
//
//  Created by Stossy11 on 02/06/2025.
//

import SwiftUI

struct AppIconCreator: Identifiable, Equatable {
    var id: String { creator }
    
    var icons: [AppIcon]
    var creator: String
}

struct AppIcon: Identifiable, Equatable {
    var id: String { iconName }
    
    var iconDisplayName: String
    var iconName: String
}

struct AppIconSwitcherView: View {
    @Environment(\.dismiss) private var dismiss
    @State var appIconCreator: [AppIconCreator] = []
    
    @State var columns: [GridItem] = [
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20)
    ]
    @State private var currentIconName: String? = nil
    @State var refresh = 0
    @State private var alertMessage: String?
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(.systemBackground).opacity(0.95),
                        Color(.systemGroupedBackground)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 32) {
                        ForEach(appIconCreator.indices, id: \.self) { index in
                            let iconGroup = appIconCreator[index]
                            
                            VStack(alignment: .leading, spacing: 20) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(iconGroup.creator)
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundStyle(.primary)
                                        
                                        Text("\(iconGroup.icons.count) icons")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                }
                                .padding(.horizontal, 24)
                                
                                LazyVGrid(columns: columns, spacing: 20) {
                                    ForEach(iconGroup.icons) { icon in
                                        Button {
                                            selectIcon(icon.iconName)
                                        } label: {
                                            ZStack {
                                                AppIconView(app: icon)
                                                
                                                if icon.iconName == currentIconName ?? UIImage.appIcon() {
                                                    VStack {
                                                        HStack {
                                                            Spacer()
                                                            Image(systemName: "checkmark.circle.fill")
                                                                .font(.system(size: 24, weight: .bold))
                                                                .foregroundStyle(.white)
                                                                .background(
                                                                    Circle()
                                                                        .fill(
                                                                            LinearGradient(
                                                                                colors: [.blue, .purple],
                                                                                startPoint: .topLeading,
                                                                                endPoint: .bottomTrailing
                                                                            )
                                                                        )
                                                                        .frame(width: 28, height: 28)
                                                                )
                                                        }
                                                        Spacer()
                                                    }
                                                    .frame(width: 80, height: 80)
                                                    .offset(x: 6, y: -6)
                                                }
                                            }
                                        }
                                        .buttonStyle(.plain)
                                        .scaleEffect(isCurrentIcon(icon.iconName) ? 0.95 : 1.0)
                                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isCurrentIcon(icon.iconName))
                                    }
                                }
                                .padding(.horizontal, 24)
                            }
                            
                            if index < appIconCreator.count - 1 {
                                Rectangle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.clear, Color(.separator), .clear],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(height: 1)
                                    .padding(.horizontal, 40)
                            }
                        }
                    }
                    .padding(.vertical, 32)
                }
            }
            .navigationTitle("Choose App Icon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.blue)
                }
            }
        }
        .onAppear(perform: setupColumns)
        .onAppear(perform: getCurrentIconName)
        .alert("Icon not changed", isPresented: Binding(get: { alertMessage != nil }, set: { if !$0 { alertMessage = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage ?? "")
        }
    }
    
    private func setupColumns() {
        /*
        if #available(iOS 19, *) {
            appIcons = [
                AppIcon(iconNames: ["Default": UIImage.appIcon(), "Round": "RoundAppIcon"], creator: "CycloKid (Liquid Glass by Transistor)"),
                AppIcon(iconNames: ["Pixel Default": "PixelAppIcon", "Pixel Round": "PixelRoundAppIcon"], creator: "Nobody (Liquid Glass by Transistor)"),
                AppIcon(iconNames: ["\"UwU\"": "uwuAppIcon"], creator: "𝒰𝓃𝓀𝓃𝑜𝓌𝓃 (Liquid Glass by Transistor)"),
            ]
        } else {
            appIcons = [
                AppIcon(iconNames: ["Default": UIImage.appIcon(), "Dark Mode": "DarkMode", "Round": "RoundAppIcon"], creator: "CycloKid"),
                AppIcon(iconNames: ["Pixel Default": "PixelAppIcon", "Pixel Round": "PixelRoundAppIcon"], creator: "Nobody"),
                AppIcon(iconNames: ["\"UwU\"": "uwuAppIcon"], creator: "𝒰𝓃𝓀𝓃𝑜𝓌𝓃"),
            ]
        }
        
        appIcons.append(contentsOf: [
            AppIcon(iconNames: [(isAvailable(iOS: 19) ? "Clear" : "Clear (Liquid Glass)"): "Clear", "Mel-o-Lantern": "Mel-o-Lantern", "Candelamas": "Candelamas", "MeluckyNX \n (Saint Patrick's Day)": "MeluckyNX"], creator: "Transistor"),
            AppIcon(iconNames: ["MellowSkyNX": "MellowSkyNX"], creator: "Sky (@dootskyre)"),
            AppIcon(iconNames: ["Skeuomorphic": "skeuomorphic"], creator: "@stars33k")
        ])
         */
        
        appIconCreator = [
            .init(icons: [
                .init(iconDisplayName: "Pearl", iconName: "CandelaPearl"),
                .init(iconDisplayName: "Moonlit Pumpkin", iconName: "CandelaMoonlitPumpkin"),
                .init(iconDisplayName: "Winter Frost", iconName: "CandelaWinterFrost"),
                .init(iconDisplayName: "Neon Night", iconName: "CandelaNeonNight"),
                .init(iconDisplayName: "Pixel Sky", iconName: "CandelaPixelSky"),
                .init(iconDisplayName: "Ocean Swirl", iconName: "CandelaOceanSwirl"),
                .init(iconDisplayName: "Sunset Shore", iconName: "CandelaSunsetShore"),
                .init(iconDisplayName: "Frosted", iconName: "CandelaFrosted"),
                .init(iconDisplayName: "Prism", iconName: "CandelaPrism"),
                .init(iconDisplayName: "Vine", iconName: "CandelaVine"),
                .init(iconDisplayName: "Onyx", iconName: "CandelaOnyx"),
                .init(iconDisplayName: "Cloud", iconName: "CandelaCloud"),
                .init(iconDisplayName: "Inferno", iconName: "CandelaInferno"),
                .init(iconDisplayName: "Lilac Dream", iconName: "CandelaLilacDream"),
                .init(iconDisplayName: "Synthwave", iconName: "CandelaSynthwave"),
                .init(iconDisplayName: "Aqua Ripple", iconName: "CandelaAquaRipple")
            ], creator: "Candela"),
            .init(icons: [
                .init(iconDisplayName: "Default", iconName: UIImage.appIcon()),
                .init(iconDisplayName: "Round", iconName: "RoundAppIcon"),
                .init(iconDisplayName: "QueerNX", iconName: "QueerNX")
            ], creator: "CycloKid & Transistor"),
            .init(icons: [
                .init(iconDisplayName: "Pixel Default", iconName: "PixelAppIcon"),
                .init(iconDisplayName: "Pixel Round", iconName: "PixelRoundAppIcon")
            ], creator: "Nobody"),
            .init(icons: [
                .init(iconDisplayName: "\"UwU\"", iconName: "uwuAppIcon")
            ], creator: "𝒰𝓃𝓀𝓃𝑜𝓌𝓃"),
            .init(icons: [
                .init(iconDisplayName: "Mel-o-Lantern", iconName: "Mel-o-Lantern"),
                .init(iconDisplayName: "Candelamas", iconName: "MeloNXmas"),
                .init(iconDisplayName: "MeluckyNX\n (Saint Patrick's Day)", iconName: "MeluckyNX")
            ], creator: "Transistor"),
            .init(icons: [
                .init(iconDisplayName: "MellowSkyNX", iconName: "MellowSkyNX"),
            ], creator: "Sky (@dootskyre)"),
            .init(icons: [
                .init(iconDisplayName: "Skeuomorphic", iconName: "skeuomorphic")
            ], creator: "@stars33k")
        ]
    }
    
    private func getCurrentIconName() {
        currentIconName = UIApplication.shared.alternateIconName ?? UIImage.appIcon()
    }
    
    private func isCurrentIcon(_ iconName: String) -> Bool {
        let currentIcon = UIApplication.shared.alternateIconName ?? UIImage.appIcon()
        return currentIcon == iconName
    }
    
    private func selectIcon(_ iconName: String) {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()

        guard UIApplication.shared.supportsAlternateIcons else {
            alertMessage = "This install does not allow changing the app icon. It may be running inside a container or re-packed app."
            return
        }
        
        if iconName == UIImage.appIcon() {
            UIApplication.shared.setAlternateIconName(nil) { error in
                if let error = error {
                    Task { @MainActor in alertMessage = "iOS refused the icon change: \(error.localizedDescription)" }
                } else {
                   Task { @MainActor in
                        currentIconName = nil
                        refresh = Int.random(in: 0...100)
                    }
                }
            }
        } else {
            var trimmedIconName = iconName
            if #available(iOS 26, *) {
                trimmedIconName = iconName.replacingOccurrences(of: "_18", with: "")
            }
            
            let declared = ((Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any])?["CFBundleAlternateIcons"] as? [String: Any]) ?? [:]
            guard declared[trimmedIconName] != nil else {
                alertMessage = "The installed app does not list the icon \"\(trimmedIconName)\". A re-signed or re-packed install can drop alternate icons from the app's Info.plist."
                return
            }

            UIApplication.shared.setAlternateIconName(trimmedIconName) { error in
                if let error = error {
                    Task { @MainActor in alertMessage = "iOS refused the icon change: \(error.localizedDescription)" }
                } else {
                   Task { @MainActor in
                        currentIconName = iconName
                        refresh = Int.random(in: 0...100)
                    }
                }
            }
        }
    }
    
    func isAvailable(iOS version: Int) -> Bool {
        let current = ProcessInfo.processInfo.operatingSystemVersion
        return current.majorVersion >= version
    }

}

/// Small, cached previews for the picker. The icons are 1024 px app-icon sets, so each one is decoded
/// one at a time off the main thread and shrunk to thumbnail size before it is kept.
nonisolated final class IconPreviewCache: @unchecked Sendable {
    static let shared = IconPreviewCache()
    private let cache = NSCache<NSString, UIImage>()
    private let queue = DispatchQueue(label: "candela.icon-previews", qos: .utility)

    func image(for name: String) async -> UIImage? {
        if let cached = cache.object(forKey: name as NSString) { return cached }
        return await withCheckedContinuation { continuation in
            queue.async { [self] in
                if let cached = cache.object(forKey: name as NSString) {
                    continuation.resume(returning: cached)
                    return
                }
                let thumb: UIImage? = autoreleasepool {
                    guard let full = UIImage(named: name) ?? UIImage.loadFromAssetsCatalog(named: name) else { return nil }
                    let format = UIGraphicsImageRendererFormat()
                    format.scale = 1
                    let side: CGFloat = 124
                    return UIGraphicsImageRenderer(size: CGSize(width: side, height: side), format: format).image { _ in
                        full.draw(in: CGRect(x: 0, y: 0, width: side, height: side))
                    }
                }
                if let thumb { cache.setObject(thumb, forKey: name as NSString) }
                continuation.resume(returning: thumb)
            }
        }
    }
}

struct AppIconView: View {
    let app: AppIcon
    
    @State var image: UIImage?
    
    var body: some View {
        VStack(spacing: 7) {
            ZStack {
                if let iconImage = image {
                    Image(uiImage: iconImage)
                        .resizable()
                        .cornerRadius(15)
                        .frame(width: 62, height: 62)
                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                } else {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 62, height: 62)
                        .overlay(
                            Image(systemName: "app.dashed")
                                .foregroundColor(.gray)
                        )
                }
            }
            
            Text(app.iconDisplayName)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                .frame(width: app.iconDisplayName.contains("\n") ? 150 : 100)
                .lineLimit(app.iconDisplayName.contains("\n") ? 2 : 1)
        }
        .task(id: app.iconName) {
            image = await IconPreviewCache.shared.image(for: app.iconName)
        }
    }
}



extension UIImage {
    static func appIcon() -> String {
        if let icons = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
           let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
           let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
           let lastIcon = iconFiles.last {
            print(icons)
            return lastIcon
        }
        return "AppIcon"
    }
}

extension UIImage {
    nonisolated static func loadFromAssetsCatalog(named name: String) -> UIImage? {
        guard let carURL = Bundle.main.url(forResource: "Assets", withExtension: "car") else {
            print("Could not find Assets.car")
            return nil
        }
        
        guard let coreUIBundle = Bundle(path: "/System/Library/PrivateFrameworks/CoreUI.framework") else {
            print("Could not load CoreUI framework")
            return nil
        }
        
        if !coreUIBundle.isLoaded { coreUIBundle.load() }
        
        guard let catalogClass = NSClassFromString("CUICatalog") as? NSObject.Type else {
            print("Could not find CUICatalog class")
            return nil
        }
        
        let catalog = catalogClass.init()
        let initSel = NSSelectorFromString("initWithURL:error:")
        guard catalog.responds(to: initSel) else { return nil }
        
        var error: NSError?
        guard let validCatalog = withUnsafeMutablePointer(to: &error, { errorPtr in
            catalog.perform(initSel, with: carURL, with: errorPtr)?.takeUnretainedValue() as? NSObject
        }) else {
            print("Failed to init CUICatalog: \(error?.localizedDescription ?? "unknown")")
            return nil
        }
        
        let imagesWithNameSel = NSSelectorFromString("imagesWithName:")
        guard validCatalog.responds(to: imagesWithNameSel),
              let results = validCatalog.perform(imagesWithNameSel, with: name)?.takeUnretainedValue() as? [NSObject] else {
            print("imagesWithName: failed for: \(name)")
            return nil
        }
        
        let cuiNamedImageClass: AnyClass? = NSClassFromString("CUINamedImage")
        let cuiMultisizeClass: AnyClass? = NSClassFromString("CUINamedMultisizeImageSet")

        guard let namedImage = results.first(where: { obj in
            guard let cls = cuiNamedImageClass else { return false }
            if let multiCls = cuiMultisizeClass, obj.isKind(of: multiCls) { return false }
            return obj.isKind(of: cls) && obj.responds(to: NSSelectorFromString("image"))
        }) else {
            print("No CUINamedImage in results for: \(name)")
            return nil
        }
        
        let imageSel = NSSelectorFromString("image")
        guard namedImage.responds(to: imageSel) else { return nil }
        
        typealias ImageIMP = @convention(c) (NSObject, Selector) -> CGImage?
        let imageIMP = unsafeBitCast(namedImage.method(for: imageSel), to: ImageIMP.self)
        
        guard let cgImage = imageIMP(namedImage, imageSel) else {
            print("CGImageRef was nil for: \(name)")
            return nil
        }
        
        let scaleSel = NSSelectorFromString("scale")
        guard namedImage.responds(to: scaleSel) else { return nil }
        typealias ScaleIMP = @convention(c) (NSObject, Selector) -> Double
        let scaleIMP = unsafeBitCast(namedImage.method(for: scaleSel), to: ScaleIMP.self)
        let imageScale = CGFloat(scaleIMP(namedImage, scaleSel))
        
        return UIImage(cgImage: cgImage, scale: imageScale, orientation: .up)
    }
}
