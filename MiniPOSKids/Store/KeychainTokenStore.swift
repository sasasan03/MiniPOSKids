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
    
    var accessToken: String? { read() }

    func save(accessToken: String, expiresIn: Int) {
        save(accessToken, expiresIn: expiresIn)
    }

    func deleteToken() {
        delete()
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

    private func save(_ token: String, expiresIn: Int) {
        guard expiresIn > 0 else {
            logger.error("save: 不正な expiresIn を検出しました (expiresIn=\(expiresIn))")
            delete()
            return
        }
        let expiryDate = Date().addingTimeInterval(TimeInterval(expiresIn))
        let payload = Payload(accessToken: token, expiryDate: expiryDate)
        do {
            let data = try JSONEncoder().encode(payload)
            let query: [CFString: Any] = [
                kSecClass:            kSecClassGenericPassword,
                kSecAttrService:      service,
                kSecAttrAccount:      account,
            ]
            let updateAttrs: [CFString: Any] = [
                kSecValueData: data,
                kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock,
            ]
            let updateStatus = SecItemUpdate(query as CFDictionary, updateAttrs as CFDictionary)
            if updateStatus == errSecSuccess {
                logger.info("save: トークンを保存しました (expiry=\(expiryDate))")
                return
            }
            if updateStatus == errSecItemNotFound {
                var addAttrs = query
                addAttrs[kSecValueData] = data
                addAttrs[kSecAttrAccessible] = kSecAttrAccessibleAfterFirstUnlock
                let addStatus = SecItemAdd(addAttrs as CFDictionary, nil)
                if addStatus == errSecSuccess {
                    logger.info("save: トークンを保存しました (expiry=\(expiryDate))")
                } else {
                    logger.error("save: Keychain への保存に失敗しました (status=\(addStatus))")
                }
                return
            }
            logger.error("save: Keychain 更新に失敗しました (status=\(updateStatus))")
        } catch {
            logger.error("save: エンコードに失敗しました (error=\(error))")
            return
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
