//
//  BarcodeRow.swift
//  MiniPOSKids
//
//  Created by sako0602 on 2026/04/13.
//

import SwiftUI

struct BarcodeRow<ImageContent: View>: View {
    let name: String
    let price: String
    let imageContent: () -> ImageContent

    init(
        name: String,
        price: String,
        @ViewBuilder imageContent: @escaping () -> ImageContent
    ) {
        self.name = name
        self.price = price
        self.imageContent = imageContent
    }

    var body: some View {
        VStack {
            HStack {
                Text(name)
                Spacer()
                Text(price)
            }
            imageContent()
                .frame(width: 90, height: 70)
        }
        .padding()
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.gray, lineWidth: 1)
        )
    }
}

#Preview {
    List {
        BarcodeRow(name: "りんご", price: "100円") {
            Image(systemName: "apple.logo")
                .resizable()
                .scaledToFit()
        }
    }
}
