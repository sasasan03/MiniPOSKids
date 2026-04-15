//
//  AppConfig.swift
//  MiniPOSKids
//

import Foundation

enum AppConfig {
    static var smaregiClientId: String {
        guard let value = Bundle.main.infoDictionary?["SMAREGI_CLIENT_ID"] as? String,
              !value.isEmpty else {
            fatalError("SMAREGI_CLIENT_ID が Info.plist に設定されていません。Secrets.xcconfig を確認してください。")
        }
        return value
    }
}
