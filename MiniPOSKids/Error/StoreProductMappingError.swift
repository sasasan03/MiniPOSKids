//
//  StoreProductMappingError.swift
//  MiniPOSKids
//
//  Created by sako0602 on 2026/05/17.
//

import Foundation

enum StoreProductMappingError: Error {
    case invalidPrice(productID: String, rawPrice: String)
}
