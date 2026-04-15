//
//  AuthAPIError.swift
//  MiniPOSKids
//
//  Created by sako0602 on 2026/04/15.
//

import Foundation

enum AuthAPIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case statusCode(Int, Data)
    case encodingFailed
    case decodingFailed(Error)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URLが不正です。"
        case .invalidResponse:
            return "レスポンスが不正です。"
        case .statusCode(let code, _):
            return "サーバーエラー: \(code)"
        case .encodingFailed:
            return "リクエストデータのエンコードに失敗しました。"
        case .decodingFailed(let error):
            return "レスポンスのデコードに失敗しました: \(error.localizedDescription)"
        case .networkError(let error):
            return "通信エラー: \(error.localizedDescription)"
        }
    }
}
