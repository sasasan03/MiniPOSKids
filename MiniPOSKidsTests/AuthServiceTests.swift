//
//  AuthServiceTests.swift
//  MiniPOSKidsTests
//

import Testing
import Foundation
@testable import MiniPOSKids

// MARK: - Mocks

final class MockAPIClient: APIClientProtocol {
    // send(path:method:body:headers:) の呼び出し記録
    var capturedPath: String?
    var capturedMethod: HTTPMethod?
    var capturedHeaders: [String: String]?

    // 返す値またはスローするエラーを外から注入する
    var stubbedResult: (any Decodable)?
    var stubbedError: Error?

    func send<RequestBody: Encodable, ResponseBody: Decodable>(
        path: String,
        method: HTTPMethod,
        body: RequestBody?,
        headers: [String: String]
    ) async throws -> ResponseBody {
        capturedPath = path
        capturedMethod = method
        capturedHeaders = headers

        if let error = stubbedError {
            throw error
        }
        guard let result = stubbedResult as? ResponseBody else {
            fatalError("stubbedResult の型が ResponseBody と一致しません")
        }
        return result
    }

    func send<ResponseBody: Decodable>(
        path: String,
        method: HTTPMethod,
        headers: [String: String]
    ) async throws -> ResponseBody {
        capturedPath = path
        capturedMethod = method
        capturedHeaders = headers

        if let error = stubbedError {
            throw error
        }
        guard let result = stubbedResult as? ResponseBody else {
            fatalError("stubbedResult の型が ResponseBody と一致しません")
        }
        return result
    }
}

final class MockTokenStore: TokenStoreProtocol {
    var accessToken: String?
}

// MARK: - Tests

struct AuthServiceTests {

    // MARK: login 成功

    @Test func login_success_returnsLoginResponse() async throws {
        let mockClient = MockAPIClient()
        let mockStore = MockTokenStore()
        let expected = LoginResponse(accessToken: "test-token-abc", userId: 42)
        mockClient.stubbedResult = expected

        let sut = await AuthService(apiClient: mockClient, tokenStore: mockStore)
        let response = try await sut.login(email: "user@example.com", password: "pass1234")

        #expect(response.accessToken == expected.accessToken)
        #expect(response.userId == expected.userId)
    }

    @Test func login_success_storesAccessTokenInTokenStore() async throws {
        let mockClient = MockAPIClient()
        let mockStore = MockTokenStore()
        mockClient.stubbedResult = LoginResponse(accessToken: "stored-token", userId: 1)

        let sut = await AuthService(apiClient: mockClient, tokenStore: mockStore)
        _ = try await sut.login(email: "user@example.com", password: "pass1234")

        #expect(mockStore.accessToken == "stored-token")
    }

    @Test func login_success_callsCorrectEndpoint() async throws {
        let mockClient = MockAPIClient()
        let mockStore = MockTokenStore()
        mockClient.stubbedResult = LoginResponse(accessToken: "token", userId: 1)

        let sut = await AuthService(apiClient: mockClient, tokenStore: mockStore)
        _ = try await sut.login(email: "user@example.com", password: "pass1234")

        #expect(mockClient.capturedPath == "/auth/login")
        #expect(mockClient.capturedMethod == .post)
    }

    // MARK: login 失敗

    @Test func login_failure_propagatesNetworkError() async {
        let mockClient = MockAPIClient()
        let mockStore = MockTokenStore()
        mockClient.stubbedError = APIError.networkError(URLError(.notConnectedToInternet))

        let sut = await AuthService(apiClient: mockClient, tokenStore: mockStore)

        do {
            _ = try await sut.login(email: "user@example.com", password: "pass1234")
            Issue.record("エラーがスローされるべきでした")
        } catch {
            #expect(error is APIError)
        }
    }

    @Test func login_failure_propagatesStatusCodeError() async {
        let mockClient = MockAPIClient()
        let mockStore = MockTokenStore()
        mockClient.stubbedError = APIError.statusCode(401, Data())

        let sut = await AuthService(apiClient: mockClient, tokenStore: mockStore)

        do {
            _ = try await sut.login(email: "user@example.com", password: "pass1234")
            Issue.record("エラーがスローされるべきでした")
        } catch {
            #expect(error is APIError)
        }
    }

    @Test func login_failure_doesNotStoreTokenOnError() async {
        let mockClient = MockAPIClient()
        let mockStore = MockTokenStore()
        mockClient.stubbedError = APIError.statusCode(401, Data())

        let sut = await AuthService(apiClient: mockClient, tokenStore: mockStore)

        _ = try? await sut.login(email: "user@example.com", password: "pass1234")

        #expect(mockStore.accessToken == nil)
    }
}
