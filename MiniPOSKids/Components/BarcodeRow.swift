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
        VStack(spacing: 6) {
            HStack {
                Text(name)
                    .font(.caption)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer(minLength: 4)
                Text(price)
                    .font(.caption)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            imageContent()
                .frame(maxWidth: .infinity)
                .frame(height: 50)
        }
        .padding(8)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.gray, lineWidth: 1)
        )
    }
}

#Preview {
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    LazyVGrid(columns: columns) {
        ForEach(1...4, id: \.self) { i in
            BarcodeRow(name: "りんご\(i)", price: "\((500...1000).randomElement()!)円") {
                Color.red
            }
//            .background(Color.blue)
        }
    }
    .padding()
}
