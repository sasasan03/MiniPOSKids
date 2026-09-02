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
final class AuthService: AuthServiceProtocol, TokenRefresherProtocol, ContractIdProviding {
    private let apiClient: APIClientProtocol
    private var tokenStore: TokenStoreProtocol
    private let logger = Logger(subsystem: "com.miniposkids.auth", category: "AuthService")

    private var cachedAccessToken: String?
    private var accessTokenExpiry: Date?

    /// 直近のアクセストークンから取り出した契約ID。ログイン前は nil。
    ///
    /// アクセストークンのキャッシュを破棄しても契約自体は変わらないため、ここは保持し続ける。
    private(set) var contractId: String?

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
            logJWTPayload(tokenResponse.accessToken)
            // 契約IDを取り出せないトークンでは以降の API を呼べないため、
            // 中途半端にログイン済みの状態を作らずここで失敗させる。
            let claims = try AccessTokenClaims(accessToken: tokenResponse.accessToken)
            warnIfClientIdMismatch(claims)
            contractId = claims.contractId
            tokenStore.save(refreshToken: tokenResponse.refreshToken)
            cacheAccessToken(tokenResponse.accessToken, expiresIn: tokenResponse.expiresIn)
            logger.info("exchangeToken: 成功 (expiresIn=\(tokenResponse.expiresIn) hasRefreshToken=\(tokenResponse.refreshToken != nil))")
            return tokenResponse
        } catch {
            logger.error("exchangeToken: 失敗 error=\(error)")
            throw error
        }
    }

    // MARK: リフレッシュトークンによる自動更新
    func refreshAccessToken() async throws -> String {
        if let token = cachedAccessToken, let expiry = accessTokenExpiry, Date() < expiry {
            logger.debug("refreshAccessToken: キャッシュ済みトークンを返します")
            return token
        }
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
            updateContractIdIfPossible(from: tokenResponse.accessToken)
            let usedNewRefreshToken = tokenResponse.refreshToken != nil
            tokenStore.save(refreshToken: tokenResponse.refreshToken ?? currentRefreshToken)
            cacheAccessToken(tokenResponse.accessToken, expiresIn: tokenResponse.expiresIn)
            logger.info("refreshAccessToken: 成功 (expiresIn=\(tokenResponse.expiresIn) refreshTokenRotated=\(usedNewRefreshToken))")
            return tokenResponse.accessToken
        } catch let error as APIError {
            if case .statusCode(let code, _) = error, code == 400 || code == 401 {
                logger.warning("refreshAccessToken: サーバーが \(code) を返した → トークン削除 → sessionExpired")
                invalidateCachedToken()
                tokenStore.deleteToken()
                throw APIError.sessionExpired
            }
            logger.error("refreshAccessToken: 失敗 error=\(error)")
            throw error
        }
    }

    // MARK: - ContractIdProviding

    func currentContractId() async throws -> String {
        // トークンが未取得・期限切れなら更新し、その副作用で contractId が埋まる。
        _ = try await refreshAccessToken()
        guard let contractId else {
            logger.error("currentContractId: アクセストークンから契約IDを取得できませんでした")
            throw APIError.missingContractId
        }
        return contractId
    }

    /// アクセストークンから契約IDを取り出して保持する。取り出せない場合は既存の値を維持する。
    ///
    /// リフレッシュ時に契約が変わることはないため、解析に失敗しても直ちにセッションを
    /// 切らず、ログだけ残して継続する。
    /// - Parameter accessToken: 新しく取得したアクセストークン。
    private func updateContractIdIfPossible(from accessToken: String) {
        do {
            let claims = try AccessTokenClaims(accessToken: accessToken)
            warnIfClientIdMismatch(claims)
            contractId = claims.contractId
        } catch {
            logger.error("updateContractIdIfPossible: 契約IDの取り出しに失敗しました error=\(error)")
        }
    }

    /// トークンの発行先クライアントIDがアプリの設定値と異なる場合に警告する。
    ///
    /// 環境（dev / 本番）や `Secrets.xcconfig` を取り違えたビルドを早期に気付くための保険。
    /// 不一致でもリクエスト自体は成立しうるためエラーにはしない。
    /// - Parameter claims: アクセストークンから取り出したクレーム。
    private func warnIfClientIdMismatch(_ claims: AccessTokenClaims) {
        guard let audience = claims.clientId, audience != Self.clientId else { return }
        logger.warning("warnIfClientIdMismatch: aud が設定中の client_id と一致しません")
    }

    func invalidateCachedToken() {
        logger.info("invalidateCachedToken: アクセストークンキャッシュを破棄しました")
        cachedAccessToken = nil
        accessTokenExpiry = nil
    }

    /// アクセストークン（JWT）のペイロードをデコードしてログ出力する。クレームの中身を確認するための調査用。
    ///
    /// 本番ビルドのログにトークンの中身が残らないよう `#if DEBUG` で囲っている。
    /// - Parameter accessToken: `header.payload.signature` 形式の JWT 文字列。
    private func logJWTPayload(_ accessToken: String) {
        #if DEBUG
        let segments = accessToken.split(separator: ".")
        guard segments.count >= 2 else {
            logger.debug("logJWTPayload: JWT 形式ではないためスキップします")
            return
        }
        guard let data = AccessTokenClaims.decodeBase64URL(segments[1]),
              let json = String(data: data, encoding: .utf8) else {
            logger.debug("logJWTPayload: ペイロードのデコードに失敗しました")
            return
        }
        // 既定では Console.app 上でマスクされ中身を確認できないため、調査目的で .public を指定する。
        logger.debug("logJWTPayload: payload=\(json, privacy: .public)")
        #endif
    }

    private func cacheAccessToken(_ token: String, expiresIn: Int) {
        cachedAccessToken = token
        // 60秒のバッファを設けて期限切れ前にリフレッシュ
        accessTokenExpiry = Date().addingTimeInterval(TimeInterval(expiresIn) - 60)
    }
}
