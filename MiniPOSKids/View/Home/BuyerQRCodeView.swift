//
//  BuyerQRCodeView.swift
//  MiniPOSKids
//
//  Created by sako0602 on 2026/04/13.
//

import SwiftUI

struct BuyerQRCodeView: View {
    
    @State private var qrCode: UIImage?
    let qrCodePrice: Int
    
    init(qrCodePrice: Int) {
        self.qrCodePrice = qrCodePrice
    }
    
    var body: some View {
        VStack {
            Text("利用可能額は \(qrCodePrice)円です")
                .padding(.bottom, 30)
            if let qrCode {
                Image(uiImage: qrCode)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
            } else {
                Image(systemName: "xmark.octagon.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 300, height: 300)
            }
            Text("")
                .padding(.top, 30)
        }
        .onAppear {
            qrCode = makeQRCode(price: qrCodePrice)
        }
    }
    
    private func makeQRCode(price: Int) -> UIImage? {
        let context = CIContext()
        let qrCodeGenerator = CIFilter.qrCodeGenerator()
        // 数値だけではQRコードがシンプルになるため、余分なデータを持たせて複雑にしている。これを行うとQRCodeっぽくなり、見栄えを良くしている。
        let payload: [String: Any] = [
            "amount": price,
            "currency": "JPY",
            "timestamp": Date().timeIntervalSince1970,
            "transactionId": UUID().uuidString
        ]
        let jsonData = try! JSONSerialization.data(withJSONObject: payload)
        qrCodeGenerator.message = jsonData
        qrCodeGenerator.correctionLevel = "H"
        guard let outputImage = qrCodeGenerator.outputImage,
              let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }
}

#Preview {
    BuyerQRCodeView(qrCodePrice: 2000)
}
