# Swift コーディング規約 — MiniPOSKids

MiniPOSKids プロジェクトの Swift コーディング規約です。
コードを書くとき・レビューするときはこの規約に従ってください。

## 命名規則

- **型・プロトコル**: UpperCamelCase（例: `LoginView`, `CartItem`）
- **変数・関数**: lowerCamelCase（例: `isLoggedIn`, `handleLogin()`）
- **定数**: lowerCamelCase（`let` を使用）
- **Bool**: `is`, `has`, `should`, `can` で始める（例: `isFormValid`, `hasItems`）

## ファイル構成

各 Swift ファイルは以下の順序で構成する：

```swift
// 1. Import
import SwiftUI

// 2. MARK: - 型定義
struct MyView: View {

    // 3. MARK: - Properties
    // State → Binding → Environment → その他
    @State private var value = ""

    // 4. MARK: - Body
    var body: some View { ... }

    // 5. MARK: - Private Methods
    private func doSomething() { ... }
}

// 6. MARK: - Preview
#Preview { MyView() }
```

## SwiftUI ガイドライン

- `@State` は `private` をつける
- View の body は 100行以内を目安に、大きくなったらサブViewに分割
- マジックナンバーは定数化する（例: `let cornerRadius: CGFloat = 12`）
- `NavigationStack` を使う（`NavigationView` は非推奨）

## アクセス制御

- デフォルトは `internal`（省略可）
- 外部公開不要なものは積極的に `private` / `fileprivate` をつける

## コメント

- `// MARK: -` でセクションを区切る
- 自明なコードにコメント不要、「なぜ」を書く場面に限定する
- TODO は `// TODO: 説明` の形式で残す
