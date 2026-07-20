//
//  ScanQRCodeView.swift
//  MiniPOSKids
//
//  Created by sako0602 on 2026/04/13.
//

import SwiftUI
import VisionKit
import Vision

// TODO: この画面から次の画面に渡すもの。
struct ScanQRCodeView: View {
    @Environment(HomeRouter.self) var router
    @State private var scanError: ScanProductBarcodeError?
    @State private var scannedPayload = ""
    @State private var hasHandledScan = false
    let totalAmount: Int
    let cartProducts: [CartProduct]
    
    var body: some View {
        ZStack {
            BarcodeScannerCameraView(
                symbologies: [.qr],
                recognizedPayload: $scannedPayload,
                scanError: $scanError
            )
            .onChange(of: scannedPayload) {
                _,
                newValue in
                // TODO: Int(newValue) だけで受理しているため、発行元や取引識別子を検証できない。
                // 外部で生成された数値 QR でも購入成功になってしまうので、
                // 固定プレフィックス付きの構造化ペイロードにしてフォーマット検証を入れる（BuyerQRCodeView 側と対応）。
                guard !hasHandledScan,
                      !newValue.isEmpty,
                      let qrCodeValue = Int(newValue) else { return }
                hasHandledScan = true
                if totalAmount <= qrCodeValue {
                    router.navigationHomeRoutePush(
                        .purchaseResult(
                            true,
                            totalAmount,
                            qrCodeValue,
                            cartProducts
                        )
                    )
                    } else {
                        router.navigationHomeRoutePush(
                            .purchaseResult(
                                false,
                                totalAmount,
                                qrCodeValue,
                                cartProducts
                            )
                        )
                    }
                }
        }
        .task {
            if !DataScannerViewController.isSupported {
                scanError = .scannerUnsupported
            } else if !DataScannerViewController.isAvailable {
                scanError = .scannerUnavailable
            }
        }
        .alert(
            scanError?.errorDescription ?? "",
            isPresented: Binding(
                get: { scanError != nil },
                set: { if !$0 { scanError = nil } }
            ),
            presenting: scanError
        ) { error in
            switch error {
            case .emptyPayload:
                Button("再試行") {
                    scannedPayload = ""
                    hasHandledScan = false
                }
                Button("レジ画面へ戻る", role: .cancel) {
                    router.navigationBack()
                }
            case .scannerUnsupported, .scannerUnavailable, .scannerStartFailed:
                Button("レジ画面へ戻る", role: .cancel) {
                    router.navigationBack()
                }
            }
        }
    }
}

#Preview {
    ScanQRCodeView(
        totalAmount: 800, cartProducts: [
            CartProduct(
                product: Product(
                    productID: "123",
                    name: "りんご",
                    price: 200
                ),
                quantity: 4
            )
        ]
    )
    .environment(HomeRouter())
}
