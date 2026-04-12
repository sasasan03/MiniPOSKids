//
//  HomeView.swift
//  MiniPOSKids
//
//  Created by sako0602 on 2026/04/12.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationStack {
            List {
                Text("Hello, World!")
            }
            .navigationDestination(for: HomeRoute.self) { route in
                switch route {
                case .home:
                    Text("ホーム画面")
                case .storeList:
                    Text("登録店舗一覧")
                case .printProductBarcode:
                    Text("商品バーコード")
                case .selectAvailableBalance:
                    Text("利用可能残高選択画面")
                case .showBuyerQRCode:
                    Text("QRコード決済画面（購入者がわ）")
                case .cashRegister:
                    Text("レジ画面")
                case .scanProductBarcode:
                    Text("バーコード読み取り画面")
                case .purchaseSuccess:
                    Text("購入完了画面")
                case .purchaseFailure:
                    Text("購入失敗画面")
                }
            }
        }
    }
}

#Preview {
    HomeView()
}
