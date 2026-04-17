# Git ワークフロールール

## 言語ポリシー

本プロジェクトは個人開発で、外部コントリビューションを受ける予定はない。メンテナは日本語ネイティブのため、**内部成果物は日本語優先**。外部ユーザー向けドキュメントのみ英語版を併記する。

| 層 | 対象 | 言語 |
|---|---|---|
| **外部向け** | `README.md` / `CHANGELOG.md` | 英語 |
| **外部向け** | `README.ja.md` / `CHANGELOG.ja.md` | 日本語 |
| **内部向け** | コミット description / PR タイトル・本文 / Issue / ブランチ名の説明部分を除く全て | **日本語** |
| **形式規約** | コミット・PR タイトルの `<type>:` プレフィックス | 英語（Conventional Commits） |
| **形式規約** | ブランチ名の `<short-description>` 部分 | 英字推奨（URL・ツール互換性のため） |

## ブランチ

- `main` から新しいブランチを作成する
- 命名規則: `<type>/<short-description>`（例: `feat/add-blog`, `fix/nav-error`）
- type: feat, fix, docs, style, refactor, perf, test, build, ci, chore
- `<short-description>` は英字 + ハイフンで記述する（URL・CI ツールの安全性のため）

## コミット

Conventional Commits 形式を使用する:

```text
<type>[optional scope]: <description>
```

- `<type>` は上記のブランチ type と同一（英語）
- `<description>` は**日本語**で、簡潔に変更内容を記述
- 破壊的変更: type 後に `!`（例: `feat!: ランディングページを再設計`）

### 例

```text
feat: mise を導入し Volta を置換
refactor: Azure / Google Cloud CLI を opt-in に降格
test: CLI エントリーポイントの smoke テストを追加
docs: README を両モード対応 + 新ツール反映で更新
```

## PR

- マージ方法: **squash merge のみ**
- PR タイトル: `<type>[optional scope]: <description>`（コミット規約と同じ形式、description は日本語）
- PR 本文も**日本語**で記述する
- マージ後に feature branch を削除する

## Git フック

lefthook で品質を担保する。フックの具体的な構成はリポジトリごとに異なる。

## 禁止事項

- `main` への直接 push
- `--force` push
- `.env` ファイルのステージング
- `--no-verify` でのフックスキップ
