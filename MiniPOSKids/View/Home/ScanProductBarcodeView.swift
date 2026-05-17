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
    @State private var scanError: ScanProductBarcodeError?
    @State private var scannedPayload = ""
    @State private var hasHandledScan = false

    var body: some View {
        ZStack {
            BarcodeScannerCameraView(recognizedPayload: $scannedPayload, scanError: $scanError)
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

private struct BarcodeScannerCameraView: UIViewControllerRepresentable {

    @Binding var recognizedPayload: String
    @Binding var scanError: ScanProductBarcodeError?

    func makeUIViewController(context: Context) -> some DataScannerViewController {
        let dataScannerViewController = DataScannerViewController(
            recognizedDataTypes: [.barcode(symbologies: [.code128])],
            recognizesMultipleItems: false,
            isHighlightingEnabled: true
        )
        do {
            try dataScannerViewController.startScanning()
        } catch {
            scanError = .scannerStartFailed(error)
        }
        // context.coordinatorをセットすることで、バーコードを読みとった後の振る舞いを決める
        dataScannerViewController.delegate = context.coordinator
        return dataScannerViewController
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        private let parent: BarcodeScannerCameraView

        init(_ parent: BarcodeScannerCameraView) {
            self.parent = parent
        }

        // スキャナがアイテムの認識を開始
        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            guard case .barcode(let barcode) = addedItems.first else { return }
            if let payloadStringValue = barcode.payloadStringValue {
                parent.recognizedPayload = payloadStringValue
            } else {
                parent.scanError = .emptyPayload
            }
        }

        // スキャナの認識停止
        func dataScanner(_ dataScanner: DataScannerViewController, didRemove removedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            parent.recognizedPayload = ""
        }

    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
}

#Preview {
    ScanProductBarcodeView()
        .environment(HomeRouter())
}
