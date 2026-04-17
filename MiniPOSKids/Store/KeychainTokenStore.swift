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
        let refreshToken: String?
    }

    var accessToken: String? {
        guard let payload = readPayload() else { return nil }
        guard Date() < payload.expiryDate else {
            logger.info("read: トークンの有効期限切れ (expiry=\(payload.expiryDate))")
            return nil
        }
        logger.info("read: アクセストークンを取得しました (expiry=\(payload.expiryDate))")
        return payload.accessToken
    }

    var refreshToken: String? {
        readPayload()?.refreshToken
    }

    func save(accessToken: String, expiresIn: Int, refreshToken: String?) {
        save(accessToken, expiresIn: expiresIn, refreshToken: refreshToken)
    }

    func deleteToken() {
        delete()
    }

    // MARK: - Private

    private func readPayload() -> Payload? {
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
            logger.info("readPayload: トークンが存在しません")
            return nil
        case let s where s != errSecSuccess:
            logger.error("readPayload: Keychain の読み取りに失敗しました (status=\(s))")
            return nil
        default:
            break
        }

        guard let data = result as? Data else {
            logger.error("readPayload: データの取得に失敗しました")
            return nil
        }

        do {
            return try JSONDecoder().decode(Payload.self, from: data)
        } catch {
            logger.error("readPayload: デコードに失敗しました (error=\(error))")
            return nil
        }
    }

    private func save(_ token: String, expiresIn: Int, refreshToken: String?) {
        guard expiresIn > 0 else {
            logger.error("save: 不正な expiresIn を検出しました (expiresIn=\(expiresIn))")
            delete()
            return
        }
        let expiryDate = Date().addingTimeInterval(TimeInterval(expiresIn))
        let payload = Payload(accessToken: token, expiryDate: expiryDate, refreshToken: refreshToken)
        do {
            let data = try JSONEncoder().encode(payload)
            let query: [CFString: Any] = [
                kSecClass:       kSecClassGenericPassword,
                kSecAttrService: service,
                kSecAttrAccount: account,
            ]
            let updateAttrs: [CFString: Any] = [
                kSecValueData:      data,
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
