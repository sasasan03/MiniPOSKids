//
//  StoreService.swift
//  MiniPOSKids
//
//  Created by sako0602 on 2026/04/19.
//

import Foundation
import OSLog

protocol StoreServiceProtocol {
    func fetchStore() async throws -> [StoreResponse]
}

struct StoreService: StoreServiceProtocol {

    private let apiClient: APIClientProtocol
    private let contractId: String
    private let logger = Logger(subsystem: "com.miniposkids.stores", category: "StoreService")

    init(apiClient: APIClientProtocol, contractId: String) {
        self.apiClient = apiClient
        self.contractId = contractId
    }
    
    func fetchStore() async throws -> [StoreResponse] {
        logger.info("fetchStore: 開始")
        do {
            var allowed = CharacterSet.urlPathAllowed
            // URLを構築するものを許可するが、/は使えない。予約文字禁止させる。
            allowed.remove(charactersIn: "/")
            // 除外された文字を使った場合「%〜〜」の形の文字列にして返される
            let encodedContractId = contractId.addingPercentEncoding(withAllowedCharacters: allowed) ?? contractId
            let storeResponses: [StoreResponse] = try await apiClient.send(
                path: "/\(encodedContractId)/pos/stores?limit=1000&sort=storeId:asc",
                method: .get,
                headers: [:]
            )
            logger.info("fetchStore: 成功 count=\(storeResponses.count)")
            return storeResponses
        } catch {
            logger.error("fetchStore: 失敗 error=\(error)")
            throw error
        }
    }
}
