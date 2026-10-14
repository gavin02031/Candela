//
//  MeloNXApp.swift
//  MeloNX
//
//  Created by Stossy11 on 4/4/2026.
//

import SwiftUI
import SDL3
import AVFoundation
import GameController

func configureAudioSession() {
    do {
        let session = AVAudioSession.sharedInstance()

        try session.setCategory(
            .playback,
            options: .mixWithOthers
        )
        try session.setPreferredSampleRate(48000)
        try session.setPreferredIOBufferDuration(0.005)
        try session.setActive(true)
    } catch {
        print("Audio session error: \(error.localizedDescription)")
    }
}

var environment: [EnvironmentVariable] = [
    //EnvironmentVariable(string: "MVK_CONFIG_SYNCHRONOUS_QUEUE_SUBMITS", value: "0"),
    EnvironmentVariable(string: "MVK_CONFIG_MAX_ACTIVE_METAL_COMMAND_BUFFERS_PER_QUEUE", value: "32"),
   //  EnvironmentVariable(string: "MVK_CONFIG_SHADER_COMPRESSION_ALGORITHM", value: "1"),
]

func initEnvironmentVariables() {
    if let device = MTLCreateSystemDefaultDevice() {
        environment.append(contentsOf: [
            .init(string: "MVK_CONFIG_USE_METAL_ARGUMENT_BUFFERS", value: device.argumentBuffersSupport.rawValue >= MTLArgumentBuffersTier.tier2.rawValue ? "1" : "0")
        ])
        
        if #available(iOS 17, macOS 14, *) {
            environment.append(contentsOf: [
                .init(string: "MVK_SUPPORTS_EXT_DYN_STATE", value: device.supportsFamily(.apple4) ? "1" : "0")
            ])
        } else {
            environment.append(contentsOf: [
                .init(string: "MVK_SUPPORTS_EXT_DYN_STATE", value: "0")
            ])
        }
    }
    
    if #available(iOS 19, *) {
        environment.append(contentsOf: [
            .init(string: "HAS_TXM", value: ProcessInfo.processInfo.hasTXM && !ProcessInfo.processInfo.isiOSAppOnMac ? "1" : "0"),
            .init(string: "DUAL_MAPPED_JIT", value: !ProcessInfo.processInfo.isiOSAppOnMac ? "1" : "0")
        ])
    } else {
        environment.append(contentsOf: [
            .init(string: "HAS_TXM", value: "0"),
            .init(string: "DUAL_MAPPED_JIT", value: "0")
        ])
    }
    
    // Optional: MoltenVK's own timing report (shader and pipeline compile, queue submit, GPU time), logged every 600 frames.
    if UserDefaults.standard.bool(forKey: "candela.mvkPerf") {
        environment.append(contentsOf: [
            .init(string: "MVK_CONFIG_PERFORMANCE_TRACKING", value: "1"),
            .init(string: "MVK_CONFIG_ACTIVITY_PERFORMANCE_LOGGING_STYLE", value: "0"),
            .init(string: "MVK_CONFIG_PERFORMANCE_LOGGING_FRAME_COUNT", value: "600"),
            .init(string: "MVK_CONFIG_LOG_LEVEL", value: "3"),
        ])
    }

    // Hidden experiments, all off by default. Each is a separate switch in More. Restart the app to apply.
    let defaults = UserDefaults.standard
    if defaults.bool(forKey: "candela.expCompress") {
        environment.append(.init(string: "MVK_CONFIG_SHADER_COMPRESSION_ALGORITHM", value: "3"))
    }
    if defaults.bool(forKey: "candela.expPrefill") {
        environment.append(.init(string: "MVK_CONFIG_PREFILL_METAL_COMMAND_BUFFERS", value: "1"))
    }
    if defaults.bool(forKey: "candela.expWorkers") {
        environment.append(.init(string: "CANDELA_BG_COMPILE_THREADS", value: "3"))
    }

    for env in environment { env.set() }
}

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    static var orientationLock = UIInterfaceOrientationMask.all

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        SDL_SetMainReady()
        SDL_SetiOSEventPump(true)
        SDL_Init(SDL_INIT_EVENTS)
        JIT26BreakpointHandler()
        initEnvironmentVariables()
        Ryujinx.initialize()
        CrashHandlerInstaller.install()
        ThemeManager.shared.applyUIKitAppearance()
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        configureAudioSession()
        return true
    }

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        AppDelegate.orientationLock
    }

    func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
        report_memory_pressure(0)
    }
}

class MainSceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = MainViewController()
        self.window = window
        window.makeKeyAndVisible()
        open(connectionOptions.urlContexts)
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        open(URLContexts)
    }

    private func open(_ contexts: Set<UIOpenURLContext>) {
        for context in contexts {
            AppEnvironment.handleDeepLink(context.url, ryujinxController: .shared)
        }
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        let controller = RyujinxController.shared
        if controller.isRunning.isRunning() {
            if !controller.wasManuallyPaused { controller.isPaused = false }
        } else {
            _ = controller.attemptToMapDualMapping()
        }
    }

    func sceneWillResignActive(_ scene: UIScene) {
        pauseEmulation()
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        RyujinxController.shared.flushPendingSettingsSaves()
        pauseEmulation()
    }

    private func pauseEmulation() {
        let controller = RyujinxController.shared
        if controller.isRunning.isRunning(), !controller.wasManuallyPaused {
            controller.isPaused = true
        }
    }
}


class MainViewController: GCEventViewController {
    private var displayRegistration: AnyObject?

    private let host = UIHostingController<AnyView>(rootView: AnyView(
        AppRootView()
            .environmentObject(RyujinxController.shared)
            .environmentObject(ThemeManager.shared)
            .withAppTheme()
    ))

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("Use init()")
    }
    
    override var childForStatusBarStyle: UIViewController? { host }
    override var childForStatusBarHidden: UIViewController? { host }
    override var childForHomeIndicatorAutoHidden: UIViewController? { host }
    override var childViewControllerForPointerLock: UIViewController? { host }

    override func viewDidLoad() {
        super.viewDidLoad()

        controllerUserInteractionEnabled = false

        addChild(host)

        host.view.frame = view.bounds
        host.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        view.addSubview(host.view)
        host.didMove(toParent: self)

        #if CANDELA_IOS27_AIRPLAY
        if #available(iOS 27.0, *) {
            let configuration = UISceneConfiguration()
            configuration.delegateClass = ExternalDisplaySceneDelegate.self
            displayRegistration = registerSceneAccessory(
                .externalNonInteractive(sceneConfiguration: configuration)
            )
        }
        #endif
    }
}

private struct AppRootView: View {
    @EnvironmentObject var ryujinxController: RyujinxController
    @AppStorage("hasSetupFinished") private var hasSetupFinished = false
    @AppStorage("lastAppversion") private var lastAppversion = Data()

    var body: some View {
        ContentView()
            .onAppear {
                var previousVersion: Float = 0
                if lastAppversion.count == MemoryLayout<Float>.size {
                    _ = withUnsafeMutableBytes(of: &previousVersion) { lastAppversion.copyBytes(to: $0) }
                }
                let currentVersion = Float(Bundle.main.versionNumber) ?? .zero
                if previousVersion < currentVersion {
                    var value = currentVersion
                    lastAppversion = Data(bytes: &value, count: MemoryLayout<Float>.size)
                    hasSetupFinished = false
                }
            }
            .sheet(isPresented: .constant(!hasSetupFinished)) {
                SetupView {
                    hasSetupFinished = true
                    ryujinxController.loadGames()
                }
                .interactiveDismissDisabled()
                .withAppTheme()
            }
    }
}
