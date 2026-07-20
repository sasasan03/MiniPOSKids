//
//  HomeRouter.swift
//  MiniPOSKids
//
//  Created by sako0602 on 2026/04/12.
//

import Foundation
import SwiftUI

@Observable
final class HomeRouter {
    var path = NavigationPath()
    /// スキャンしたバーコード情報をCashRegisterViewへ渡すために使用
    var scannedBarcode: String?
    
    func navigationBack() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
    
    func backToCashRegister() {
        let popCount = min(2, path.count)
        guard popCount > 0 else { return }
        path.removeLast(popCount)
    }
    
    func navigationHomeRoutePush(_ route: HomeRoute) {
        path.append(route)
    }
    
    func saveScannedBarcode(_ barcode: String) {
        scannedBarcode = barcode
    }
    
    func clearScannedBarcode() {
        scannedBarcode = nil
    }
    
}
