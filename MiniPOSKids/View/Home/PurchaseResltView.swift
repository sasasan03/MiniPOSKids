//
//  PurchaseSuccessView.swift
//  MiniPOSKids
//
//  Created by sako0602 on 2026/04/13.
//

import SwiftUI

// TODO: １．購入する商品情報を取得。２．購入後の残金の計算
struct PurchaseResultView: View {
    
    @Environment(HomeRouter.self) var router
    @State private var viewModel: PurchaseViewModel
    
    init(viewModel: PurchaseViewModel) {
        _viewModel = State(initialValue: viewModel)
    }
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            Text("残り残高は \(viewModel.qrCodeValue)円です")
            Text("合計金額は \(viewModel.totalAmount)円です")
            Spacer()
            Button("レジ画面へ戻る") {
                router.backToCashRegister()
            }
            Spacer()
            List {
                ForEach(viewModel.cartProducts, id: \.product.productID){ product in
                    receiptRow(
                        productName: product.product.name,
                        pieces: product.quantity,
                        price: product.product.price
                    )
                }
            }
            .frame(height: 500)
            .padding()
        }
    }
    
    private func receiptRow(productName: String, pieces: Int, price: Int)  -> some View {
        HStack {
            Text(productName)
                .frame(width: 80, alignment: .leading)
            Text("\(pieces)個 × \(price)円・・\(pieces * price)円")
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    PurchaseResultView(
        viewModel: PurchaseViewModel(
            cartProducts: [
                CartProduct(product: Product(productID: "1", name: "りんご", price: 1000), quantity: 2)
            ],
            totalAmount: 2000,
            qrCodeValue: 3000
        )
    )
    .environment(HomeRouter())
}
