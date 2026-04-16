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

    enum Session {
        case unauthenticated
        case authenticated
    }

    init(tokenStore: TokenStoreProtocol = KeychainTokenStore()) {
        session = tokenStore.accessToken != nil ? .authenticated : .unauthenticated
    }

    func loginSucceeded() {
        session = .authenticated
    }

    func logout() {
        session = .unauthenticated
    }
}
