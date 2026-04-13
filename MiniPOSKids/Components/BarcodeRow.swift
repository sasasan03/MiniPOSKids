//
//  BarcodeRow.swift
//  MiniPOSKids
//
//  Created by sako0602 on 2026/04/13.
//

import SwiftUI

struct BarcodeRow: View {
    var body: some View {
        VStack {
            HStack {
                Text("りんご")
                Spacer()
                Text("100円")
            }
            Image(systemName: "car")
                .frame(width: 90, height: 70)
                .background(Color.blue)
            
        }
        .padding()
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.gray, lineWidth: 1)
        )
    }
}

#Preview {
    List {
        BarcodeRow()
    }
}
