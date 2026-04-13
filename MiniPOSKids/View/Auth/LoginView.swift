import SwiftUI

struct LoginView: View {
    @Environment(AuthRouter.self) private var router
    @Environment(AppState.self) private var appState
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var isLoggedIn: Bool = false
    @State private var showError: Bool = false
    
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
            
            // 入力フォーム
            VStack(spacing: 16) {
                TextField("ユーザー名", text: $username)
                    .onChange(of: username) {
                        showError = false
                    }
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                
                SecureField("パスワード", text: $password)
                    .onChange(of: password) {
                        showError = false
                    }
                    .textFieldStyle(.roundedBorder)
            }
            .padding(.horizontal, 32)
            
            // エラーメッセージ
            if showError {
                Text("ユーザー名またはパスワードが正しくありません")
                    .foregroundStyle(.red)
                    .font(.caption)
            }
            
            // ログインボタン
            Button {
                handleLogin()
            } label: {
                Text("ログイン")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isFormValid ? Color.blue : Color.gray)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(!isFormValid)
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
    
    private var isFormValid: Bool {
        !username.isEmpty && !password.isEmpty
    }
    
    private func handleLogin() {
        // TODO: Replace with server/API authentication
#if DEBUG
        let isAuthenticated = (username == "q" && password == "q")
#else
        let isAuthenticated = (username == "q" && password == "q")
#endif
        if isAuthenticated {
            showError = false
            isLoggedIn = true
            appState.loginSucceeded()
        } else {
            showError = true
        }
    }
    
    private var appHowTo: some View {
        ZStack {
            // TODO: アプリを始めてダウンロードした人がこの画面を開いた時に、 こちらボタンにポップアップを表示させて、商品の登録にはスマレジデベロッパの登録を行い、商品の登録を行う必要があることを伝えたい
            VStack {
                //TODO: 細かな説明に修正
                Text("初めてお使いになる方へ")
                    .font(.system(size: 20,weight: .bold))
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
    
    var body: some View {
        LoginView()
            .environment(router)
            .environment(appState)
    }
}
