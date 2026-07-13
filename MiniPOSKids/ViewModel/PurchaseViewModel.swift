//
//  PurchaseSuccessViewModel.swift
//  MiniPOSKids
//
//  Created by sako0602 on 2026/06/14.
//

import Foundation
import OSLog

@MainActor
@Observable
class PurchaseViewModel {
    
    private let logger = Logger(subsystem: "com.sako.MiniPOSKids", category: "PurchaseSuccessViewModel")
    let cartProducts: [CartProduct]
    let totalAmount: Int
    let qrCodeValue: Int
    
    init(cartProducts: [CartProduct], totalAmount: Int, qrCodeValue: Int) {
        self.cartProducts = cartProducts
        self.totalAmount = totalAmount
        self.qrCodeValue = qrCodeValue
    }
    
    func calculateChange() -> Int {
        if qrCodeValue - totalAmount > 0 {
            return qrCodeValue - totalAmount
        } else {
            return totalAmount - qrCodeValue
        }
    }
}
