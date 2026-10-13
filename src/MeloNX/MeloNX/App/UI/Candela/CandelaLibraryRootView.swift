//
//  CandelaLibraryRootView.swift
//  Candela
//
//  Chooses between the classic library and the new Candela home. The new home is
//  off by default, and it has a "Use classic library" button, so it can never
//  trap the user.
//

import SwiftUI

struct CandelaLibraryRootView: View {
    @AppStorage("candelaNewHome") private var useNewHome = false

    var body: some View {
        if useNewHome {
            CandelaHomeView()
        } else {
            GamesListView()
        }
    }
}

/// Settings row for the beta home screen.
struct CandelaHomeToggleRow: View {
    @AppStorage("candelaNewHome") private var useNewHome = false

    var body: some View {
        SettingsToggle(
            isOn: $useNewHome,
            icon: "square.grid.2x2",
            label: "New Candela Home (beta)",
            infoMessage: "Try the new home screen with Continue Playing, Recently Added and Favorites. Turn it off to return to the classic library."
        )
    }
}
