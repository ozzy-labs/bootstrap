---
description: 全リンターを自動修正付きで実行し、結果を報告する
disable-model-invocation: true
allowed-tools: Bash, Read, Edit, AskUserQuestion
---

# lint

`.agents/skills/lint/SKILL.md` を Read し、ワークフロー手順に従う。

## Claude Code 固有の追加事項

サマリー報告の直後に AskUserQuestion を呼び出す（`answers` パラメータは設定しない）。報告の出力だけでスキルを終了しない:

**全て通過した場合:**

- **「コミットする」** → `.claude/skills/commit/SKILL.md` を Read し、その手順に従う
- **「コミット・PR まで一括実行する」** → `.claude/skills/ship/SKILL.md` を Read し、その手順に従う
- **「追加の変更を行う」** → 終了する

**エラーがある場合:**

- **「エラーを修正する」** → 修正完了後、再実行する
- **「追加の変更を行う」** → 終了する
