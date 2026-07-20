//
//  PurchaseSuccessView.swift
//  MiniPOSKids
//
//  Created by sako0602 on 2026/04/13.
//

import SwiftUI

struct PurchaseResultView: View {
    
    @Environment(HomeRouter.self) var router
    @State private var viewModel: PurchaseViewModel
    let isSuccess: Bool
    
    init(viewModel: PurchaseViewModel, isSuccess: Bool) {
        _viewModel = State(initialValue: viewModel)
        self.isSuccess = isSuccess
    }
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            Text(isSuccess ? "買い物成功" : "買い物失敗")
            Text("QRコード残高：\(viewModel.qrCodeValue)円")
            Text("支払い合計金額は \(viewModel.totalAmount)円です")
            if isSuccess {
                Text("残り残高：\(viewModel.calculateChange())円")
            } else {
                Text("不足している金額： \(viewModel.calculateChange())円")
            }
            Button("レジ画面へ戻る") {
                router.backToCashRegister()
            }
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
        ),
        isSuccess: true
    )
    .environment(HomeRouter())
}
