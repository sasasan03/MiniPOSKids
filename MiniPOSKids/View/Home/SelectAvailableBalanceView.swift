//
//  SelectAvailableBalanceView.swift
//  MiniPOSKids
//
//  Created by sako0602 on 2026/04/13.
//

import SwiftUI

struct SelectAvailableBalanceView: View {
    @Environment(HomeRouter.self) private var router
    private enum Price: Int {
        case p1000 = 1000, p2000 = 2000, p3000 = 3000
    }
    private let qrCodePrices: [Price] = [.p1000, .p2000, .p3000]

    var body: some View {
        List {
            ForEach(qrCodePrices, id: \.self) { qrCodePrice in
                Row(title: "\(qrCodePrice.rawValue)") {
                    router.navigationHomeRoutePush(.showBuyerQRCode(qrCodePrice.rawValue))
                }
            }
            
        }
    }
}

#Preview {
    SelectAvailableBalanceView()
        .environment(HomeRouter())
}
