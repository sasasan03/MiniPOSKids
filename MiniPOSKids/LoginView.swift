import SwiftUI

struct LoginView: View {
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var isLoggedIn: Bool = false
    @State private var showError: Bool = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                // ロゴ / タイトル
                VStack(spacing: 8) {
                    Image(systemName: "cart.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 64, height: 64)
                        .foregroundStyle(.blue)

                    Text("MiniPOS Kids")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }

                // 入力フォーム
                VStack(spacing: 16) {
                    TextField("ユーザー名", text: $username)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    SecureField("パスワード", text: $password)
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

                Spacer()
            }
            .navigationDestination(isPresented: $isLoggedIn) {
                Text("ホーム画面")
                    .navigationTitle("ホーム")
            }
        }
    }

    private var isFormValid: Bool {
        !username.isEmpty && !password.isEmpty
    }

    private func handleLogin() {
        // TODO: 実際の認証処理に置き換える
        if username == "admin" && password == "password" {
            showError = false
            isLoggedIn = true
        } else {
            showError = true
        }
    }
}

#Preview {
    LoginView()
}
