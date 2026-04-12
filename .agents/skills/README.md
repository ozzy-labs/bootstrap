# Shared Skills

このディレクトリは、複数の AI エージェントが共有する**ワークフロー定義の SSOT** です。

## 位置づけ

- `.agents/skills/` は共有ワークフロー定義の SSOT
- Codex CLI、Gemini CLI、GitHub Copilot が直接消費する
- Claude Code は `.claude/skills/` のオーバーレイ経由で参照する

## 対応エージェント

- **Codex CLI**: `.agents/skills/` を標準スキル配置先としてネイティブサポート
- **Gemini CLI**: `.agents/skills/` を `.gemini/skills/` のエイリアスとしてサポート（優先）
- **GitHub Copilot**: `.agents/skills/` を `.github/skills/`、`.claude/skills/` と並んでサポート
- **Claude Code**: `.claude/skills/` のオーバーレイが本ディレクトリのスキルを Read して参照

## 設計原則

1. frontmatter は共通フィールド（`name`, `description`）のみ使用
2. ワークフローの手順・判断基準・検証要件を定義する（WHAT を定義）
3. ユーザーとの対話方法は書かない（HOW TO INTERACT はオーバーレイの責務）
4. 開発ルールは `.agents/skills/commit-conventions/` と `.agents/skills/lint-rules/` を参照する
