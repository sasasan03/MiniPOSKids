//
//  DemoStoreService.swift
//  MiniPOSKids
//

import Foundation

/// デモモード用の店舗サービス。API を呼ばずに `DemoCatalog` の内容を返す。
struct DemoStoreService: StoreServiceProtocol {

    /// サンプル店舗一覧を返す。
    /// - Returns: `DemoCatalog.stores`。
    func fetchStore() async throws -> [StoreResponse] {
        DemoCatalog.stores
    }
}
