//
//  AuthRootView.swift
//  MiniPOSKids
//
//  Created by sako0602 on 2026/04/13.
//

import SwiftUI

struct AuthRootView: View {
    @Environment(AppState.self) private var appState
    @State private var router = AuthRouter()
    @State private var authService: AuthService
    
    init(tokenStore: TokenStoreProtocol) {
        let apiClient = APIClient(baseURL: "https://id.smaregi.dev")
        let authService = AuthService(apiClient: apiClient, tokenStore: tokenStore)
        apiClient.tokenRefresher = authService
        _authService = State(initialValue: authService)
    }

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
            LoginView(authService: authService)
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
    private let tokenStore: TokenStoreProtocol
    @State private var appState: AppState

    init() {
        let store = InMemoryTokenStore()
        tokenStore = store
        _appState = State(initialValue: AppState(tokenStore: store))
    }

    var body: some View {
        AuthRootView(tokenStore: tokenStore)
            .environment(appState)
    }
}
