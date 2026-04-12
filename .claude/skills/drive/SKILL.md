---
description: Issue から実装・PR 作成・セルフレビュー・修正を自動で回し、merge-ready な PR を出す
argument-hint: "<#issue-number | instruction>"
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, WebSearch, WebFetch, AskUserQuestion
---

# drive

`.agents/skills/drive/SKILL.md` を Read し、ワークフロー手順に従う。

**重要:** 各フェーズでは対応するスキルの SKILL.md を Read して**ワークフロー手順のみ**を実行する。読み込んだ SKILL.md 内の「次のアクション提案」セクションおよび「完了報告」セクションは**すべて無視**する。フェーズ間の遷移は本スキルが制御する。

## Claude Code 固有の追加事項

### 入力解析

`$ARGUMENTS` を解析し、要件を特定する。

### 自律実行

計画承認を含め、マージ前まで AskUserQuestion を使用しない（完全自律実行）。

### 中断時

いずれかのフェーズで中断した場合、AskUserQuestion で次のアクションを確認する:

- **「エラーを修正して再開する」** → 中断したフェーズから再開
- **「中断する」** → 終了

### 完了後

AskUserQuestion を呼び出す（`answers` パラメータは設定しない）:

- **「PR をマージする」** → `gh pr merge --squash --delete-branch` でマージを実行し、結果を報告する
- **「追加の変更を行う」** → 終了する
