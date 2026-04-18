//
//  InMemoryTokenStore.swift
//  MiniPOSKids
//
//  Created by sako0602 on 2026/04/18.
//

import Foundation

// MARK: - TokenStore

protocol TokenStoreProtocol {
    var refreshToken: String? { get }
    func save(refreshToken: String?)
    func deleteToken()
}

final class InMemoryTokenStore: TokenStoreProtocol {
    var refreshToken: String?

    func save(refreshToken: String?) {
        self.refreshToken = refreshToken
    }

    func deleteToken() {
        refreshToken = nil
    }
}
