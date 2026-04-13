//
//  HomeRootView.swift
//  MiniPOSKids
//
//  Created by sako0602 on 2026/04/13.
//

import SwiftUI

struct HomeRootView: View {
    @State private var router = HomeRouter()
    
    var body: some View {
        NavigationStack(path: $router.path) {
            makeView(route: .home)
                .navigationDestination(for: HomeRoute.self) { route in
                    makeView(route: route)
                }
        }
        .environment(router)
    }
    
    @ViewBuilder
    private func makeView(route: HomeRoute) -> some View {
        switch route {
        case .home:
            HomeView()
        case .storeList:
            StoreListView()
                .navigationTitle("登録店舗一覧")
        case .printProductBarcode:
            ProductBarcodeView()
                .navigationTitle("商品バーコード")
        case .selectAvailableBalance:
            SelectAvailableBalanceView()
                .navigationTitle("利用可能残高選択画面")
        case .showBuyerQRCode:
            BuyerQRCodeView()
                .navigationTitle("QRコード決済画面")
        case .cashRegister:
            CashRegisterView()
                .navigationTitle("レジ画面")
        case .scanProductBarcode:
            ScanProductBarcodeView()
                .navigationTitle("バーコード読み取り画面")
        case .purchaseSuccess:
            PurchaseSuccessView()
                .navigationTitle("支払い完了")
        case .purchaseFailure:
            PurchaseFailureView()
                .navigationTitle("支払い失敗")
        }
    }
}

#Preview {
    HomeRootView()
}
