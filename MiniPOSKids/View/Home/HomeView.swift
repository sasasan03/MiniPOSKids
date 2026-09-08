//
//  HomeView.swift
//  MiniPOSKids
//
//  Created by sako0602 on 2026/04/12.
//

import SwiftUI

struct HomeView: View {
    
    @Environment(HomeRouter.self) var router
    @Environment(AppState.self) private var appState
    
    var body: some View {
        List {
            if appState.isDemo {
                Section {
                    Label("デモモードで表示中です。サンプルの店舗・商品を使用しています。", systemImage: "info.circle")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            Row(title: "登録店舗一覧") {
                router.navigationHomeRoutePush(.storeList)
            }
            Row(title: "利用可能残高選択") {
                router.navigationHomeRoutePush(.selectAvailableBalance)
            }
            Row(title: "レジ画面") {
                router.navigationHomeRoutePush(.cashRegister)
            }
        }
        .toolbar {
            ToolbarItem(
                content: {
                    Button("設定", systemImage: "gearshape.fill", action: {
                        router.navigationHomeRoutePush(.setting)
                    })
                }
            )
        }
    }
}

#Preview {
    HomeView()
        .environment(HomeRouter())
        .environment(AppState(tokenStore: InMemoryTokenStore()))
}
