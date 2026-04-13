//
//  HomeView.swift
//  MiniPOSKids
//
//  Created by sako0602 on 2026/04/12.
//

import SwiftUI

struct HomeView: View {
    
    @State private var router = HomeRouter()
    
    var body: some View {
        List {
            Button("登録店舗一覧") {
                router.navigationHomeRoutePush(.printProductBarcode)
            }
            Button("利用可能残高選択"){
                router.navigationHomeRoutePush(.showBuyerQRCode)
            }
            Button("レジ画面"){
                router.navigationHomeRoutePush(.cashRegister)
            }
        }
    }
}

#Preview {
    HomeView()
}
