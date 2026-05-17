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
    @State private var isShowingAlert = false
    @State private var scannedPayload = ""
    
    var body: some View {
        ZStack {
            BarcodeScannerCameraView(recognizedPayload: $scannedPayload)
                .onChange(of: scannedPayload) { _, newValue in
                    print("⭐️ScanProductBarcodeView newvalue",newValue)
                    guard !newValue.isEmpty else { return }
                    router.saveScannedBarcode(newValue)
                    router.navigationBack()
                }
        }
        .alert("読み取りに失敗しました", isPresented: $isShowingAlert) {
            Button("レジ画面へ戻る", role: .cancel) {
                router.navigationBack()
            }
        }
    }
}

private struct BarcodeScannerCameraView: UIViewControllerRepresentable {
    
    @Binding var recognizedPayload: String
    
    func makeUIViewController(context: Context) -> some DataScannerViewController {
        let dataScannerViewController = DataScannerViewController(
            recognizedDataTypes: [.barcode(symbologies: [.code128])],
            recognizesMultipleItems: false,
            isHighlightingEnabled: true
        )
        try? dataScannerViewController.startScanning()
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
