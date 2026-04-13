//
//  StoreListView.swift
//  MiniPOSKids
//
//  Created by sako0602 on 2026/04/13.
//

import SwiftUI

struct StoreListView: View {
    
    @Environment(HomeRouter.self) private var router
    @State private var dummyStore = [
        "店舗A",
        "店舗B"
    ]
    
    var body: some View {
        List {
            ForEach(dummyStore, id: \.self) { store in
                Row(title: store) {
                    router.navigationHomeRoutePush(.printProductBarcode)
                }
            }
            
        }
    }
}

#Preview {
    StoreListView()
        .environment(HomeRouter())
}
