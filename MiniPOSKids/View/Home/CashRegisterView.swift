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
        let pieces: Int
    }
    
    @State private var items = [
        Item(name: "りんご", price: 100, pieces: 5),
        Item(name: "なし", price: 220, pieces: 3)
    ]
    
    
    var body: some View {
        ZStack {
            VStack {
                List {
                    ForEach(items){ item in
                        receiptRow(itemName: item.name, pieces: item.pieces, price: item.price)
                    }
                }
                .listStyle(.grouped)
                Spacer()
                HStack {
                    let total = items
                        .map { item in item.price * item.pieces }
                        .reduce(0, +)
                    totalText(total)
                    Spacer()
                    barcodeButton
                        .padding(.trailing, 5)
                }
                .padding()
                Button(action: {
                    router.navigationHomeRoutePush(.scanQRCode)
                }, label: {
                    Text("支払いを行う")
                        .font(.system(size: 25))
                        .frame(width: 300,height: 50)
                })
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(.gray, lineWidth: 1)
                )
            }
        }
    }
    
    private func receiptRow(itemName: String ,pieces: Int ,price: Int) -> some View {
        HStack {
            Text(itemName)
                .frame(width: 150, alignment: .leading)
            Spacer()
            Text("\(pieces)個 × \(price)円・・\(pieces * price)円")
        }
        .frame(maxWidth: .infinity)
    }
    
    private func totalText(_ totalPrice: Int) -> some View {
        HStack {
            Text("合計")
                .font(.system(size: 20, weight: .bold))
                .padding(.horizontal, 5)
            Text("\(totalPrice.formatted(.number))円")
                .font(.system(size: 20, weight: .bold))
        }
    }
    
    private var barcodeButton: some View {
        Button {
            router.navigationHomeRoutePush(.scanProductBarcode)
        } label: {
            ZStack{
                Circle()
                    .frame(width: 50,height: 50)
                    .overlay(
                        RoundedRectangle(cornerRadius: 45)
                            .stroke(Color.blue, lineWidth: 1)
                    )
                Image(systemName: "barcode.viewfinder")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .foregroundStyle(Color.white)
            }
        }

    }
    
}

#Preview {
    CashRegisterView()
        .environment(HomeRouter())
}
