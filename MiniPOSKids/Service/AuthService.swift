//
//  AuthService.swift
//  MiniPOSKids
//
//  Created by sako0602 on 2026/04/15.
//

import Foundation
import Observation
import OSLog

// MARK: - Protocol
protocol AuthServiceProtocol {
    func exchangeToken(code: String, codeVerifier: String) async throws -> TokenResponse
    @discardableResult
    func refreshAccessToken() async throws -> String
}

// MARK: - AuthService
@Observable
final class AuthService: AuthServiceProtocol, TokenRefresherProtocol {
    private let apiClient: APIClientProtocol
    private var tokenStore: TokenStoreProtocol
    private let logger = Logger(subsystem: "com.miniposkids.auth", category: "AuthService")

    private static var clientId: String { AppConfig.smaregiClientId }
    private static var redirectUri: String { AppConfig.oauthRedirectURI }

    init(
        apiClient: APIClientProtocol,
        tokenStore: TokenStoreProtocol
    ) {
        self.apiClient = apiClient
        self.tokenStore = tokenStore
    }

    /// 認可コード＋codeVerifier をサーバへ送り、アクセストークンを取得
    func exchangeToken(code: String, codeVerifier: String) async throws -> TokenResponse {
        logger.info("exchangeToken: 開始")
        let params: [String: String] = [
            "grant_type": "authorization_code",
            "code": code,
            "redirect_uri": Self.redirectUri,
            "client_id": Self.clientId,
            "code_verifier": codeVerifier,
        ]
        do {
            let tokenResponse: TokenResponse = try await apiClient.sendForm(
                path: "/authorize/token",
                method: .post,
                formParams: params,
                headers: [:]
            )
            tokenStore.save(refreshToken: tokenResponse.refreshToken)
            logger.info("exchangeToken: 成功 (expiresIn=\(tokenResponse.expiresIn) hasRefreshToken=\(tokenResponse.refreshToken != nil))")
            return tokenResponse
        } catch {
            logger.error("exchangeToken: 失敗 error=\(error)")
            throw error
        }
    }

    // MARK: リフレッシュトークンによる自動更新
    func refreshAccessToken() async throws -> String {
        guard let currentRefreshToken = tokenStore.refreshToken else {
            logger.warning("refreshAccessToken: リフレッシュトークンが存在しない → sessionExpired")
            throw APIError.sessionExpired
        }
        logger.info("refreshAccessToken: 開始")
        let params: [String: String] = [
            "grant_type":    "refresh_token",
            "refresh_token": currentRefreshToken,
            "client_id":     Self.clientId,
        ]
        do {
            let tokenResponse: TokenResponse = try await apiClient.sendForm(
                path: "/authorize/token",
                method: .post,
                formParams: params,
                headers: [:]
            )
            let usedNewRefreshToken = tokenResponse.refreshToken != nil
            tokenStore.save(refreshToken: tokenResponse.refreshToken ?? currentRefreshToken)
            logger.info("refreshAccessToken: 成功 (expiresIn=\(tokenResponse.expiresIn) refreshTokenRotated=\(usedNewRefreshToken))")
            return tokenResponse.accessToken
        } catch let error as APIError {
            if case .statusCode(let code, _) = error, code == 400 || code == 401 {
                logger.warning("refreshAccessToken: サーバーが \(code) を返した → トークン削除 → sessionExpired")
                tokenStore.deleteToken()
                throw APIError.sessionExpired
            }
            logger.error("refreshAccessToken: 失敗 error=\(error)")
            throw error
        }
    }
}
