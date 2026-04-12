---
description: ビルド・テスト・型チェックを実行し、結果を報告する
disable-model-invocation: true
allowed-tools: Bash, Read, Edit, Write, AskUserQuestion
---

# test

`.agents/skills/test/SKILL.md` を Read し、ワークフロー手順に従う。

## Claude Code 固有の追加事項

サマリー報告の直後に AskUserQuestion を呼び出す（`answers` パラメータは設定しない）。報告の出力だけでスキルを終了しない:

**全て通過した場合:**

- **「コミットする」** → `.claude/skills/commit/SKILL.md` を Read し、その手順に従う
- **「PR を作成する」** → `.claude/skills/pr/SKILL.md` を Read し、その手順に従う
- **「コミット・PR まで一括実行する」** → `.claude/skills/ship/SKILL.md` を Read し、その手順に従う
- **「追加の変更を行う」** → 終了する

**失敗がある場合:**

- **「失敗を修正する」** → 修正完了後、再実行する
- **「追加の変更を行う」** → 終了する
