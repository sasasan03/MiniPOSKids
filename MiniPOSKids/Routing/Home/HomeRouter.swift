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
    
//    @discardableResult
//    func navigationBack() -> AuthRoute? {
//        path.popLast()
//    }
    
    func navigationPush(_ route: HomeRoute) {
        path.append(route)
    }
}
