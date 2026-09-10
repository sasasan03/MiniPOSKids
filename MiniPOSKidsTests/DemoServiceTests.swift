//
//  DemoServiceTests.swift
//  MiniPOSKidsTests
//

import Testing
@testable import MiniPOSKids

@Suite("デモモードのサービス")
struct DemoServiceTests {

    @Test("店舗一覧はサンプル店舗を返す")
    func fetchStoreReturnsDemoStores() async throws {
        let stores = try await DemoStoreService().fetchStore()
        #expect(stores.count == DemoCatalog.stores.count)
        #expect(stores.allSatisfy { !$0.storeName.isEmpty })
    }

    @Test("店舗ごとに商品が1件以上返る")
    func fetchStoreItemsReturnsProductsForEachStore() async throws {
        let service = DemoStoreProductService()
        for store in DemoCatalog.stores {
            let products = try await service.fetchStoreItems(storeId: store.storeId)
            #expect(!products.isEmpty)
        }
    }

    @Test("サンプル商品のバーコードから商品を引ける")
    func fetchStoreItemFindsProductByBarcode() async throws {
        let service = DemoStoreProductService()
        let expected = try #require(DemoCatalog.products.first)
        let product = try await service.fetchStoreItem(productID: expected.productID)
        #expect(product == expected)
    }

    @Test("未知のバーコードでは nil を返す")
    func fetchStoreItemReturnsNilForUnknownBarcode() async throws {
        let product = try await DemoStoreProductService().fetchStoreItem(productID: "0000000000000")
        #expect(product == nil)
    }

    @Test("商品IDは重複しない")
    func demoProductIDsAreUnique() {
        let ids = Set(DemoCatalog.products.map(\.productID))
        #expect(ids.count == DemoCatalog.products.count)
    }
}
