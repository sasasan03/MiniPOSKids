//
//  ScanProductBarcodeView.swift
//  MiniPOSKids
//
//  Created by sako0602 on 2026/04/13.
//

import SwiftUI

struct ScanProductBarcodeView: View {
    @Environment(HomeRouter.self) var router
    @State private var isShowingAlert = false
    var body: some View {
        ZStack {
            Color.black
            VStack {
                Button {
                    router.navigationBack()
                } label: {
                    Text("読み取り成功")
                }
                
                Button {
                    isShowingAlert = true
                } label: {
                    Text("読み取り失敗")
                }
            }
        }
        .alert("読み取りに失敗しました", isPresented: $isShowingAlert) {
            Button("レジ画面へ戻る", role: .cancel) {
                router.navigationBack()
            }
        }
    }
}

#Preview {
    ScanProductBarcodeView()
        .environment(HomeRouter())
}
