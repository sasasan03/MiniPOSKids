//
//  PurchaseSuccessView.swift
//  MiniPOSKids
//
//  Created by sako0602 on 2026/04/13.
//

import SwiftUI

struct PurchaseSuccessView: View {
    
    @Environment(HomeRouter.self) var router
    
    private struct Item: Identifiable {
        let id = UUID()
        let name: String
        let price: Int
    }
    
    @State private var items = [
        Item(name: "りんご", price: 1000),
        Item(name: "なし", price: 2200)
    ]
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            Text("残り残高は 3000円です")
            Text("購入商品合計見学は 2000円です")
            Spacer()
            Button("レジ画面へ戻る") {
                router.backToCashRegister()
            }
            Spacer()
            List {
                ForEach(items){ item in
                    HStack {
                        Text(item.name)
                        Text("\(item.price)円")
                    }
                }
            }
            .frame(height: 500)
            .padding()
        }
    }
}

#Preview {
    PurchaseSuccessView()
        .environment(HomeRouter())
}
