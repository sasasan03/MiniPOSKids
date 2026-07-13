//
//  Item.swift
//  MiniPOSKids
//
//  Created by sako0602 on 2026/04/21.
//

import Foundation

struct Product: Equatable, Hashable{
    let productID: String
    let name: String
    let price: Int
}

/// バーコードで読み取った商品
struct CartProduct: Equatable, Hashable {
    var totalPrice: Int { product.price * quantity }
    let product: Product
    var quantity: Int
}
