//
//  StoreProductService.swift
//  MiniPOSKids
//
//  Created by sako0602 on 2026/04/21.
//

import Foundation
import OSLog

protocol StoreProductServiceProtocol {
    func fetchStoreItems(storeId: String) async throws -> [Product]
    func fetchStoreItem(productID: String) async throws -> Product?
}

struct StoreItemService: StoreProductServiceProtocol {
    
    struct StoreItemResponseDTO: Decodable {
        let productId: String
        let productName: String
        let price: String
    }
    
    private let apiClient: APIClientProtocol
    private let contractId: String
    private let logger = Logger(subsystem: "com.miniposkids.storeitems", category: "StoreItemService")
    
    init(apiClient: APIClientProtocol, contractId: String) {
        self.apiClient = apiClient
        self.contractId = contractId
    }
    
    func fetchStoreItems(storeId: String) async throws -> [Product] {
        do {
            var allowed = CharacterSet.urlPathAllowed
            // URLを構築するものを許可するが、/は使えない。予約文字禁止させる。
            allowed.remove(charactersIn: "/")
            // 日本語を%〜〜の形に変換する
            let encodedContractId = contractId.addingPercentEncoding(withAllowedCharacters: allowed) ?? contractId
            let encodedStoreId = storeId.addingPercentEncoding(withAllowedCharacters: allowed) ?? storeId
            let itemsResponse: [StoreItemResponseDTO] = try await apiClient.send(
                path: "/\(encodedContractId)/pos/stores/\(encodedStoreId)/products",
                method: .get,
                headers: [:]
            )
            var products: [Product] = []
            itemsResponse.forEach {
                products.append(Product(dto: $0))
            }
            logger.info("fetchItem: 成功 count=\(itemsResponse.count)")
            return products
        } catch {
            logger.error("fetchItem: 失敗 error=\(error)")
            throw error
        }
    }
    
    func fetchStoreItem(productID: String) async throws -> Product? {
        do {
            var allowed = CharacterSet.urlPathAllowed
            allowed.remove(charactersIn: "/")
            let encodedContractId = contractId.addingPercentEncoding(withAllowedCharacters: allowed) ?? contractId
            let itemResponse: StoreItemResponseDTO = try await apiClient.send(
                path: "/\(encodedContractId)/pos/products/\(productID)",
                method: .get,
                headers: [:]
            )
            logger.info("fetchItem: 成功")
            return Product.init(dto: itemResponse)
        } catch {
            logger.error("fetchItem: 失敗 error=\(error)")
            throw error
        }
        
    }
}

private extension Product {
    init(dto: StoreItemService.StoreItemResponseDTO) {
        self.productID = dto.productId
        self.name = dto.productName
        self.price = Int(dto.price) ?? 0
    }
}
