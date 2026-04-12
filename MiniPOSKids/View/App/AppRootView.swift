//
//  AppRootView.swift
//  MiniPOSKids
//
//  Created by sako0602 on 2026/04/09.
//

import SwiftUI

struct AppRootView: View {
    @State private var path = AuthRouter()
    
    var body: some View {
        NavigationStack(path: $path.path) {
            root
                .navigationDestination(for: AuthRoute.self) { route in
                    switch route {
                    case .home:
                        HomeView()
                    case .login:
                        LoginView()
                    case .web:
                        SmaregiWebView()
                    }
                }
        }
        .environment(path)
    }
        
    
    @ViewBuilder
    private var root: some View {
        if path.path.isEmpty {
            LoginView()
        } else {
            Text("未実装")
        }

    }
}

#Preview {
    AppRootView()
}
