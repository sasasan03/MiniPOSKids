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
    private let session: URLSession
    private let decoder: JSONDecoder

    private static var clientId: String { AppConfig.smaregiClientId }
    private static let redirectUri = "miniposkids://callback"
    private static let tokenEndpoint = URL(string: "https://id.smaregi.dev/authorize/token")!

    init(
        apiClient: APIClientProtocol,
        tokenStore: TokenStoreProtocol,
        session: URLSession = .shared
    ) {
        self.apiClient = apiClient
        self.tokenStore = tokenStore
        self.session = session
        self.decoder = JSONDecoder()
    }

    // MARK: PKCEトークン交換

    func exchangeToken(code: String, codeVerifier: String) async throws -> TokenResponse {
        var request = URLRequest(url: Self.tokenEndpoint)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let params: [String: String] = [
            "grant_type":    "authorization_code",
            "code":          code,
            "redirect_uri":  Self.redirectUri,
            "client_id":     Self.clientId,
            "code_verifier": codeVerifier,
        ]
        request.httpBody = params
            .map { key, value in
                let encodedValue = value.addingPercentEncoding(
                    withAllowedCharacters: .urlQueryAllowed
                ) ?? value
                return "\(key)=\(encodedValue)"
            }
            .sorted()
            .joined(separator: "&")
            .data(using: .utf8)

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            guard 200...299 ~= httpResponse.statusCode else {
                throw APIError.statusCode(httpResponse.statusCode, data)
            }

            let tokenResponse = try decoder.decode(TokenResponse.self, from: data)
            tokenStore.accessToken = tokenResponse.accessToken
            return tokenResponse
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }
}
