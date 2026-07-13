//
//  BuyerQRCodeView.swift
//  MiniPOSKids
//
//  Created by sako0602 on 2026/04/13.
//

import SwiftUI
import CoreImage.CIFilterBuiltins

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
                    .frame(width: 300, height: 300)
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
    
    // TODO: 現状は価格の数値をそのまま QR に載せているため、発行元や取引識別子を検証できない。
    // 過去のスクショや外部で生成した数値 QR でも、数値が十分大きければ購入成功になってしまう。
    // 固定プレフィックス付きの構造化ペイロード（エンコード/デコードを共有する型）に戻し、
    // 読み取り側（ScanQRCodeView）でもフォーマット検証を入れる。
    private func makeQRCode(price: Int) -> UIImage? {
        guard price > 0 else { return nil }
        let context = CIContext()
        let qrCodeGenerator = CIFilter.qrCodeGenerator()
        guard let strPriceDate = String(price).data(using: .ascii) else { return nil }
        qrCodeGenerator.message = strPriceDate
        qrCodeGenerator.correctionLevel = "H"
        guard let outputImage = qrCodeGenerator.outputImage?
                .transformed(by: CGAffineTransform(scaleX: 10, y: 10)),
              let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }
}

#Preview {
    BuyerQRCodeView(qrCodePrice: 2000)
}
