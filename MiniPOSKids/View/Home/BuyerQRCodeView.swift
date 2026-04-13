//
//  BuyerQRCodeView.swift
//  MiniPOSKids
//
//  Created by sako0602 on 2026/04/13.
//

import SwiftUI

struct BuyerQRCodeView: View {
    var body: some View {
        VStack {
            Text("利用可能額は 1000円")
            Color.red
                .frame(width: 300, height: 300)
        }
    }
}

#Preview {
    BuyerQRCodeView()
}
