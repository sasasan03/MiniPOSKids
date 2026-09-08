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
        /// スマレジのアカウント登録・ログインなしでアプリの全機能を試せる状態。
        /// トークンを持たず、API も呼ばずにサンプルデータで動作する。
        case demo
    }

    /// デモモードで動作中かどうか。サービスの注入先や画面の分岐に使う。
    var isDemo: Bool { session == .demo }

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

    /// デモモードを開始する。Keychain には一切触れないため、アプリを再起動すると未ログインに戻る。
    func startDemo() {
        session = .demo
        logger.info("AppState: デモモード開始 → demo")
    }

    func logout() {
        // デモモード中はトークンを保存していないが、削除は冪等なのでそのまま呼ぶ。
        tokenStore.deleteToken()
        session = .unauthenticated
        logger.info("AppState: ログアウト → unauthenticated")
    }
}
