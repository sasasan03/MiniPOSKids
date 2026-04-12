//
//  SmaregiWebView.swift
//  MiniPOSKids
//
//  Created by sako0602 on 2026/04/09.
//

import SwiftUI
import WebKit

struct SmaregiWebView: View {
    @State private var webPage = WebPage()
    @State private var didLoad = false
    private let url = URL(string: "https://developers.smaregi.jp/signup/")!
    
    var body: some View {
        ZStack {
            WebView(webPage)
                .task {
                    guard !didLoad else { return }
                    didLoad = true
                    webPage.load(URLRequest(url: url))
                }
            
            if webPage.estimatedProgress < 1 {
                ProgressView(value: webPage.estimatedProgress)
                    .progressViewStyle(CircularProgressViewStyle())
            }
        }
    }
    
}

#Preview {
    SmaregiWebView()
}
