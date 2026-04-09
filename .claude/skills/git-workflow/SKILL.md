# Git ワークフロー — MiniPOSKids

MiniPOSKids プロジェクトのブランチ戦略とコミットメッセージの規約です。

## ブランチ戦略

```
main          ← リリース済みの安定版（直接pushしない）
  └─ develop  ← 開発の統合ブランチ
       ├─ feature/xxx   ← 機能追加
       ├─ fix/xxx       ← バグ修正
       ├─ refactor/xxx  ← リファクタリング
       └─ docs/xxx      ← ドキュメント
```

## ブランチ命名規則

| 種類 | プレフィックス | 例 |
|------|--------------|-----|
| 機能追加 | `feature/` | `feature/add-cart-view` |
| バグ修正 | `fix/` | `fix/login-crash` |
| リファクタリング | `refactor/` | `refactor/login-view` |
| ドキュメント | `docs/` | `docs/readme-update` |

- 英語・小文字・ハイフン区切り
- 具体的な内容がわかる名前にする

## コミットメッセージ規則

```
<type>: <概要（日本語OK、50文字以内）>

<本文（任意）>
```

### type 一覧

| type | 用途 |
|------|------|
| `feat` | 新機能 |
| `fix` | バグ修正 |
| `refactor` | リファクタリング |
| `style` | フォーマット修正（機能変化なし） |
| `docs` | ドキュメント |
| `test` | テスト追加・修正 |
| `chore` | ビルド設定・依存関係など |

### 例

```
feat: ログイン画面を追加
fix: パスワード入力時のクラッシュを修正
refactor: LoginViewをサブViewに分割
```

## PR ルール

- `feature/*` → `develop` へ PR を作成
- `develop` → `main` はリリース時のみ
- PR タイトルはコミットメッセージと同形式
- セルフレビュー後に PR を作成する
