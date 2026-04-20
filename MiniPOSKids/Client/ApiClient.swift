//
//  ApiClient.swift
//  MiniPOSKids
//
//  Created by sako0602 on 2026/04/15.
//

import Foundation
import OSLog

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
}

protocol APIClientProtocol {
    func send<RequestBody: Encodable, ResponseBody: Decodable>(
        path: String,
        method: HTTPMethod,
        body: RequestBody?,
        headers: [String: String]
    ) async throws -> ResponseBody

    func send<ResponseBody: Decodable>(
        path: String,
        method: HTTPMethod,
        headers: [String: String]
    ) async throws -> ResponseBody

    /// フォーム URL エンコード形式のリクエストを送信し、レスポンスを指定した型へデコードする。
    func sendForm<ResponseBody: Decodable>(
        path: String,
        method: HTTPMethod,
        formParams: [String: String],
        headers: [String: String]
    ) async throws -> ResponseBody
}

final class APIClient: APIClientProtocol {
    private let baseURL: String
    private let session: URLSession
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let logger = Logger(subsystem: "com.miniposkids", category: "APIClient")
    /// API リクエスト送信時にアクセストークンを取得する責務を持つオブジェクト
    weak var tokenRefresher: (any TokenRefresherProtocol)?

    /// Unicode characterの値に制限をかける（"-._~"のみ使用可能）
    private static let formURLEncodedAllowed: CharacterSet = {
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._~")
        return allowed
    }()

    init(
        baseURL: String,
        session: URLSession = .shared,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.baseURL = baseURL
        self.session = session
        self.encoder = encoder
        self.decoder = decoder
    }

    /// GET専用のリクエスト送信
    func send<ResponseBody: Decodable>(
        path: String,
        method: HTTPMethod = .get,
        headers: [String: String] = [:]
    ) async throws -> ResponseBody {
        try await send(
            path: path,
            method: method,
            body: Optional<String>.none,
            headers: headers
        )
    }

    /// GET以外でリクエスト送信
    func send<RequestBody: Encodable, ResponseBody: Decodable>(
        path: String,
        method: HTTPMethod,
        body: RequestBody?,
        headers: [String: String] = [:]
    ) async throws -> ResponseBody {
        guard let url = buildURL(path: path) else {
            logger.error("send: 不正なURL (baseURL=\(self.baseURL, privacy: .public) path=\(path, privacy: .public))")
            throw APIError.invalidURL
        }

        logger.debug("send: → \(method.rawValue, privacy: .public) \(path, privacy: .public)")

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let body = body {
            do {
                request.httpBody = try encoder.encode(body)
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            } catch {
                logger.error("send: エンコード失敗 \(method.rawValue, privacy: .public) \(path, privacy: .public)")
                throw APIError.encodingFailed
            }
        }

        do {
            try await setAuthorizationHeaderIfNeeded(on: &request)
            headers.forEach { key, value in
                request.setValue(value, forHTTPHeaderField: key)
            }
            return try await performRequest(request, method: method, path: path)
        } catch let error as APIError {
            throw error
        } catch {
            logger.error("send: ネットワークエラー \(method.rawValue, privacy: .public) \(path, privacy: .public) error=\(error)")
            throw APIError.networkError(error)
        }
    }

    /// フォーム URL エンコード形式のリクエストを送信し、レスポンスを指定した型へデコードする。
    ///
    /// OAuth のトークン取得など、JSON ではなく `application/x-www-form-urlencoded` の
    /// ボディを要求する API 向けの送信メソッド。`send` と異なり、このメソッドでは
    /// `tokenRefresher` による Authorization ヘッダーの付与や 401 時の自動リトライは行わない。
    /// レスポンスボディが不要な API では `ResponseBody` に `EmptyResponse` を指定する。
    /// フォーム URL エンコード形式では、`key1=value1&key2=value2` のようにキーと値を `=` で結び、
    /// 複数の項目を `&` で連結する。
    ///
    /// - Parameters:
    ///   - path: `baseURL` からの相対パス。
    ///   - method: リクエストに使用する HTTP メソッド。
    ///   - formParams: フォームボディに含めるキーと値。
    ///   - headers: 追加で設定する HTTP ヘッダー。
    /// - Returns: レスポンスボディを `ResponseBody` としてデコードした値。
    /// - Throws: URL 生成、通信、ステータスコード、レスポンス形式、デコードに失敗した場合は `APIError` を投げる。
    func sendForm<ResponseBody: Decodable>(
        path: String,
        method: HTTPMethod,
        formParams: [String: String],
        headers: [String: String] = [:]
    ) async throws -> ResponseBody {
        guard let url = buildURL(path: path) else {
            logger.error("sendForm: 不正なURL (path=\(path, privacy: .public))")
            throw APIError.invalidURL
        }

        logger.debug("sendForm: → \(method.rawValue, privacy: .public) \(path, privacy: .public)")

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        // application/x-www-form-urlencoded の仕様に合わせてキーと値をエンコードし、
        // 生成されるボディの順序がぶれないようにソートする。
        request.httpBody = formParams
            .map { key, value in
                let encodedKey = key.addingPercentEncoding(
                    withAllowedCharacters: Self.formURLEncodedAllowed
                ) ?? key
                let encodedValue = value.addingPercentEncoding(
                    withAllowedCharacters: Self.formURLEncodedAllowed
                ) ?? value
                return "\(encodedKey)=\(encodedValue)"
            }
            .sorted()
            .joined(separator: "&")
            .data(using: .utf8)

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                logger.error("sendForm: 不正なレスポンス \(path, privacy: .public)")
                throw APIError.invalidResponse
            }
            logger.debug("sendForm: ← \(httpResponse.statusCode) \(path, privacy: .public)")
            guard 200...299 ~= httpResponse.statusCode else {
                logger.error("sendForm: エラーステータス \(httpResponse.statusCode) \(path, privacy: .public)")
                throw APIError.statusCode(httpResponse.statusCode, data)
            }

            // レスポンスボディを使わない API ではデコード処理を省略する。
            if ResponseBody.self == EmptyResponse.self {
                return EmptyResponse() as! ResponseBody
            }
            do {
                return try decoder.decode(ResponseBody.self, from: data)
            } catch {
                logger.error("sendForm: デコード失敗 \(path, privacy: .public) error=\(error)")
                throw APIError.decodingFailed(error)
            }
        } catch let error as APIError {
            throw error
        } catch {
            logger.error("sendForm: ネットワークエラー \(path, privacy: .public) error=\(error)")
            throw APIError.networkError(error)
        }
    }

    // MARK: - Private

    private func buildURL(path: String) -> URL? {
        let normalizedBase = baseURL.hasSuffix("/") ? String(baseURL.dropLast()) : baseURL
        let normalizedPath = path.hasPrefix("/") ? path : "/\(path)"
        return URL(string: normalizedBase + normalizedPath)
    }

    private func setAuthorizationHeaderIfNeeded(on request: inout URLRequest) async throws {
        guard let tokenRefresher else { return }
        let accessToken = try await tokenRefresher.refreshAccessToken()
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
    }

    /// リクエストを実行し、401 のときアクセストークンを再取得して1回だけリトライする
    private func performRequest<ResponseBody: Decodable>(
        _ request: URLRequest,
        method: HTTPMethod,
        path: String,
        isRetry: Bool = false
    ) async throws -> ResponseBody {
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            logger.error("performRequest: 不正なレスポンス \(method.rawValue, privacy: .public) \(path, privacy: .public)")
            throw APIError.invalidResponse
        }

        logger.debug("performRequest: ← \(httpResponse.statusCode) \(method.rawValue, privacy: .public) \(path, privacy: .public)\(isRetry ? " (retry)" : "", privacy: .public)")

        if httpResponse.statusCode == 401, !isRetry, let refresher = tokenRefresher {
            logger.info("performRequest: 401 を受信 → アクセストークンをリフレッシュしてリトライ (\(method.rawValue, privacy: .public) \(path, privacy: .public))")
            refresher.invalidateCachedToken()
            let newToken = try await refresher.refreshAccessToken()
            var retryRequest = request
            retryRequest.setValue("Bearer \(newToken)", forHTTPHeaderField: "Authorization")
            return try await performRequest(retryRequest, method: method, path: path, isRetry: true)
        }

        guard 200...299 ~= httpResponse.statusCode else {
            logger.error("performRequest: エラーステータス \(httpResponse.statusCode) \(method.rawValue, privacy: .public) \(path, privacy: .public)")
            throw APIError.statusCode(httpResponse.statusCode, data)
        }

        if ResponseBody.self == EmptyResponse.self {
            return EmptyResponse() as! ResponseBody
        }
        do {
            return try decoder.decode(ResponseBody.self, from: data)
        } catch {
            logger.error("performRequest: デコード失敗 \(method.rawValue, privacy: .public) \(path, privacy: .public) error=\(error)")
            throw APIError.decodingFailed(error)
        }
    }
}

/// 削除やログアウトなど、レスポンスボディを返さないAPI向けの型
struct EmptyResponse: Decodable {}
