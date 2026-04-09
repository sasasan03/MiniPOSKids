//
//  AuthRouter.swift
//  MiniPOSKids
//
//  Created by sako0602 on 2026/04/09.
//

import Foundation
import Observation

@Observable
final class AuthRouter {
    var path: [AuthRoute] = []
    
    @discardableResult
    func navigationBack() -> AuthRoute? {
        path.popLast()
    }
}
