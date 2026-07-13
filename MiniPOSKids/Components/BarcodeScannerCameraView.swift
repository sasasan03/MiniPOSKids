//
//  BarcodeScannerCameraView.swift
//  MiniPOSKids
//
//  Created by sako0602 on 2026/05/19.
//

import Foundation
import AVFoundation
import SwiftUI
import VisionKit
import Vision

struct BarcodeScannerCameraView: UIViewControllerRepresentable {

    let symbologies: [VNBarcodeSymbology]
    @Binding var recognizedPayload: String
    @Binding var scanError: ScanProductBarcodeError?

    func makeUIViewController(context: Context) -> some DataScannerViewController {
        let dataScannerViewController = DataScannerViewController(
            recognizedDataTypes: [.barcode(symbologies: symbologies)],
            recognizesMultipleItems: false,
            isHighlightingEnabled: true
        )
        // context.coordinatorをセットすることで、バーコードを読みとった後の振る舞いを決める
        dataScannerViewController.delegate = context.coordinator
        do {
            try dataScannerViewController.startScanning()
        } catch {
            scanError = .scannerStartFailed(error)
        }
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
            // 親ビューが処理、リセットのタイミングを管理する
        }

    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
}
