//
//  LoginView.swift
//  MiniPOSKids
//

import SwiftUI

struct LoginView: View {
    @Environment(AuthRouter.self) private var router
    @Environment(AppState.self) private var appState
    @State private var viewModel: LoginViewModel

    init(authService: AuthService) {
        _viewModel = State(initialValue: LoginViewModel(authService: authService))
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // ロゴ / タイトル
            VStack(spacing: 8) {
                Image(systemName: "cart.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 64, height: 64)
                    .foregroundStyle(.blue)

                Text("レジごっこ")
                    .font(.largeTitle)
                    .fontWeight(.bold)
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            // ログインボタン
            Button {
                viewModel.login(onSuccess: appState.loginSucceeded)
            } label: {
                Text("スマレジでログイン")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 32)

            // スマレジデベロッパの登録
            VStack {
                HStack {
                    Text("スマレジデベロッパの登録をしていない方は")
                    Button("こちら") {
                        router.path.append(.web)
                    }
                }
                .padding(.vertical, 13)
                appHowTo
                    .padding(20)
            }
            Spacer()
        }
    }

    private var appHowTo: some View {
        ZStack {
            VStack {
                Text("初めてお使いになる方へ")
                    .font(.system(size: 20, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 5)
                VStack(alignment: .leading) {
                    Text("1. スマレジデベロッパに新規登録（無料）")
                    Text("2. 商品の登録")
                    Text("3. 「アプリの登録商品一覧」からPDFダウンロード")
                    Text("4. バーコードを印刷")
                    Text("5. アプリでバーコードを読み取ってお買い物")
                }
                .font(Font.system(size: 15))
            }
            .padding()
            Rectangle()
                .stroke(.gray,
                        style: StrokeStyle(
                            lineWidth: 5.0,
                            lineCap: .round,
                            lineJoin: .round
                        )
                )
                .frame(height: 200)
        }
    }
}

#Preview {
    PreviewContainer()
}

private struct PreviewContainer: View {
    @State private var router = AuthRouter()
    @State private var appState = AppState()
    @State private var authService: AuthService = {
        let store = TokenStore()
        return AuthService(
            apiClient: APIClient(baseURL: "https://id.smaregi.dev", tokenStore: store),
            tokenStore: store
        )
    }()

    var body: some View {
        LoginView(authService: authService)
            .environment(router)
            .environment(appState)
    }
}
