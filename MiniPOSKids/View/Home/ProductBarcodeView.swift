//
//  ProductBarcodeView.swift
//  MiniPOSKids
//
//  Created by sako0602 on 2026/04/13.
//

import SwiftUI
import UIKit
import CoreImage.CIFilterBuiltins

struct ProductBarcodeView: View {
    
    @Environment(HomeRouter.self) private var router
    @Environment(AppState.self) private var appState
    @State private var viewModel: StoreItemViewModel
    let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]
    
    init(viewModel: StoreItemViewModel) {
        _viewModel = State(initialValue: viewModel)
    }
    // バーコード関連
    private let context = CIContext()
    // PDF関連
    private let a4PageSize = CGSize(width: 595.2, height: 841.8)
    private let pdfColumnCount = 3
    private let pdfGridSpacing: CGFloat = 10
    private let pdfPagePadding: CGFloat = 8
    private let pdfItemHeight: CGFloat = 95
    
    var body: some View {
        ScrollView {
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
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                ShareLink(item: renderPDF()) {
                    Text("PDF")
                }
                .disabled(viewModel.items.isEmpty)
            }
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
    
    // １列当たりの横幅
    private var pdfColumnWidth: CGFloat {
        let totalSpacing = pdfGridSpacing * CGFloat(pdfColumnCount - 1)
        let availableWidth = a4PageSize.width - (pdfPagePadding * 2) - totalSpacing
        return availableWidth / CGFloat(pdfColumnCount)
    }
    
    // １ページのPDFに何行のRowが入るか計算する
    private var pdfRowsPerPage: Int {
        let availableHeight = a4PageSize.height - (pdfPagePadding * 2)
        let rowHeightWithSpacing = pdfItemHeight + pdfGridSpacing
        return max(1, Int((availableHeight + pdfGridSpacing) / rowHeightWithSpacing))
    }
    
    // １ページに表示できるアイテムの総数
    private var pdfItemsPerPage: Int {
        pdfRowsPerPage * pdfColumnCount
    }
    
    // 同じ幅の列を、指定した数だけ並べた配列
    private var pdfColumns: [GridItem] {
        Array(
            repeating: GridItem(.fixed(pdfColumnWidth), spacing: pdfGridSpacing),
            count: pdfColumnCount
        )
    }
    
    // ページ単位のデータに変換
    private var pdfPageItemGroups: [[StoreItemResponse]] {
        stride(from: 0, to: viewModel.items.count, by: pdfItemsPerPage).map { startIndex in
            let endIndex = min(startIndex + pdfItemsPerPage, viewModel.items.count)
            return Array(viewModel.items[startIndex..<endIndex])
        }
    }
    
    // 実施にPDF化される画面を構築
    private func pdfPageContent(items: [StoreItemResponse]) -> some View {
        VStack(spacing: 0) {
            LazyVGrid(columns: pdfColumns, spacing: pdfGridSpacing) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    BarcodeRow(name: item.productName, price: item.price) {
                        barcode(id: item.productId)
                    }
                    .frame(width: pdfColumnWidth, height: pdfItemHeight)
                }
            }
            .padding(pdfPagePadding)
            Spacer(minLength: 0)
        }
        .frame(width: a4PageSize.width, height: a4PageSize.height, alignment: .top)
        .background(Color.white)
    }
    
    private func renderPDF() -> URL {
        let url = URL.documentsDirectory.appending(path: "barcodes.pdf")
        guard !viewModel.items.isEmpty else { return url }
        
        // ページの区切りをA4サイズにする
        var mediaBox = CGRect(origin: .zero, size: a4PageSize)
        guard let pdf = CGContext(url as CFURL, mediaBox: &mediaBox, nil) else {
            return url
        }
        
        // PDFのサイズを指定
        let pageInfo = [
            kCGPDFContextMediaBox as String: mediaBox
        ] as CFDictionary
        
        
        for items in pdfPageItemGroups {
            // A4 1ページに収まる分の商品だけをSwiftUI Viewとして組み立てる。
            let renderer = ImageRenderer(content: pdfPageContent(items: items))
            // PDFの用紙サイズとSwiftUI Viewの描画サイズをA4にそろえる。
            renderer.proposedSize = .init(a4PageSize)
            // PDF上では1ptをそのまま1ptとして描画する。
            renderer.scale = 1
            
            // >>>>>>>>>>>ここから1ページ分のPDF描画を開始する。
            pdf.beginPDFPage(pageInfo)
            // 背景色など、このページ用の描画状態を一時的に保存する。
            pdf.saveGState()
            // 透明部分が黒く見えないよう、ページ全体を白で塗る。
            pdf.setFillColor(UIColor.white.cgColor)
            pdf.fill(mediaBox)
            
            // SwiftUIで作ったバーコード一覧をPDFの描画コンテキストへ描き込む。
            renderer.render { _, renderInContext in
                renderInContext(pdf)
            }
            
            // 描画状態を戻してから、このページを閉じる。
            pdf.restoreGState()
            pdf.endPDFPage()
            // <<<<<<<<<<<< PDF描画終了
        }
        
        pdf.closePDF()
        return url
    }
}

#Preview {
    NavigationStack {
        ProductBarcodeView(
            viewModel: StoreItemViewModel(
                storeItemService: PreviewStoreItemService(), storeId: "1"
            )
        )
        .navigationTitle("商品バーコード")
    }
    .environment(HomeRouter())
    .environment(AppState(tokenStore: InMemoryTokenStore()))
}

private struct PreviewStoreItemService: StoreItemServiceProtocol {
    
    func fetchStoreItem(storeId: String) async throws -> [StoreItemResponse] {
        [
            StoreItemResponse(productId: "1", productName: "コーラ", price: "190"),
            StoreItemResponse(productId: "2", productName: "ドーナッツ", price: "250"),
            StoreItemResponse(productId: "3", productName: "アメ", price: "220"),
            StoreItemResponse(productId: "4", productName: "コーラ", price: "190"),
            StoreItemResponse(productId: "5", productName: "ドーナッツ", price: "250"),
            StoreItemResponse(productId: "6", productName: "アメ", price: "220"),
            StoreItemResponse(productId: "7", productName: "コーラ", price: "190"),
            StoreItemResponse(productId: "8", productName: "ドーナッツ", price: "250"),
            StoreItemResponse(productId: "9", productName: "アメ", price: "220"),
            StoreItemResponse(productId: "10", productName: "アメ", price: "220"),
            StoreItemResponse(productId: "11", productName: "コーラ", price: "190"),
            StoreItemResponse(productId: "12", productName: "ドーナッツ", price: "250"),
            StoreItemResponse(productId: "13", productName: "アメ", price: "220"),
            StoreItemResponse(productId: "14", productName: "アメ", price: "220"),
        ]
    }
}
