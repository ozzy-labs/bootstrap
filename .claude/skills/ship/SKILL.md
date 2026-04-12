---
description: lint・コミット・PR 作成を一括実行する
disable-model-invocation: true
allowed-tools: Bash, Read, Grep, Glob, AskUserQuestion
---

# ship

`.agents/skills/ship/SKILL.md` を Read し、ワークフロー手順に従う。

**重要:** 各ステップの実行中、読み込んだスキル内の「次のアクション提案」セクションおよび「完了報告」セクションは**すべて無視**する。ステップ間の遷移は本スキルが制御する。

## Claude Code 固有の追加事項

**失敗した場合:** エラー内容を報告し、修正→再度 `/ship` を提案して中断する。

完了報告の直後に AskUserQuestion を呼び出す（`answers` パラメータは設定しない）:

- **「PR をレビューする」** → `.claude/skills/review/SKILL.md` を Read し、その手順に従う
- **「PR をマージする」** → `gh pr merge --squash --delete-branch` でマージを実行し、結果を報告する
