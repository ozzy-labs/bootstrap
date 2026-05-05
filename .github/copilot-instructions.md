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

<!-- end: @ozzylabs/skills -->
