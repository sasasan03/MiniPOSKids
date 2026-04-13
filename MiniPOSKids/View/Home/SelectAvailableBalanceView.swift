//
//  SelectAvailableBalanceView.swift
//  MiniPOSKids
//
//  Created by sako0602 on 2026/04/13.
//

import SwiftUI

struct SelectAvailableBalanceView: View {
    @Environment(HomeRouter.self) private var router
    let dummyPrice = ["1000", "2000", "3000"]
    var body: some View {
        List {
            ForEach(dummyPrice, id: \.self) { store in
                Row(title: store) {
                    router.navigationHomeRoutePush(.showBuyerQRCode)
                }
            }
            
        }
    }
}

#Preview {
    SelectAvailableBalanceView()
        .environment(HomeRouter())
}
