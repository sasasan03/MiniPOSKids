//
//  AuthService.swift
//  MiniPOSKids
//
//  Created by sako0602 on 2026/04/15.
//

import Foundation


protocol TokenStoreProtocol {
    var accessToken: String? { get set }
}

final class TokenStore: TokenStoreProtocol {
    var accessToken: String?
}

struct LoginRequest: Encodable {
    let email: String
    let password: String
}

struct LoginResponse: Decodable {
    let accessToken: String
    let userId: Int
}

protocol AuthServiceProtocol {
    func login(email: String, password: String) async throws -> LoginResponse
}

final class AuthService: AuthServiceProtocol {
    private let apiClient: APIClientProtocol
    private var tokenStore: TokenStoreProtocol

    init(
        apiClient: APIClientProtocol,
        tokenStore: TokenStoreProtocol
    ) {
        self.apiClient = apiClient
        self.tokenStore = tokenStore
    }

    func login(email: String, password: String) async throws -> LoginResponse {
        let request = LoginRequest(email: email, password: password)

        let response: LoginResponse = try await apiClient.send(
            path: "/auth/login",
            method: .post,
            body: request,
            headers: [:]
        )

        tokenStore.accessToken = response.accessToken
        return response
    }
}
