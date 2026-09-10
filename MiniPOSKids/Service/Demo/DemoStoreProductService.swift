//
//  DemoStoreProductService.swift
//  MiniPOSKids
//

import Foundation

/// デモモード用の商品サービス。API を呼ばずに `DemoCatalog` の内容を返す。
struct DemoStoreProductService: StoreProductServiceProtocol {

    /// 指定店舗のサンプル商品一覧を返す。
    /// - Parameter storeId: `DemoCatalog.stores` の店舗 ID。
    /// - Returns: 該当店舗のサンプル商品。
    func fetchStoreItems(storeId: String) async throws -> [Product] {
        DemoCatalog.products(forStoreId: storeId)
    }

    /// バーコードに対応するサンプル商品を返す。
    /// - Parameter productID: 読み取られたバーコードの値。
    /// - Returns: 一致する商品。存在しなければ nil。
    func fetchStoreItem(productID: String) async throws -> Product? {
        DemoCatalog.product(forProductID: productID)
    }
}
