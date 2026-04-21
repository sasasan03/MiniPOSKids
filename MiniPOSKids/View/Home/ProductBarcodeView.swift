//
//  ProductBarcodeView.swift
//  MiniPOSKids
//
//  Created by sako0602 on 2026/04/13.
//

import SwiftUI
import CoreImage.CIFilterBuiltins

struct ProductBarcodeView: View {
    let context = CIContext()
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        LazyVGrid(columns: columns) {
            ForEach(1...10, id: \.self) { i in
                BarcodeRow(name: "りんご\(i)", price: "\((500...1000).randomElement()!)円") {
                    barcode(id: "\(i)")
                }
            }
        }
        .padding()
    }

    @ViewBuilder
    private func barcode(id: String) -> some View {
        if let image = generateBarCodeImage(id: id) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
        } else {
            failureImage
        }
    }

    private func generateBarCodeImage(id: String) -> UIImage? {
        guard let codeData = id.data(using: .ascii) else { return nil }
        let filter = CIFilter.code128BarcodeGenerator()
        filter.message = codeData
        guard let outputImage = filter.outputImage?.transformed(by: CGAffineTransform(scaleX: 3, y: 3)),
              let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    private var failureImage: some View {
        Image(systemName: "xmark.octagon.fill")
            .foregroundStyle(.red, .white)
    }
}

#Preview {
    ProductBarcodeView()
}
