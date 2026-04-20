//
//  AuthServiceTests.swift
//  MiniPOSKidsTests
//

import Testing
import Foundation
@testable import MiniPOSKids

// MARK: - Mocks

final class MockAPIClient: APIClientProtocol {
    var sendFormResponse: Any?
    var sendFormError: Error?
    var capturedFormParams: [String: String] = [:]
    var capturedFormPath: String = ""

    func sendForm<ResponseBody: Decodable>(
        path: String, method: HTTPMethod, formParams: [String: String], headers: [String: String]
    ) async throws -> ResponseBody {
        capturedFormPath = path
        capturedFormParams = formParams
        if let error = sendFormError { throw error }
        return sendFormResponse as! ResponseBody
    }

    func send<RequestBody: Encodable, ResponseBody: Decodable>(
        path: String, method: HTTPMethod, body: RequestBody?, headers: [String: String]
    ) async throws -> ResponseBody { fatalError("not used in AuthService") }

    func send<ResponseBody: Decodable>(
        path: String, method: HTTPMethod, headers: [String: String]
    ) async throws -> ResponseBody { fatalError("not used in AuthService") }
}

final class MockTokenStore: TokenStoreProtocol {
    var refreshToken: String?

    func save(refreshToken: String?) {
        self.refreshToken = refreshToken
    }

    func deleteToken() {
        refreshToken = nil
    }
}

// MARK: - Helpers

private func makeTokenResponse(
    accessToken: String = "test-token",
    refreshToken: String? = "test-refresh-token"
) -> TokenResponse {
    TokenResponse(accessToken: accessToken, tokenType: "Bearer", expiresIn: 3600, refreshToken: refreshToken)
}

// MARK: - Tests

@MainActor
@Suite(.serialized)
struct AuthServiceTests {

    private func makeSUT() -> (sut: AuthService, client: MockAPIClient, store: MockTokenStore) {
        let client = MockAPIClient()
        let store = MockTokenStore()
        let sut = AuthService(apiClient: client, tokenStore: store)
        return (sut, client, store)
    }

    // MARK: exchangeToken - 成功

    @Test func exchangeToken_success_returnsTokenResponse() async throws {
        let (sut, client, _) = makeSUT()
        client.sendFormResponse = makeTokenResponse(accessToken: "abc123")

        let result = try await sut.exchangeToken(code: "auth-code", codeVerifier: "verifier")

        #expect(result.accessToken == "abc123")
        #expect(result.tokenType == "Bearer")
        #expect(result.expiresIn == 3600)
    }

    @Test func exchangeToken_success_storesRefreshToken() async throws {
        let (sut, client, store) = makeSUT()
        client.sendFormResponse = makeTokenResponse(accessToken: "stored-token", refreshToken: "stored-refresh")

        _ = try await sut.exchangeToken(code: "auth-code", codeVerifier: "verifier")

        #expect(store.refreshToken == "stored-refresh")
    }

    @Test func exchangeToken_success_sendsCorrectParams() async throws {
        let (sut, client, _) = makeSUT()
        client.sendFormResponse = makeTokenResponse()

        _ = try await sut.exchangeToken(code: "my-code", codeVerifier: "my-verifier")

        #expect(client.capturedFormParams["code"] == "my-code")
        #expect(client.capturedFormParams["code_verifier"] == "my-verifier")
        #expect(client.capturedFormParams["grant_type"] == "authorization_code")
        #expect(client.capturedFormParams["redirect_uri"] == "miniposkids://callback")
        #expect(client.capturedFormPath == "/authorize/token")
    }

    // MARK: exchangeToken - 失敗

    @Test func exchangeToken_failure_statusCode401_throwsStatusCodeError() async throws {
        let (sut, client, _) = makeSUT()
        client.sendFormError = APIError.statusCode(401, Data())

        do {
            _ = try await sut.exchangeToken(code: "code", codeVerifier: "verifier")
            Issue.record("エラーがスローされるべきでした")
        } catch let error as APIError {
            guard case .statusCode(let code, _) = error else {
                Issue.record("想定外のAPIErrorケース: \(error)"); return
            }
            #expect(code == 401)
        }
    }

    @Test func exchangeToken_failure_networkError_throwsNetworkError() async throws {
        let (sut, client, _) = makeSUT()
        client.sendFormError = APIError.networkError(URLError(.notConnectedToInternet))

        do {
            _ = try await sut.exchangeToken(code: "code", codeVerifier: "verifier")
            Issue.record("エラーがスローされるべきでした")
        } catch let error as APIError {
            guard case .networkError = error else {
                Issue.record("想定外のAPIErrorケース: \(error)"); return
            }
        }
    }

    @Test func exchangeToken_failure_doesNotStoreTokenOnError() async throws {
        let (sut, client, store) = makeSUT()
        client.sendFormError = APIError.statusCode(500, Data())

        _ = try? await sut.exchangeToken(code: "code", codeVerifier: "verifier")

        #expect(store.refreshToken == nil)
    }

    // MARK: refreshAccessToken - 成功

    @Test func refreshAccessToken_success_returnsAccessTokenAndStoresNewRefreshToken() async throws {
        let (sut, client, store) = makeSUT()
        store.refreshToken = "existing-refresh"
        client.sendFormResponse = makeTokenResponse(accessToken: "new-access", refreshToken: "new-refresh")

        let accessToken = try await sut.refreshAccessToken()

        #expect(accessToken == "new-access")
        #expect(store.refreshToken == "new-refresh")
    }

    @Test func refreshAccessToken_success_sendsCorrectParams() async throws {
        let (sut, client, store) = makeSUT()
        store.refreshToken = "my-refresh-token"
        client.sendFormResponse = makeTokenResponse()

        _ = try await sut.refreshAccessToken()

        #expect(client.capturedFormParams["grant_type"] == "refresh_token")
        #expect(client.capturedFormParams["refresh_token"] == "my-refresh-token")
        #expect(client.capturedFormPath == "/authorize/token")
    }

    @Test func refreshAccessToken_keepsExistingRefreshToken_whenServerDoesNotReturnNewOne() async throws {
        let (sut, client, store) = makeSUT()
        store.refreshToken = "original-refresh"
        client.sendFormResponse = makeTokenResponse(accessToken: "new-access", refreshToken: nil)

        _ = try await sut.refreshAccessToken()

        #expect(store.refreshToken == "original-refresh")
    }

    // MARK: refreshAccessToken - 失敗

    @Test func refreshAccessToken_noRefreshToken_throwsSessionExpired() async throws {
        let (sut, _, _) = makeSUT()

        do {
            _ = try await sut.refreshAccessToken()
            Issue.record("エラーがスローされるべきでした")
        } catch let error as APIError {
            guard case .sessionExpired = error else {
                Issue.record("想定外のAPIErrorケース: \(error)"); return
            }
        }
    }

    @Test func refreshAccessToken_serverReturns401_throwsSessionExpired_andDeletesTokens() async throws {
        let (sut, client, store) = makeSUT()
        store.refreshToken = "expired-refresh"
        client.sendFormError = APIError.statusCode(401, Data())

        do {
            _ = try await sut.refreshAccessToken()
            Issue.record("エラーがスローされるべきでした")
        } catch let error as APIError {
            guard case .sessionExpired = error else {
                Issue.record("想定外のAPIErrorケース: \(error)"); return
            }
        }

        #expect(store.refreshToken == nil)
    }

    @Test func refreshAccessToken_serverReturns400_throwsSessionExpired_andDeletesTokens() async throws {
        let (sut, client, store) = makeSUT()
        store.refreshToken = "expired-refresh"
        client.sendFormError = APIError.statusCode(400, Data())

        do {
            _ = try await sut.refreshAccessToken()
            Issue.record("エラーがスローされるべきでした")
        } catch let error as APIError {
            guard case .sessionExpired = error else {
                Issue.record("想定外のAPIErrorケース: \(error)"); return
            }
        }

        #expect(store.refreshToken == nil)
    }
}
