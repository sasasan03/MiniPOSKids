//
//  HomeRoute.swift
//  MiniPOSKids
//
//  Created by sako0602 on 2026/04/12.
//

import Foundation

enum HomeRoute: Hashable {
    case home
    case storeList
    case printProductBarcode(String)
    case selectAvailableBalance
    case showBuyerQRCode(Int)
    case cashRegister
    case scanProductBarcode
    case scanQRCode
    case purchaseSuccess
    case purchaseFailure
}
