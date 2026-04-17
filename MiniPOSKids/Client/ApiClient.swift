//
//  ApiClient.swift
//  MiniPOSKids
//
//  Created by sako0602 on 2026/04/15.
//

import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
//    case put = "PUT"
//    case patch = "PATCH"
//    case delete = "DELETE"
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
    private let tokenStore: TokenStoreProtocol
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    /// Unicode characterの値に制限をかける（"-._~"のみ使用可能）
    private static let formURLEncodedAllowed: CharacterSet = {
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._~")
        return allowed
    }()

    init(
        baseURL: String,
        session: URLSession = .shared,
        tokenStore: TokenStoreProtocol,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.baseURL = baseURL
        self.session = session
        self.tokenStore = tokenStore
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
        let normalizedBase = baseURL.hasSuffix("/") ? String(baseURL.dropLast()) : baseURL
        let normalizedPath = path.hasPrefix("/") ? path : "/\(path)"
        guard let url = URL(string: normalizedBase + normalizedPath) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let token = tokenStore.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        if let body = body {
            do {
                request.httpBody = try encoder.encode(body)
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            } catch {
                throw APIError.encodingFailed
            }
        }

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            guard 200...299 ~= httpResponse.statusCode else {
                throw APIError.statusCode(httpResponse.statusCode, data)
            }

            // 削除やログアウトなど、レスポンスボディを返さないAPI向けの処理
            if ResponseBody.self == EmptyResponse.self {
                return EmptyResponse() as! ResponseBody
            }

            do {
                return try decoder.decode(ResponseBody.self, from: data)
            } catch {
                throw APIError.decodingFailed(error)
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }

    /// フォームエンコードされたPOSTリクエスト送信（OAuth トークン交換など）
    func sendForm<ResponseBody: Decodable>(
        path: String,
        method: HTTPMethod,
        formParams: [String: String],
        headers: [String: String] = [:]
    ) async throws -> ResponseBody {
        let normalizedBase = baseURL.hasSuffix("/") ? String(baseURL.dropLast()) : baseURL
        let normalizedPath = path.hasPrefix("/") ? path : "/\(path)"
        guard let url = URL(string: normalizedBase + normalizedPath) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

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
                throw APIError.invalidResponse
            }
            guard 200...299 ~= httpResponse.statusCode else {
                throw APIError.statusCode(httpResponse.statusCode, data)
            }
            
            // 削除やログアウトなど、レスポンスボディを返さないAPI向けの処理
            if ResponseBody.self == EmptyResponse.self {
                return EmptyResponse() as! ResponseBody
            }

            do {
                return try decoder.decode(ResponseBody.self, from: data)
            } catch {
                throw APIError.decodingFailed(error)
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }
}

/// 削除やログアウトなど、レスポンスボディを返さないAPI向けの型
struct EmptyResponse: Decodable {}
