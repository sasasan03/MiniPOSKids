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
    var accessToken: String?
}

// MARK: - Helpers

private func makeTokenResponse(accessToken: String = "test-token") -> TokenResponse {
    TokenResponse(accessToken: accessToken, tokenType: "Bearer", expiresIn: 3600)
}

// MARK: - Tests

@Suite(.serialized)
struct AuthServiceTests {

    private func makeSUT() -> (sut: AuthService, client: MockAPIClient, store: MockTokenStore) {
        let client = MockAPIClient()
        let store = MockTokenStore()
        let sut = AuthService(apiClient: client, tokenStore: store)
        return (sut, client, store)
    }

    // MARK: 成功

    @Test func exchangeToken_success_returnsTokenResponse() async throws {
        let (sut, client, _) = makeSUT()
        client.sendFormResponse = makeTokenResponse(accessToken: "abc123")

        let result = try await sut.exchangeToken(code: "auth-code", codeVerifier: "verifier")

        #expect(result.accessToken == "abc123")
        #expect(result.tokenType == "Bearer")
        #expect(result.expiresIn == 3600)
    }

    @Test func exchangeToken_success_storesAccessToken() async throws {
        let (sut, client, store) = makeSUT()
        client.sendFormResponse = makeTokenResponse(accessToken: "stored-token")

        _ = try await sut.exchangeToken(code: "auth-code", codeVerifier: "verifier")

        #expect(store.accessToken == "stored-token")
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

    // MARK: 失敗

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

        #expect(store.accessToken == nil)
    }
}
