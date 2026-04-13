//
//  CashRegisterView.swift
//  MiniPOSKids
//
//  Created by sako0602 on 2026/04/13.
//

import SwiftUI

struct CashRegisterView: View {
    
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
        VStack {
            List {
                ForEach(items){ item in
                    HStack {
                        Text(item.name)
                        Text("\(item.price)円")
                    }
                }
            }
            Spacer()
            HStack {
                HStack {
                    Text("合計")
                    Text("2200円")
                }
                Spacer()
                Button("商品追加") {
                    router.navigationHomeRoutePush(.scanProductBarcode)
                }
            }
            .padding()
            Button(action: {
                router.navigationHomeRoutePush(.scanQRCode)
            }, label: {
                Text("支払いを行う")
                    .frame(width: 300,height: 50)
                
            })
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(.gray, lineWidth: 1)
            )
        }
    }
}

#Preview {
    CashRegisterView()
        .environment(HomeRouter())
}
