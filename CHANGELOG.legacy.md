# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- **Mission**: expanded from Dev-Container-only host setup to an AI-agent-driven development environment that supports both Dev Container and direct-host workflows (#13).
- Replaced **Volta** with **mise** as the unified runtime / CLI version manager (#14). Node.js LTS, pnpm, Python, and uv are now managed through `mise use --global`.
- Replaced **git-secrets** with **gitleaks** (installed via mise) as the modern, actively maintained secret scanner. Global git hook installation was removed; gitleaks is intended to be wired into project-level hooks (e.g. lefthook) (#15).
- **Azure CLI** and **Google Cloud CLI** demoted from default-on to **opt-in**; AWS CLI remains default-on (#18).
- `install.sh` reformatted to match `.editorconfig` (2-space indent) and gained an `update` subcommand.

### Added

- **AI power tools** category to boost AI agent capabilities (#16):
  - `markitdown[all]` via `uv tool` (PDF / Office / image / audio → Markdown)
  - `tesseract-ocr` + `tesseract-ocr-jpn` via apt (OCR backend)
  - `ffmpeg` via apt (audio/video backend)
  - `ast-grep` via mise (structural code search)
  - `yq` via mise (YAML query)
- `shellcheck` added to the dev helper tools category via mise (#17).
- `scripts/update-tools.sh` to batch-update every tool across mise / uv tool / npm / native installer backends. Supports `--dry-run` and `SETUP_LOG` (#19).
- `install.sh update` subcommand that delegates to the new update script (#19).
- `ensure_mise_installed` helper function reused across mise-managed install flows.
- **Layered test infrastructure** (#28 and sub-issues #29-#33): smoke / BATS unit / Docker integration / weekly canary (`ubuntu:devel` + `ubuntu:rolling`) with GitHub Actions workflows for each layer.
- **Ubuntu 26.04 (Resolute Raccoon) readiness**: canary workflow verifies the toolchain against the next LTS dev snapshot. Added a 3-stage fallback for `wslu` (apt → PPA → graceful warning) so 26.04 users can install without `wslu` blocking the whole setup (#39).
- **PR auto-labeler** (#46): PRs touching install / test paths receive the `ci:integration` label automatically so integration tests run without manual tagging.
- **Canary duplicate-issue prevention** (#46): repeated canary failures on the same day comment on the existing issue instead of creating duplicates.
- `bubblewrap` added to the Ubuntu/Debian container / sandbox tool set via apt.

### Removed

- Volta and all related PATH / env-variable setup.
- git-secrets installation and AWS pattern registration.
- Legacy apt-based Python install (now managed via mise).

### Docs

- README.md / README.ja.md restructured to highlight AI-first, dual-mode (Dev Container / direct-host) workflows, document the new AI power tools and `update-tools.sh` script, and update verification commands.
- README now advertises supported Ubuntu releases as a table (22.04 / 24.04 CI-verified, 25.10 / 26.04 canary-verified).
- CONTRIBUTING.md rewritten in Japanese (matching the new Japanese-first internal artifact policy) with local test execution / WSL2 pre-release manual smoke checklist / canary triage.

## [0.1.0]

### Added

- Zsh環境セットアップスクリプト（`setup-zsh-linux.sh`）
  - zsh本体のインストール
  - oh-my-zshフレームワークのインストール
  - zshプラグインのインストール
    - zsh-completions（補完定義の追加）
    - zsh-autosuggestions（コマンド補完候補）
    - zsh-history-substring-search（履歴検索の強化）
    - zsh-syntax-highlighting（シンタックスハイライト）
  - デフォルトシェルの変更
- WSL2/Ubuntu 環境セットアップスクリプト（`setup-local-linux.sh`）
  - システム設定（Locale/Timezone、devcontainerマウント用ディレクトリ）
  - ビルドツール（build-essential）
  - 基本CLIツール（tree, fzf, jq, ripgrep, fd, unzip, wslu）
  - Node.js環境（Volta, Node.js LTS, pnpm）
  - Python環境（uv, Python最新安定版）
  - バージョン管理ツール（Git, GitHub CLI, git-secrets）
  - コンテナツール（Docker Engine, Docker Compose）
  - クラウドツール（AWS CLI v2, Azure CLI, Google Cloud CLI）
  - AIツール（Claude Code, Codex CLI, GitHub Copilot CLI, Gemini CLI）
  - 開発補助ツール（just, zoxide）
  - 冪等性保証（複数回実行しても安全）
  - 詳細なログ機能（トラブルシューティング用）
  - 統一的なエラーハンドリング（わかりやすいエラーメッセージと対処法）
- プロジェクトドキュメント
  - README.md（英語版）
  - README.ja.md（日本語版）
  - CLAUDE.md（Claude向けプロジェクトガイド）
  - LICENSE（MITライセンス）
- GitHub関連設定
  - Issue テンプレート（バグ報告、新機能提案、ドキュメント改善）
  - Pull Request テンプレート
- Git除外設定（`.gitignore`）
