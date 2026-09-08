//
//  ScanProductBarcodeView.swift
//  MiniPOSKids
//
//  Created by sako0602 on 2026/04/13.
//
import AVFoundation
import SwiftUI
import VisionKit
import Vision

struct ScanProductBarcodeView: View {
    @Environment(HomeRouter.self) var router
    @Environment(AppState.self) private var appState
    @State private var scanError: ScanProductBarcodeError?
    @State private var scannedPayload = ""
    @State private var hasHandledScan = false

    var body: some View {
        // デモモードでは印刷したバーコードもカメラも用意できないため、
        // サンプル商品のタップを「読み取り成功」として扱う。
        if appState.isDemo {
            demoProductPicker
        } else {
            scanner
        }
    }

    /// デモモード用。サンプル商品を一覧表示し、タップされた商品をスキャン結果として返す。
    private var demoProductPicker: some View {
        List {
            Section {
                ForEach(DemoCatalog.products, id: \.productID) { product in
                    Button {
                        router.saveScannedBarcode(product.productID)
                        router.navigationBack()
                    } label: {
                        HStack {
                            Image(systemName: "barcode")
                                .foregroundStyle(.blue)
                            Text(product.name)
                            Spacer()
                            Text("\(product.price)円")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } header: {
                Text("デモモードのため、カメラの代わりにサンプル商品をタップしてレジに追加してください。")
                    .textCase(nil)
            }
        }
    }

    private var scanner: some View {
        ZStack {
            BarcodeScannerCameraView(
                symbologies: [.code128],
                recognizedPayload: $scannedPayload,
                scanError: $scanError
            )
                .onChange(of: scannedPayload) { _, newValue in
                    guard !hasHandledScan, !newValue.isEmpty else { return }
                    hasHandledScan = true
                    router.saveScannedBarcode(newValue)
                    router.navigationBack()
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
    ScanProductBarcodeView()
        .environment(HomeRouter())
        .environment(AppState(tokenStore: InMemoryTokenStore()))
}
