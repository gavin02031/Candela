//
//  FirmwareView.swift
//  Candela
//
//  Created by Stossy11 on 6/7/2026.
//

import SwiftUI
import UniformTypeIdentifiers

struct FirmwareView: View {
    var goForward: () -> Void
    
    var fileImporter: FileImporterManager = .shared
    @ObservedObject var ryujinxController: RyujinxController = .shared
    let fileManager: FileManager = .default
    
    @State var fwAdded: Bool = false
    
    private var isInstalling: Bool {
        ryujinxController.firmwareInstallState.isInstalling
    }
    
    private var failureMessage: String? {
        if case .failed(let message) = ryujinxController.firmwareInstallState { return message }
        return nil
    }
    
    private var supportedSources: String {
        AppEnvironment.shared.needsAsCopy ? "Zip or XCI" : "Zip, Folder or XCI"
    }
    
    var body: some View {
        CandelaStepPage(
            step: 3, of: 4,
            symbol: fwAdded ? "checkmark.circle" : (failureMessage == nil ? "externaldrive" : "exclamationmark.circle"),
            title: "Import firmware",
            message: fwAdded
                ? "Firmware \(ryujinxController.firmwareVersion) is installed. You can replace it any time from the library."
                : "Import your firmware as \(supportedSources), dumped from your own hardware.",
            primaryTitle: "Continue",
            primaryEnabled: fwAdded && !isInstalling,
            primaryAction: goForward
        ) {
            VStack(spacing: 12) {
                if let failureMessage {
                    Text(failureMessage)
                        .font(.footnote)
                        .foregroundColor(.candelaBad)
                        .multilineTextAlignment(.center)
                }
                if isInstalling {
                    ProgressView()
                    Text("Installing firmware...")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                } else {
                    Button(buttonTitle, action: importFirmware)
                        .buttonStyle(CandelaSecondaryButtonStyle())
                }
            }
            .animation(.default, value: ryujinxController.firmwareInstallState)
        }
        .onAppear(perform: checkForFirmware)
        .onChange(of: ryujinxController.firmwareInstallState) { _ in
            checkForFirmware()
        }
    }
    
    private var buttonTitle: LocalizedStringKey {
        if failureMessage != nil { return "Try Again" }
        return fwAdded ? "Replace Firmware" : "Import"
    }
    
    func importFirmware() {
        guard !isInstalling else { return }
        
        fileImporter.importFiles(types: [.folder, .zip, .xci], allowMultiple: false, securityScoped: false) { result in
            ryujinxController.handleFirmwareImport(result: result)
        }
    }
    
    func checkForFirmware() {
        fwAdded = ryujinxController.firmwareInstalled
    }
}
