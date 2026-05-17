//
//  CashRegisterView.swift
//  MiniPOSKids
//
//  Created by sako0602 on 2026/04/13.
//

import SwiftUI

struct CashRegisterView: View {
    
    @Environment(HomeRouter.self) var router
    @State private var viewModel: CashRegisterViewModel
    let itemId: String? = nil
    
    init(viewModel: CashRegisterViewModel) {
        _viewModel = State(initialValue: viewModel)
    }
    
    var body: some View {
        ZStack {
            VStack {
                List {
                    ForEach($viewModel.cartProducts, id: \.product.productID){ $product in
                        receiptRow(
                            productName: product.product.name,
                            pieces: product.quantity,
                            price: product.product.price
                        )
                    }
                }
                .listStyle(.grouped)
                .onChange(of: router.scannedBarcode) { _, newValue in
                    print("⭐️⭐️CashRegisterView 34 newValue：", newValue)
                    viewModel.addProduct(barcode: newValue)
                }
                Spacer()
                HStack {
                    totalText(viewModel.totalPrice)
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
    
    private func receiptRow(productName: String ,pieces: Int ,price: Int) -> some View {
        HStack {
            Text(productName)
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
    CashRegisterView(
        viewModel: CashRegisterViewModel(
            storeItemService: PreviewStoreItemService()
        )
    )
    .environment(HomeRouter())
}

private struct PreviewStoreItemService: StoreProductServiceProtocol {
    func fetchStoreItem(productID: String) async throws -> Product? {
        nil
    }

    func fetchStoreItems(storeId: String) async throws -> [Product] {
        []
    }
}
