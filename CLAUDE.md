# CLAUDE.md

スマレジ・プラットフォーム API を利用した、子ども向けレジ体験アプリ（スマレジ側のアプリ名は「レジごっこ」）。

共通規約は上位の `~/iOSProject/CLAUDE.md`（SwiftUI ワークスペース規約）と `~/.claude/CLAUDE.md`（グローバル規約）を参照。ここにはこのアプリ固有の事項だけを書く。

## ビルド / テスト

```bash
# ビルド
xcodebuild -scheme "MiniPOSKids" -destination 'platform=iOS Simulator,name=iPhone 17' build

# テスト
xcodebuild -scheme "MiniPOSKids" -destination 'platform=iOS Simulator,name=iPhone 17' test
```

スキーム名は `MiniPOSKids`。ワークスペース規約には `iPhone 15` と書かれているが、この環境には対応ランタイムが無く解決できないため `iPhone 17` を使う。

## ディレクトリ構成

ワークスペース規約の `Models/ Repositories/ ViewModels/ Views/` とは異なる構成を採用している（単数形・レイヤー分割が細かい）。既存コードに合わせること。

```
MiniPOSKids/
├── Client/        # APIClient（HTTP 層）、TokenRefresherProtocol
├── Components/    # 汎用 UI 部品
├── Error/         # APIError
├── Model/         # データ型（TokenResponse 等）
├── Routing/       # ルーター・ルート定義（Auth / Home）
├── Service/       # AuthService, StoreService, StoreProductService（API 呼び出し）
├── Store/         # KeychainTokenStore, InMemoryTokenStore（トークン永続化）
├── View/          # App / Auth / Home / Components
└── ViewModel/     # @Observable な ViewModel
```

`Service/` がワークスペース規約でいう `Repositories/` に相当する。トークンの永続化は `Store/` が担当。

## 設定値（Secrets）

`MiniPOSKids/Secrets.xcconfig`（Git 管理外）に記述し、`Info.plist` のビルド設定展開を経て `AppConfig` から読む。

```
Secrets.xcconfig → Info.plist の $(KEY) → Bundle.main.infoDictionary → AppConfig
```

| キー | 用途 |
| --- | --- |
| `SMAREGI_CLIENT_ID` | OAuth クライアント ID |
| `SMAREGI_CLIENT_SECRET` | トークンエンドポイントの Basic 認証用 |
| `SMAREGI_CONTRACT_ID` | Platform API（`api.smaregi.dev`）呼び出し用の契約 ID |

新しいキーを足すときは `Secrets.xcconfig.example` にも追記する。`AppConfig` は未設定時に `fatalError` させて即座に気付けるようにしている（設定漏れは開発時にしか起きず、黙って進むと原因究明に時間がかかるため）。

**注意**: xcconfig は `//` 以降がコメント扱いになる。値に `//` が含まれると途中で切れる。

## 認証フロー（OAuth 2.0 認可コードフロー + PKCE）

```
LoginViewModel.login()
  ↓ ASWebAuthenticationSession で認可画面を表示
https://id.smaregi.dev/authorize
  ↓ 認可成功
https://sasasan03.github.io/miniposkids/callback.html   ← 中継ページ
  ↓ JavaScript が転送
miniposkids://callback?code=...&state=...
  ↓ ASWebAuthenticationSession が捕捉
AuthService.exchangeToken()
  ↓ Basic 認証 + code_verifier
https://id.smaregi.dev/authorize/token
  ↓
アクセストークン + リフレッシュトークン（Keychain へ）
```

- 認可コード横取り対策に PKCE、CSRF 対策に `state` 照合を実装済み
- アクセストークンは `AuthService` がメモリにキャッシュし、有効期限の 60 秒前に再取得
- `APIClient` は 401 受信時にトークンを再取得して 1 回だけリトライする
- リフレッシュトークンが失効すると `APIError.sessionExpired` が投げられ、各 ViewModel の `onSessionExpired` 経由で `AppState.logout()` に繋がる

### 中継ページ

`sasasan03/sasasan03.github.io` リポジトリの `miniposkids/callback.html`。認可コードを含むクエリをそのまま `miniposkids://callback` へ転送するだけの静的ページ。秘密情報は含まず、コードはブラウザ内で処理されサーバーには残らない。

## Gotchas

形式: 症状 / 原因 / 対処

### 「現在のログインユーザーはアクセスできません。」

- **症状**: 認可画面でログインは成功するが、その直後にこのエラーが表示される
- **原因**: `SMAREGI_CLIENT_ID` が、デベロッパーサイトで**削除済みのアプリ**を指していた。削除されたアプリを利用できる契約は存在しないため、認証は通っても認可で拒否される
- **対処**: デベロッパーサイトのアプリ詳細に表示されているクライアント ID と `Secrets.xcconfig` の値を突き合わせる。アプリを作り直すと ID が変わるので、削除・再作成したら必ず更新する

### `invalid_client`（認可画面すら出ない）

- **症状**: 認可リクエストの時点で `invalid_client` が返る
- **原因**: アプリが送る `redirect_uri` と、スマレジに登録された値が不一致。完全一致で照合される
- **対処**: 登録値と `AppConfig.oauthRedirectURI` を揃える

### スマレジ開発環境はカスタムスキームを登録できない

- **症状**: リダイレクト URI に `miniposkids://callback` を登録しようとすると「リダイレクトURIはhttp://から始まる文字列 or urn:ietf:wg:oauth:2.0:oob で入力してください」と弾かれる
- **原因**: 開発環境の仕様。`https://` は登録できる
- **対処**: https の中継ページ経由にする（上記「中継ページ」参照）。`oauthRedirectURI` はスマレジに申告する配達先、`oauthCallbackScheme` は `ASWebAuthenticationSession` が待ち受けるスキームで、**両者が異なる値になるのが正しい状態**

### `401 invalid_client` / "Client authentication failed"（トークン交換時）

- **症状**: 認可コードは取得できるが、`/authorize/token` が 401 を返す
- **原因**: スマレジのユーザーアクセストークン取得は Basic 認証が必須。`client_id` をボディに入れるだけでは通らない
- **対処**: `Authorization: Basic base64(client_id:client_secret)` を付与する（`AuthService.basicAuthorizationHeader()`）
- **補足**: これはアプリを **WEB アプリ**として登録しているため。ネイティブアプリとして登録すればシークレット不要で PKCE のみになる。公開配布するならトークン交換をバックエンドへ移すこと

### `prefersEphemeralWebBrowserSession` による問題の隠蔽

- **症状**: 設定不備があるのに、しばらくログインが成功し続ける
- **原因**: `false` だと Safari の既存 Cookie を再利用し、認可画面を経ずにコードが発行される。スコープやアカウントの検証が走らず、壊れていることに気付けない
- **対処**: `true` を維持する。毎回まっさらな状態で認証されるので、設定不備が即座に表面化する

### API エラーの調査

`APIClient` はエラー時にレスポンスボディをログ出力する（`privacy: .private` のためデバッガ接続時のみ表示）。OAuth のエラーは `{"error":"...","error_description":"..."}` で返るので、ステータスコードだけで悩まずまず本文を読む。Xcode コンソールのフィルタに `com.miniposkids` を入れるとシステムログを除外できる。

## 参考

- [スマレジ・プラットフォームAPI 共通仕様](https://developers.smaregi.dev/platform-api-reference/common) — トークンエンドポイントの仕様はここが現行の挙動と一致している
- [スコープの設定 〜 アクセストークンの取得](https://developers.smaregi.dev/platform-api-reference/start-guide/get-access-token/) — エンドポイントや Basic 認証の要否について共通仕様と食い違う記述があるので注意
