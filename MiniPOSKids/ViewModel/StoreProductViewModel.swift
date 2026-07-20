//
//  StoreItemViewModel.swift
//  MiniPOSKids
//
//  Created by sako0602 on 2026/04/21.
//

import Foundation
import OSLog

// ProductBarcodeViewで使用されているため、命名の修正が必要
@MainActor
@Observable
final class StoreProductViewModel {

    var errorMessage: String?
    let storeId: String
    var products: [Product] = []
    private let storeItemService: StoreProductServiceProtocol
    private let logger = Logger(subsystem: "com.miniposkids.storeitems", category: "StoreItemViewModel")
    var onSessionExpired: (() -> Void)?

    init(storeItemService: StoreProductServiceProtocol, storeId: String) {
        self.storeItemService = storeItemService
        self.storeId = storeId
    }

    func getStoreItems() async {
        do {
            products = try await storeItemService.fetchStoreItems(storeId: storeId)
            errorMessage = nil
            logger.info("getStores: 成功 count=\(self.products.count)")
        } catch is CancellationError {
            logger.debug("getStores: キャンセル")
        } catch APIError.sessionExpired {
            logger.warning("getStores: セッション期限切れ → ログアウト")
            onSessionExpired?()
        } catch {
            logger.error("getStores: 失敗 error=\(error)")
            errorMessage = "店舗の商品一覧の取得に失敗しました"
        }
    }
}
