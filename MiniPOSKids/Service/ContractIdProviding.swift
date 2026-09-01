//
//  ContractIdProviding.swift
//  MiniPOSKids
//

import Foundation

/// プラットフォーム API のパスに埋め込む契約IDを供給する口。
///
/// 契約IDはログイン時に受け取るアクセストークン（JWT）から取り出すため、
/// ビルド時には決まらない。API 呼び出し側はこの口を通して都度取得する。
protocol ContractIdProviding: AnyObject {
    /// 現在ログイン中の契約IDを返す。
    ///
    /// 必要ならアクセストークンを取得・更新し、その副作用で解決した値を返す。
    /// - Returns: 契約ID。
    /// - Throws: セッションが失効している場合は `APIError.sessionExpired`、
    ///   トークンから契約IDを取り出せない場合は `APIError.missingContractId`。
    func currentContractId() async throws -> String
}
