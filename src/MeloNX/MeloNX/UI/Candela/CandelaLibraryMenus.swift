// SPDX-License-Identifier: AGPL-3.0-or-later
// Library actions for the Candela home: add games, firmware, folders, profiles, and the per-game tools.
import SwiftUI
import UniformTypeIdentifiers
import Melo_Controller

enum CandelaLibraryActions {
    @MainActor
    static func addGame(_ controller: RyujinxController) {
        FileImporterManager.shared.importFiles(types: [.nsp, .xci, .item]) { result in
            controller.handleAddingGame(result: result)
        }
    }

    @MainActor
    static func openGame(_ controller: RyujinxController) {
        FileImporterManager.shared.importFiles(types: [.nsp, .xci, .item]) { result in
            controller.handleRunningGame(result: result)
        }
    }

    @MainActor
    static func importFirmware(_ controller: RyujinxController) {
        FileImporterManager.shared.importFiles(types: [.folder, .zip, .xci], securityScoped: false) { result in
            controller.handleFirmwareImport(result: result)
        }
    }

    @MainActor
    static func deleteGame(_ game: GameInfo, controller: RyujinxController) {
        try? FileManager.default.removeItem(at: game.fileURL)
        controller.loadGames()
    }
}

/// Items for the library options menu (home status pill).
struct CandelaLibraryMenuItems: View {
    @EnvironmentObject private var ryujinxController: RyujinxController
    var onAccount: () -> Void

    var body: some View {
        Button {
            CandelaLibraryActions.addGame(ryujinxController)
        } label: {
            Label("Add Game", systemImage: "plus")
        }
        Button {
            CandelaLibraryActions.openGame(ryujinxController)
        } label: {
            Label("Open Game", systemImage: "square.and.arrow.down")
        }
        Button {
            ryujinxController.loadGames()
        } label: {
            Label("Reload Games", systemImage: "arrow.clockwise")
        }
        Button {
            URL.documentsDirectory.openInFiles()
        } label: {
            Label("Show Candela Folder", systemImage: "folder")
        }

        Divider()

        if ryujinxController.firmwareInstallState.isInstalling {
            Button {} label: {
                Label("Installing Firmware\u{2026}", systemImage: "hourglass")
            }
            .disabled(true)
        } else if ryujinxController.firmwareInstalled {
            Section("Firmware: \(ryujinxController.firmwareVersion)") {
                Menu("Applets") {
                    Button {
                        let game = GameInfo(containerFolder: URL(string: "none")!, fileType: .item, fileURL: URL(string: "0x0100000000001009")!, titleName: "Mii Maker", titleId: "0", developer: "Nintendo", version: ryujinxController.firmwareVersion)
                        ryujinxController.startGame(game)
                    } label: {
                        Label("Launch Mii Maker", systemImage: "person.crop.circle")
                    }
                }
                Button {
                    CandelaLibraryActions.importFirmware(ryujinxController)
                } label: {
                    Label("Update Firmware", systemImage: "arrow.down.circle")
                }
            }
        } else {
            Button {
                CandelaLibraryActions.importFirmware(ryujinxController)
            } label: {
                Label("Install Firmware", systemImage: "square.and.arrow.down")
            }
        }

        Divider()

        Button(action: onAccount) {
            Label("Profile Manager", systemImage: "person.2")
        }
    }
}

/// Per-game long-press items: the same tools the old list offered.
struct CandelaGameMenuItems: View {
    @EnvironmentObject private var ryujinxController: RyujinxController
    let game: GameInfo
    @Binding var activeSheet: ActiveSheet?
    @Binding var controllerEditor: GameInfo?

    var body: some View {
        Section {
            Button {
                ryujinxController.startGame(game)
            } label: {
                Label("Play Now", systemImage: "play.fill")
            }
            Button {
                activeSheet = .gameInfo(game: game)
            } label: {
                Label("Game Info", systemImage: "info.circle")
            }
            Button {
                activeSheet = .perGameSettings(game: game)
            } label: {
                Label("\(game.titleName) Settings", systemImage: ryujinxController.hasPerGameConfig(game.titleId) ? "checkmark.circle" : "gear")
            }
            Button {
                controllerEditor = game
            } label: {
                Label("Controller Layout", systemImage: "formfitting.gamecontroller")
            }
        }

        Section {
            Button {
                activeSheet = .update(game: game)
            } label: {
                Label("Update Manager", systemImage: "arrow.up.circle")
            }
            Button {
                activeSheet = .dlc(game: game)
            } label: {
                Label("DLC Manager", systemImage: "plus.circle")
            }
            Button {
                activeSheet = .mods(game: game)
            } label: {
                Label("Mod Manager", systemImage: "folder.circle")
            }
            Menu {
                ForEach(SaveDataType.allCases) { type in
                    Button {
                        ryujinxController.openSaveDirectory(for: game, type: type)
                    } label: {
                        Label(type.name, systemImage: type.symbol)
                    }
                }
            } label: {
                Label("Open Save Directory", systemImage: "folder")
            }
        }

        Section {
            Button(role: .destructive) {
                ryujinxController.clearShaderCacheWithConfirmation(game)
            } label: {
                Label("Clear Shader Cache", systemImage: "trash")
            }
            Button(role: .destructive) {
                CandelaLibraryActions.deleteGame(game, controller: ryujinxController)
            } label: {
                Label("Delete Game", systemImage: "trash")
            }
        }
    }
}
