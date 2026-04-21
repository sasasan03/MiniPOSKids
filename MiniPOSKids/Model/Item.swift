//
//  Item.swift
//  MiniPOSKids
//
//  Created by sako0602 on 2026/04/21.
//

import Foundation

struct StoreItemResponse: Decodable {
    let productId: String
    let productName: String
    let price: String
}
