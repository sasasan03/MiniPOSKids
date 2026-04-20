//
//  StoreListView.swift
//  MiniPOSKids
//
//  Created by sako0602 on 2026/04/13.
//

import SwiftUI

struct StoreListView: View {
    
    @Environment(HomeRouter.self) private var router
    @State private var viewModel: StoreListViewModel

    init(viewModel: StoreListViewModel) {
        _viewModel = State(initialValue: viewModel)
    }
    
    var body: some View {
        List {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
            }

            ForEach(viewModel.stores, id: \.storeId) { store in
                Row(title: store.storeName) {
                    router.navigationHomeRoutePush(.printProductBarcode)
                }
            }
        }
        .task {
            await viewModel.getStores()
        }
    }
}

#Preview {
    StoreListView(
        viewModel: StoreListViewModel(
            storeService: PreviewStoreService()
        )
    )
        .environment(HomeRouter())
}

private struct PreviewStoreService: StoreServiceProtocol {
    func fetchStore() async throws -> [StoreResponse] {
        [
            StoreResponse(storeId: "1", storeName: "店舗A"),
            StoreResponse(storeId: "2", storeName: "店舗B"),
        ]
    }
}
