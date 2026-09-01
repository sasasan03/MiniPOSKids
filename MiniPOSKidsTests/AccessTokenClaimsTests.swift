//
//  AccessTokenClaimsTests.swift
//  MiniPOSKidsTests
//

import Testing
import Foundation
@testable import MiniPOSKids

// MARK: - Helpers

/// テスト用のダミー JWT を組み立てる。
///
/// 署名は検証しないため、`signature` 部分は固定のダミー文字列で足りる。
/// - Parameters:
///   - sub: `sub` クレームに入れる文字列。nil の場合はクレーム自体を含めない。
///   - aud: `aud` クレームに入れるクライアントID。
/// - Returns: `header.payload.signature` 形式の文字列。
func makeJWT(sub: String? = "sb_test123:user456", aud: String = "test-client-id") -> String {
    var payload: [String: Any] = ["aud": aud, "scopes": ["pos.stores:read"]]
    if let sub { payload["sub"] = sub }
    let data = try! JSONSerialization.data(withJSONObject: payload)
    let encoded = data.base64EncodedString()
        .replacingOccurrences(of: "+", with: "-")
        .replacingOccurrences(of: "/", with: "_")
        .replacingOccurrences(of: "=", with: "")
    return "eyJhbGciOiJIUzI1NiJ9.\(encoded).dummy-signature"
}

// MARK: - Tests

@Suite("AccessTokenClaims")
struct AccessTokenClaimsTests {

    @Test("sub の `:` より前を契約IDとして取り出す")
    func extractsContractIdFromSub() throws {
        let claims = try AccessTokenClaims(accessToken: makeJWT(sub: "sb_skp999j6:72l6g6yiqr0g"))

        #expect(claims.contractId == "sb_skp999j6")
    }

    @Test("aud をクライアントIDとして取り出す")
    func extractsClientIdFromAud() throws {
        let claims = try AccessTokenClaims(accessToken: makeJWT(aud: "6ecaebaa6eb89e8ff788631e51bea46e"))

        #expect(claims.clientId == "6ecaebaa6eb89e8ff788631e51bea46e")
    }

    @Test("ユーザーID側に `:` が含まれても契約IDを取り違えない")
    func splitsOnlyAtFirstColon() throws {
        let claims = try AccessTokenClaims(accessToken: makeJWT(sub: "sb_abc:user:extra"))

        #expect(claims.contractId == "sb_abc")
    }

    @Test("JWT 形式でない文字列は missingContractId")
    func throwsForNonJWT() {
        #expect(throws: APIError.self) {
            _ = try AccessTokenClaims(accessToken: "not-a-jwt")
        }
    }

    @Test("sub が無いトークンは missingContractId")
    func throwsWhenSubIsMissing() {
        #expect(throws: APIError.self) {
            _ = try AccessTokenClaims(accessToken: makeJWT(sub: nil))
        }
    }

    @Test("sub が `契約ID:ユーザーID` 形式でない場合は missingContractId")
    func throwsWhenSubHasNoColon() {
        #expect(throws: APIError.self) {
            _ = try AccessTokenClaims(accessToken: makeJWT(sub: "sb_abc"))
        }
    }

    @Test("契約IDが空のトークンは missingContractId")
    func throwsWhenContractIdIsEmpty() {
        #expect(throws: APIError.self) {
            _ = try AccessTokenClaims(accessToken: makeJWT(sub: ":user456"))
        }
    }
}
