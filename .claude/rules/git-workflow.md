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
