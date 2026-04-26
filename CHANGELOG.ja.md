# 変更履歴

このプロジェクトのすべての重要な変更は、このファイルに記録されます。

フォーマットは [Keep a Changelog](https://keepachangelog.com/ja/1.1.0/) に基づいており、
このプロジェクトは [Semantic Versioning](https://semver.org/lang/ja/spec/v2.0.0.html) に準拠しています。

## [Unreleased]

### 変更

- **ミッション**: 「Dev Container 前提のホストセットアップ」から「**AI エージェント駆動開発を一発構築する（Dev Container / 直接開発の両対応）**」へ拡張（#13）
- **Volta → mise に置換**: Node.js LTS / pnpm / Python / uv を mise 配下で統一管理（#14）
- **git-secrets → gitleaks に置換**: mise 経由で導入、2026 デファクトのシークレットスキャナへ移行。グローバル Git フック設定は削除し、プロジェクト側の lefthook 等で運用する方針（#15）
- **Azure CLI / Google Cloud CLI を opt-in に降格**: AWS CLI のみデフォルト ON を維持（#18）
- `install.sh` を `.editorconfig`（2-space indent）に合わせて整形、`update` サブコマンドを追加

### 追加

- **AI パワーツール** カテゴリを新設してエージェントの能力を強化（#16）
  - `markitdown[all]`（uv tool）- PDF / Office / 画像 / 音声 → Markdown
  - `tesseract-ocr` + `tesseract-ocr-jpn`（apt）- OCR 基盤
  - `ffmpeg`（apt）- 音声・動画処理基盤
  - `ast-grep`（mise）- 構造的コード検索
  - `yq`（mise）- YAML クエリ
- `shellcheck` を開発補助ツールカテゴリに追加（mise 経由、#17）
- `scripts/update-tools.sh` を新設し、mise / uv tool / npm / 独自インストーラを横断的に一括更新（`--dry-run` / `SETUP_LOG` 対応、#19）
- `install.sh update` サブコマンド（上記スクリプトを呼び出す、#19）
- `ensure_mise_installed` ヘルパー関数を追加（mise ベースのインストール関数で共通利用）
- **層別テスト基盤**（#28 と Sub-Issues #29-#33）: smoke / BATS / Docker 統合 / 週次 Canary（`ubuntu:devel` + `ubuntu:rolling`）の各層に対応する GitHub Actions ワークフロー
- **Ubuntu 26.04 Resolute Raccoon 対応**: Canary で次期 LTS 開発版に対する検証を継続。`wslu` が 26.04 の標準リポジトリから外れている問題に 3 段フォールバック（apt → PPA → 警告出して継続）を実装済み（#39）
- **PR 自動ラベリング**（#46）: install/test 系パスを変更した PR に `ci:integration` ラベルを自動付与、手動タグ付け漏れによる統合テスト漏れを回避
- **Canary 重複 Issue 抑止**（#46）: 同日複数失敗時は既存 Open Issue にコメントで再発を記録、重複起票を防止
- Ubuntu/Debian のコンテナ / サンドボックスツールセットに apt 経由の `bubblewrap` を追加

### 削除

- Volta 本体とその PATH / 環境変数設定
- git-secrets のインストール処理と AWS パターン登録
- apt 経由の Python インストール（mise 管理に統合）

### ドキュメント

- README.md / README.ja.md を AI ファースト・両モード対応を前提に再構成、新ツールと `update-tools.sh` を追記、動作確認コマンドを最新化
- README にサポート Ubuntu リリース一覧表を追加（22.04 / 24.04 は CI 検証、25.10 / 26.04 は Canary 検証）
- CONTRIBUTING.md を日本語で全面書き直し（内部成果物の日本語化方針に準拠）し、ローカルテスト実行手順 / WSL2 リリース前スモークチェック / Canary トリアージを追記

## [0.1.0]

### 追加

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
