//
//  DemoCatalog.swift
//  MiniPOSKids
//

import Foundation

/// デモモードで表示するサンプルデータ。
///
/// スマレジのアカウント登録・API 通信なしでアプリの全機能を体験できるようにするため、
/// 店舗一覧・商品一覧・バーコード読み取り結果のすべてをここ 1 箇所から供給する。
enum DemoCatalog {

    /// デモモードで表示するサンプル店舗。
    static let stores: [StoreResponse] = [
        StoreResponse(storeId: "demo-store-1", storeName: "デモ商店（おかしコーナー）"),
        StoreResponse(storeId: "demo-store-2", storeName: "デモ商店（のみものコーナー）"),
    ]

    /// デモモードで表示するサンプル商品。バーコードの値は `productID` をそのまま使う。
    static let products: [Product] = [
        Product(productID: "4900000000001", name: "チョコレート", price: 120),
        Product(productID: "4900000000002", name: "ポテトチップス", price: 150),
        Product(productID: "4900000000003", name: "グミ", price: 100),
        Product(productID: "4900000000004", name: "オレンジジュース", price: 130),
        Product(productID: "4900000000005", name: "ぎゅうにゅう", price: 200),
        Product(productID: "4900000000006", name: "アイスクリーム", price: 250),
    ]

    /// 店舗ごとのサンプル商品を返す。
    /// - Parameter storeId: `stores` に含まれる店舗 ID。
    /// - Returns: 該当店舗の商品一覧。未知の ID の場合は全商品。
    static func products(forStoreId storeId: String) -> [Product] {
        switch storeId {
        case "demo-store-1": return Array(products.prefix(3))
        case "demo-store-2": return Array(products.suffix(3))
        default: return products
        }
    }

    /// バーコード（商品 ID）からサンプル商品を引く。
    /// - Parameter productID: 読み取られたバーコードの値。
    /// - Returns: 一致する商品。存在しなければ nil。
    static func product(forProductID productID: String) -> Product? {
        products.first { $0.productID == productID }
    }
}
