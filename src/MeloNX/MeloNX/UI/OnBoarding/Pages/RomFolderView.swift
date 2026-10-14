// SPDX-License-Identifier: AGPL-3.0-or-later
//
//  RomFolderView.swift
//  Candela
//
//  Last first-launch step: an optional games folder. Games can also be added
//  later, from anywhere.
//

import SwiftUI
import UniformTypeIdentifiers

struct RomFolderView: View {
    var finish: () -> Void

    @StateObject private var folderManager = ROMFolderManager.shared
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let p = CandelaPalette(dark: scheme == .dark)
        CandelaStepPage(
            step: 4, of: 4,
            symbol: "folder.badge.plus",
            title: "Pick a games folder",
            message: "Optional. If your games live in one folder, Candela can watch it. You can also skip this and add games from anywhere, any time.",
            primaryTitle: folderManager.bookmarks.isEmpty ? "Skip for now" : "Open my library",
            primaryAction: finish
        ) {
            VStack(spacing: 12) {
                ForEach(folderManager.bookmarks, id: \.self) { bookmark in
                    CandelaStatusRow(
                        symbol: "folder.fill",
                        title: folderManager.getUrl(from: bookmark)?.lastPathComponent ?? "Unknown folder",
                        chip: "Added",
                        chipTint: .candelaGood
                    )
                }
                Button(folderManager.bookmarks.isEmpty ? "Choose a folder" : "Add another folder") {
                    FileImporterManager.shared.importFiles(types: [.folder]) { result in
                        if case .success(let urls) = result {
                            for url in urls { _ = folderManager.addFolder(url: url) }
                            RyujinxController.shared.loadGames()
                        }
                    }
                }
                .buttonStyle(CandelaSecondaryButtonStyle())
                Text("Folders can be changed in Settings.")
                    .font(.footnote)
                    .foregroundColor(p.inkSoft)
            }
        }
    }
}
