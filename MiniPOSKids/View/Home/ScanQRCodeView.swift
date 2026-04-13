//
//  ScanQRCodeView.swift
//  MiniPOSKids
//
//  Created by sako0602 on 2026/04/13.
//

import SwiftUI

struct ScanQRCodeView: View {
    @Environment(HomeRouter.self) var router
    var body: some View {
        ZStack {
            Color.black
            VStack {
                Button {
                    router.navigationHomeRoutePush(.purchaseSuccess)
                } label: {
                    Text("読み取り成功")
                }
                
                Button {
                    router.navigationHomeRoutePush(.purchaseFailure)
                } label: {
                    Text("読み取り失敗")
                }
            }
        }
    }
}

#Preview {
    ScanQRCodeView()
        .environment(HomeRouter())
}
