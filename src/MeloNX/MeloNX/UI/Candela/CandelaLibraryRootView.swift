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
    @AppStorage("candelaNewHome") private var useNewHome = true

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
    @AppStorage("candelaNewHome") private var useNewHome = true

    var body: some View {
        Toggle("New Candela Home (beta)", isOn: $useNewHome)
    }
}
