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
            if appState.session == .unauthenticated {
                AuthRootView(tokenStore: appState.tokenStore)
            } else if appState.session == .authenticated {
                HomeRootView(tokenStore: appState.tokenStore)
            } else {
                Text("session is not set")
            }
        }
        .environment(appState)
    }
}

#Preview {
    AppRootView()
}
