//
//  StoreListViewModel.swift
//  MiniPOSKids
//
//  Created by sako0602 on 2026/04/19.
//

import Foundation
import OSLog

@MainActor
@Observable
final class StoreListViewModel {
    
    var errorMessage: String?
    var stores: [StoreResponse] = []
    private let storeService: StoreServiceProtocol
    private let logger = Logger(subsystem: "com.miniposkids.stores", category: "StoreListViewModel")

    init(storeService: StoreServiceProtocol) {
        self.storeService = storeService
    }

    func getStores() async {
        logger.info("getStores: 開始")
        do {
            stores = try await storeService.fetchStore()
            errorMessage = nil
            logger.info("getStores: 成功 count=\(self.stores.count)")
        } catch {
            logger.error("getStores: 失敗 error=\(error)")
            errorMessage = "店舗一覧の取得に失敗しました"
        }
    }
}
