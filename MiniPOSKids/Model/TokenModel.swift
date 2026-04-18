//
//  TokenModel.swift
//  MiniPOSKids
//
//  Created by sako0602 on 2026/04/18.
//

import Foundation

struct TokenResponse: Decodable {
    let accessToken: String
    let tokenType: String
    let expiresIn: Int
    let refreshToken: String?

    enum CodingKeys: String, CodingKey {
        case accessToken  = "access_token"
        case tokenType    = "token_type"
        case expiresIn    = "expires_in"
        case refreshToken = "refresh_token"
    }
}
