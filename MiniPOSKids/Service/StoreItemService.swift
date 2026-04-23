//
//  StoreItemService.swift
//  MiniPOSKids
//
//  Created by sako0602 on 2026/04/21.
//

import Foundation
import OSLog

protocol StoreItemServiceProtocol {
    func fetchStoreItem(storeId: String) async throws -> [StoreItemResponse]
}

struct StoreItemService: StoreItemServiceProtocol {
    
    private let apiClient: APIClientProtocol
    private let contractId: String
    private let logger = Logger(subsystem: "com.miniposkids.storeitems", category: "StoreItemService")
    
    init(apiClient: APIClientProtocol, contractId: String) {
        self.apiClient = apiClient
        self.contractId = contractId
    }
    
    func fetchStoreItem(storeId: String) async throws -> [StoreItemResponse] {
        logger.info("fetchItem: 開始")
        do {
            var allowed = CharacterSet.urlPathAllowed
            // URLを構築するものを許可するが、/は使えない。予約文字禁止させる。
            allowed.remove(charactersIn: "/")
            // 除外された文字を使った場合「%〜〜」の形の文字列にして返される
            let encodedContractId = contractId.addingPercentEncoding(withAllowedCharacters: allowed) ?? contractId
            let encodedStoreId = storeId.addingPercentEncoding(withAllowedCharacters: allowed) ?? storeId
            let itemResponse: [StoreItemResponse] = try await apiClient.send(
                path: "/\(encodedContractId)/pos/stores/\(encodedStoreId)/products",
                method: .get,
                headers: [:]
            )
            logger.info("fetchItem: 成功 count=\(itemResponse.count)")
            return itemResponse
        } catch {
            logger.error("fetchItem: 失敗 error=\(error)")
            throw error
        }
    }
}
