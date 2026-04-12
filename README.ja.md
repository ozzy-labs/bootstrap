# wsl-dev-setup

**Dev Container 開発のための WSL2/Ubuntu ホスト環境セットアップスクリプト**

**[English](README.md) | 日本語**

WSL2/Ubuntu 環境に開発ツールを包括的にセットアップするシェルスクリプト集です。Dev Container を前提にしたホスト初期化を高速かつ再現性高く実行することに特化し、AI 開発ツール／コンテナ開発環境／モダンなパッケージ管理ツールなどを一括導入できます。

## 目次

- [1. リポジトリ背景](#1-リポジトリ背景)
- [2. リポジトリ構成](#2-リポジトリ構成)
- [3. 機能](#3-機能)
- [4. クイックスタート](#4-クイックスタート)
- [5. 前提条件](#5-前提条件)
- [6. スクリプト](#6-スクリプト)
  - [6.1 setup-zsh-ubuntu.sh](#61-setup-zsh-ubuntush)
  - [6.2 setup-local-ubuntu.sh](#62-setup-local-ubuntush)
- [7. トラブルシューティング](#7-トラブルシューティング)
- [8. コントリビューション](#8-コントリビューション)
- [9. 変更履歴](#9-変更履歴)

## 1. リポジトリ背景

- Dev Container 中心の開発に必要なホスト側ツールの導入をワンコマンド化し、WSL2/Ubuntu 上での再現性を確保することを目指しています。
- 冪等性・詳細ログ・エラーメッセージを重視し、チーム全体で同じ初期化手順を共有できるように設計しています。
- アプリケーションリポジトリとは独立してバージョン管理し、ホスト要件のアップデートを機動的に行えるようにしています。

## 2. リポジトリ構成

```
wsl-dev-setup/
├── install.sh
├── README.md
├── README.ja.md
└── scripts/
    ├── setup-local-ubuntu.sh
    └── setup-zsh-ubuntu.sh
```

## 3. 機能

- 🤖 **AI 開発ツール対応** - Claude Code, Codex CLI をサポート
- 🐳 **コンテナ開発環境** - Docker Engine, Docker Compose（Dev Container に必須）
- 📦 **モダンなパッケージ管理** - Volta (Node.js LTS), uv (Python 最新安定版), pnpm
- ☁️ **クラウド開発** - AWS CLI v2, GitHub CLI
- 🔒 **セキュリティ** - git-secrets のグローバル設定（機密情報の誤コミット防止）
- 🎨 **快適なシェル環境** - zsh + oh-my-zsh + プラグイン
- ✅ **冪等性保証** - 複数回実行しても安全
- 📝 **詳細なログ機能** - トラブルシューティング用のログ出力（オプション）
- 🛠️ **統一的なエラーハンドリング** - わかりやすいエラーメッセージと対処法

## 4. クイックスタート

```bash
# 1. zsh セットアップ（推奨：最初に実行）
curl -fsSL https://raw.githubusercontent.com/ozzy-labs/wsl-dev-setup/main/install.sh | bash -s -- zsh

# 2. ターミナルを再起動
exit
# 新しいターミナルを開く

# 3. 開発ツールをセットアップ
curl -fsSL https://raw.githubusercontent.com/ozzy-labs/wsl-dev-setup/main/install.sh | bash -s -- local

# 4. 認証を完了
aws configure      # または aws configure sso
gh auth login
claude auth login
codex auth login
```

事前に内容を確認したい場合は、従来どおり clone してから実行できます。

```bash
git clone https://github.com/ozzy-labs/wsl-dev-setup.git
cd wsl-dev-setup
./install.sh zsh
./install.sh local
```

## 5. 前提条件

これらのスクリプトは **WSL2/Ubuntu 環境（ホスト側）** のセットアップを目的としています。

- **開発スタイル**: Dev Container 内で開発を行う前提
- **対象環境**: WSL2/Ubuntu（ホスト側）
- **用途**: Dev Container を実行するためのホスト環境のセットアップ

Dev Container 内の環境は `.devcontainer/` の設定で自動構築されるため、これらのスクリプトで直接セットアップする必要はありません。

## 6. スクリプト

### 6.1 setup-zsh-ubuntu.sh

WSL2/Ubuntu 環境で zsh + oh-my-zsh + プラグインをセットアップするスクリプトです。

`install.sh` 経由でも、`scripts/setup-zsh-ubuntu.sh` を直接実行しても使えます。

**6.1.1 インストールされる内容**

- **curl** - oh-my-zsh のインストールに必要
- **git** - プラグインのインストールに必要
- **zsh** - シェル本体
- **oh-my-zsh** - zsh フレームワーク
- **zsh-completions** - 追加の補完定義
- **zsh-autosuggestions** - コマンドの自動補完
- **zsh-history-substring-search** - 履歴検索の強化
- **zsh-syntax-highlighting** - コマンドのシンタックスハイライト
- `.zshrc` の plugins 設定自動修正
- インタラクティブなプラグイン選択（すべてインストールまたは個別選択）

**6.1.2 主な機能**

- ✅ **冪等性保証** - 複数回実行しても安全
  - プラグイン設定の堅牢な検出（既存の`plugins=(git docker)`などに対応）
  - 既存プラグインを保持しながら新しいプラグインを追加
- ✅ **実行環境チェック** - Ubuntu/Debian 系のみ実行可能
- ✅ **依存関係の自動解決** - curl, git を事前インストール
- ✅ **設定の自動更新** - .zshrc のプラグイン設定を自動追加
  - 任意のプラグイン構成に対応（スペース区切りのバリエーションも可）
- ✅ **デフォルトシェル変更** - zsh をデフォルトシェルに設定（失敗時は代替案を提示）
- ✅ **エラーハンドリング** - すべての重要な操作でエラーチェック
- ✅ **ログ記録機能** - トラブルシューティング用のログ出力（オプション）
- ✅ **詳細なコメント** - 複雑な処理には説明コメントを付与

**6.1.3 使用方法**

```bash
# install.sh 経由で実行（初回セットアップ向け）
curl -fsSL https://raw.githubusercontent.com/ozzy-labs/wsl-dev-setup/main/install.sh | bash -s -- zsh

# clone 済みリポジトリから実行
./install.sh zsh

# スクリプトを直接実行
./scripts/setup-zsh-ubuntu.sh

# ログを記録する場合
SETUP_LOG=1 ./install.sh zsh

# カスタムログファイルパスを指定
SETUP_LOG=/path/to/setup.log ./install.sh zsh

# シェル再起動（zsh が有効化されます）
exec zsh
```

**6.1.4 セットアップ後の確認**

```bash
# zsh が動作しているか確認
echo $SHELL

# oh-my-zsh のバージョン確認
omz version

# プラグインが有効か確認
echo $plugins
```

**6.1.5 注意事項**

- Dev Container **外**の WSL2/Ubuntu 環境用です
- Dev Container 内では Dockerfile で自動セットアップされます
- 複数回実行しても安全です（冪等性保証）
- デフォルトシェル変更が失敗した場合は手動設定の手順が表示されます

---

### 6.2 setup-local-ubuntu.sh

WSL2/Ubuntu 環境に必要な開発ツールをインストールする包括的なセットアップスクリプトです。

`install.sh` 経由でも、`scripts/setup-local-ubuntu.sh` を直接実行しても使えます。

**6.2.1 インストールされるツール**

1. **システム設定**
   - **Locale/Timezone** - ja_JP.UTF-8 と Asia/Tokyo を自動設定
   - **devcontainer マウント用ディレクトリ** - `~/.aws`, `~/.claude`, `~/.gemini`, `~/.config/gh`, `~/.local/share/pnpm` など
2. **基本CLIツール**
   - **build-essential** - C/C++ コンパイラとビルドツール
   - **tree** - ディレクトリ構造の可視化
   - **fzf** - ファジーファインダー（Ctrl+R で履歴検索）
   - **jq** - JSON 処理
   - **ripgrep** - 高速なテキスト検索ツール
   - **fd-find** - find の高速でユーザーフレンドリーな代替
   - **unzip** - アーカイブ展開（AWS CLI に必要）
   - **wslu** - WSL2 でブラウザを開くためのユーティリティ
3. **Node.js エコシステム**
   - **Volta** - Node.js バージョン管理（推奨）
   - **Node.js LTS** - JavaScript ランタイム
   - **pnpm** - 高速なパッケージマネージャー
4. **Python エコシステム**
   - **uv** - 高速な Python パッケージインストーラ
   - **Python（最新安定版）** - Python ランタイム
5. **バージョン管理ツール**
   - **Git** - バージョン管理システム
   - **GitHub CLI** - GitHub 操作
   - **git-secrets** - 機密情報の誤コミット防止（グローバル設定済み）
   - **Git 基本設定** - user.name, user.email, core.editor などの自動設定
6. **コンテナツール**
   - **Docker Engine** - コンテナ実行環境
   - **Docker Compose** - 複数コンテナの管理ツール（Dev Container に必須）
   - **Docker サービス自動起動** - WSL2 でのサービス起動
7. **クラウドツール**
   - **AWS CLI v2** - AWS リソース操作
   - **Azure CLI** - Microsoft Azure リソース操作
   - **Google Cloud CLI** - Google Cloud Platform リソース操作
8. **AIツール**
   - **Claude Code** - Claude AI との対話型開発ツール
   - **Codex CLI** - OpenAI Codex CLI（コード生成AI）
9. **開発補助ツール**
   - **just** - タスクランナー
   - **zoxide** - ディレクトリジャンプ機能を持つスマートな cd コマンド

**6.2.2 主な機能**

- ✅ **対話的なツール選択** - インストールするツールを選択可能（すべてインストール or 個別選択）
- ✅ **冪等性保証** - 複数回実行しても安全
- ✅ **実行環境チェック** - Ubuntu/Debian 系のみ実行可能
- ✅ **統一的なエラーハンドリング** - すべての重要な操作でエラーチェック
  - 統一フォーマット（原因分析 + 対処法 + 手動コマンド）
  - トラブルシューティングが容易
- ✅ **詳細なエラーメッセージ** - トラブルシューティングのヒントを表示
- ✅ **入力バリデーション** - Git メールアドレスの形式チェック
- ✅ **ログ記録機能** - トラブルシューティング用のログ出力（オプション）
- ✅ **DRY原則の適用** - コードの重複を最小化
  - `add_to_shell_config` 関数の一貫使用
  - シェル設定の統一的な管理
- ✅ **インタラクティブ設定** - Git ユーザー名/メールアドレスの対話的設定
- ✅ **セキュリティ機能** - git-secrets のグローバル設定を自動化
- ✅ **詳細なサマリー表示** - インストール結果の確認が容易
- ✅ **明確な変数管理** - グローバル変数の明示的な初期化とスコープ管理
- ✅ **詳細なコメント** - 複雑な処理（パイプライン、正規表現等）に説明を付与

**6.2.3 使用方法**

```bash
# install.sh 経由で実行（初回セットアップ向け）
curl -fsSL https://raw.githubusercontent.com/ozzy-labs/wsl-dev-setup/main/install.sh | bash -s -- local

# clone 済みリポジトリから実行
./install.sh local

# スクリプトを直接実行
./scripts/setup-local-ubuntu.sh

# ログを記録する場合（デフォルトパス: ~/setup-local-ubuntu-YYYYMMDD-HHMMSS.log）
SETUP_LOG=1 ./install.sh local

# カスタムログファイルパスを指定
SETUP_LOG=/var/log/setup.log ./install.sh local

# ターミナルを完全に閉じて再ログイン
# （パスを確実に通すため、exec では不十分です）
exit
```

**6.2.4 セットアップ後の推奨手順**

1. **AWS 認証情報を設定**:
   ```bash
   aws configure      # IAM ユーザーの場合
   aws configure sso  # SSO の場合
   ```

2. **GitHub 認証**:
   ```bash
   gh auth login
   ```

3. **Claude Code 認証**:
   ```bash
   claude auth login
   ```

4. **Codex CLI 認証**:
   ```bash
   codex auth login
   ```

5. **各ツールの動作確認**:
   ```bash
   # バージョン確認
   volta --version
   node --version
   pnpm --version
   uv --version
   python3 --version
   aws --version
   gh --version
   claude --version
   codex --version
   docker --version
   docker compose version
   command -v git-secrets  # git-secrets には --version オプションがない
   just --version
   claude --version
   codex --version
   ```

**6.2.5 Git 設定について**

スクリプト実行時に以下が対話的に設定されます：

- `user.name` - Git ユーザー名（デフォルト: 現在のユーザー名）
- `user.email` - Git メールアドレス（形式バリデーション付き）
- `core.editor` - デフォルトエディタ（vim）
- `init.defaultBranch` - デフォルトブランチ（main）
- `core.autocrlf` - 改行コード設定（input）
- `core.fileMode` - 実行権限の追跡（true）

**6.2.6 エラーハンドリングについて**

すべての重要な操作でエラーチェックを実施し、統一的なフォーマットで詳細な情報を提供：

**統一エラーメッセージフォーマット**:
```
⚠️  エラーメッセージ
ℹ️  考えられる原因:
    - 原因1
    - 原因2
ℹ️  対処法:
    1. 手順1
    2. 手順2
ℹ️  手動で確認/実行: コマンド
```

**例1: apt update の失敗時**
```bash
⚠️  システムパッケージの更新に失敗しました
ℹ️  考えられる原因:
    - ネットワーク接続の問題
    - パッケージリポジトリの障害
    - /etc/apt/sources.list の設定ミス
ℹ️  手動で確認: sudo apt update
```

**例2: Volta が見つからない場合**
```bash
⚠️  Volta が見つかりません
ℹ️  考えられる原因:
    - Volta のインストールが完了していない
    - インストール直後で PATH が反映されていない
ℹ️  対処法:
    1. ターミナルを完全に閉じて再ログイン（exit）
    2. このスクリプトを再実行
ℹ️  手動で確認: volta --version
```

**例3: Docker サービス起動失敗**
```bash
⚠️  Docker サービスの起動に失敗しました
ℹ️  考えられる原因:
    - Docker のインストールが不完全
    - システムのサービス管理に問題がある
    - カーネルモジュールが読み込まれていない
ℹ️  対処法:
    1. Docker のインストール状態を確認: dpkg -l | grep docker
    2. サービスの詳細なステータスを確認: sudo service docker status
ℹ️  手動で起動する場合: sudo service docker start
```

**6.2.7 ログファイルについて**

`SETUP_LOG` 環境変数を設定すると、すべての出力がログファイルに記録されます：

```bash
# デフォルトパスに記録（~/setup-local-ubuntu-YYYYMMDD-HHMMSS.log）
SETUP_LOG=1 ./install.sh local

# カスタムパスに記録
SETUP_LOG=/tmp/setup.log ./install.sh local
```

ログには以下が記録されます：
- すべての出力メッセージ
- エラーメッセージ
- ユーザー入力（Git 設定など）
- インストール結果

**6.2.8 注意事項**

- Dev Container **外**の WSL2/Ubuntu 環境用です
- Dev Container 内ではすでに必要なツールがインストール済みです
- 複数回実行しても安全です（冪等性保証）
- Ubuntu/Debian 系以外では警告が表示され、続行を確認されます
- Git ユーザー名/メールアドレスが未設定の場合、対話的に設定を求められます
- 空白文字のみの入力や無効なメールアドレスはバリデーションされます

---

## 7. トラブルシューティング

### 7.1 よくある問題

**7.1.1 apt update が失敗する**
```bash
# エラーメッセージ例
⚠️  システムパッケージの更新に失敗しました

# 対処法
1. ネットワーク接続を確認
2. sudo apt update を手動で実行してエラー詳細を確認
3. /etc/apt/sources.list の設定を確認
```

**7.1.2 Volta/uv が見つからない**
```bash
# エラーメッセージ例
⚠️  Volta が見つかりません
ℹ️  考えられる原因:
    - Volta のインストールが完了していない
    - インストール直後で PATH が反映されていない
ℹ️  対処法:
    1. ターミナルを完全に閉じて再ログイン（exit）
    2. このスクリプトを再実行
ℹ️  手動で確認: volta --version

# 追加の確認手順
1. ターミナルを完全に閉じる（exit）
2. 新しいターミナルセッションを開く
3. echo $PATH で PATH が更新されているか確認
4. ls -la ~/.volta で Volta がインストールされているか確認
```

**7.1.3 Docker が起動しない**
```bash
# エラーメッセージ例
⚠️  Docker サービスの起動に失敗しました
ℹ️  考えられる原因:
    - Docker のインストールが不完全
    - システムのサービス管理に問題がある
    - カーネルモジュールが読み込まれていない
ℹ️  対処法:
    1. Docker のインストール状態を確認: dpkg -l | grep docker
    2. サービスの詳細なステータスを確認: sudo service docker status
ℹ️  手動で起動する場合: sudo service docker start

# 追加の確認手順
sudo service docker status  # 状態確認
sudo service docker start   # 手動起動
sudo docker run hello-world # 動作確認
```

**7.1.4 Docker Compose が見つからない**
```bash
# エラーメッセージ例
⚠️  Docker Compose のインストールに失敗しました
ℹ️  考えられる原因:
    - パッケージリポジトリに docker-compose-plugin がない
    - Docker Engine のインストールが不完全
ℹ️  対処法:
    1. Docker のインストール状態を確認: dpkg -l | grep docker
    2. 手動でインストール: sudo apt-get install -y docker-compose-plugin
ℹ️  手動で確認: docker compose version

# 追加の確認手順
docker compose version              # バージョン確認
dpkg -l | grep docker-compose       # パッケージ確認
sudo apt-get update                 # リポジトリ更新後に再試行
sudo apt-get install -y docker-compose-plugin
```

**7.1.5 Git メールアドレスが無効**
```bash
# エラーメッセージ例
⚠️  無効なメールアドレス形式です

# 対処法
有効な形式で入力: user@example.com
または後で設定: git config --global user.email "you@example.com"
```

### 7.2 ログの確認方法

```bash
# ログ記録付きで実行した場合
SETUP_LOG=1 ./install.sh local

# ログファイルの場所が表示されます
ℹ️  ログを /home/user/setup-local-ubuntu-20250109-123456.log に記録します

# ログを確認
cat /home/user/setup-local-ubuntu-20250109-123456.log
```

---

## 8. コントリビューション

コントリビューションを歓迎します！Pull Request をお気軽に送ってください。

詳細なレビュープロセスについては、以下を参照してください：
- [レビュープロセスガイド](docs/review-process.md)
- [レビューチェックリスト](docs/review-checklist.md)

---

## 9. 変更履歴

プロジェクトの変更履歴の詳細は [CHANGELOG.ja.md](CHANGELOG.ja.md) を参照してください。
