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
    
    func navigationBack() {
        path.removeLast()
    }
    
    func navigationHomeRoutePush(_ route: HomeRoute) {
        path.append(route)
    }
    
}
