//
//  String+PathComponent.swift
//  MiniPOSKids
//

import Foundation

extension String {
    /// URL のパス1要素として安全な形にパーセントエンコードした文字列を返す。
    ///
    /// 契約IDや店舗IDをパスへ埋め込む際に使う。`urlPathAllowed` から `/` を除いているため、
    /// 値に `/` が含まれていても階層が増えず、`%2F` へ変換される。
    /// - Returns: エンコード後の文字列。エンコードに失敗した場合は元の文字列。
    var percentEncodedPathComponent: String {
        var allowed = CharacterSet.urlPathAllowed
        allowed.remove(charactersIn: "/")
        return addingPercentEncoding(withAllowedCharacters: allowed) ?? self
    }
}
