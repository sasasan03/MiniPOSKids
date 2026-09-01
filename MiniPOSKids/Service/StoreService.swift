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
    private let contractIdProvider: any ContractIdProviding
    private let logger = Logger(subsystem: "com.miniposkids.stores", category: "StoreService")

    init(apiClient: APIClientProtocol, contractIdProvider: any ContractIdProviding) {
        self.apiClient = apiClient
        self.contractIdProvider = contractIdProvider
    }
    
    func fetchStore() async throws -> [StoreResponse] {
        do {
            // 契約IDはログイン時のアクセストークンから決まるため、リクエストごとに取得する。
            let encodedContractId = try await contractIdProvider.currentContractId().percentEncodedPathComponent
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
