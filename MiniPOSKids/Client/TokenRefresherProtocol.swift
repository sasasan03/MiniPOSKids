//
//  TokenRefresherProtocol.swift
//  MiniPOSKids
//

import Foundation

/// APIClient が API リクエストに使うアクセストークンを取得するための口
protocol TokenRefresherProtocol: AnyObject {
    @discardableResult
    func refreshAccessToken() async throws -> String
    /// キャッシュされたアクセストークンを破棄する（401 受信後に呼び出す）
    func invalidateCachedToken()
}
