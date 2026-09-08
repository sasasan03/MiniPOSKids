//
//  SettingView.swift
//  MiniPOSKids
//
//  Created by sako0602 on 2026/08/14.
//

import SwiftUI

struct SettingView: View {
    
    @Environment(AppState.self) private var appState
    @State private var viewModel: SettingViewModel
    
    init(viewModel: SettingViewModel) {
        _viewModel = State(initialValue: viewModel)
    }
    
    var body: some View {
        List(viewModel.settingMenus){ menu in
            Button {
                viewModel.handle(menu)
            } label: {
                Text(viewModel.title(for: menu))
            }
        }
        .alert(viewModel.logoutAlertTitle, isPresented: $viewModel.isLogoutAlertPresented) {
            Button("キャンセル", role: .cancel) {
                viewModel.dismissLogoutAlert()
            }
            Button(viewModel.logoutConfirmTitle, role: .destructive) {
                appState.logout()
            }
        }
    }
}

#Preview {
    SettingView(viewModel: SettingViewModel(isDemo: true))
        .environment(AppState(tokenStore: InMemoryTokenStore()))
}
