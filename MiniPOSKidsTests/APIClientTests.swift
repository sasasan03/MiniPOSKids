//
//  APIClientTests.swift
//  MiniPOSKidsTests
//

import Testing
import Foundation
@testable import MiniPOSKids

// MARK: - URLProtocol Mock

private final class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
            return
        }
        // URLSession は httpBody を httpBodyStream に変換して渡すため、元に戻す
        var resolved = request
        if let stream = request.httpBodyStream {
            var data = Data()
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 4096)
            stream.open()
            while stream.hasBytesAvailable {
                let count = stream.read(buffer, maxLength: 4096)
                if count <= 0 { break }
                data.append(buffer, count: count)
            }
            stream.close()
            buffer.deallocate()
            resolved.httpBody = data
        }
        do {
            let (response, data) = try handler(resolved)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

// MARK: - Mocks

private final class MockTokenRefresher: TokenRefresherProtocol {
    var refreshCalled = false
    var refreshCallCount = 0
    var accessToken = "refreshed-token"
    var refreshError: Error?
    var onRefresh: ((Int) -> Void)?

    func refreshAccessToken() async throws -> String {
        refreshCalled = true
        refreshCallCount += 1
        onRefresh?(refreshCallCount)
        if let error = refreshError { throw error }
        return accessToken
    }

    func invalidateCachedToken() {}
}

// MARK: - Helpers

private struct Item: Codable, Equatable {
    let id: Int
    let name: String
}

private struct RequestPayload: Encodable {
    let value: String
}

private func makeMockSession() -> URLSession {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [MockURLProtocol.self]
    return URLSession(configuration: config)
}

private func makeResponse(statusCode: Int = 200) -> HTTPURLResponse {
    HTTPURLResponse(
        url: URL(string: "https://api.example.com")!,
        statusCode: statusCode,
        httpVersion: nil,
        headerFields: nil
    )!
}

private func makeItemJSON(id: Int = 1, name: String = "test") -> Data {
    Data(#"{"id":\#(id),"name":"\#(name)"}"#.utf8)
}

// MARK: - Tests

@MainActor
@Suite(.serialized)
struct APIClientTests {
    private let baseURL = "https://api.example.com"

    private func makeSUT(
        baseURL: String? = nil
    ) -> APIClient {
        APIClient(
            baseURL: baseURL ?? self.baseURL,
            session: makeMockSession()
        )
    }

    // MARK: send - URL 構築

    @Test func send_buildsCorrectURL() async throws {
        var captured: URLRequest?
        MockURLProtocol.requestHandler = { request in
            captured = request; return (makeResponse(), makeItemJSON())
        }
        let _: Item = try await makeSUT().send(path: "/items/1", method: .get, headers: [:])

        #expect(captured?.url?.absoluteString == "https://api.example.com/items/1")
    }

    @Test func send_normalizesTrailingSlashInBaseURL() async throws {
        var captured: URLRequest?
        MockURLProtocol.requestHandler = { request in
            captured = request; return (makeResponse(), makeItemJSON())
        }
        let _: Item = try await makeSUT(baseURL: "https://api.example.com/")
            .send(path: "/items/1", method: .get, headers: [:])

        #expect(captured?.url?.absoluteString == "https://api.example.com/items/1")
    }

    @Test func send_normalizesLeadingSlashInPath() async throws {
        var captured: URLRequest?
        MockURLProtocol.requestHandler = { request in
            captured = request; return (makeResponse(), makeItemJSON())
        }
        let _: Item = try await makeSUT().send(path: "items/1", method: .get, headers: [:])

        #expect(captured?.url?.absoluteString == "https://api.example.com/items/1")
    }

    @Test func send_throwsInvalidURL_whenBaseURLIsMalformed() async throws {
        do {
            // "http://[invalid" は URL(string:) が nil を返す形式
            let _: Item = try await makeSUT(baseURL: "http://[invalid")
                .send(path: "/items", method: .get, headers: [:])
            Issue.record("エラーがスローされるべきでした")
        } catch let error as APIError {
            guard case .invalidURL = error else {
                Issue.record("想定外のAPIErrorケース: \(error)"); return
            }
        }
    }

    // MARK: send - リクエストヘッダー

    @Test func send_setsAcceptApplicationJSON() async throws {
        var captured: URLRequest?
        MockURLProtocol.requestHandler = { request in
            captured = request; return (makeResponse(), makeItemJSON())
        }
        let _: Item = try await makeSUT().send(path: "/items", method: .get, headers: [:])

        #expect(captured?.value(forHTTPHeaderField: "Accept") == "application/json")
    }

    @Test func send_setsAuthorizationHeader_whenTokenRefresherReturnsToken() async throws {
        var captured: URLRequest?
        MockURLProtocol.requestHandler = { request in
            captured = request; return (makeResponse(), makeItemJSON())
        }
        let refresher = MockTokenRefresher()
        refresher.accessToken = "my-token"
        let sut = makeSUT()
        sut.tokenRefresher = refresher
        let _: Item = try await sut.send(path: "/items", method: .get, headers: [:])

        #expect(captured?.value(forHTTPHeaderField: "Authorization") == "Bearer my-token")
    }

    @Test func send_doesNotSetAuthorizationHeader_whenNoToken() async throws {
        var captured: URLRequest?
        MockURLProtocol.requestHandler = { request in
            captured = request; return (makeResponse(), makeItemJSON())
        }
        let _: Item = try await makeSUT().send(path: "/items", method: .get, headers: [:])

        #expect(captured?.value(forHTTPHeaderField: "Authorization") == nil)
    }

    @Test func send_setsCustomHeaders() async throws {
        var captured: URLRequest?
        MockURLProtocol.requestHandler = { request in
            captured = request; return (makeResponse(), makeItemJSON())
        }
        let _: Item = try await makeSUT()
            .send(path: "/items", method: .get, headers: ["X-Custom-Header": "hello"])

        #expect(captured?.value(forHTTPHeaderField: "X-Custom-Header") == "hello")
    }

    // MARK: send - HTTPメソッド / ボディ

    @Test func send_usesGETMethod() async throws {
        var captured: URLRequest?
        MockURLProtocol.requestHandler = { request in
            captured = request; return (makeResponse(), makeItemJSON())
        }
        let _: Item = try await makeSUT().send(path: "/items", method: .get, headers: [:])

        #expect(captured?.httpMethod == "GET")
    }

    @Test func send_usesPOSTMethod() async throws {
        var captured: URLRequest?
        MockURLProtocol.requestHandler = { request in
            captured = request; return (makeResponse(), makeItemJSON())
        }
        let _: Item = try await makeSUT()
            .send(path: "/items", method: .post, body: RequestPayload(value: "x"), headers: [:])

        #expect(captured?.httpMethod == "POST")
    }

    @Test func send_setsContentTypeJSON_whenBodyProvided() async throws {
        var captured: URLRequest?
        MockURLProtocol.requestHandler = { request in
            captured = request; return (makeResponse(), makeItemJSON())
        }
        let _: Item = try await makeSUT()
            .send(path: "/items", method: .post, body: RequestPayload(value: "x"), headers: [:])

        #expect(captured?.value(forHTTPHeaderField: "Content-Type") == "application/json")
    }

    @Test func send_doesNotSetContentType_whenNoBody() async throws {
        var captured: URLRequest?
        MockURLProtocol.requestHandler = { request in
            captured = request; return (makeResponse(), makeItemJSON())
        }
        let _: Item = try await makeSUT().send(path: "/items", method: .get, headers: [:])

        #expect(captured?.value(forHTTPHeaderField: "Content-Type") == nil)
    }

    // MARK: send - レスポンス

    @Test func send_success_decodesResponse() async throws {
        MockURLProtocol.requestHandler = { _ in (makeResponse(), makeItemJSON(id: 42, name: "apple")) }
        let item: Item = try await makeSUT().send(path: "/items/42", method: .get, headers: [:])

        #expect(item == Item(id: 42, name: "apple"))
    }

    @Test func send_returnsEmptyResponse() async throws {
        MockURLProtocol.requestHandler = { _ in (makeResponse(), Data()) }
        let _: EmptyResponse = try await makeSUT()
            .send(path: "/items/1", method: .post, body: Optional<String>.none, headers: [:])
    }

    @Test func send_throwsStatusCodeError_on404() async throws {
        MockURLProtocol.requestHandler = { _ in (makeResponse(statusCode: 404), Data()) }

        do {
            let _: Item = try await makeSUT().send(path: "/items/999", method: .get, headers: [:])
            Issue.record("エラーがスローされるべきでした")
        } catch let error as APIError {
            guard case .statusCode(let code, _) = error else {
                Issue.record("想定外のAPIErrorケース: \(error)"); return
            }
            #expect(code == 404)
        }
    }

    @Test func send_throwsStatusCodeError_on500() async throws {
        MockURLProtocol.requestHandler = { _ in (makeResponse(statusCode: 500), Data()) }

        do {
            let _: Item = try await makeSUT().send(path: "/items", method: .get, headers: [:])
            Issue.record("エラーがスローされるべきでした")
        } catch let error as APIError {
            guard case .statusCode(let code, _) = error else {
                Issue.record("想定外のAPIErrorケース: \(error)"); return
            }
            #expect(code == 500)
        }
    }

    @Test func send_throwsDecodingFailed_whenResponseMalformed() async throws {
        MockURLProtocol.requestHandler = { _ in (makeResponse(), Data("invalid json".utf8)) }

        do {
            let _: Item = try await makeSUT().send(path: "/items", method: .get, headers: [:])
            Issue.record("エラーがスローされるべきでした")
        } catch let error as APIError {
            guard case .decodingFailed = error else {
                Issue.record("想定外のAPIErrorケース: \(error)"); return
            }
        }
    }

    @Test func send_throwsNetworkError_onURLError() async throws {
        MockURLProtocol.requestHandler = { _ in throw URLError(.notConnectedToInternet) }

        do {
            let _: Item = try await makeSUT().send(path: "/items", method: .get, headers: [:])
            Issue.record("エラーがスローされるべきでした")
        } catch let error as APIError {
            guard case .networkError = error else {
                Issue.record("想定外のAPIErrorケース: \(error)"); return
            }
        }
    }

    // MARK: sendForm - リクエスト

    @Test func sendForm_setsContentTypeFormEncoded() async throws {
        var captured: URLRequest?
        MockURLProtocol.requestHandler = { request in
            captured = request; return (makeResponse(), makeItemJSON())
        }
        let _: Item = try await makeSUT()
            .sendForm(path: "/token", method: .post, formParams: ["key": "value"], headers: [:])

        #expect(captured?.value(forHTTPHeaderField: "Content-Type") == "application/x-www-form-urlencoded")
    }

    @Test func sendForm_doesNotSetAuthorizationHeader_whenTokenRefresherExists() async throws {
        var captured: URLRequest?
        MockURLProtocol.requestHandler = { request in
            captured = request; return (makeResponse(), makeItemJSON())
        }
        let refresher = MockTokenRefresher()
        let sut = makeSUT()
        sut.tokenRefresher = refresher
        let _: Item = try await sut.sendForm(path: "/token", method: .post, formParams: ["key": "value"], headers: [:])

        #expect(captured?.value(forHTTPHeaderField: "Authorization") == nil)
        #expect(!refresher.refreshCalled)
    }

    @Test func sendForm_encodesParamsInBody() async throws {
        var captured: URLRequest?
        MockURLProtocol.requestHandler = { request in
            captured = request; return (makeResponse(), makeItemJSON())
        }
        let _: Item = try await makeSUT().sendForm(
            path: "/token",
            method: .post,
            formParams: ["code": "abc123", "grant_type": "authorization_code"],
            headers: [:]
        )

        let body = captured.flatMap(\.httpBody).flatMap { String(data: $0, encoding: .utf8) } ?? ""
        #expect(body.contains("code=abc123"))
        #expect(body.contains("grant_type=authorization_code"))
    }

    @Test func sendForm_sortsParamsAlphabetically() async throws {
        var captured: URLRequest?
        MockURLProtocol.requestHandler = { request in
            captured = request; return (makeResponse(), makeItemJSON())
        }
        let _: Item = try await makeSUT().sendForm(
            path: "/token",
            method: .post,
            formParams: ["z_key": "last", "a_key": "first"],
            headers: [:]
        )

        let body = captured.flatMap(\.httpBody).flatMap { String(data: $0, encoding: .utf8) } ?? ""
        #expect(body == "a_key=first&z_key=last")
    }

    @Test func sendForm_percentEncodesSpecialChars() async throws {
        var captured: URLRequest?
        MockURLProtocol.requestHandler = { request in
            captured = request; return (makeResponse(), makeItemJSON())
        }
        let _: Item = try await makeSUT().sendForm(
            path: "/token",
            method: .post,
            formParams: ["message": "hello world"],
            headers: [:]
        )

        let body = captured.flatMap(\.httpBody).flatMap { String(data: $0, encoding: .utf8) } ?? ""
        #expect(body == "message=hello%20world")
    }

    // MARK: sendForm - レスポンス

    @Test func sendForm_success_decodesResponse() async throws {
        MockURLProtocol.requestHandler = { _ in (makeResponse(), makeItemJSON(id: 99, name: "form")) }
        let item: Item = try await makeSUT()
            .sendForm(path: "/token", method: .post, formParams: ["key": "value"], headers: [:])

        #expect(item == Item(id: 99, name: "form"))
    }

    @Test func sendForm_throwsStatusCodeError_on401() async throws {
        MockURLProtocol.requestHandler = { _ in (makeResponse(statusCode: 401), Data()) }

        do {
            let _: Item = try await makeSUT()
                .sendForm(path: "/token", method: .post, formParams: [:], headers: [:])
            Issue.record("エラーがスローされるべきでした")
        } catch let error as APIError {
            guard case .statusCode(let code, _) = error else {
                Issue.record("想定外のAPIErrorケース: \(error)"); return
            }
            #expect(code == 401)
        }
    }

    @Test func sendForm_throwsNetworkError_onURLError() async throws {
        MockURLProtocol.requestHandler = { _ in throw URLError(.notConnectedToInternet) }

        do {
            let _: Item = try await makeSUT()
                .sendForm(path: "/token", method: .post, formParams: [:], headers: [:])
            Issue.record("エラーがスローされるべきでした")
        } catch let error as APIError {
            guard case .networkError = error else {
                Issue.record("想定外のAPIErrorケース: \(error)"); return
            }
        }
    }

    // MARK: send - 401 自動リフレッシュ

    @Test func send_on401_withTokenRefresher_retriesOnce() async throws {
        let refresher = MockTokenRefresher()
        refresher.onRefresh = { refreshCallCount in
            if refreshCallCount == 2 {
                MockURLProtocol.requestHandler = { _ in (makeResponse(), makeItemJSON(id: 1, name: "retried")) }
            }
        }
        MockURLProtocol.requestHandler = { _ in
            return (makeResponse(statusCode: 401), Data())
        }

        let sut = makeSUT()
        sut.tokenRefresher = refresher
        let item: Item = try await sut.send(path: "/items", method: .get, headers: [:])

        #expect(refresher.refreshCalled)
        #expect(refresher.refreshCallCount == 2)
        #expect(item.name == "retried")
    }

    @Test func send_withTokenRefresher_throwsSessionExpired_whenRefreshFails() async throws {
        MockURLProtocol.requestHandler = { _ in (makeResponse(statusCode: 401), Data()) }
        let refresher = MockTokenRefresher()
        refresher.refreshError = APIError.sessionExpired

        let sut = makeSUT()
        sut.tokenRefresher = refresher

        do {
            let _: Item = try await sut.send(path: "/items", method: .get, headers: [:])
            Issue.record("エラーがスローされるべきでした")
        } catch let error as APIError {
            guard case .sessionExpired = error else {
                Issue.record("想定外のAPIErrorケース: \(error)"); return
            }
        }
    }

    @Test func send_on401_withoutTokenRefresher_throwsStatusCodeError() async throws {
        MockURLProtocol.requestHandler = { _ in (makeResponse(statusCode: 401), Data()) }

        do {
            let _: Item = try await makeSUT().send(path: "/items", method: .get, headers: [:])
            Issue.record("エラーがスローされるべきでした")
        } catch let error as APIError {
            guard case .statusCode(let code, _) = error else {
                Issue.record("想定外のAPIErrorケース: \(error)"); return
            }
            #expect(code == 401)
        }
    }

    @Test func send_on401_doesNotRetryMoreThanOnce() async throws {
        var callCount = 0
        MockURLProtocol.requestHandler = { _ in
            callCount += 1
            return (makeResponse(statusCode: 401), Data())
        }
        let refresher = MockTokenRefresher()

        let sut = makeSUT()
        sut.tokenRefresher = refresher

        do {
            let _: Item = try await sut.send(path: "/items", method: .get, headers: [:])
            Issue.record("エラーがスローされるべきでした")
        } catch {
            #expect(callCount == 2)
        }
    }
}
