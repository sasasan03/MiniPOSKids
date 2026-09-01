//
//  AccessTokenClaims.swift
//  MiniPOSKids
//

import Foundation

/// アクセストークン（JWT）のペイロードから、API 呼び出しに必要な情報を取り出した値。
///
/// スマレジのアクセストークンには契約IDの専用クレームが無く、`sub` に
/// `{契約ID}:{ユーザーID}` の形で埋め込まれている（例: `sb_skp999j6:72l6g6yiqr0g`）。
/// プラットフォームAPIのパスは `/{契約ID}/pos/...` なので、ここで取り出した値を使う。
struct AccessTokenClaims {
    /// スマレジの契約ID。`sub` クレームの `:` より前の部分。
    let contractId: String
    /// トークンの発行先クライアントID（`aud` クレーム）。
    let clientId: String?

    private struct Payload: Decodable {
        let sub: String?
        let aud: String?
    }

    /// JWT 形式のアクセストークンをデコードしてクレームを取り出す。
    ///
    /// 署名検証は行わない。トークンは HTTPS で認可サーバーから直接受け取ったものであり、
    /// ここでの用途が API パスに埋める契約IDの取得に限られるため。
    /// - Parameter accessToken: `header.payload.signature` 形式の JWT 文字列。
    /// - Throws: JWT 形式でない、`sub` が無い、`sub` が `契約ID:ユーザーID` 形式でない場合に `APIError.missingContractId`。
    init(accessToken: String) throws {
        let segments = accessToken.split(separator: ".")
        guard segments.count >= 2,
              let data = Self.decodeBase64URL(segments[1]),
              let payload = try? JSONDecoder().decode(Payload.self, from: data) else {
            throw APIError.missingContractId
        }
        // ユーザーID側に `:` が含まれても契約IDを取り違えないよう、最初の `:` だけで分割する。
        guard let sub = payload.sub else { throw APIError.missingContractId }
        let parts = sub.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
        guard parts.count == 2, !parts[0].isEmpty else {
            throw APIError.missingContractId
        }
        contractId = String(parts[0])
        clientId = payload.aud
    }

    /// base64url 文字列を `Data` へデコードする。
    ///
    /// base64url は `+/` の代わりに `-_` を使い末尾のパディングを省くため、
    /// `Data(base64Encoded:)` が受け付ける標準 base64 に戻してから復号する。
    /// - Parameter value: JWT のセグメント文字列。
    /// - Returns: デコード結果。失敗した場合は nil。
    static func decodeBase64URL(_ value: Substring) -> Data? {
        var base64 = String(value)
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let remainder = base64.count % 4
        if remainder > 0 {
            base64 += String(repeating: "=", count: 4 - remainder)
        }
        return Data(base64Encoded: base64)
    }
}
