//
//  AppState.swift
//  MiniPOSKids
//
//  Created by sako0602 on 2026/04/09.
//

import OSLog
import SwiftUI

@Observable
final class AppState {
    var session: Session
    let tokenStore: TokenStoreProtocol
    private let logger = Logger(subsystem: "com.miniposkids", category: "AppState")

    enum Session {
        case unauthenticated
        case authenticated
    }

    init(tokenStore: TokenStoreProtocol = KeychainTokenStore()) {
        self.tokenStore = tokenStore
        let hasToken = tokenStore.refreshToken != nil
        session = hasToken ? .authenticated : .unauthenticated
        logger.info("AppState: 初期化 session=\(hasToken ? "authenticated" : "unauthenticated", privacy: .public)")
    }

    func loginSucceeded() {
        session = .authenticated
        logger.info("AppState: ログイン成功 → authenticated")
    }

    func logout() {
        tokenStore.deleteToken()
        session = .unauthenticated
        logger.info("AppState: ログアウト → unauthenticated")
    }
}
