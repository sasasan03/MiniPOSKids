//
//  CashRegisterViewModel.swift
//  MiniPOSKids
//
//  Created by sako0602 on 2026/05/13.
//

import Foundation
import OSLog

@MainActor
@Observable
final class CashRegisterViewModel {
    
    struct CartProduct {
        var totalPrice: Int { product.price * quantity }
        let product: Product
        var quantity: Int
    }
    
    private let logger = Logger(subsystem: "com.sako0602.MiniPOSKids", category: "CashRegisterViewModel")
    private let storeItemService: StoreProductServiceProtocol
    
    var cartProducts: [CartProduct] = []
    var totalPrice: Int { cartProducts.map(\.totalPrice).reduce(0, +) }
    var errorMessage: String?
    var onSessionExpired: (() -> Void)?
    
    init(storeItemService: StoreProductServiceProtocol) {
        self.storeItemService = storeItemService
    }
    
    private func fetchProduct(by barcode: String) async throws -> Product? {
        do {
            if let itemResponse = try await storeItemService.fetchStoreItem(productID: barcode) {
                errorMessage = nil
                logger.info("getItem: 成功 id = \(itemResponse.productID) 、name=\(itemResponse.name)")
                return itemResponse
            } else {
                errorMessage = "商品のIDが見つかりませんでした"
                logger.info("getItem: 失敗 id・name = nil")
                return nil
            }
        } catch {
            logger.error("getStore or getItem: 失敗 error=\(error)")
            throw error
        }
    }
    
    /// CashRegisterViewModelの表示用のプロパティにスキャンしたProductを追加していく
    func addProduct(barcode: String?) {
        if let barcode {
            Task {
                do {
                    guard let product = try await fetchProduct(by: barcode) else {
                        errorMessage = "商品のIDが見つかりませんでした"
                        logger.info("fetchProduct: 失敗 バーコードから商品を見つけることができませんでした。")
                        return
                    }
                    
                    if let index = cartProducts.firstIndex(where:{ $0.product.productID == product.productID }) {
                        // 既にスキャンしたバーコードが配列に存在する場合に数量を＋１する
                        cartProducts[index].quantity += 1
                        logger.info("カートに既に商品が存在するため、数量を＋1しました。商品名：\(product.name)、商品数量：\(self.cartProducts[index].quantity)")
                        return
                    } else {
                        // カートに新しくプロダクトを追加
                        let cartProduct = CartProduct(product: product, quantity: 1)
                        cartProducts.append(cartProduct)
                        logger.info("カートに新しく商品を追加しました。商品名：\(cartProduct.product.name)")
                        return
                    }
                } catch is CancellationError {
                    logger.debug("fetchProduct: キャンセル")
                } catch APIError.sessionExpired {
                    logger.warning("fetchProduct: セッション期限切れ → ログアウト")
                    onSessionExpired?()
                } catch {
                    errorMessage = "スマレジdeveloperから商品情報取得に失敗しました"
                    logger.info("fetchProduct: 失敗 error=\(error)")
                }
            }
        } else {
            errorMessage = "バーコード取得に失敗しました"
            logger.info("fetchProduct: 失敗 barcode=nil")
        }
    }
}
