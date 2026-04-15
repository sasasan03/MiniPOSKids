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

// ASWebAuthenticationSession が Safari を表示するために必要なアンカー提供クラス
private final class PresentationContext: NSObject, ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?
            .keyWindow ?? ASPresentationAnchor()
    }
}

@Observable
final class LoginViewModel {
    var errorMessage: String?

    private var webAuthSession: ASWebAuthenticationSession?
    private let presentationContext = PresentationContext()

    // MARK: - Login

    func login(authService: AuthService, onSuccess: @escaping () -> Void) {
        let codeVerifier  = generateCodeVerifier()
        let codeChallenge = generateCodeChallenge(from: codeVerifier)

        let session = ASWebAuthenticationSession(
            url: buildAuthURL(codeChallenge: codeChallenge),
            callbackURLScheme: "miniposkids"
        ) { [weak self] callbackURL, error in
            guard let self else { return }
            webAuthSession = nil

            if let error {
                if (error as? ASWebAuthenticationSessionError)?.code == .canceledLogin { return }
                errorMessage = "認証に失敗しました: \(error.localizedDescription)"
                return
            }
            guard let callbackURL,
                  let code = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?
                      .queryItems?
                      .first(where: { $0.name == "code" })?
                      .value
            else {
                errorMessage = "認証コードを取得できませんでした"
                return
            }
            Task {
                do {
                    _ = try await authService.exchangeToken(code: code, codeVerifier: codeVerifier)
                    onSuccess()
                } catch {
                    self.errorMessage = "トークン取得に失敗しました: \(error.localizedDescription)"
                }
            }
        }
        session.presentationContextProvider = presentationContext
        session.prefersEphemeralWebBrowserSession = false
        webAuthSession = session
        session.start()
    }

    // MARK: - PKCE

    private func generateCodeVerifier() -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    private func generateCodeChallenge(from verifier: String) -> String {
        let data = Data(verifier.utf8)
        let hash = SHA256.hash(data: data)
        return Data(hash).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    private func buildAuthURL(codeChallenge: String) -> URL {
        var components = URLComponents(string: "https://id.smaregi.dev/authorize")!
        components.queryItems = [
            URLQueryItem(name: "response_type",          value: "code"),
            URLQueryItem(name: "client_id",              value: "02658c46faecf5d471d788d26d194897"),
            URLQueryItem(name: "redirect_uri",           value: "miniposkids://callback"),
            URLQueryItem(name: "scope",                  value: "pos.products:read pos.stores:read"),
            URLQueryItem(name: "code_challenge",         value: codeChallenge),
            URLQueryItem(name: "code_challenge_method",  value: "S256"),
        ]
        return components.url!
    }
}

