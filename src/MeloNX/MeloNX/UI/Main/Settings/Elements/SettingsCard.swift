//
//  SettingsCard.swift
//  Candela
//
//  Row container used across settings. Uses the Candela surface on phones.
//

import SwiftUI

struct SettingsCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        if UIDevice.current.userInterfaceIdiom == .phone {
            content
                .padding()
                .candelaSurface(radius: 18)
                .padding(.horizontal)
        } else {
            VStack {
                Divider()
                content
                Divider()
            }
            .padding()
        }
    }
}
