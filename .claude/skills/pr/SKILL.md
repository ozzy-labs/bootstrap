---
description: 変更を push し、PR を作成・更新する
disable-model-invocation: true
allowed-tools: Bash, Read, Grep, Glob, AskUserQuestion
---

# pr

`.agents/skills/pr/SKILL.md` を Read し、ワークフロー手順に従う。

## Claude Code 固有の追加事項

完了報告の直後に AskUserQuestion を呼び出す（`answers` パラメータは設定しない）:

- **「PR をレビューする」** → `.claude/skills/review/SKILL.md` を Read し、その手順に従う
- **「PR をマージする」** → `gh pr merge --squash --delete-branch` でマージを実行し、結果を報告する
