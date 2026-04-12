---
description: Issue または指示をもとに、ブランチ作成・実装を行う
argument-hint: "<#issue-number | instruction>"
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, WebSearch, WebFetch, AskUserQuestion
---

# implement

`.agents/skills/implement/SKILL.md` を Read し、ワークフロー手順に従う。

## Claude Code 固有の追加事項

### 入力解析

`$ARGUMENTS` を解析し、要件を特定する。

- **引数なしの場合:** AskUserQuestion で「何を実装しますか？（Issue 番号 or 説明）」と確認する（`answers` パラメータは設定しない）
- **`gh` CLI エラー時:** 認証エラーの場合は `gh auth login` の実行を案内して中断する

### 実装計画の確認

実装計画を提示した後、AskUserQuestion で確認する（`answers` パラメータは設定しない）:

- **「この計画で実装」**
- **「計画を修正」**
- **「キャンセル」**

**重要:** 承認なしにコード変更を開始しない。

### 完了後の次のアクション

実装完了報告の直後に AskUserQuestion を呼び出す（`answers` パラメータは設定しない）:

- **「lint・コミット・PR まで一括実行する」** → `.claude/skills/ship/SKILL.md` を Read し、その手順に従う
- **「個別に lint を実行する」** → `.claude/skills/lint/SKILL.md` を Read し、その手順に従う
- **「追加の変更を行う」** → 終了する
