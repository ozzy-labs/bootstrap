---
description: 変更をステージし、Conventional Commits でコミットする（push はしない）
disable-model-invocation: true
allowed-tools: Bash, Read, Grep, Glob, AskUserQuestion
---

# commit

`.agents/skills/commit/SKILL.md` を Read し、ワークフロー手順に従う。

## Claude Code 固有の追加事項

変更ファイルの一覧をユーザーに提示する:

```text
変更ファイル:
  M src/pages/index.astro
  A src/content/blog/new-post.md
```

完了報告の直後に AskUserQuestion を呼び出す（`answers` パラメータは設定しない）。報告の出力だけでスキルを終了しない:

- **「PR を作成する」** → `.claude/skills/pr/SKILL.md` を Read し、その手順に従う
- **「追加の変更を行う」** → 終了する
