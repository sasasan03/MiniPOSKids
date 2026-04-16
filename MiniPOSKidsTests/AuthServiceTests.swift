//
//  AuthServiceTests.swift
//  MiniPOSKidsTests
//

import Testing
import Foundation
@testable import MiniPOSKids

// MARK: - URLProtocol Mock

final class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

// MARK: - Helpers

private func makeMockSession() -> URLSession {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [MockURLProtocol.self]
    return URLSession(configuration: config)
}

private func makeTokenJSON(accessToken: String = "test-token") -> Data {
    Data("""
    {"access_token":"\(accessToken)","token_type":"Bearer","expires_in":3600}
    """.utf8)
}

// MARK: - Mocks

final class MockAPIClient: APIClientProtocol {
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

// MARK: - Tests

struct AuthServiceTests {

    private func makeSUT() -> (sut: AuthService, store: MockTokenStore) {
        let store = MockTokenStore()
        let sut = AuthService(apiClient: MockAPIClient(), tokenStore: store, session: makeMockSession())
        return (sut, store)
    }

    // MARK: 成功

    @Test func exchangeToken_success_returnsTokenResponse() async throws {
        MockURLProtocol.requestHandler = { _ in
            let res = HTTPURLResponse(url: URL(string: "https://id.smaregi.dev")!,
                                      statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (res, makeTokenJSON(accessToken: "abc123"))
        }
        let (sut, _) = makeSUT()
        let result = try await sut.exchangeToken(code: "auth-code", codeVerifier: "verifier")

        #expect(result.accessToken == "abc123")
        #expect(result.tokenType == "Bearer")
        #expect(result.expiresIn == 3600)
    }

    @Test func exchangeToken_success_storesAccessToken() async throws {
        MockURLProtocol.requestHandler = { _ in
            let res = HTTPURLResponse(url: URL(string: "https://id.smaregi.dev")!,
                                      statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (res, makeTokenJSON(accessToken: "stored-token"))
        }
        let (sut, store) = makeSUT()
        _ = try await sut.exchangeToken(code: "auth-code", codeVerifier: "verifier")

        #expect(store.accessToken == "stored-token")
    }

    @Test func exchangeToken_success_sendsCorrectRequest() async throws {
        var captured: URLRequest?
        MockURLProtocol.requestHandler = { request in
            captured = request
            let res = HTTPURLResponse(url: URL(string: "https://id.smaregi.dev")!,
                                      statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (res, makeTokenJSON())
        }
        let (sut, _) = makeSUT()
        _ = try await sut.exchangeToken(code: "my-code", codeVerifier: "my-verifier")

        let body = captured.flatMap(\.httpBody).flatMap { String(data: $0, encoding: .utf8) } ?? ""
        #expect(captured?.httpMethod == "POST")
        #expect(captured?.value(forHTTPHeaderField: "Content-Type") == "application/x-www-form-urlencoded")
        #expect(body.contains("code=my-code"))
        #expect(body.contains("code_verifier=my-verifier"))
        #expect(body.contains("grant_type=authorization_code"))
        #expect(body.contains("redirect_uri=miniposkids"))
    }

    // MARK: 失敗

    @Test func exchangeToken_failure_statusCode401_throwsStatusCodeError() async throws {
        MockURLProtocol.requestHandler = { _ in
            let res = HTTPURLResponse(url: URL(string: "https://id.smaregi.dev")!,
                                      statusCode: 401, httpVersion: nil, headerFields: nil)!
            return (res, Data())
        }
        let (sut, _) = makeSUT()

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
        MockURLProtocol.requestHandler = { _ in
            throw URLError(.notConnectedToInternet)
        }
        let (sut, _) = makeSUT()

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
        MockURLProtocol.requestHandler = { _ in
            let res = HTTPURLResponse(url: URL(string: "https://id.smaregi.dev")!,
                                      statusCode: 500, httpVersion: nil, headerFields: nil)!
            return (res, Data())
        }
        let (sut, store) = makeSUT()
        _ = try? await sut.exchangeToken(code: "code", codeVerifier: "verifier")

        #expect(store.accessToken == nil)
    }
}
