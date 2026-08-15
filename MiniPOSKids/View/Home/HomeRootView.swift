//
//  HomeRootView.swift
//  MiniPOSKids
//
//  Created by sako0602 on 2026/04/13.
//

import SwiftUI

struct HomeRootView: View {
    @State private var router = HomeRouter()
    
    private let authService: AuthService
    private let storeService: StoreServiceProtocol
    private let storeItemService: StoreProductServiceProtocol

    // AppStoreからトークンを取得（キーチェーンのリフレッシュトークン）するためのtokenStore。
    // contractId（契約者ID）はapi.smaregi.devのapiを呼び出すために必要
    init(
        tokenStore: TokenStoreProtocol,
        contractId: String = AppConfig.smaregiContractId
    ) {
        // 認証取得用APIClient
        let authApiClient = APIClient(baseURL: "https://id.smaregi.dev")
        let authService = AuthService(apiClient: authApiClient, tokenStore: tokenStore)

        // 店舗・商品情報取得用APIClient。認可ページから返されるアクセストークンが必要
        let platformApiClient = APIClient(baseURL: "https://api.smaregi.dev")
        // APIリクエスト → 401エラー → tokenRefresher.refreshToken() → 再リクエスト
        platformApiClient.tokenRefresher = authService

        self.authService = authService
        self.storeService = StoreService(apiClient: platformApiClient, contractId: contractId)
        self.storeItemService = StoreItemService(apiClient: platformApiClient, contractId: contractId)
    }
    
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
        case .setting:
            SettingView(viewModel: SettingViewModel())
                .navigationTitle("設定")
        case .storeList:
            StoreListView(viewModel: StoreListViewModel(storeService: storeService))
                .navigationTitle("登録店舗一覧")
        case .printProductBarcode(let storeId):
            ProductBarcodeView(viewModel: StoreProductViewModel(storeItemService: storeItemService, storeId: storeId))
                .navigationTitle("商品バーコード一覧")
        case .selectAvailableBalance:
            SelectAvailableBalanceView()
                .navigationTitle("利用可能残高選択画面")
        case .showBuyerQRCode(let price):
            BuyerQRCodeView(qrCodePrice: price)
                .navigationTitle("QRコード決済画面")
        case .cashRegister:
            CashRegisterView(viewModel: CashRegisterViewModel(storeItemService: storeItemService))
                .navigationTitle("レジ画面")
        case .scanProductBarcode:
            ScanProductBarcodeView()
                .navigationTitle("バーコード読み取り画面")
        case .scanQRCode(let totalAmount, let cartProducts):
            ScanQRCodeView(totalAmount: totalAmount, cartProducts: cartProducts)
                .navigationTitle("QRコード読み取り画面")
        case .purchaseResult(
            let isSuccess,
            let totalAmount,
            let qrCodeValue,
            let cartProducts
        ):
            PurchaseResultView(
                viewModel: PurchaseViewModel(
                    cartProducts: cartProducts,
                    totalAmount: totalAmount,
                    qrCodeValue: qrCodeValue
                ),
                isSuccess: isSuccess
            )
        }
    }
}

#Preview {
    HomeRootView(tokenStore: InMemoryTokenStore(), contractId: "preview_contract_id")
        .environment(AppState())
}
