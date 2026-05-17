//
//  ScanProductBarcodeError.swift
//  MiniPOSKids
//
//  Created by sako0602 on 2026/05/17.
//

import Foundation

enum ScanProductBarcodeError: Error, LocalizedError, Identifiable {
    case scannerUnsupported
    case scannerUnavailable
    case scannerStartFailed(Error)
    case emptyPayload

    var id: String {
        switch self {
        case .scannerUnsupported:  "scannerUnsupported"
        case .scannerUnavailable:  "scannerUnavailable"
        case .scannerStartFailed:  "scannerStartFailed"
        case .emptyPayload:        "emptyPayload"
        }
    }

    var errorDescription: String? {
        switch self {
        case .scannerUnsupported:  "この端末ではバーコードスキャンを利用できません"
        case .scannerUnavailable:  "カメラを利用できません。設定からカメラへのアクセスを許可してください"
        case .scannerStartFailed:  "スキャナの起動に失敗しました"
        case .emptyPayload:        "バーコードを読み取れませんでした。もう一度お試しください"
        }
    }
}
