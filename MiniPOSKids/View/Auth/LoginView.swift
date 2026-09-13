//
//  LoginView.swift
//  MiniPOSKids
//

import SwiftUI

struct LoginView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel: LoginViewModel

    init(authService: AuthService) {
        _viewModel = State(initialValue: LoginViewModel(authService: authService))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // ロゴ / タイトル
                VStack(spacing: 8) {
                    Image(systemName: "cart.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 64, height: 64)
                        .foregroundStyle(.blue)

                    Text("レジっこ")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }
                .padding(.top, 32)

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                // 登録・ログインなしで全機能を試せる導線。アプリの主導線としてログインより上に置く。
                VStack(spacing: 8) {
                    Button {
                        appState.startDemo()
                    } label: {
                        Text("デモモードで試す")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    Text("アカウント登録・ログインは不要です。サンプルの店舗と商品ですべての機能をお試しいただけます。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)

                Divider()
                    .padding(.horizontal, 32)

                // 自分のスマレジの商品を使いたい人だけが通る導線
                VStack(spacing: 8) {
                    Text("スマレジをご利用中の方は、ご自身の登録商品でお買い物ができます。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    Button {
                        viewModel.login(onSuccess: appState.loginSucceeded)
                    } label: {
                        Text("スマレジでログイン（任意）")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .foregroundStyle(Color.blue)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.blue, lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal, 32)

                appHowTo
                    .padding(20)
            }
        }
    }

    private var appHowTo: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("スマレジ連携でのお買い物の流れ")
                .font(.system(size: 18, weight: .bold))
                .frame(maxWidth: .infinity)

            Text("1. スマレジのアカウントでログイン")
            Text("2. スマレジに商品を登録")
            Text("3. 「アプリの登録商品一覧」からPDFダウンロード")
            Text("4. バーコードを印刷")
            Text("5. アプリでバーコードを読み取ってお買い物")
        }
        .font(Font.system(size: 15))
        .padding()
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(.gray, lineWidth: 1)
        )
    }
}

#Preview {
    PreviewContainer()
}

private struct PreviewContainer: View {
    @State private var appState = AppState()
    @State private var authService: AuthService = {
        let store = InMemoryTokenStore()
        return AuthService(
            apiClient: APIClient(baseURL: AppConfig.idBaseURL),
            tokenStore: store
        )
    }()

    var body: some View {
        LoginView(authService: authService)
            .environment(appState)
    }
}
