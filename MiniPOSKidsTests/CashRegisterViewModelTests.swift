//
//  CashRegisterViewModelTests.swift
//  MiniPOSKidsTests
//

import Testing
import Foundation
@testable import MiniPOSKids

// MARK: - Mock

final class MockStoreProductService: StoreProductServiceProtocol {
    var fetchStoreItemResult: Product?
    var fetchStoreItemError: Error?
    private(set) var fetchStoreItemCallCount = 0
    private(set) var lastProductID: String?

    func fetchStoreItems(storeId: String) async throws -> [Product] { [] }

    func fetchStoreItem(productID: String) async throws -> Product? {
        fetchStoreItemCallCount += 1
        lastProductID = productID
        if let error = fetchStoreItemError { throw error }
        return fetchStoreItemResult
    }
}

private enum DummyError: Error { case failure }

/// fire-and-forget な addProduct を待つためのポーリングヘルパー
///
/// 監視対象は MainActor 隔離された ViewModel の状態なので、この関数自体も MainActor 上で回す。
@MainActor
private func waitUntil(
    timeout: Duration = .milliseconds(500),
    _ condition: @escaping () -> Bool
) async {
    let deadline = ContinuousClock.now.advanced(by: timeout)
    while ContinuousClock.now < deadline {
        if condition() { return }
        try? await Task.sleep(for: .milliseconds(5))
    }
}

// MARK: - Tests

// CashRegisterViewModel は MainActor 隔離のため、テストも MainActor 上で実行する。
@MainActor
@Suite("CashRegisterViewModel")
struct CashRegisterViewModelTests {

    @Test("バーコードが nil のときは errorMessage が設定される")
    func addProduct_nilBarcode_setsErrorMessage() async {
        let mock = MockStoreProductService()
        let sut = CashRegisterViewModel(storeItemService: mock)

        sut.addProduct(barcode: nil)

        #expect(sut.errorMessage == "バーコード取得に失敗しました")
        #expect(mock.fetchStoreItemCallCount == 0)
        #expect(sut.cartProducts.isEmpty)
    }

    @Test("新規商品をスキャンするとカートに数量1で追加される")
    func addProduct_newProduct_appendsWithQuantityOne() async {
        let mock = MockStoreProductService()
        mock.fetchStoreItemResult = Product(productID: "P-1", name: "コーラ", price: 190)
        let sut = CashRegisterViewModel(storeItemService: mock)

        sut.addProduct(barcode: "P-1")
        await waitUntil { sut.cartProducts.count == 1 }

        #expect(mock.lastProductID == "P-1")
        #expect(sut.cartProducts.count == 1)
        #expect(sut.cartProducts.first?.product.productID == "P-1")
        #expect(sut.cartProducts.first?.quantity == 1)
        #expect(sut.errorMessage == nil)
    }

    @Test("同じ商品を2回スキャンすると数量が+1される")
    func addProduct_sameProductTwice_incrementsQuantity() async {
        let mock = MockStoreProductService()
        mock.fetchStoreItemResult = Product(productID: "P-1", name: "コーラ", price: 190)
        let sut = CashRegisterViewModel(storeItemService: mock)

        sut.addProduct(barcode: "P-1")
        await waitUntil { sut.cartProducts.count == 1 }
        sut.addProduct(barcode: "P-1")
        await waitUntil { sut.cartProducts.first?.quantity == 2 }

        #expect(sut.cartProducts.count == 1)
        #expect(sut.cartProducts.first?.quantity == 2)
    }

    @Test("異なる商品をスキャンするとそれぞれ別エントリで追加される")
    func addProduct_differentProducts_appendsSeparateEntries() async {
        let mock = MockStoreProductService()
        let sut = CashRegisterViewModel(storeItemService: mock)

        mock.fetchStoreItemResult = Product(productID: "P-1", name: "コーラ", price: 190)
        sut.addProduct(barcode: "P-1")
        await waitUntil { sut.cartProducts.count == 1 }

        mock.fetchStoreItemResult = Product(productID: "P-2", name: "ドーナッツ", price: 250)
        sut.addProduct(barcode: "P-2")
        await waitUntil { sut.cartProducts.count == 2 }

        #expect(sut.cartProducts.map { $0.product.productID } == ["P-1", "P-2"])
        #expect(sut.cartProducts.allSatisfy { $0.quantity == 1 })
    }

    @Test("totalPrice は各 CartProduct の合計を返す")
    func totalPrice_sumsAllCartProducts() async {
        let mock = MockStoreProductService()
        let sut = CashRegisterViewModel(storeItemService: mock)

        mock.fetchStoreItemResult = Product(productID: "P-1", name: "コーラ", price: 190)
        sut.addProduct(barcode: "P-1")
        await waitUntil { sut.cartProducts.count == 1 }
        sut.addProduct(barcode: "P-1")
        await waitUntil { sut.cartProducts.first?.quantity == 2 }

        mock.fetchStoreItemResult = Product(productID: "P-2", name: "ドーナッツ", price: 250)
        sut.addProduct(barcode: "P-2")
        await waitUntil { sut.cartProducts.count == 2 }

        #expect(sut.totalPrice == 190 * 2 + 250)
    }

    @Test("サービスが nil を返した場合は errorMessage が設定されカートは増えない")
    func addProduct_serviceReturnsNil_setsErrorMessage() async {
        let mock = MockStoreProductService()
        mock.fetchStoreItemResult = nil
        let sut = CashRegisterViewModel(storeItemService: mock)

        sut.addProduct(barcode: "UNKNOWN")
        await waitUntil { sut.errorMessage != nil }

        #expect(sut.errorMessage == "商品のIDが見つかりませんでした")
        #expect(sut.cartProducts.isEmpty)
    }

    @Test("サービスがエラーを投げた場合は errorMessage が設定される")
    func addProduct_serviceThrows_setsErrorMessage() async {
        let mock = MockStoreProductService()
        mock.fetchStoreItemError = DummyError.failure
        let sut = CashRegisterViewModel(storeItemService: mock)

        sut.addProduct(barcode: "P-1")
        await waitUntil { sut.errorMessage != nil }

        #expect(sut.errorMessage == "スマレジdeveloperから商品情報取得に失敗しました")
        #expect(sut.cartProducts.isEmpty)
    }
}
