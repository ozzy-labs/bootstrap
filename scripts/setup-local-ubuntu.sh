#!/bin/bash
# shellcheck disable=SC2088  # チルダはログメッセージ内の表示用であり、パス展開は不要
set -e

# ========================================
# グローバル変数（インストール対象フラグ）
# ========================================
# 環境変数で事前に設定されている場合はそれを尊重（CI / Docker でのオーバーライド用途）

# 基本開発環境
INSTALL_BUILD_TOOLS="${INSTALL_BUILD_TOOLS:-1}" # build-essential
INSTALL_BASIC_CLI="${INSTALL_BASIC_CLI:-1}"     # tree, fzf, jq, ripgrep, fd, unzip, wslu
INSTALL_GIT_TOOLS="${INSTALL_GIT_TOOLS:-1}"     # Git, GitHub CLI, gitleaks

# プログラミング言語環境（mise で統一管理）
INSTALL_NODE="${INSTALL_NODE:-1}"     # mise + Node.js LTS + pnpm
INSTALL_PYTHON="${INSTALL_PYTHON:-1}" # mise + Python + uv

# コンテナツール
INSTALL_CONTAINER="${INSTALL_CONTAINER:-1}" # Docker, Docker Compose

# クラウドツール（個別選択可能、Azure/GCP は opt-in）
INSTALL_AWS_CLI="${INSTALL_AWS_CLI:-1}"       # AWS CLI (デフォルト ON)
INSTALL_AZURE_CLI="${INSTALL_AZURE_CLI:-0}"   # Azure CLI (opt-in)
INSTALL_GCLOUD_CLI="${INSTALL_GCLOUD_CLI:-0}" # Google Cloud CLI (opt-in)

# AIエージェント CLI（個別選択可能）
INSTALL_CLAUDE_CODE="${INSTALL_CLAUDE_CODE:-1}" # Claude Code
INSTALL_CODEX_CLI="${INSTALL_CODEX_CLI:-1}"     # Codex CLI
INSTALL_COPILOT_CLI="${INSTALL_COPILOT_CLI:-1}" # GitHub Copilot CLI
INSTALL_GEMINI_CLI="${INSTALL_GEMINI_CLI:-1}"   # Gemini CLI

# AIパワーツール（エージェントの文書読み込み・検索を強化）
INSTALL_AI_POWER_TOOLS="${INSTALL_AI_POWER_TOOLS:-1}" # markitdown, tesseract-ocr(+jpn), ffmpeg, ast-grep, yq

# 開発補助ツール
INSTALL_DEV_TOOLS="${INSTALL_DEV_TOOLS:-1}" # just, zoxide, shellcheck

# ========================================
# グローバル変数（実行時に設定される値）
# ========================================

# mise バイナリのパス
MISE_BIN="$HOME/.local/bin/mise"

# ========================================
# ユーティリティ関数
# ========================================

# 非対話モードかどうかを判定
# WSL_DEV_SETUP_ASSUME_YES=1 or CI=true でプロンプトを自動回答する
_is_non_interactive() {
  [ "${WSL_DEV_SETUP_ASSUME_YES:-0}" = "1" ] || [ "${CI:-}" = "true" ]
}

# パイプ実行時 (curl ... | bash) でも対話プロンプトが動作するよう、
# stdin が tty でなく /dev/tty が読める場合は /dev/tty にフォールバックする。
# 非対話モード（CI / ASSUME_YES）ではフォールバックしない。
if [ ! -t 0 ] && [ -r /dev/tty ] && ! _is_non_interactive; then
  exec </dev/tty
fi

# [Y/n] プロンプト（既定 Y）を処理し、REPLY に結果を設定する
# 非対話時は read をスキップして REPLY=Y を即設定
# $1: プロンプト文字列
_prompt_default_yes() {
  local prompt="$1"
  if _is_non_interactive; then
    REPLY=Y
    printf '%sY (non-interactive)\n' "$prompt"
    return 0
  fi
  REPLY=""
  read -p "$prompt" -n 1 -r || true
  echo ""
}

# [y/N] プロンプト（既定 N）を処理し、REPLY に結果を設定する
# 非対話時は read をスキップして REPLY=N を即設定
# $1: プロンプト文字列
_prompt_default_no() {
  local prompt="$1"
  if _is_non_interactive; then
    REPLY=N
    printf '%sN (non-interactive)\n' "$prompt"
    return 0
  fi
  REPLY=""
  read -p "$prompt" -n 1 -r || true
  echo ""
}

# シェル設定ファイルに行を追加する関数
add_to_shell_config() {
  local file="$1"
  local pattern="$2"
  local lines="$3"
  local description="$4"

  if [ -f "$file" ]; then
    if grep -q "$pattern" "$file" 2>/dev/null; then
      echo "  ⏭️  $file には既に設定済み"
    else
      echo "" >>"$file"
      echo "$lines" >>"$file"
      echo "  ✅ $description"
    fi
  else
    if [ "$file" = "$HOME/.zshrc" ]; then
      echo "  ⚠️  $file が見つかりません（zsh を使用していない場合は問題ありません）"
    else
      echo "  ⚠️  $file が見つかりません"
    fi
  fi
}

# Docker 公式リポジトリをセットアップする関数
setup_docker_repository() {
  # Docker 公式リポジトリが既に設定されているかを確認
  if [ -f /etc/apt/sources.list.d/docker.list ] && grep -q "download.docker.com" /etc/apt/sources.list.d/docker.list 2>/dev/null; then
    echo "  ⏭️  Docker 公式リポジトリは既にセットアップ済みです"
    return
  fi

  echo "  ℹ️  Docker 公式リポジトリをセットアップしています..."

  # 依存パッケージのインストール
  sudo apt-get install -y ca-certificates curl gnupg >/dev/null

  # GPG キーの登録
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  sudo chmod a+r /etc/apt/keyrings/docker.gpg

  # リポジトリの追加
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
      https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" |
    sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

  # パッケージリストの更新
  sudo apt-get update >/dev/null

  echo "  ✅ Docker 公式リポジトリをセットアップしました"
}

# ========================================
# インストール関数群（依存関係順）
# ========================================
# 注意: 以下の関数は依存関係の順序で定義されています
# 1. ビルドツール（最も基本的な依存）
# 2. 基本CLIツール（unzipがクラウドツールで必要）
# 3. Git/バージョン管理ツール（git, gh）
# 4. mise + 言語環境（Node.js + pnpm + Python + uv を mise で統一管理）
# 5. Git セキュリティツール（gitleaks、mise に依存）
# 6. コンテナツール（Dev Container開発の中核）
# 7. クラウドツール（unzipに依存）
# 8. AIエージェント CLI（Claude Code/Copilot CLIはcurlに依存、Codex/Gemini CLIはnpmに依存）
# 9. AI パワーツール（markitdown は uv 依存、ast-grep/yq は mise 依存）
# 10. 開発補助ツール

# 1. ビルドツールのインストール（最も基本的な依存）
install_build_tools() {
  [ "$INSTALL_BUILD_TOOLS" != "1" ] && return

  echo ""
  echo "🔨 ビルドツールをインストール中..."

  # build-essential のインストール・アップデート
  if ! dpkg -l | grep -q build-essential; then
    sudo apt-get install -y build-essential
    echo "  ✅ build-essential インストール完了"
  else
    sudo apt-get install -y --only-upgrade build-essential >/dev/null 2>&1
    echo "  ⏭️  build-essential は最新版です"
  fi

  echo "✅ ビルドツールインストール完了"
}

# 2. 基本CLIツールのインストール
install_basic_cli_tools() {
  [ "$INSTALL_BASIC_CLI" != "1" ] && return

  echo ""
  echo "🔧 基本CLIツールをインストール中..."

  # tree のインストール
  if ! command -v tree &>/dev/null; then
    sudo apt-get install -y tree
    echo "  ✅ tree インストール完了"
  else
    sudo apt-get install -y --only-upgrade tree >/dev/null 2>&1
    echo "  ⏭️  tree は最新版です"
  fi

  # fzf のインストール
  if ! command -v fzf &>/dev/null; then
    sudo apt-get install -y fzf
    echo "  ✅ fzf インストール完了"

    # fzf のキーバインド設定を .zshrc に追加
    add_to_shell_config ~/.zshrc "source /usr/share/doc/fzf/examples/key-bindings.zsh" "# fzf キーバインド（Ctrl+R で履歴検索）
[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ] && source /usr/share/doc/fzf/examples/key-bindings.zsh" "fzf キーバインドを ~/.zshrc に追加しました"

    # fzf のキーバインド設定を .bashrc に追加
    add_to_shell_config ~/.bashrc "source /usr/share/doc/fzf/examples/key-bindings.bash" "# fzf キーバインド（Ctrl+R で履歴検索）
[ -f /usr/share/doc/fzf/examples/key-bindings.bash ] && source /usr/share/doc/fzf/examples/key-bindings.bash" "fzf キーバインドを ~/.bashrc に追加しました"
  else
    sudo apt-get install -y --only-upgrade fzf >/dev/null 2>&1
    echo "  ⏭️  fzf は最新版です"
  fi

  # jq のインストール
  if ! command -v jq &>/dev/null; then
    sudo apt-get install -y jq
    echo "  ✅ jq インストール完了"
  else
    sudo apt-get install -y --only-upgrade jq >/dev/null 2>&1
    echo "  ⏭️  jq は最新版です"
  fi

  # ripgrep のインストール
  if ! command -v rg &>/dev/null; then
    sudo apt-get install -y ripgrep
    echo "  ✅ ripgrep インストール完了"
  else
    sudo apt-get install -y --only-upgrade ripgrep >/dev/null 2>&1
    echo "  ⏭️  ripgrep は最新版です"
  fi

  # fd のインストール
  if ! command -v fd &>/dev/null; then
    sudo apt-get install -y fd-find
    echo "  ✅ fd インストール完了"
    # Ubuntu では fd コマンドが fd-find という名前でインストールされるため、シンボリックリンクを作成
    if [ ! -f "$HOME/.local/bin/fd" ]; then
      mkdir -p "$HOME/.local/bin"
      ln -s "$(which fdfind)" "$HOME/.local/bin/fd" 2>/dev/null || true
      echo "  ✅ fd コマンドのシンボリックリンクを作成しました"
    fi
  else
    sudo apt-get install -y --only-upgrade fd-find >/dev/null 2>&1
    echo "  ⏭️  fd は最新版です"
  fi

  # unzip のインストール（AWS CLI に必要）
  if ! command -v unzip &>/dev/null; then
    sudo apt-get install -y unzip
    echo "  ✅ unzip インストール完了"
  else
    sudo apt-get install -y --only-upgrade unzip >/dev/null 2>&1
    echo "  ⏭️  unzip は最新版です"
  fi

  # wslu のインストール（WSL2 でブラウザを開くために必要）
  # Ubuntu 22.04 / 24.04 は main リポジトリに含まれるが、26.04 以降は未収録の
  # 場合があるため PPA フォールバックを用意し、いずれも失敗した場合は警告の上で
  # セットアップ全体を中断しない（wslview なしでもホスト開発自体は機能するため）。
  install_wslu() {
    if sudo apt-get install -y wslu 2>/dev/null; then
      echo "  ✅ wslu インストール完了（apt）"
      return 0
    fi
    echo "  ℹ️  wslu が標準リポジトリに無いため PPA（ppa:wslutilities/wslu）を試行..."
    if sudo add-apt-repository -y ppa:wslutilities/wslu >/dev/null 2>&1; then
      if sudo apt-get update -qq 2>/dev/null && sudo apt-get install -y wslu 2>/dev/null; then
        echo "  ✅ wslu インストール完了（PPA）"
        return 0
      fi
      # PPA 追加には成功したが install で失敗した場合、Release ファイル欠落等で
      # 以降の apt-get update を汚染するため PPA sources を確実に削除する
      sudo rm -f /etc/apt/sources.list.d/wslutilities-ubuntu-wslu-*.list \
        /etc/apt/sources.list.d/wslutilities-ubuntu-wslu-*.sources 2>/dev/null || true
      sudo apt-get update -qq >/dev/null 2>&1 || true
    fi
    echo "  ⚠️  wslu のインストールに失敗しました（Ubuntu バージョン未対応の可能性）"
    echo "  ℹ️  影響: wslview コマンドが使えないため WSL2 から Windows ブラウザの自動起動はできません"
    echo "  ℹ️  手動インストール: https://github.com/wslutilities/wslu#installation"
    return 0
  }

  if ! command -v wslview &>/dev/null; then
    install_wslu
  else
    sudo apt-get install -y --only-upgrade wslu >/dev/null 2>&1 || true
    echo "  ⏭️  wslu は最新版です"
  fi

  echo "✅ 基本CLIツールインストール完了"
}

# 3. Gitツールのインストール
install_git_tools() {
  [ "$INSTALL_GIT_TOOLS" != "1" ] && return

  echo ""
  echo "🔧 バージョン管理ツールをインストール中..."

  # Git公式PPAが既に追加されているかチェック
  if ! compgen -G "/etc/apt/sources.list.d/git-core-ubuntu-ppa-*.list" >/dev/null 2>&1; then
    sudo add-apt-repository -y ppa:git-core/ppa >/dev/null
    sudo apt-get update >/dev/null
  fi

  # Git のインストール・アップデート
  if ! command -v git &>/dev/null; then
    sudo apt-get install -y git
    echo "  ✅ Git インストール完了"
  else
    sudo apt-get install -y --only-upgrade git >/dev/null 2>&1
    echo "  ⏭️  Git は最新安定版です"
  fi

  # GitHub CLI のインストール・アップデート
  if ! command -v gh &>/dev/null; then
    # GitHub CLI公式リポジトリを追加
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg >/dev/null 2>&1
    sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
    sudo apt-get update >/dev/null 2>&1
    sudo apt-get install -y gh
    echo "  ✅ GitHub CLI インストール完了"
  else
    sudo apt-get update >/dev/null 2>&1
    sudo apt-get install -y --only-upgrade gh >/dev/null 2>&1
    echo "  ⏭️  GitHub CLI は最新安定版です"
  fi

  # gitleaks は mise 経由で導入（install_mise_and_languages の後で実行）
  # シークレットスキャンはプロジェクト単位で lefthook 等のフックに組み込む運用を想定

  echo "✅ バージョン管理ツールインストール完了"
}

# mise を初期化（未インストールならインストール、既存なら自己更新）
# 複数の install 関数から共通利用される冪等なエントリーポイント
ensure_mise_installed() {
  # 既に初期化済みの場合は再実行しない（同一セッション内のガード）
  if [ "${_MISE_INITIALIZED:-0}" = "1" ]; then
    return 0
  fi

  echo ""
  echo "⚡ mise（バージョン管理）を準備中..."

  if ! [ -x "$MISE_BIN" ]; then
    # 注意: curl | sh パターンは mise 公式のインストール方法（HTTPS使用）
    if ! curl -fsSL https://mise.run | sh >/dev/null 2>&1; then
      echo "⚠️  mise のインストールに失敗しました"
      echo "ℹ️  考えられる原因:"
      echo "    - ネットワーク接続の問題"
      echo "    - curl が利用できない"
      echo "ℹ️  対処法:"
      echo "    1. ネットワーク接続を確認"
      echo "    2. curl のインストール状態を確認: command -v curl"
      echo "ℹ️  手動で確認: curl -fsSL https://mise.run | sh"
      return 1
    fi
    echo "  ✅ mise インストール完了"
  else
    echo "  ℹ️  mise を最新版に更新中..."
    "$MISE_BIN" self-update -y >/dev/null 2>&1 || true
    echo "  ⏭️  mise は最新版です ($("$MISE_BIN" --version 2>/dev/null | head -n1))"
  fi

  # 以降のコマンドで mise とそのシム（node, npm, python, gitleaks 等）を使えるようにする
  export PATH="$HOME/.local/share/mise/shims:$HOME/.local/bin:$PATH"

  # シェル統合（mise activate）を設定
  # 注意: パターンは書き込まれた文字列内に実在する部分列を使う必要がある。
  # eval 行には `" activate zsh)"` のように途中に `"` が入るため、
  # コメント行の固定文字列（"# mise（バージョン管理）"）をアンカーとして利用する。
  add_to_shell_config ~/.zshrc '# mise（バージョン管理）' '# mise（バージョン管理）
eval "$("$HOME/.local/bin/mise" activate zsh)"' "~/.zshrc に mise 初期化を追加しました"
  add_to_shell_config ~/.bashrc '# mise（バージョン管理）' '# mise（バージョン管理）
eval "$("$HOME/.local/bin/mise" activate bash)"' "~/.bashrc に mise 初期化を追加しました"

  _MISE_INITIALIZED=1
  return 0
}

# 4. mise + 言語環境のインストール
# mise を土台として Node.js / pnpm / Python / uv を統一管理
install_mise_and_languages() {
  # Node または Python のいずれかが必要な場合のみ処理
  if [ "$INSTALL_NODE" != "1" ] && [ "$INSTALL_PYTHON" != "1" ]; then
    return
  fi

  ensure_mise_installed || return 1

  # Node.js + pnpm を mise で導入
  if [ "$INSTALL_NODE" = "1" ]; then
    echo ""
    echo "📦 Node.js と pnpm を mise でインストール中..."
    mise_use_global "node@lts" "Node.js LTS"
    mise_use_global "pnpm@latest" "pnpm"
  fi

  # Python + uv を mise で導入
  if [ "$INSTALL_PYTHON" = "1" ]; then
    echo ""
    echo "🐍 Python と uv を mise でインストール中..."
    mise_use_global "python@latest" "Python"
    mise_use_global "uv@latest" "uv"
  fi

  echo "✅ mise + 言語環境インストール完了"
}

# 5. Git セキュリティツール（gitleaks）のインストール
# git-secrets（メンテ停滞）の後継として gitleaks を mise 経由で導入
install_git_security_tools() {
  [ "$INSTALL_GIT_TOOLS" != "1" ] && return

  ensure_mise_installed || return 1

  echo ""
  echo "🔒 Git セキュリティツールをインストール中..."
  mise_use_global "gitleaks@latest" "gitleaks"
  echo "✅ Git セキュリティツールインストール完了"
}

# mise でグローバルツールを導入する汎用ヘルパー
# $1: tool_spec（例: node@lts, python@latest, gitleaks@latest）
# $2: display_name（表示名）
mise_use_global() {
  local tool_spec="$1"
  local display_name="$2"
  local tool_name="${tool_spec%%@*}"

  if ! [ -x "$MISE_BIN" ]; then
    echo "  ⚠️  mise が利用できません（$display_name はスキップ）"
    return 1
  fi

  # 既にグローバル設定済みかを確認
  if "$MISE_BIN" ls --global 2>/dev/null | awk '{print $1}' | grep -qx "$tool_name"; then
    "$MISE_BIN" use --global "$tool_spec" >/dev/null 2>&1 || true
    "$MISE_BIN" install "$tool_spec" >/dev/null 2>&1 || true
    echo "  ⏭️  $display_name は導入済み・最新化しました"
  else
    if "$MISE_BIN" use --global "$tool_spec" >/dev/null; then
      echo "  ✅ $display_name インストール完了"
    else
      echo "  ⚠️  $display_name のインストールに失敗しました"
      echo "ℹ️  手動で確認: mise use --global $tool_spec"
      return 1
    fi
  fi
}

# 6. コンテナツールのインストール
install_container_tools() {
  [ "$INSTALL_CONTAINER" != "1" ] && return

  echo ""
  echo "🐳 コンテナツールをインストール中..."

  # Docker のインストール・アップデート
  if ! command -v docker &>/dev/null; then
    if install_docker_engine_and_compose; then
      echo "  ✅ Docker + Docker Compose インストール完了"
    else
      echo "  ⚠️  Docker のインストールに失敗しました"
      return 1
    fi
  else
    echo "  ℹ️  Docker を最新安定版に更新中..."
    setup_docker_repository
    sudo apt-get update >/dev/null 2>&1
    sudo apt-get install -y --only-upgrade docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin >/dev/null 2>&1
    echo "  ⏭️  Docker は最新安定版です"
  fi

  # Docker サービスの起動
  if ! sudo service docker status >/dev/null 2>&1; then
    sudo service docker start >/dev/null
    echo "  ✅ Docker サービス起動完了"
  else
    echo "  ⏭️  Docker サービスは既に起動しています"
  fi

  # 現在のユーザーを docker グループに追加
  if ! groups | grep -q docker; then
    sudo usermod -aG docker "$USER"
    echo "  ✅ dockerグループに追加しました（次回ログイン時から有効）"
  else
    echo "  ⏭️  既にdockerグループに所属しています"
  fi

  echo "✅ コンテナツールインストール完了"
}

# 7. クラウドツールのインストール
install_cloud_tools() {
  local any_installed=0

  # AWS CLI
  if [ "$INSTALL_AWS_CLI" = "1" ]; then
    [ "$any_installed" = "0" ] && {
      echo ""
      echo "☁️ クラウドツールをインストール中..."
      any_installed=1
    }

    if ! command -v aws &>/dev/null; then
      curl "https://awscli.amazonaws.com/awscli-exe-linux-$(uname -m).zip" -o "/tmp/awscliv2.zip"
      unzip -q /tmp/awscliv2.zip -d /tmp
      sudo /tmp/aws/install >/dev/null
      rm -rf /tmp/aws /tmp/awscliv2.zip
      echo "  ✅ AWS CLI インストール完了"
    else
      echo "  ℹ️  AWS CLI を最新版に更新中..."
      curl "https://awscli.amazonaws.com/awscli-exe-linux-$(uname -m).zip" -o "/tmp/awscliv2.zip"
      unzip -q /tmp/awscliv2.zip -d /tmp
      sudo /tmp/aws/install --update >/dev/null 2>&1
      rm -rf /tmp/aws /tmp/awscliv2.zip
      echo "  ⏭️  AWS CLI は最新版です"
    fi
  fi

  # Azure CLI
  if [ "$INSTALL_AZURE_CLI" = "1" ]; then
    [ "$any_installed" = "0" ] && {
      echo ""
      echo "☁️ クラウドツールをインストール中..."
      any_installed=1
    }

    if ! command -v az &>/dev/null; then
      curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
      echo "  ✅ Azure CLI インストール完了"
    else
      echo "  ℹ️  Azure CLI を最新版に更新中..."
      sudo apt-get update >/dev/null 2>&1
      if sudo apt-get install -y --only-upgrade azure-cli >/dev/null 2>&1; then
        echo "  ⏭️  Azure CLI は最新版です"
      else
        # パッケージが見つからない場合は再インストール
        curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash >/dev/null 2>&1
        echo "  ⏭️  Azure CLI は最新版です"
      fi
    fi
  fi

  # Google Cloud CLI
  if [ "$INSTALL_GCLOUD_CLI" = "1" ]; then
    [ "$any_installed" = "0" ] && {
      echo ""
      echo "☁️ クラウドツールをインストール中..."
      any_installed=1
    }

    if ! command -v gcloud &>/dev/null; then
      echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" |
        sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list >/dev/null
      curl https://packages.cloud.google.com/apt/doc/apt-key.gpg |
        sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add - >/dev/null 2>&1
      sudo apt-get update >/dev/null 2>&1
      sudo apt-get install -y google-cloud-cli >/dev/null
      echo "  ✅ Google Cloud CLI インストール完了"
    else
      echo "  ℹ️  Google Cloud CLI を最新版に更新中..."
      sudo apt-get update >/dev/null 2>&1
      if sudo apt-get install -y --only-upgrade google-cloud-cli >/dev/null 2>&1; then
        echo "  ⏭️  Google Cloud CLI は最新版です"
      else
        # パッケージが見つからない場合はスキップ（既にインストール済み）
        echo "  ⏭️  Google Cloud CLI は既にインストール済みです"
      fi
    fi
  fi

  [ "$any_installed" = "1" ] && echo "✅ クラウドツールインストール完了"
}

# 8. AIツールのインストール
install_ai_tools() {
  local any_installed=0

  # Claude Code（Native Install — 自動更新対応）
  if [ "$INSTALL_CLAUDE_CODE" = "1" ]; then
    [ "$any_installed" = "0" ] && {
      echo ""
      echo "🤖 AIツールをインストール中..."
      any_installed=1
    }

    if ! command -v claude &>/dev/null; then
      curl -fsSL https://claude.ai/install.sh | bash >/dev/null 2>&1
      echo "  ✅ Claude Code インストール完了"
    else
      echo "  ℹ️  Claude Code を最新版に更新中..."
      timeout 10 claude update </dev/null >/dev/null 2>&1 || true
      echo "  ⏭️  Claude Code は最新版です ($(claude --version 2>/dev/null || echo '不明'))"
    fi
  fi

  # Codex CLI
  if [ "$INSTALL_CODEX_CLI" = "1" ]; then
    [ "$any_installed" = "0" ] && {
      echo ""
      echo "🤖 AIツールをインストール中..."
      any_installed=1
    }

    if ! command -v codex &>/dev/null; then
      npm install -g @openai/codex
      echo "  ✅ Codex CLI インストール完了"
    else
      echo "  ℹ️  Codex CLI を最新版に更新中..."
      npm update -g @openai/codex >/dev/null 2>&1 || true
      echo "  ⏭️  Codex CLI は最新版です"
    fi
  fi

  # GitHub Copilot CLI（Install Script — 自動更新対応）
  if [ "$INSTALL_COPILOT_CLI" = "1" ]; then
    [ "$any_installed" = "0" ] && {
      echo ""
      echo "🤖 AIツールをインストール中..."
      any_installed=1
    }

    # VS Code 拡張の shim（~/.vscode-server/...）はスタンドアロン CLI ではないため除外
    local copilot_path
    copilot_path=$(command -v copilot 2>/dev/null || true)
    if [ -z "$copilot_path" ] || [[ "$copilot_path" == *".vscode-server"* ]]; then
      curl -fsSL https://gh.io/copilot-install | bash >/dev/null 2>&1
      echo "  ✅ GitHub Copilot CLI インストール完了"
    else
      echo "  ℹ️  GitHub Copilot CLI を最新版に更新中..."
      timeout 10 copilot update </dev/null >/dev/null 2>&1 || true
      echo "  ⏭️  GitHub Copilot CLI は最新版です ($(copilot --version 2>/dev/null | head -n1 || echo '不明'))"
    fi
  fi

  # Gemini CLI
  if [ "$INSTALL_GEMINI_CLI" = "1" ]; then
    [ "$any_installed" = "0" ] && {
      echo ""
      echo "🤖 AIツールをインストール中..."
      any_installed=1
    }

    if ! command -v gemini &>/dev/null; then
      npm install -g @google/gemini-cli
      echo "  ✅ Gemini CLI インストール完了"
    else
      echo "  ℹ️  Gemini CLI を最新版に更新中..."
      npm update -g @google/gemini-cli >/dev/null 2>&1 || true
      echo "  ⏭️  Gemini CLI は最新版です"
    fi
  fi

  # mise 管理下の node で npm グローバルインストールした CLI のシムを生成
  # （Codex / Gemini 等の新規バイナリを ~/.local/share/mise/shims 経由で使えるようにする）
  if [ "$any_installed" = "1" ] && [ -x "$MISE_BIN" ]; then
    "$MISE_BIN" reshim >/dev/null 2>&1 || true
  fi

  [ "$any_installed" = "1" ] && echo "✅ AIツールインストール完了"
}

# 9. AI パワーツールのインストール
# AI エージェントの文書読み込み・コード検索・データ操作を強化するツール群
# - markitdown: PDF/Office/画像/音声 → Markdown 変換（uv tool）
# - tesseract-ocr(+jpn): OCR 基盤（apt、markitdown の画像/PDF 対応を有効化）
# - ffmpeg: 音声・動画処理基盤（apt、markitdown の音声転写を有効化）
# - ast-grep: 構造的コード検索・置換（mise）
# - yq: YAML クエリツール（mise、jq の YAML 版）
install_ai_power_tools() {
  [ "$INSTALL_AI_POWER_TOOLS" != "1" ] && return

  ensure_mise_installed || return 1

  echo ""
  echo "🧠 AI パワーツールをインストール中..."

  # apt: OS 依存ライブラリ（markitdown の OCR/音声機能を有効化）
  local apt_targets=(tesseract-ocr tesseract-ocr-jpn ffmpeg)
  local apt_pkg
  for apt_pkg in "${apt_targets[@]}"; do
    if ! dpkg -l "$apt_pkg" 2>/dev/null | grep -q "^ii"; then
      sudo apt-get install -y "$apt_pkg"
      echo "  ✅ $apt_pkg インストール完了"
    else
      sudo apt-get install -y --only-upgrade "$apt_pkg" >/dev/null 2>&1
      echo "  ⏭️  $apt_pkg は最新版です"
    fi
  done

  # mise: 横断的な CLI ツール（バージョン固定・一括更新が容易）
  mise_use_global "ast-grep@latest" "ast-grep"
  mise_use_global "yq@latest" "yq"

  # uv tool: Python 製 AI 向け文書変換 CLI
  # uv はすでに mise 経由で導入済み想定。念のためコマンド存在確認
  if command -v uv &>/dev/null; then
    if ! uv tool list 2>/dev/null | grep -q "^markitdown"; then
      uv tool install "markitdown[all]" >/dev/null
      echo "  ✅ markitdown[all] インストール完了"
    else
      uv tool upgrade markitdown >/dev/null 2>&1 || true
      echo "  ⏭️  markitdown は導入済み・最新化しました"
    fi
  else
    echo "  ⚠️  uv が見つからないため markitdown はスキップしました"
    echo "ℹ️  対処法: Python 環境（mise + uv）を有効にして再実行してください"
  fi

  echo "✅ AI パワーツールインストール完了"
}

# 10. 開発補助ツールのインストール
install_dev_tools() {
  [ "$INSTALL_DEV_TOOLS" != "1" ] && return

  echo ""
  echo "🛠️ 開発補助ツールをインストール中..."

  ensure_mise_installed || return 1

  # just / zoxide / shellcheck をすべて mise 経由で導入
  # （公式インストーラは GitHub API レートリミットで詰まりやすいため mise に統一）
  mise_use_global "just@latest" "just"
  mise_use_global "zoxide@latest" "zoxide"
  mise_use_global "shellcheck@latest" "shellcheck"

  # zoxide のシェル初期化を追加（初回のみ）
  add_to_shell_config ~/.bashrc "zoxide init bash" 'eval "$(zoxide init bash)"' "~/.bashrc に zoxide 初期化を追加しました"
  add_to_shell_config ~/.zshrc "zoxide init zsh" 'eval "$(zoxide init zsh)"' "~/.zshrc に zoxide 初期化を追加しました"

  echo "✅ 開発補助ツールインストール完了"
}

# ========================================
# Docker関連のヘルパー関数
# ========================================

# Docker Compose (CLIプラグイン) をインストールするフォールバック実装
install_docker_compose_binary() {
  local compose_version="${DOCKER_COMPOSE_VERSION:-v2.27.0}"
  local arch
  case "$(uname -m)" in
  x86_64 | amd64)
    arch="x86_64"
    ;;
  aarch64 | arm64)
    arch="aarch64"
    ;;
  *)
    echo "  ⚠️  未対応アーキテクチャ ($(uname -m)) のため、Docker Compose バイナリの自動インストールに失敗しました"
    return 1
    ;;
  esac

  local plugin_dir="$HOME/.docker/cli-plugins"
  mkdir -p "$plugin_dir"

  echo "  ℹ️  Docker Compose バイナリ (${compose_version}, ${arch}) をダウンロードしています..."
  if curl -fsSL "https://github.com/docker/compose/releases/download/${compose_version}/docker-compose-linux-${arch}" \
    -o "${plugin_dir}/docker-compose"; then
    chmod +x "${plugin_dir}/docker-compose"
    echo "  ✅ Docker Compose バイナリを ${plugin_dir} に配置しました"
    return 0
  fi

  echo "  ⚠️  Docker Compose バイナリのダウンロードに失敗しました"
  return 1
}

# Docker Engine と Compose Plugin をインストールする関数
install_docker_engine_and_compose() {
  setup_docker_repository

  # Docker Engine + Compose Plugin をインストール
  if sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin; then
    return 0
  fi

  echo "  ⚠️  Docker 公式パッケージのインストールに失敗しました"
  return 1
}

# ========================================
# メイン処理開始
# ========================================

# ログ出力機能（SETUP_LOG 環境変数が設定されている場合）
if [ -n "$SETUP_LOG" ]; then
  # SETUP_LOG=1 または SETUP_LOG=true の場合はデフォルトパスを使用
  if [ "$SETUP_LOG" = "1" ] || [ "$SETUP_LOG" = "true" ]; then
    LOG_FILE="$HOME/setup-local-ubuntu-$(date +%Y%m%d-%H%M%S).log"
  else
    LOG_FILE="$SETUP_LOG"
  fi
  # プロセス置換と tee を使って標準出力とログファイルの両方に出力
  # exec: 現在のシェルの stdout/stderr をリダイレクト
  # tee -a: 標準出力とファイルの両方に追記（-a: append mode）
  exec > >(tee -a "$LOG_FILE") 2>&1
  echo "ℹ️  ログを $LOG_FILE に記録します"
fi

echo "🚀 WSL2/Ubuntu ローカル環境セットアップ開始"
echo ""

# ========================================
# 1. 環境チェック
# ========================================

# スクリプトの実行環境チェック
if [ ! -f /etc/os-release ]; then
  echo "⚠️  このスクリプトは Linux 環境でのみ実行できます"
  exit 1
fi

# Ubuntu/Debian系ディストリビューションのチェック
if ! grep -qi "ubuntu\|debian" /etc/os-release 2>/dev/null; then
  echo "⚠️  このスクリプトは Ubuntu/Debian 系ディストリビューション用です"
  echo "ℹ️  現在の OS: $(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)"
  _prompt_default_no "続行しますか？ (y/N): "
  echo
  echo "ℹ️  ユーザー入力: $REPLY" # ログに記録
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "スクリプトを中止しました"
    exit 1
  fi
fi

echo "✅ 実行環境チェック完了"
echo ""

# ========================================
# 2. ツールの選択
# ========================================

# インストール対象ツールの選択
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 インストール対象ツールの選択"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "インストール可能なツール:"
echo "  📌 基本CLIツール - tree, fzf, jq, ripgrep, fd, unzip, wslu"
echo "  🔧 ビルドツール - build-essential"
echo "  🔧 Git関連ツール - Git, GitHub CLI, gitleaks"
echo "  📦 Node.js環境 - mise, Node.js LTS, pnpm"
echo "  🐍 Python環境 - mise, Python, uv"
echo "  🐳 コンテナツール - Docker Engine, Docker Compose"
echo "  ☁️ クラウドツール - AWS CLI (default) / Azure CLI, Google Cloud CLI (opt-in)"
echo "  🤖 AIエージェント CLI - Claude Code, Codex CLI, GitHub Copilot CLI, Gemini CLI"
echo "  🧠 AIパワーツール - markitdown, tesseract-ocr, ffmpeg, ast-grep, yq"
echo "  🛠️ 開発補助ツール - just, zoxide, shellcheck"
echo ""
echo "すべてのツールをインストールしますか？"
echo "  y: すべてインストール（デフォルト）"
echo "  n: 個別に選択"
echo ""
if _is_non_interactive; then
  INSTALL_ALL=Y
  echo "選択 [Y/n]: Y (non-interactive)"
else
  INSTALL_ALL=""
  read -p "選択 [Y/n]: " -n 1 -r INSTALL_ALL || true
  echo ""
fi
echo "ℹ️  ユーザー入力: ${INSTALL_ALL:-Y}"

if [[ ! $INSTALL_ALL =~ ^[Yy]?$ ]]; then
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "各カテゴリのインストール設定"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  # 基本CLIツール
  _prompt_default_yes "📌 基本CLIツール (tree, fzf, jq, ripgrep, fd) をインストールしますか? [Y/n]: "
  echo ""
  [[ $REPLY =~ ^[Nn]$ ]] && INSTALL_BASIC_CLI=0

  # ビルドツール
  _prompt_default_yes "🔧 ビルドツール (build-essential) をインストールしますか? [Y/n]: "
  echo ""
  [[ $REPLY =~ ^[Nn]$ ]] && INSTALL_BUILD_TOOLS=0

  # Git関連ツール
  _prompt_default_yes "🔧 Git関連ツール (Git, GitHub CLI, gitleaks) をインストールしますか? [Y/n]: "
  echo ""
  [[ $REPLY =~ ^[Nn]$ ]] && INSTALL_GIT_TOOLS=0

  # Node.js環境
  _prompt_default_yes "📦 Node.js環境 (mise, Node.js, pnpm) をインストールしますか? [Y/n]: "
  echo ""
  [[ $REPLY =~ ^[Nn]$ ]] && INSTALL_NODE=0

  # Python環境
  _prompt_default_yes "🐍 Python環境 (mise, Python, uv) をインストールしますか? [Y/n]: "
  echo ""
  [[ $REPLY =~ ^[Nn]$ ]] && INSTALL_PYTHON=0

  # コンテナツール
  _prompt_default_yes "🐳 コンテナツール (Docker, Docker Compose) をインストールしますか? [Y/n]: "
  echo ""
  [[ $REPLY =~ ^[Nn]$ ]] && INSTALL_CONTAINER=0

  # クラウドツール（個別。AWS はデフォルト ON、Azure/GCP は opt-in）
  echo ""
  echo "☁️ クラウドツール:"
  _prompt_default_yes "  AWS CLI をインストールしますか? [Y/n]: "
  echo ""
  [[ $REPLY =~ ^[Nn]$ ]] && INSTALL_AWS_CLI=0

  _prompt_default_no "  Azure CLI をインストールしますか? [y/N]: "
  echo ""
  [[ $REPLY =~ ^[Yy]$ ]] && INSTALL_AZURE_CLI=1

  _prompt_default_no "  Google Cloud CLI をインストールしますか? [y/N]: "
  echo ""
  [[ $REPLY =~ ^[Yy]$ ]] && INSTALL_GCLOUD_CLI=1

  # AIエージェント CLI（個別）
  echo ""
  echo "🤖 AIエージェント CLI:"
  _prompt_default_yes "  Claude Code をインストールしますか? [Y/n]: "
  echo ""
  [[ $REPLY =~ ^[Nn]$ ]] && INSTALL_CLAUDE_CODE=0

  _prompt_default_yes "  Codex CLI をインストールしますか? [Y/n]: "
  echo ""
  [[ $REPLY =~ ^[Nn]$ ]] && INSTALL_CODEX_CLI=0

  _prompt_default_yes "  GitHub Copilot CLI をインストールしますか? [Y/n]: "
  echo ""
  [[ $REPLY =~ ^[Nn]$ ]] && INSTALL_COPILOT_CLI=0

  _prompt_default_yes "  Gemini CLI をインストールしますか? [Y/n]: "
  echo ""
  [[ $REPLY =~ ^[Nn]$ ]] && INSTALL_GEMINI_CLI=0

  # AIパワーツール
  echo ""
  _prompt_default_yes "🧠 AIパワーツール (markitdown, tesseract-ocr, ffmpeg, ast-grep, yq) をインストールしますか? [Y/n]: "
  echo ""
  [[ $REPLY =~ ^[Nn]$ ]] && INSTALL_AI_POWER_TOOLS=0

  # 開発補助ツール
  echo ""
  _prompt_default_yes "🛠️ 開発補助ツール (just, zoxide, shellcheck) をインストールしますか? [Y/n]: "
  echo ""
  [[ $REPLY =~ ^[Nn]$ ]] && INSTALL_DEV_TOOLS=0
fi

echo ""
echo "✅ インストール対象ツールの選択完了"
echo ""

# ========================================
# 3. 初期設定（ユーザー入力）
# ========================================

# ユーザー入力セクション（まとめて最初に実行）
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 初期設定（ユーザー入力が必要な項目）"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# sudo パスワード確認（最初に実行してキャッシュ）
echo "🔐 sudo パスワードの確認..."
if sudo -v; then
  echo "✅ sudo パスワード確認完了"
else
  echo "⚠️  sudo パスワードの確認に失敗しました"
  exit 1
fi
echo ""

# Git ユーザー情報の事前確認・設定
echo "🔧 Git ユーザー情報の確認..."

# user.name の確認・設定
if ! git config --global user.name &>/dev/null || [ -z "$(git config --global user.name)" ]; then
  echo ""
  echo "📝 Git ユーザー名が未設定です"
  read -e -p "Git ユーザー名を入力してください（例: Taro Yamada）: " -i "$USER" git_user_name
  echo "ℹ️  入力値: $git_user_name" # ログに記録
  # 空白文字のみの入力をチェック
  if [ -n "$git_user_name" ] && [ -n "${git_user_name// /}" ]; then
    git config --global user.name "$git_user_name"
    echo "  ✅ user.name を設定しました: $git_user_name"
  else
    echo "  ⚠️  ユーザー名が入力されませんでした（後で 'git config --global user.name \"Your Name\"' で設定してください）"
  fi
else
  echo "  ⏭️  user.name は既に設定済み: $(git config --global user.name)"
fi

# user.email の確認・設定
if ! git config --global user.email &>/dev/null || [ -z "$(git config --global user.email)" ]; then
  echo ""
  echo "📝 Git メールアドレスが未設定です"
  read -e -p "Git メールアドレスを入力してください（例: your.email@example.com）: " git_user_email
  echo "ℹ️  入力値: $git_user_email" # ログに記録
  if [ -n "$git_user_email" ]; then
    # 基本的なメールアドレス形式のバリデーション
    if [[ "$git_user_email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
      git config --global user.email "$git_user_email"
      echo "  ✅ user.email を設定しました: $git_user_email"
    else
      echo "  ⚠️  無効なメールアドレス形式です（後で 'git config --global user.email \"you@example.com\"' で設定してください）"
    fi
  else
    echo "  ⚠️  メールアドレスが入力されませんでした（後で 'git config --global user.email \"you@example.com\"' で設定してください）"
  fi
else
  echo "  ⏭️  user.email は既に設定済み: $(git config --global user.email)"
fi

echo ""
echo "✅ 初期設定完了"
echo ""

# ========================================
# 4. システムパッケージの更新と環境設定
# ========================================

# Locale と Timezone の設定
echo "🌏 ロケールとタイムゾーンを設定中..."

# タイムゾーンの設定（JST）
if [ "$(cat /etc/timezone 2>/dev/null)" != "Asia/Tokyo" ]; then
  sudo timedatectl set-timezone Asia/Tokyo 2>/dev/null || sudo ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime
  echo "  ✅ タイムゾーンを Asia/Tokyo に設定しました"
else
  echo "  ⏭️  タイムゾーンは既に Asia/Tokyo に設定済み"
fi

# ロケールの設定（ja_JP.UTF-8）
if ! locale -a 2>/dev/null | grep -q "^ja_JP.utf8"; then
  sudo apt-get install -y locales
  sudo locale-gen ja_JP.UTF-8
  echo "  ✅ ja_JP.UTF-8 ロケールを生成しました"
else
  echo "  ⏭️  ja_JP.UTF-8 ロケールは既に生成済み"
fi

# LANG 環境変数の設定
add_to_shell_config ~/.zshrc "export LANG=ja_JP.UTF-8" "export LANG=ja_JP.UTF-8" "~/.zshrc に LANG を設定しました"
add_to_shell_config ~/.bashrc "export LANG=ja_JP.UTF-8" "export LANG=ja_JP.UTF-8" "~/.bashrc に LANG を設定しました"

echo "✅ ロケールとタイムゾーン設定完了"
echo ""

# devcontainer マウント用のディレクトリ/ファイル作成
echo "📁 devcontainer マウント用のディレクトリ/ファイルを準備中..."

# ディレクトリの作成（存在しない場合のみ）
if [ ! -d ~/.aws ]; then
  mkdir -p ~/.aws
  echo "  ✅ ~/.aws を作成しました"
fi

if [ ! -d ~/.claude ]; then
  mkdir -p ~/.claude
  echo "  ✅ ~/.claude を作成しました"
fi

if [ ! -d ~/.gemini ]; then
  mkdir -p ~/.gemini
  echo "  ✅ ~/.gemini を作成しました"
fi

if [ ! -d ~/.config/gh ]; then
  mkdir -p ~/.config/gh
  echo "  ✅ ~/.config/gh を作成しました"
fi

if [ ! -d ~/.local/share/pnpm ]; then
  mkdir -p ~/.local/share/pnpm
  echo "  ✅ ~/.local/share/pnpm を作成しました"
fi

# PNPM_HOME の設定（未設定の場合のみ）
# pnpm がグローバルパッケージをインストールするディレクトリを指定
if [ -z "$PNPM_HOME" ]; then
  export PNPM_HOME="$HOME/.local/share/pnpm"
  echo "  ✅ PNPM_HOME を $PNPM_HOME に設定しました"
else
  echo "  ⏭️  PNPM_HOME は既に $PNPM_HOME に設定済み"
fi

# 現在のシェルセッションの PATH に PNPM_HOME を追加
# （永続的な設定は後続の「PATH 環境変数を設定中」セクションで行う）
# パターンマッチング: ":$PATH:" の中に ":$PNPM_HOME:" が含まれているかチェック
if [[ ":$PATH:" != *":$PNPM_HOME:"* ]]; then
  export PATH="$PNPM_HOME:$PATH"
  echo "  ✅ PATH に PNPM_HOME ($PNPM_HOME) を追加しました"
else
  echo "  ⏭️  PATH には既に PNPM_HOME ($PNPM_HOME) が含まれています"
fi

# ファイルの作成（存在しない場合のみ）
# zsh を使用している場合のみ .zsh_history を作成
if [ -f ~/.zshrc ] && [ ! -f ~/.zsh_history ]; then
  touch ~/.zsh_history
  echo "  ✅ ~/.zsh_history を作成しました"
fi

if [ ! -f ~/.gitconfig ]; then
  touch ~/.gitconfig
  echo "  ✅ ~/.gitconfig を作成しました"
fi

# Claude設定ファイル（存在しない場合はデフォルト設定で作成）
if [ ! -f ~/.claude.json ]; then
  echo '{}' >~/.claude.json
  echo "  ✅ ~/.claude.json を作成しました"
fi

echo "✅ devcontainer マウント用ファイル準備完了"
echo ""

# 基本パッケージの更新と必要なビルドツールのインストール
echo "📦 システムパッケージを更新中..."
if sudo apt-get update >/dev/null; then
  echo "✅ システムパッケージ更新完了"
else
  echo "⚠️  システムパッケージの更新に失敗しました"
  echo "ℹ️  考えられる原因:"
  echo "    - ネットワーク接続の問題"
  echo "    - パッケージリポジトリの障害"
  echo "    - /etc/apt/sources.list の設定ミス"
  echo "ℹ️  手動で確認: sudo apt-get update"
  exit 1
fi

# 依存パッケージのインストール
echo ""
echo "🔧 依存パッケージをインストール中..."

# curl のインストール（Volta、uv、AWS CLI等に必要）
if ! command -v curl &>/dev/null; then
  sudo apt-get install -y curl
  echo "  ✅ curl インストール完了"
else
  echo "  ⏭️  curl は既にインストール済み"
fi

# git のインストール（最新安定版）
echo ""
echo "🔧 Git（最新安定版）をインストール中..."

# Git公式PPAが既に追加されているかチェック
if ! compgen -G "/etc/apt/sources.list.d/git-core-ubuntu-ppa-*.list" >/dev/null 2>&1; then
  echo "  ℹ️  Git公式PPAを追加しています..."
  # add-apt-repository は software-properties-common パッケージに含まれる
  if ! command -v add-apt-repository &>/dev/null; then
    sudo apt-get install -y software-properties-common >/dev/null
  fi
  # -y: 自動的に yes と応答
  sudo add-apt-repository -y ppa:git-core/ppa >/dev/null
  sudo apt-get update >/dev/null
  echo "  ✅ Git公式PPAを追加しました"
fi

if ! command -v git &>/dev/null; then
  sudo apt-get install -y git
  echo "✅ Git インストール完了"
else
  # 既にインストール済みの場合も、最新版にアップデート
  CURRENT_VERSION=$(git --version 2>/dev/null | awk '{print $3}')
  sudo apt-get install -y --only-upgrade git >/dev/null 2>&1
  NEW_VERSION=$(git --version 2>/dev/null | awk '{print $3}')

  if [ "$CURRENT_VERSION" != "$NEW_VERSION" ]; then
    echo "✅ Git を最新安定版にアップデートしました ($CURRENT_VERSION → $NEW_VERSION)"
  else
    echo "⏭️  Git は既に最新安定版です ($CURRENT_VERSION)"
  fi
fi

echo "✅ 依存パッケージインストール完了"

# ========================================
# 5. インストール処理（関数呼び出し）
# ========================================
# 注意: 依存関係の順序で実行されます
# 1. ビルド → 2. 基本CLI → 3. Git (git, gh) → 4. mise + 言語環境
# → 5. Git セキュリティ (gitleaks) → 6. コンテナ → 7. クラウド → 8. AIエージェント
# → 9. AI パワーツール → 10. 開発補助

# 1. ビルドツールのインストール
install_build_tools

# 2. 基本CLIツールのインストール
install_basic_cli_tools

# 3. Gitツールのインストール
install_git_tools

# 4. mise + 言語環境のインストール（Node.js + pnpm + Python + uv）
install_mise_and_languages

# 5. Git セキュリティツール（gitleaks、mise 経由）
install_git_security_tools

# 6. コンテナツールのインストール
install_container_tools

# 7. クラウドツールのインストール
install_cloud_tools

# 8. AIエージェント CLI のインストール
install_ai_tools

# 9. AI パワーツールのインストール（markitdown, tesseract-ocr, ffmpeg, ast-grep, yq）
install_ai_power_tools

# 10. 開発補助ツールのインストール
install_dev_tools

# ========================================
# 6. 環境設定（PATH、Git設定等）
# ========================================
# 注意: mise activate は install_mise_and_languages で追加済みのため、
# ここでは ~/.local/bin と pnpm の PATH のみを設定する

# Git の追加設定
if command -v git &>/dev/null; then
  echo ""
  echo "🔧 Git のその他の設定を行っています..."

  # デフォルトブランチ名を main に設定
  if ! git config --global init.defaultBranch &>/dev/null || [ -z "$(git config --global init.defaultBranch)" ]; then
    git config --global init.defaultBranch main
    echo "  ✅ init.defaultBranch を main に設定しました"
  else
    echo "  ⏭️  init.defaultBranch は既に $(git config --global init.defaultBranch) に設定済み"
  fi

  # エディタを vim に設定（未設定の場合のみ）
  if ! git config --global core.editor &>/dev/null || [ -z "$(git config --global core.editor)" ]; then
    git config --global core.editor vim
    echo "  ✅ core.editor を vim に設定しました"
  else
    echo "  ⏭️  core.editor は既に $(git config --global core.editor) に設定済み"
  fi

  # 改行コード自動変換設定（WSL2 では input が推奨）
  if [ "$(git config --global core.autocrlf)" != "input" ]; then
    git config --global core.autocrlf input
    echo "  ✅ core.autocrlf を input に設定しました（コミット時にCRLF→LF変換）"
  else
    echo "  ⏭️  core.autocrlf は既に input に設定済み"
  fi

  # ファイルの実行権限を追跡（WSL2 でのファイル権限管理）
  if [ "$(git config --global core.fileMode)" != "true" ]; then
    git config --global core.fileMode true
    echo "  ✅ core.fileMode を true に設定しました（実行権限追跡）"
  else
    echo "  ⏭️  core.fileMode は既に true に設定済み"
  fi

  # git pull 時の rebase をデフォルトに
  if [ "$(git config --global pull.rebase)" != "false" ]; then
    git config --global pull.rebase false
    echo "  ✅ pull.rebase を false に設定しました"
  else
    echo "  ⏭️  pull.rebase は既に false に設定済み"
  fi

  # gitleaks はプロジェクト単位のフック（lefthook / pre-commit 等）で
  # 運用する前提のため、グローバルフックは設定しない

  echo "✅ Git 設定完了"
fi

# BROWSER 環境変数の設定（WSL2 でブラウザを開くために必要）
echo ""
echo "🌐 BROWSER 環境変数を設定中..."
add_to_shell_config ~/.zshrc "export BROWSER=wslview" "# WSL2 でブラウザを開くための設定
export BROWSER=wslview" "~/.zshrc に BROWSER 環境変数を追加しました"
add_to_shell_config ~/.bashrc "export BROWSER=wslview" "# WSL2 でブラウザを開くための設定
export BROWSER=wslview" "~/.bashrc に BROWSER 環境変数を追加しました"

# PATH 環境変数の設定（mise activate は install_mise_and_languages で追加済み）
echo ""
echo "🔧 PATH 環境変数を設定中..."

# ~/.local/bin PATH 設定（mise, uv, just, codex, gemini 等がインストールされる）
add_to_shell_config ~/.zshrc "PATH.*\.local/bin" "# ローカルユーザー向けバイナリ（mise, uv, just, codex, gemini 等）
export PATH=\"\$HOME/.local/bin:\$PATH\"" "~/.zshrc に ~/.local/bin の PATH を追加しました"
add_to_shell_config ~/.bashrc "PATH.*\.local/bin" "# ローカルユーザー向けバイナリ（mise, uv, just, codex, gemini 等）
export PATH=\"\$HOME/.local/bin:\$PATH\"" "~/.bashrc に ~/.local/bin の PATH を追加しました"

# pnpm PATH 設定（グローバルパッケージ用、パターン: PNPM_HOME に .local/share/pnpm を含む設定）
add_to_shell_config ~/.zshrc "PNPM_HOME.*\.local/share/pnpm" "# pnpm グローバルパッケージ
export PNPM_HOME=\"\$HOME/.local/share/pnpm\"
export PATH=\"\$PNPM_HOME:\$PATH\"" "~/.zshrc に pnpm の PATH を追加しました"
add_to_shell_config ~/.bashrc "PNPM_HOME.*\.local/share/pnpm" "# pnpm グローバルパッケージ
export PNPM_HOME=\"\$HOME/.local/share/pnpm\"
export PATH=\"\$PNPM_HOME:\$PATH\"" "~/.bashrc に pnpm の PATH を追加しました"

echo "✅ PATH 環境変数設定完了"

# ========================================
# 7. セットアップ完了メッセージ
# ========================================

# セットアップ結果のサマリー表示
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 セットアップ結果"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# システム設定
echo ""
echo "🌏 システム設定:"
echo "  タイムゾーン: $(cat /etc/timezone 2>/dev/null || echo '不明')"
# 設定ファイルから LANG を取得（現在のシェルセッションの値ではなく、永続的な設定を確認）
# grep: 行頭が "export LANG=" で始まる行を検索
# head -n1: 最初にマッチした1行のみ取得（.zshrc または .bashrc）
# cut -d'=' -f2: = で分割して2番目のフィールド（値の部分）を取得
# ||: 設定が見つからない場合は現在の LANG 値、それも未設定なら "未設定" を表示
CONFIGURED_LANG=$(grep "^export LANG=" ~/.zshrc ~/.bashrc 2>/dev/null | head -n1 | cut -d'=' -f2 || echo "${LANG:-未設定}")
echo "  ロケール:     $CONFIGURED_LANG"
echo "  シェル:       $SHELL"

# Git 設定
echo ""
echo "🔧 Git 設定:"
echo "  user.name:           $(git config --global user.name 2>/dev/null || echo '未設定')"
echo "  user.email:          $(git config --global user.email 2>/dev/null || echo '未設定')"
echo "  init.defaultBranch:  $(git config --global init.defaultBranch 2>/dev/null || echo '未設定')"
echo "  core.editor:         $(git config --global core.editor 2>/dev/null || echo '未設定')"
echo "  core.autocrlf:       $(git config --global core.autocrlf 2>/dev/null || echo '未設定')"
echo "  core.fileMode:       $(git config --global core.fileMode 2>/dev/null || echo '未設定')"

# インストールされたツール
echo ""
echo "🔧 インストールされたツール:"
echo ""
echo "  🔨 ビルドツール:"
echo "    build-essential: $(dpkg -l | grep -q build-essential && echo 'インストール済み' || echo '未インストール')"
echo ""
echo "  📌 基本CLIツール:"
echo "    tree:           $(tree --version 2>/dev/null | head -n1 || echo '未インストール')"
echo "    fzf:            $(fzf --version 2>/dev/null || echo '未インストール')"
echo "    jq:             $(jq --version 2>/dev/null || echo '未インストール')"
echo "    ripgrep (rg):   $(rg --version 2>/dev/null | head -n1 || echo '未インストール')"
echo "    fd:             $(fd --version 2>/dev/null || echo '未インストール')"
echo ""
echo "  🔧 バージョン管理:"
echo "    Git:            $(git --version 2>/dev/null || echo '未インストール')"
echo "    GitHub CLI:     $(gh --version 2>/dev/null | head -n1 || echo '未インストール')"
echo "    gitleaks:       $(gitleaks version 2>/dev/null || echo '未インストール')"
echo ""
echo "  ⚡ バージョン管理:"
echo "    mise:           $("$MISE_BIN" --version 2>/dev/null | head -n1 || mise --version 2>/dev/null | head -n1 || echo '未インストール')"
echo ""
echo "  📦 Node.js エコシステム:"
echo "    Node.js:        $(node --version 2>/dev/null || echo '未インストール')"
echo "    pnpm:           $(pnpm --version 2>/dev/null || echo '未インストール')"
echo ""
echo "  🐍 Python エコシステム:"
echo "    Python:         $(python3 --version 2>/dev/null || echo '未インストール')"
echo "    uv:             $(uv --version 2>/dev/null | head -n1 || echo '未インストール')"
echo ""
echo "  🐳 コンテナツール:"
echo "    Docker:         $(docker --version 2>/dev/null || echo '未インストール')"
echo "    Docker Compose: $(docker compose version 2>/dev/null || echo '未インストール')"
echo ""
echo "  ☁️ クラウドツール:"
echo "    AWS CLI:        $(aws --version 2>/dev/null || echo '未インストール')"
echo "    Azure CLI:      $(az --version 2>/dev/null | head -n1 || echo '未インストール')"
echo "    Google Cloud:   $(gcloud --version 2>/dev/null | head -n1 || echo '未インストール')"
echo ""
echo "  🤖 AIエージェント CLI:"
echo "    Claude Code:        $(claude --version 2>/dev/null || echo '未インストール')"
echo "    Codex CLI:          $(codex --version 2>/dev/null || echo '未インストール')"
echo "    GitHub Copilot CLI: $([[ "$(command -v copilot 2>/dev/null)" == *".vscode-server"* ]] && echo '未インストール' || copilot --version 2>/dev/null | head -n1 || echo '未インストール')"
echo "    Gemini CLI:         $(gemini --version 2>/dev/null || echo '未インストール')"
echo ""
echo "  🧠 AI パワーツール:"
echo "    markitdown:     $(markitdown --version 2>/dev/null || echo '未インストール')"
echo "    tesseract:      $(tesseract --version 2>&1 | head -n1 || echo '未インストール')"
echo "    ffmpeg:         $(ffmpeg -version 2>/dev/null | head -n1 | awk '{print $1, $2, $3}' || echo '未インストール')"
echo "    ast-grep:       $(ast-grep --version 2>/dev/null || sg --version 2>/dev/null || echo '未インストール')"
echo "    yq:             $(yq --version 2>/dev/null || echo '未インストール')"
echo ""
echo "  🛠️ 開発補助ツール:"
echo "    just:           $(just --version 2>/dev/null || echo '未インストール')"
echo "    zoxide:         $(zoxide --version 2>/dev/null || echo '未インストール')"
echo "    shellcheck:     $(shellcheck --version 2>/dev/null | awk '/^version:/{print $2}' || echo '未インストール')"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo ""
echo "🎉 セットアップ完了！"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "次のステップ:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. ターミナルを完全に閉じて再ログイン:"
echo "   exit"
echo ""
echo "2. クラウド認証情報を設定（インストール済みのものだけ）:"
echo "   # AWS (どちらかを実行)"
echo "   aws configure      # IAM ユーザーの場合"
echo "   aws configure sso  # SSO の場合"
echo ""
echo "   # Azure (opt-in でインストールした場合)"
echo "   az login"
echo ""
echo "   # Google Cloud (opt-in でインストールした場合)"
echo "   gcloud init"
echo ""
echo "3. GitHub 認証:"
echo "   gh auth login"
echo ""
echo "4. AI ツール認証:"
echo "   claude auth login   # Claude Code"
echo "   codex auth login    # Codex CLI"
echo "   copilot             # GitHub Copilot CLI（初回起動時に /login で認証）"
echo "   gemini              # Gemini CLI（初回起動時に Google アカウントで認証）"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
if [ -n "$SETUP_LOG" ]; then
  echo "ℹ️  セットアップログ: $LOG_FILE"
  echo ""
fi
