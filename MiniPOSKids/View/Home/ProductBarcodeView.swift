//
//  ProductBarcodeView.swift
//  MiniPOSKids
//
//  Created by sako0602 on 2026/04/13.
//

import SwiftUI

struct ProductBarcodeView: View {

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns) {
                ForEach(1...15, id: \.self) { i in
                    BarcodeRow(name: "りんご\(i)", price: "\((500...1000).randomElement()!)円") {
                        Image(systemName: "apple.logo")
                            .resizable()
                            .scaledToFit()
                    }
                }
            }
            .padding()
        }
    }
}

#Preview {
    ProductBarcodeView()
}
