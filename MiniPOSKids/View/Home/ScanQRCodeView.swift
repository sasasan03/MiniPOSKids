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
    @Environment(AppState.self) private var appState
    @State private var scanError: ScanProductBarcodeError?
    @State private var scannedPayload = ""
    @State private var hasHandledScan = false
    let totalAmount: Int
    let cartProducts: [CartProduct]

    /// デモモードで選べる支払い用 QR コードの額面。`SelectAvailableBalanceView` と揃えている。
    private let demoBalances = [1000, 2000, 3000]

    var body: some View {
        // デモモードでは 1 台の端末で QR コードを表示しつつ読み取ることができないため、
        // 額面のタップを「QR コードの読み取り成功」として扱う。
        if appState.isDemo {
            demoBalancePicker
        } else {
            scanner
        }
    }

    /// デモモード用。額面を一覧表示し、タップされた金額を読み取り結果として決済処理へ渡す。
    private var demoBalancePicker: some View {
        List {
            Section {
                ForEach(demoBalances, id: \.self) { balance in
                    Button {
                        handleScannedAmount(balance)
                    } label: {
                        HStack {
                            Image(systemName: "qrcode")
                                .foregroundStyle(.blue)
                            Text("残高 \(balance)円のQRコード")
                            Spacer()
                        }
                    }
                }
            } header: {
                Text("お支払い金額は \(totalAmount)円です。デモモードのため、カメラの代わりに使用するQRコードをタップしてください。")
                    .textCase(nil)
            }
        }
    }

    /// 読み取った残高と合計金額を比較し、購入結果画面へ遷移する。
    /// - Parameter qrCodeValue: QR コードに含まれる利用可能残高。
    private func handleScannedAmount(_ qrCodeValue: Int) {
        router.navigationHomeRoutePush(
            .purchaseResult(
                totalAmount <= qrCodeValue,
                totalAmount,
                qrCodeValue,
                cartProducts
            )
        )
    }

    private var scanner: some View {
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
                handleScannedAmount(qrCodeValue)
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
    .environment(AppState(tokenStore: InMemoryTokenStore()))
}
