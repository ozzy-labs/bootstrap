---
description: コード変更や PR をレビューし、問題点・改善案を報告する
argument-hint: "<#PR-number | (blank for working tree changes)>"
disable-model-invocation: true
allowed-tools: Bash, Read, Edit, Write, Grep, Glob, AskUserQuestion
---

# review

`.agents/skills/review/SKILL.md` を Read し、ワークフロー手順に従う。

## Claude Code 固有の追加事項

完了報告の直後に AskUserQuestion を呼び出す（`answers` パラメータは設定しない）:

**指摘ありの場合:**

- **「指摘事項を修正する」** → 指摘事項に基づきコードを修正する
- **「このまま進める」** → 終了する

**指摘なしの場合:**

- **「コミット・PR まで一括実行する」** → `.claude/skills/ship/SKILL.md` を Read し、その手順に従う
- **「このまま進める」** → 終了する
