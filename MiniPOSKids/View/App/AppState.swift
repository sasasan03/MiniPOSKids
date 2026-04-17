//
//  AppState.swift
//  MiniPOSKids
//
//  Created by sako0602 on 2026/04/09.
//

import SwiftUI

@Observable
final class AppState {
    var session: Session
    private let tokenStore: TokenStoreProtocol

    enum Session {
        case unauthenticated
        case authenticated
    }

    init(tokenStore: TokenStoreProtocol = KeychainTokenStore()) {
        self.tokenStore = tokenStore
        session = tokenStore.accessToken != nil ? .authenticated : .unauthenticated
    }

    func loginSucceeded() {
        session = .authenticated
    }

    func logout() {
        tokenStore.deleteToken()
        session = .unauthenticated
    }
}
