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
    private let contractIdProvider: any ContractIdProviding
    private let logger = Logger(subsystem: "com.miniposkids.storeitems", category: "StoreItemService")
    
    init(apiClient: APIClientProtocol, contractIdProvider: any ContractIdProviding) {
        self.apiClient = apiClient
        self.contractIdProvider = contractIdProvider
    }
    
    func fetchStoreItems(storeId: String) async throws -> [Product] {
        do {
            // 契約IDはログイン時のアクセストークンから決まるため、リクエストごとに取得する。
            let encodedContractId = try await contractIdProvider.currentContractId().percentEncodedPathComponent
            let encodedStoreId = storeId.percentEncodedPathComponent
            let itemsResponse: [StoreItemResponseDTO] = try await apiClient.send(
                path: "/\(encodedContractId)/pos/stores/\(encodedStoreId)/products",
                method: .get,
                headers: [:]
            )
            var products: [Product] = []
            for item in itemsResponse {
                let product = try Product(dto: item)
                products.append(product)
            }
            logger.info("fetchStoreItems: 成功 count=\(itemsResponse.count)")
            return products
        } catch {
            logger.error("fetchStoreItems: 失敗 error=\(error)")
            throw error
        }
    }
    
    func fetchStoreItem(productID: String) async throws -> Product? {
        do {
            let encodedContractId = try await contractIdProvider.currentContractId().percentEncodedPathComponent
            let encodedProductID = productID.percentEncodedPathComponent
            let itemResponse: StoreItemResponseDTO = try await apiClient.send(
                path: "/\(encodedContractId)/pos/products/\(encodedProductID)",
                method: .get,
                headers: [:]
            )
            logger.info("fetchItem: 成功")
            return try Product.init(dto: itemResponse)
        } catch {
            logger.error("fetchItem: 失敗 error=\(error)")
            throw error
        }
        
    }
}



private extension Product {
    init(dto: StoreItemService.StoreItemResponseDTO) throws {
        guard let dtoPrice = Int(dto.price) else {
            throw StoreProductMappingError.invalidPrice(productID: dto.productId, rawPrice: dto.price)
        }
        self.productID = dto.productId
        self.name = dto.productName
        self.price = dtoPrice
    }
}
