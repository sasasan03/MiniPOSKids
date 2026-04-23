//
//  StoreItemViewModel.swift
//  MiniPOSKids
//
//  Created by sako0602 on 2026/04/21.
//

import Foundation
import OSLog

@MainActor
@Observable
final class StoreItemViewModel {

    var errorMessage: String?
    let storeId: String
    var items: [StoreItemResponse] = []
    private let storeItemService: StoreItemServiceProtocol
    private let logger = Logger(subsystem: "com.miniposkids.storeitems", category: "StoreItemViewModel")
    var onSessionExpired: (() -> Void)?

    init(storeItemService: StoreItemServiceProtocol, storeId: String) {
        self.storeItemService = storeItemService
        self.storeId = storeId
    }

    func getStoreItems() async {
        logger.info("getStores: 開始")
        do {
            items = try await storeItemService.fetchStoreItem(storeId: storeId)
            errorMessage = nil
            logger.info("getStores: 成功 count=\(self.items.count)")
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
