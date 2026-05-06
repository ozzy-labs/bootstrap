<!-- begin: ozzy-labs/commons -->

# GitHub Copilot Instructions

共通方針は [AGENTS.md](../AGENTS.md) を参照してください。
GitHub Copilot Chat / Copilot コーディングエージェントは本ファイルを自動で読み込みます。

## 基本ルール

- 日本語で応答する
- 推奨案とその理由を提示する
- `.env` ファイルは読み取り・ステージングしない
- 破壊的な Git 操作を避ける

## コミット・ブランチ・PR

- Conventional Commits 形式（`<type>[scope]: <description>`）
- ブランチ命名: `<type>/<short-description>`
- PR はタイトルをコミット規約と同じ形式にする
- マージ方法は squash merge のみ

## 検証

変更後は以下を通すこと:

```bash
mise exec -- lefthook run pre-commit --all-files
```

プロジェクト固有の検証は [AGENTS.md](../AGENTS.md) の「検証」セクションを参照。

<!-- end: ozzy-labs/commons -->

<!-- begin: @ozzylabs/skills -->

## Available Skills

- `commit` — 変更をステージし、Conventional Commits でコミットする。プッシュや PR 作成は行わない。
- `commit-conventions` — Conventional Commits のメッセージ生成ルール（Type/Scope 判定表、フォーマット）。他スキルから参照される。
- `drive` — Issue から実装・PR 作成・セルフレビュー・修正を自動で回し、merge-ready な PR を出す。Issue 番号またはテキスト指示を受け取る。オプションでマージまで実行可能。
- `implement` — Issue または指示をもとに、ブランチ作成・実装計画・コード変更を行う。Issue 番号またはテキスト指示を受け取る。
- `lint` — 全リンターを自動修正付きで実行し、結果を報告する。コード品質チェック、フォーマット、型チェック、セキュリティスキャンを含む。
- `lint-rules` — 拡張子別リンター・フォーマッターのコマンド対応表と型チェックルール。他スキルから参照される。
- `pr` — コミット済みの変更をリモートにプッシュし、PR を作成・更新する。
- `review` — コード変更や PR をレビューし、問題点・改善案を報告する。PR 番号または空（ワーキングツリー）を受け取る。
- `ship` — lint・コミット・PR 作成を一括実行する。変更に対して lint → コミット → PR 作成を順に実行する統合パイプライン。
- `test` — ビルド・テスト・型チェックを実行し、結果を報告する。

<!-- end: @ozzylabs/skills -->
