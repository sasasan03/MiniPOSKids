//
//  AppConfig.swift
//  MiniPOSKids
//

import Foundation

enum AppConfig {
    static var smaregiClientId: String {
        guard let value = Bundle.main.infoDictionary?["SMAREGI_CLIENT_ID"] as? String,
              !value.isEmpty,
              value != "your_client_id_here" else {
            fatalError("SMAREGI_CLIENT_ID が Info.plist に設定されていません。Secrets.xcconfig を確認してください。")
        }
        return value
    }

    static var smaregiContractId: String {
        guard let value = Bundle.main.infoDictionary?["SMAREGI_CONTRACT_ID"] as? String,
              !value.isEmpty,
              value != "your_contract_id_here" else {
            fatalError("SMAREGI_CONTRACT_ID が Info.plist に設定されていません。Secrets.xcconfig を確認してください。")
        }
        return value
    }


    /// `ASWebAuthenticationSession` がコールバックとして待ち受けるスキーム。
    static let oauthCallbackScheme = "miniposkids"

    /// 認可サーバーに登録済みのリダイレクト URI。
    static let oauthRedirectURI    = "miniposkids://callback"
}
