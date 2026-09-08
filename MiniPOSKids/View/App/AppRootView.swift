//
//  AppRootView.swift
//  MiniPOSKids
//
//  Created by sako0602 on 2026/04/09.
//

import SwiftUI

struct AppRootView: View {
    @State private var appState = AppState()

    var body: some View {
        Group {
            switch appState.session {
            case .unauthenticated:
                AuthRootView(tokenStore: appState.tokenStore)
            case .authenticated:
                HomeRootView(tokenStore: appState.tokenStore, isDemo: false)
            case .demo:
                HomeRootView(tokenStore: appState.tokenStore, isDemo: true)
            }
        }
        .environment(appState)
    }
}

#Preview {
    AppRootView()
}
