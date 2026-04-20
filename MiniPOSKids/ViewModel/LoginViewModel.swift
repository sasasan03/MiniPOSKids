//
//  LoginViewModel.swift
//  MiniPOSKids
//
//  Created by sako0602 on 2026/04/15.
//

import AuthenticationServices
import CryptoKit
import Foundation
import Observation
import OSLog

/// ASWebAuthenticationSession が Safari を表示するために必要なアンカー提供クラス
private final class PresentationContext: NSObject, ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        return scenes
            .first { $0.activationState == .foregroundActive }?
            .windows.first(where: { $0.isKeyWindow })
            ?? scenes.flatMap { $0.windows }.first(where: { $0.isKeyWindow })
            ?? scenes.flatMap { $0.windows }.first
            ?? scenes.first.map { UIWindow(windowScene: $0) }
            ?? UIWindow()
    }
}

@Observable
final class LoginViewModel {
    var errorMessage: String?

    private let authService: AuthServiceProtocol
    private var webAuthSession: ASWebAuthenticationSession?
    private let presentationContext = PresentationContext()
    private var pendingState: String?
    private let logger = Logger(subsystem: "com.miniposkids.auth", category: "LoginViewModel")

    init(authService: AuthServiceProtocol) {
        self.authService = authService
    }

    // MARK: - Login

    /// ログインを実施する（PKCE で認可コードの横取りを防ぎ、state で自分が開始した認可リクエストのコールバックか確認する）。
    ///
    /// PKCE（認可コードをアクセストークンに交換できる正規のアプリか確認する仕組み）のフロー:
    /// 1. `codeVerifier`（暗号学的乱数）を生成 ※外部に漏れてはいけない
    /// 2. `codeVerifier` を SHA256 でハッシュ化した `codeChallenge` を認可リクエストに含めてサーバへ送信（サーバが一時保持）
    /// 3. ユーザーがログインし、サーバから認可コードが返る
    /// 4. アプリが認可コードと `codeVerifier` をトークンエンドポイントへ送信
    /// 5. サーバが `codeVerifier` をハッシュ化し、手順2の値と一致すればアクセストークンを発行
    func login(onSuccess: @escaping () -> Void) {
        // MARK: ① PKCE パラメータ生成
        let codeVerifier: String
        let state: String
        do {
            codeVerifier = try generateCodeVerifier()
            state        = try generateState()
        } catch {
            logger.error("login: PKCEパラメータ生成に失敗しました error=\(error)")
            errorMessage = "認証の初期化に失敗しました"
            return
        }

        // MARK: ② codeVerifier を SHA256 でハッシュ化して codeChallenge を作成
        let codeChallenge = generateCodeChallenge(from: codeVerifier)
        // CSRF 対策として state を保持し、コールバックで返ってきた値と照合する。
        // 例: https://your-app/callback?code=XXXXXXXXXX&state=abcdefg
        pendingState = state

        // MARK: ③ Safari で認可画面を表示し、認可コードを受け取るセッションを構築
        let session = ASWebAuthenticationSession(
            url: buildAuthURL(codeChallenge: codeChallenge, state: state),
            callbackURLScheme: AppConfig.oauthCallbackScheme
        ) { [weak self] callbackURL, error in
            // @Observable のプロパティ変更はすべて MainActor で実行する
            Task { @MainActor [weak self] in
                guard let self else { return }
                webAuthSession = nil

                // MARK: ④ エラー・キャンセル処理
                if let error {
                    pendingState = nil
                    if (error as? ASWebAuthenticationSessionError)?.code == .canceledLogin {
                        logger.info("login: ユーザーがログインをキャンセルしました")
                        return
                    }
                    logger.error("login: 認証セッションエラー error=\(error)")
                    errorMessage = "認証に失敗しました: \(error.localizedDescription)"
                    return
                }
                guard let callbackURL else {
                    pendingState = nil
                    logger.error("login: コールバックURLが nil")
                    errorMessage = "認証コードを取得できませんでした"
                    return
                }

                // MARK: ⑤ state 照合（CSRF対策）
                let items = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?.queryItems
                let returnedState = items?.first(where: { $0.name == "state" })?.value
                // state を取り出し、自分が作成した state と同じか検証する。
                guard returnedState == pendingState else {
                    pendingState = nil
                    logger.fault("login: state不一致を検出 (CSRF攻撃の可能性) returned=\(returnedState ?? "nil", privacy: .public)")
                    errorMessage = "不正なレスポンスを検出しました（state 不一致）"
                    return
                }
                pendingState = nil

                // MARK: ⑥ 認可コードを取得
                guard let code = items?.first(where: { $0.name == "code" })?.value else {
                    logger.error("login: コールバックURLに認可コードが含まれていない url=\(callbackURL, privacy: .public)")
                    errorMessage = "認証コードを取得できませんでした"
                    return
                }

                // MARK: ⑦ 認可コード＋codeVerifier をサーバへ送り、アクセストークンを取得
                do {
                    _ = try await authService.exchangeToken(code: code, codeVerifier: codeVerifier)
                    logger.info("login: ログイン成功")
                    onSuccess()
                } catch {
                    logger.error("login: トークン交換に失敗しました error=\(error)")
                    errorMessage = "トークン取得に失敗しました: \(error.localizedDescription)"
                }
            }
        }

        // MARK: ⑧ セッション開始
        session.presentationContextProvider = presentationContext
        session.prefersEphemeralWebBrowserSession = false
        webAuthSession = session
        guard session.start() else {
            webAuthSession = nil
            pendingState = nil
            logger.error("login: ASWebAuthenticationSession の開始に失敗しました")
            errorMessage = "認証セッションを開始できませんでした"
            return
        }
        logger.info("login: 認証セッション開始")
    }

    // MARK: - PKCE / State

    private enum CryptoError: Error {
        case randomGenerationFailed(OSStatus)
    }

    /// 暗号学的乱数を生成して base64url エンコードした文字列を返す
    /// SecRandomCopyBytes の失敗を検出して throw する
    private func generateRandomBase64URLString(byteCount: Int) throws -> String {
        var bytes = [UInt8](repeating: 0, count: byteCount)
        let status = SecRandomCopyBytes(kSecRandomDefault, byteCount, &bytes)
        guard status == errSecSuccess else {
            throw CryptoError.randomGenerationFailed(status)
        }
        return Data(bytes).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    private func generateCodeVerifier() throws -> String {
        try generateRandomBase64URLString(byteCount: 32)
    }

    private func generateCodeChallenge(from verifier: String) -> String {
        let data = Data(verifier.utf8)
        let hash = SHA256.hash(data: data)
        return Data(hash).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    private func generateState() throws -> String {
        try generateRandomBase64URLString(byteCount: 32)
    }

    private func buildAuthURL(codeChallenge: String, state: String) -> URL {
        var components = URLComponents(string: "https://id.smaregi.dev/authorize")!
        components.queryItems = [
            URLQueryItem(name: "response_type",          value: "code"),
            URLQueryItem(name: "client_id",              value: AppConfig.smaregiClientId),
            URLQueryItem(name: "redirect_uri",           value: AppConfig.oauthRedirectURI),
            URLQueryItem(name: "scope",                  value: "pos.products:read pos.stores:read offline_access"),
            URLQueryItem(name: "code_challenge",         value: codeChallenge),
            URLQueryItem(name: "code_challenge_method",  value: "S256"),
            URLQueryItem(name: "state",                  value: state),
        ]
        return components.url!
    }
}
