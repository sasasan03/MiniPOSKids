//
//  StoreListViewModel.swift
//  MiniPOSKids
//
//  Created by sako0602 on 2026/04/19.
//

import Foundation

@MainActor
@Observable
final class StoreListViewModel {
    
    var errorMessage: String?
    var stores: [StoreResponse] = []
    private let storeService: StoreServiceProtocol

    init(storeService: StoreServiceProtocol) {
        self.storeService = storeService
    }
    
    // 店舗一覧を取得
    func getStores() async {
        do {
            stores = try await storeService.fetchStore()
            errorMessage = nil
            print("-----------", stores.map(\.storeName))
        } catch {
            errorMessage = "店舗一覧の取得に失敗しました"
            print("💫error",error.localizedDescription)
        }
    }
}
