//
//  KeychainTokenStore.swift
//  MiniPOSKids
//

import Foundation
import Security
import OSLog

final class KeychainTokenStore: TokenStoreProtocol {
    private let service = "com.miniposkids.auth"
    private let account = "accessToken"
    private let logger = Logger(subsystem: "com.miniposkids.auth", category: "KeychainTokenStore")

    private struct Payload: Codable {
        let accessToken: String
        let expiryDate: Date
    }
    
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

        switch status {
        case errSecItemNotFound:
            logger.info("read: トークンが存在しません")
            return nil
        case let s where s != errSecSuccess:
            logger.error("read: Keychain の読み取りに失敗しました (status=\(s))")
            return nil
        default:
            break
        }

        guard let data = result as? Data else {
            logger.error("read: データの取得に失敗しました")
            return nil
        }

        do {
            let payload = try JSONDecoder().decode(Payload.self, from: data)
            guard Date() < payload.expiryDate else {
                logger.info("read: トークンの有効期限切れ (expiry=\(payload.expiryDate))")
                return nil
            }
            logger.info("read: トークンを取得しました (expiry=\(payload.expiryDate))")
            return payload.accessToken
        } catch {
            logger.error("read: デコードに失敗しました (error=\(error))")
            return nil
        }
    }

    private func save(_ token: String) {
        let expiryDate = Date().addingTimeInterval(3600)
        let payload = Payload(accessToken: token, expiryDate: expiryDate)
        do {
            let data = try JSONEncoder().encode(payload)
            delete()
            let attributes: [CFString: Any] = [
                kSecClass:            kSecClassGenericPassword,
                kSecAttrService:      service,
                kSecAttrAccount:      account,
                kSecValueData:        data,
                kSecAttrAccessible:   kSecAttrAccessibleAfterFirstUnlock,
            ]
            let status = SecItemAdd(attributes as CFDictionary, nil)
            if status == errSecSuccess {
                logger.info("save: トークンを保存しました (expiry=\(expiryDate))")
            } else {
                logger.error("save: Keychain への保存に失敗しました (status=\(status))")
            }
        } catch {
            logger.error("save: エンコードに失敗しました (error=\(error))")
            fatalError("save error \(error)")
        }
    }

    private func delete() {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
        ]
        let status = SecItemDelete(query as CFDictionary)
        switch status {
        case errSecSuccess:
            logger.info("delete: トークンを削除しました")
        case errSecItemNotFound:
            break
        default:
            logger.error("delete: 削除に失敗しました (status=\(status))")
        }
    }
}
