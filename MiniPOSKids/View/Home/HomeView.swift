//
//  HomeView.swift
//  MiniPOSKids
//
//  Created by sako0602 on 2026/04/12.
//

import SwiftUI

struct HomeView: View {
    
    @Environment(HomeRouter.self) var router
    
    var body: some View {
        List {
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
    }
}

#Preview {
    HomeView()
        .environment(HomeRouter())
}
