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
                Text(menu.title)
            }
        }
        .alert("ログアウトしますか？", isPresented: $viewModel.isLogoutAlertPresented) {
            Button("キャンセル", role: .cancel) {
                viewModel.dismissLogoutAlert()
            }
            Button("ログアウト", role: .destructive) {
                appState.logout()
            }
        }
    }
}

#Preview {
    SettingView(viewModel: SettingViewModel())
        .environment(AppState())
}
