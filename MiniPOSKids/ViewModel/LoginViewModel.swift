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

    init(authService: AuthServiceProtocol) {
        self.authService = authService
    }

    // MARK: - Login

    func login(onSuccess: @escaping () -> Void) {
        let codeVerifier: String
        let state: String
        do {
            codeVerifier = try generateCodeVerifier()
            state        = try generateState()
        } catch {
            errorMessage = "認証の初期化に失敗しました"
            return
        }
        let codeChallenge = generateCodeChallenge(from: codeVerifier)
        pendingState = state

        let session = ASWebAuthenticationSession(
            url: buildAuthURL(codeChallenge: codeChallenge, state: state),
            callbackURLScheme: AppConfig.oauthCallbackScheme
        ) { [weak self] callbackURL, error in
            // @Observable のプロパティ変更はすべて MainActor で実行する
            Task { @MainActor [weak self] in
                guard let self else { return }
                webAuthSession = nil

                if let error {
                    pendingState = nil
                    if (error as? ASWebAuthenticationSessionError)?.code == .canceledLogin { return }
                    errorMessage = "認証に失敗しました: \(error.localizedDescription)"
                    return
                }
                guard let callbackURL else {
                    pendingState = nil
                    errorMessage = "認証コードを取得できませんでした"
                    return
                }
                let items = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?.queryItems
                let returnedState = items?.first(where: { $0.name == "state" })?.value
                guard returnedState == pendingState else {
                    pendingState = nil
                    errorMessage = "不正なレスポンスを検出しました（state 不一致）"
                    return
                }
                pendingState = nil
                guard let code = items?.first(where: { $0.name == "code" })?.value else {
                    errorMessage = "認証コードを取得できませんでした"
                    return
                }
                do {
                    _ = try await authService.exchangeToken(code: code, codeVerifier: codeVerifier)
                    onSuccess()
                } catch {
                    errorMessage = "トークン取得に失敗しました: \(error.localizedDescription)"
                }
            }
        }
        session.presentationContextProvider = presentationContext
        session.prefersEphemeralWebBrowserSession = false
        webAuthSession = session
        guard session.start() else {
            webAuthSession = nil
            pendingState = nil
            errorMessage = "認証セッションを開始できませんでした"
            return
        }
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
            URLQueryItem(name: "scope",                  value: "pos.products:read pos.stores:read"),
            URLQueryItem(name: "code_challenge",         value: codeChallenge),
            URLQueryItem(name: "code_challenge_method",  value: "S256"),
            URLQueryItem(name: "state",                  value: state),
        ]
        return components.url!
    }
}
