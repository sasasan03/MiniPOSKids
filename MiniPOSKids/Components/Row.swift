//
//  ListRow.swift
//  MiniPOSKids
//
//  Created by sako0602 on 2026/04/13.
//

import SwiftUI

struct Row: View {
    let title: String
    let onTap: () -> Void

    var body: some View {
        Button {
            onTap()
        } label: {
            HStack {
                Text(title)
                    .foregroundStyle(.black)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.black)
            }
        }
    }
}

#Preview {
    List {
        Row(title: "登録店舗一覧", onTap: {})
        Row(title: "利用可能残高選択", onTap: {})
        Row(title: "レジ画面", onTap: {})
    }
}
