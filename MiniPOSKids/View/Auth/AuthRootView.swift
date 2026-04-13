//
//  AuthRootView.swift
//  MiniPOSKids
//
//  Created by sako0602 on 2026/04/13.
//

import SwiftUI

struct AuthRootView: View {
    @State private var router = AuthRouter()
    
    var body: some View {
        NavigationStack(path: $router.path) {
            makeView(route: .login)
                .navigationDestination(for: AuthRoute.self) { route in
                    makeView(route: route)
                }
        }
        .environment(router)
    }
    
    @ViewBuilder
    private func makeView(route: AuthRoute) -> some View {
        switch route {
        case .login:
            LoginView()
        case .web:
            SmaregiWebView()
                .navigationTitle("スマレジデベロッパー")
        }
    }
}

#Preview {
    PreviewContainer()
}

private struct PreviewContainer: View {
    @State private var appState = AppState()
    
    var body: some View {
        AuthRootView()
            .environment(appState)
    }
}
