//
//  ProductBarcodeView.swift
//  MiniPOSKids
//
//  Created by sako0602 on 2026/04/13.
//

import SwiftUI

struct ProductBarcodeView: View {
    private let colors: [Color] = [.pink, .blue, .orange, .green]

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    var body: some View {
        LazyVGrid(columns: columns) {
            BarcodeRow()
            BarcodeRow()
            BarcodeRow()
            BarcodeRow()
        }
        .frame(width: 300)
    }
}

#Preview {
    ProductBarcodeView()
}
