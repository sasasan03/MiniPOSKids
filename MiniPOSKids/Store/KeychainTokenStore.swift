//
//  KeychainTokenStore.swift
//  MiniPOSKids
//

import Foundation
import Security
import OSLog

final class KeychainTokenStore: TokenStoreProtocol {
    private let service = "com.miniposkids.auth"
    private let account = "refreshToken"
    private let logger = Logger(subsystem: "com.miniposkids.auth", category: "KeychainTokenStore")
    
    /// Keychainへリフレッシュトークンを保存することと、取り出すこと
    private struct Payload: Codable {
        let token: String?
    }
    
    var refreshToken: String? {
        readRefreshToken()?.token
    }
    
    func save(refreshToken: String?) {
        do {
            let payload = Payload(token: refreshToken)
            let data = try JSONEncoder().encode(payload)
            let query: [CFString: Any] = [
                kSecClass: kSecClassGenericPassword,
                kSecAttrService: service,
                kSecAttrAccount: account,
            ]
            let updateAttrs: [CFString: Any] = [
                kSecValueData: data,
                kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock,
            ]
            // キーチェーンにリフレッシュトークンが存在する場合
            let updateStatus = SecItemUpdate(query as CFDictionary, updateAttrs as CFDictionary)
            if updateStatus == errSecSuccess {
                logger.info("save: リフレッシュトークンを更新しました")
                return
            }
            // キーチェーンにリフレッシュトークンが存在しない場合（初回認証時）
            if updateStatus == errSecItemNotFound {
                var addAttrs = query
                addAttrs[kSecValueData] = data
                addAttrs[kSecAttrAccessible] = kSecAttrAccessibleAfterFirstUnlock
                let addStatus = SecItemAdd(addAttrs as CFDictionary, nil)
                if addStatus == errSecSuccess {
                    logger.info("save: 初めてリフレッシュトークンを保存しました")
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
    
    func deleteToken() {
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
    
    // MARK: - Private
    private func readRefreshToken() -> Payload? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecReturnData:  true,
            kSecMatchLimit:  kSecMatchLimitOne,
        ]
        var result: AnyObject?
        // ここで上記のクエリを使ってキーチェインにリフレッシュトークンがないかを検索する
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
}
