# Git ワークフロールール

## ブランチ

- `main` から新しいブランチを作成する
- 命名規則: `<type>/<short-description>`（例: `feat/add-blog`, `fix/nav-error`）
- type: feat, fix, docs, style, refactor, perf, test, build, ci, chore

## コミット

Conventional Commits 形式を使用する:

```text
<type>[optional scope]: <description>
```

- type は上記のブランチ type と同一
- description は英語で、簡潔に変更内容を記述
- 破壊的変更: type 後に `!`（例: `feat!: redesign landing page`）

### `fix` と `ci` の境界

エンドユーザー（`install.sh` 利用者）の挙動が変わるかで判定する:

- **`fix`:** `install.sh` / `scripts/` 配下のユーザーが実行するコードのバグ修正
- **`ci`:** lint / formatter 設定（`.markdownlint-cli2.yaml`, `.yamllint.yaml` 等）、GitHub Actions、lefthook、その他開発者向けツール設定の修正

例: `CHANGELOG.md` を markdownlint の対象から外す変更は `ci(lint):`（ユーザー挙動は不変）であって `fix:` ではない。

## PR

- マージ方法: **squash merge のみ**
- PR タイトル: `<type>[optional scope]: <description>`（コミット規約と同じ形式）
- マージ後に feature branch を削除する

## Git フック

lefthook で品質を担保する。フックの具体的な構成はリポジトリごとに異なる。

## 禁止事項

- `main` への直接 push
- `--force` push
- `.env` ファイルのステージング
- `--no-verify` でのフックスキップ
