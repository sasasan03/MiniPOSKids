//
//  AuthService.swift
//  MiniPOSKids
//
//  Created by sako0602 on 2026/04/15.
//

import Foundation
import Observation

// MARK: - TokenStore

protocol TokenStoreProtocol {
    var accessToken: String? { get set }
}

final class TokenStore: TokenStoreProtocol {
    var accessToken: String?
}

struct TokenResponse: Decodable {
    let accessToken: String
    let tokenType: String
    let expiresIn: Int

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType   = "token_type"
        case expiresIn   = "expires_in"
    }
}

// MARK: - Protocol

protocol AuthServiceProtocol {
    func exchangeToken(code: String, codeVerifier: String) async throws -> TokenResponse
}

// MARK: - AuthService

@Observable
final class AuthService: AuthServiceProtocol {
    private let apiClient: APIClientProtocol
    private var tokenStore: TokenStoreProtocol

    private static var clientId: String { AppConfig.smaregiClientId }
    private static let redirectUri = "miniposkids://callback"

    init(
        apiClient: APIClientProtocol,
        tokenStore: TokenStoreProtocol
    ) {
        self.apiClient = apiClient
        self.tokenStore = tokenStore
    }

    // MARK: PKCEトークン交換

    func exchangeToken(code: String, codeVerifier: String) async throws -> TokenResponse {
        let params: [String: String] = [
            "grant_type":    "authorization_code",
            "code":          code,
            "redirect_uri":  Self.redirectUri,
            "client_id":     Self.clientId,
            "code_verifier": codeVerifier,
        ]
        let tokenResponse: TokenResponse = try await apiClient.sendForm(
            path: "/authorize/token",
            method: .post,
            formParams: params,
            headers: [:]
        )
        tokenStore.accessToken = tokenResponse.accessToken
        return tokenResponse
    }
}
