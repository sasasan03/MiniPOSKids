//
//  ProductBarcodeView.swift
//  MiniPOSKids
//
//  Created by sako0602 on 2026/04/13.
//

import SwiftUI
import CoreImage.CIFilterBuiltins

struct ProductBarcodeView: View {
    
    @Environment(HomeRouter.self) private var router
    @Environment(AppState.self) private var appState
    @State private var viewModel: StoreItemViewModel
    
    init(viewModel: StoreItemViewModel) {
        _viewModel = State(initialValue: viewModel)
    }
    
    let context = CIContext()
    let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(viewModel.items, id: \.productId) { item in
                BarcodeRow(name: item.productName, price: item.price) {
                    barcode(id: item.productId)
                }
            }
        }
        .padding(8)
        .task {
            await viewModel.getStoreItems()
        }
    }
    
    /// generateBarCodeImageで作成した画像をImageへ変換して表示させる
    @ViewBuilder
    private func barcode(id: String) -> some View {
        if let image = generateBarCodeImage(id: id) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
        } else {
            failureImage
        }
    }
    
    /// バーコード画像を生成しUIImage?を返す
    private func generateBarCodeImage(id: String) -> UIImage? {
        guard let codeData = id.data(using: .ascii) else { return nil }
        let filter = CIFilter.code128BarcodeGenerator()
        filter.message = codeData
        guard let outputImage = filter.outputImage?.transformed(by: CGAffineTransform(scaleX: 4, y: 3)),
              let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
    
    private var failureImage: some View {
        Image(systemName: "xmark.octagon.fill")
            .resizable()
            .scaledToFit()
            .frame(width: 50, height: 50)
            .foregroundStyle(.white, .red)
    }
}

#Preview {
    ProductBarcodeView(
        viewModel: StoreItemViewModel(
            storeItemService: PreviewStoreItemService(), storeId: "1"
        )
    )
    .environment(HomeRouter())
    .environment(AppState(tokenStore: InMemoryTokenStore()))
}

private struct PreviewStoreItemService: StoreItemServiceProtocol {
    
    func fetchStoreItem(storeId: String) async throws -> [StoreItemResponse] {
        [
            StoreItemResponse(productId: "1", productName: "コーラ", price: "190"),
            StoreItemResponse(productId: "2", productName: "ドーナッツ", price: "250"),
            StoreItemResponse(productId: "3", productName: "アメ", price: "220")
        ]
    }
}
