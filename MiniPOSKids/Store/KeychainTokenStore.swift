//
//  KeychainTokenStore.swift
//  MiniPOSKids
//

import Foundation
import Security

final class KeychainTokenStore: TokenStoreProtocol {
    private let service = "com.miniposkids.auth"
    private let account = "accessToken"

    var accessToken: String? {
        get { read() }
        set {
            if let newValue {
                save(newValue)
            } else {
                delete()
            }
        }
    }

    private func read() -> String? {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecReturnData:  true,
            kSecMatchLimit:  kSecMatchLimitOne,
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func save(_ token: String) {
        guard let data = token.data(using: .utf8) else { return }
        delete()
        let attributes: [CFString: Any] = [
            kSecClass:            kSecClassGenericPassword,
            kSecAttrService:      service,
            kSecAttrAccount:      account,
            kSecValueData:        data,
            kSecAttrAccessible:   kSecAttrAccessibleAfterFirstUnlock,
        ]
        SecItemAdd(attributes as CFDictionary, nil)
    }

    private func delete() {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
        ]
        SecItemDelete(query as CFDictionary)
    }
}
