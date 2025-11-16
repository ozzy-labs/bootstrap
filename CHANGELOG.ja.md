# 変更履歴

このプロジェクトのすべての重要な変更は、このファイルに記録されます。

フォーマットは [Keep a Changelog](https://keepachangelog.com/ja/1.1.0/) に基づいており、
このプロジェクトは [Semantic Versioning](https://semver.org/lang/ja/spec/v2.0.0.html) に準拠しています。

## [Unreleased]

### 追加
- Zsh環境セットアップスクリプト（`setup-zsh-ubuntu.sh`）
  - zsh本体のインストール
  - oh-my-zshフレームワークのインストール
  - zshプラグインのインストール
    - zsh-completions（補完定義の追加）
    - zsh-autosuggestions（コマンド補完候補）
    - zsh-history-substring-search（履歴検索の強化）
    - zsh-syntax-highlighting（シンタックスハイライト）
  - デフォルトシェルの変更
- WSL2/Ubuntu 環境セットアップスクリプト（`setup-local-ubuntu.sh`）
  - システム設定（Locale/Timezone、devcontainerマウント用ディレクトリ）
  - ビルドツール（build-essential）
  - 基本CLIツール（tree, fzf, jq, ripgrep, fd, unzip, wslu）
  - Node.js環境（Volta, Node.js LTS, pnpm）
  - Python環境（uv, Python最新安定版）
  - バージョン管理ツール（Git, GitHub CLI, git-secrets）
  - コンテナツール（Docker Engine, Docker Compose）
  - クラウドツール（AWS CLI v2, Azure CLI, Google Cloud CLI）
  - AIツール（Claude Code, Codex CLI）
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
