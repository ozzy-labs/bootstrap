# AGENTS.md

このファイルは AI エージェント向けの共通 instructions です。

## 基本方針

- 日本語で応答する
- 推奨案とその理由を提示する
- `.env` ファイルは読み取り・ステージングしない
- 破壊的な Git 操作を避ける

## プロジェクト概要

`<project-name>`: <description>

## Tech Stack

- Runtime: Node.js (ESM)
- Package manager: pnpm
- Version management: mise (`.mise.toml`)

## 主要コマンド

```bash
pnpm install               # 依存関係インストール
pnpm run dev               # 開発サーバー起動
pnpm run build             # プロダクションビルド
```

## 検証（必須）

コード変更後、報告前に以下を通すこと:

1. `pnpm run build` — ビルド成功
2. `pnpm run typecheck` — 型チェック通過

## コーディング規約

- インデント: 2 スペース
- 改行コード: LF
- ファイル末尾: 改行あり

## 規約

言語・コミット・ブランチ・PR のルールは README.md を参照すること。

## Adapter Files

| Agent | Configuration |
|-------|---------------|
| Claude Code | `CLAUDE.md`, `.claude/` |
| Gemini CLI | `.gemini/settings.json` → `AGENTS.md` |
| Codex CLI | `AGENTS.md` + `.agents/skills/` |
| GitHub Copilot | `AGENTS.md` + `.agents/skills/` |
