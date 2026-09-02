//
//  AppConfig.swift
//  MiniPOSKids
//

import Foundation

enum AppConfig {
    /// 接続先のスマレジ環境。
    ///
    /// 開発（サンドボックス）と本番でホストが分かれているため、切り替えはここ 1 箇所で行う。
    enum Environment {
        case development
        case production

        /// 認可・トークン発行を行う ID サーバーのベース URL。
        var idBaseURL: String {
            switch self {
            case .development: return "https://id.smaregi.dev"
            case .production:  return "https://id.smaregi.jp"
            }
        }

        /// 店舗・商品情報を取得するプラットフォーム API のベース URL。
        var platformBaseURL: String {
            switch self {
            case .development: return "https://api.smaregi.dev"
            case .production:  return "https://api.smaregi.jp"
            }
        }
    }

    /// 現在の接続先環境。本番へ切り替える際はここを `.production` にし、
    /// `Secrets.xcconfig` の `SMAREGI_CLIENT_ID` も本番アプリの値へ差し替える。
    static let environment: Environment = .development

    static var idBaseURL: String { environment.idBaseURL }
    static var platformBaseURL: String { environment.platformBaseURL }

    /// 認可エンドポイントの URL。
    static var authorizeURL: String { "\(idBaseURL)/authorize" }

    static var smaregiClientId: String {
        guard let value = Bundle.main.infoDictionary?["SMAREGI_CLIENT_ID"] as? String,
              !value.isEmpty,
              value != "your_client_id_here" else {
            fatalError("SMAREGI_CLIENT_ID が Info.plist に設定されていません。Secrets.xcconfig を確認してください。")
        }
        return value
    }

    /// `ASWebAuthenticationSession` がコールバックとして待ち受けるスキーム。
    static let oauthCallbackScheme = "miniposkids"

    /// 認可サーバーに登録済みのリダイレクト URI。
    static let oauthRedirectURI    = "miniposkids://callback"
}
