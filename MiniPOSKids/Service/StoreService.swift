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
        let storeResponses: [StoreResponse] = try await apiClient.send(
            path: "/\(contractId)/pos/stores?limit=1000&sort=storeId:asc",
            method: .get,
            headers: [:]
        )
        logger.info("fetchStore: 店舗一覧を取得しました count=\(storeResponses.count)")
        return storeResponses
    }
}
