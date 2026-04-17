#!/bin/bash
set -e

# Ubuntu/Debian系 zsh + oh-my-zsh + プラグインセットアップスクリプト

# ========================================
# グローバル変数（インストール対象フラグ）
# ========================================

# プラグインのインストールフラグ（デフォルト: すべてインストール）
INSTALL_SYNTAX_HIGHLIGHTING=1
INSTALL_AUTOSUGGESTIONS=1
INSTALL_COMPLETIONS=1
INSTALL_HISTORY_SUBSTRING_SEARCH=1

# ========================================
# ユーティリティ関数
# ========================================

# .zshrc に plugins 設定を追加する関数
add_plugins_to_zshrc() {
  local plugins_to_add="$1"

  if [ ! -f "$HOME/.zshrc" ]; then
    echo "  ⚠️  ~/.zshrc が見つかりません"
    return 1
  fi

  # 既にプラグインが設定されているかチェック
  if grep -q "plugins=.*zsh-syntax-highlighting" "$HOME/.zshrc" 2>/dev/null; then
    echo "  ⏭️  プラグインは既に設定済み"
    return 0
  fi

  if grep -q "^plugins=(" "$HOME/.zshrc" 2>/dev/null; then
    # plugins=(...) 行が存在する場合、プラグインを追加
    # sed 置換の動作:
    #   - \(.*\): 括弧内の既存プラグインをキャプチャ（後方参照 \1 で使用）
    #   - plugins=(\1 ...) の形式で、既存プラグインの後ろに新しいプラグインを追加
    sed -i "s/^plugins=(\(.*\))/plugins=(\1 $plugins_to_add)/" "$HOME/.zshrc"
    # 余分なスペースをクリーンアップ（行頭の plugins=( の後の連続スペースを1つに）
    # \+: 1つ以上のスペースにマッチ
    sed -i 's/^plugins=( \+/plugins=(/' "$HOME/.zshrc"
    echo "  ✅ プラグイン設定を追加しました"
  else
    echo "  ⚠️  plugins=(...) 行が見つかりません"
    echo "  ℹ️  手動で設定する場合: ~/.zshrc に以下を追加"
    echo "      plugins=(git $plugins_to_add)"
  fi
}

# ========================================
# インストール関数群（依存関係順）
# ========================================

# 1. 依存パッケージのインストール
install_dependencies() {
  echo ""
  echo "🔧 依存パッケージをインストール中..."

  # curl のインストール（oh-my-zsh に必要）
  if ! command -v curl &>/dev/null; then
    sudo apt-get install -y curl
    echo "  ✅ curl インストール完了"
  else
    sudo apt-get install -y --only-upgrade curl >/dev/null 2>&1
    echo "  ⏭️  curl は最新版です"
  fi

  # git のインストール（プラグインに必要）
  if ! command -v git &>/dev/null; then
    sudo apt-get install -y git
    echo "  ✅ git インストール完了"
  else
    sudo apt-get install -y --only-upgrade git >/dev/null 2>&1
    echo "  ⏭️  git は最新版です"
  fi

  echo "✅ 依存パッケージインストール完了"
}

# 2. zsh のインストール
install_zsh() {
  echo ""
  echo "🐚 zsh をインストール中..."

  if ! command -v zsh &>/dev/null; then
    sudo apt-get install -y zsh
    echo "✅ zsh インストール完了"
  else
    sudo apt-get install -y --only-upgrade zsh >/dev/null 2>&1
    echo "⏭️  zsh は最新版です"
  fi
}

# 3. oh-my-zsh のインストール
install_oh_my_zsh() {
  echo ""
  echo "🎨 oh-my-zsh をインストール中..."

  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    # 注意: curl | sh パターンは公式のインストール方法（HTTPS使用）
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    echo "✅ oh-my-zsh インストール完了"
  else
    # 既にインストール済みの場合も最新版に更新
    echo "  ℹ️  oh-my-zsh を最新版に更新中..."
    if [ -d "$HOME/.oh-my-zsh" ]; then
      (cd "$HOME/.oh-my-zsh" && git pull >/dev/null 2>&1)
    fi
    echo "⏭️  oh-my-zsh は最新版です"
  fi
}

# 4. zsh プラグインのインストール
install_zsh_plugins() {
  local plugins_installed=0
  local plugins_list=""

  echo ""
  echo "🔌 プラグインをインストール中..."

  # 注意: プラグインの読み込み順序は重要です
  # 推奨順序: completions -> autosuggestions -> history-substring-search -> syntax-highlighting

  # 1. zsh-completions プラグイン（最初に補完定義を読み込む）
  if [ "$INSTALL_COMPLETIONS" = "1" ]; then
    plugins_installed=1

    if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-completions" ]; then
      git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-completions
      echo "  ✅ zsh-completions インストール完了"
    else
      # 既にインストール済みの場合も最新版に更新
      (cd "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-completions" && git pull >/dev/null 2>&1)
      echo "  ⏭️  zsh-completions は最新版です"
    fi

    plugins_list="$plugins_list zsh-completions"
  fi

  # 2. zsh-autosuggestions プラグイン
  if [ "$INSTALL_AUTOSUGGESTIONS" = "1" ]; then
    plugins_installed=1

    if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ]; then
      git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
      echo "  ✅ zsh-autosuggestions インストール完了"
    else
      # 既にインストール済みの場合も最新版に更新
      (cd "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" && git pull >/dev/null 2>&1)
      echo "  ⏭️  zsh-autosuggestions は最新版です"
    fi

    plugins_list="$plugins_list zsh-autosuggestions"
  fi

  # 3. zsh-history-substring-search プラグイン
  if [ "$INSTALL_HISTORY_SUBSTRING_SEARCH" = "1" ]; then
    plugins_installed=1

    if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-history-substring-search" ]; then
      git clone https://github.com/zsh-users/zsh-history-substring-search ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-history-substring-search
      echo "  ✅ zsh-history-substring-search インストール完了"
    else
      # 既にインストール済みの場合も最新版に更新
      (cd "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-history-substring-search" && git pull >/dev/null 2>&1)
      echo "  ⏭️  zsh-history-substring-search は最新版です"
    fi

    plugins_list="$plugins_list zsh-history-substring-search"
  fi

  # 4. zsh-syntax-highlighting プラグイン（最後に読み込む）
  if [ "$INSTALL_SYNTAX_HIGHLIGHTING" = "1" ]; then
    plugins_installed=1

    if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" ]; then
      git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
      echo "  ✅ zsh-syntax-highlighting インストール完了"
    else
      # 既にインストール済みの場合も最新版に更新
      (cd "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" && git pull >/dev/null 2>&1)
      echo "  ⏭️  zsh-syntax-highlighting は最新版です"
    fi

    plugins_list="$plugins_list zsh-syntax-highlighting"
  fi

  # .zshrc の plugins 設定を修正
  if [ "$plugins_installed" = "1" ]; then
    echo ""
    echo "⚙️ .zshrc の plugins 設定を確認中..."
    add_plugins_to_zshrc "$plugins_list"
  fi

  echo "✅ プラグインインストール完了"
}

# 5. デフォルトシェルの変更
change_default_shell() {
  echo ""
  echo "🐚 デフォルトシェルを確認中..."

  # zsh のパスを取得
  local ZSH_PATH
  ZSH_PATH=$(command -v zsh)

  if [ -z "$ZSH_PATH" ]; then
    echo "  ⚠️  zsh が見つかりません"
    return 1
  elif [ "$SHELL" = "$ZSH_PATH" ]; then
    echo "  ⏭️  デフォルトシェルは既に zsh です"
  else
    echo "  デフォルトシェルを zsh に変更中..."
    # Dev Container 環境では sudo で実行
    if sudo chsh -s "$ZSH_PATH" "$USER" 2>/dev/null; then
      echo "  ✅ デフォルトシェルを zsh に変更しました"
    else
      echo "  ⚠️  デフォルトシェルの変更に失敗しました"
      echo "  ℹ️  手動で変更する場合: sudo chsh -s $ZSH_PATH $USER"
      echo "  ℹ️  または、~/.bashrc や ~/.profile に以下を追加:"
      echo "       exec $ZSH_PATH"
    fi
  fi
}

# ========================================
# メイン処理
# ========================================

# ログ出力機能（SETUP_LOG 環境変数が設定されている場合）
if [ -n "$SETUP_LOG" ]; then
  # SETUP_LOG=1 または SETUP_LOG=true の場合はデフォルトパスを使用
  if [ "$SETUP_LOG" = "1" ] || [ "$SETUP_LOG" = "true" ]; then
    LOG_FILE="$HOME/setup-zsh-ubuntu-$(date +%Y%m%d-%H%M%S).log"
  else
    LOG_FILE="$SETUP_LOG"
  fi
  # プロセス置換と tee を使って標準出力とログファイルの両方に出力
  # exec: 現在のシェルの stdout/stderr をリダイレクト
  # tee -a: 標準出力とファイルの両方に追記（-a: append mode）
  exec > >(tee -a "$LOG_FILE") 2>&1
  echo "ℹ️  ログを $LOG_FILE に記録します"
fi

echo "🚀 zsh + oh-my-zsh セットアップ開始"
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
  read -p "続行しますか？ (y/N): " -n 1 -r
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
# 2. プラグインの選択
# ========================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔌 インストールするプラグインの選択"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "インストール可能なプラグイン:"
echo "  📚 zsh-completions - 追加の補完定義"
echo "  💡 zsh-autosuggestions - コマンド補完候補"
echo "  🔍 zsh-history-substring-search - 履歴検索強化"
echo "  🎨 zsh-syntax-highlighting - シンタックスハイライト"
echo ""
echo "すべてのプラグインをインストールしますか？"
echo "  y: すべてインストール（デフォルト）"
echo "  n: 個別に選択"
echo ""
read -p "選択 [Y/n]: " -n 1 -r INSTALL_ALL_PLUGINS
echo ""
echo "ℹ️  ユーザー入力: ${INSTALL_ALL_PLUGINS:-Y}"

if [[ ! $INSTALL_ALL_PLUGINS =~ ^[Yy]?$ ]]; then
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "各プラグインのインストール設定"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  # zsh-completions
  read -p "📚 zsh-completions (追加の補完定義) をインストールしますか? [Y/n]: " -n 1 -r
  echo ""
  [[ $REPLY =~ ^[Nn]$ ]] && INSTALL_COMPLETIONS=0

  # zsh-autosuggestions
  read -p "💡 zsh-autosuggestions (コマンド補完候補) をインストールしますか? [Y/n]: " -n 1 -r
  echo ""
  [[ $REPLY =~ ^[Nn]$ ]] && INSTALL_AUTOSUGGESTIONS=0

  # zsh-history-substring-search
  read -p "🔍 zsh-history-substring-search (履歴検索強化) をインストールしますか? [Y/n]: " -n 1 -r
  echo ""
  [[ $REPLY =~ ^[Nn]$ ]] && INSTALL_HISTORY_SUBSTRING_SEARCH=0

  # zsh-syntax-highlighting
  read -p "🎨 zsh-syntax-highlighting (シンタックスハイライト) をインストールしますか? [Y/n]: " -n 1 -r
  echo ""
  [[ $REPLY =~ ^[Nn]$ ]] && INSTALL_SYNTAX_HIGHLIGHTING=0
fi

echo ""
echo "✅ プラグイン選択完了"
echo ""

# ========================================
# 3. 初期設定（ユーザー入力）
# ========================================

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
echo "✅ 初期設定完了"
echo ""

# ========================================
# 4. システムパッケージの更新
# ========================================

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

# ========================================
# 5. インストール処理（関数呼び出し）
# ========================================

# 依存パッケージのインストール
install_dependencies

# zsh のインストール
install_zsh

# oh-my-zsh のインストール
install_oh_my_zsh

# プラグインのインストール
install_zsh_plugins

# デフォルトシェルの変更
change_default_shell

# ========================================
# 6. セットアップ完了メッセージ
# ========================================

echo ""
echo "🎉 zsh + oh-my-zsh + プラグインセットアップ完了！"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 インストール結果"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🐚 シェル:"
echo "  zsh: $(zsh --version 2>/dev/null || echo '未インストール')"
echo "  oh-my-zsh: $([ -d "$HOME/.oh-my-zsh" ] && echo 'インストール済み' || echo '未インストール')"
echo "  デフォルトシェル: $SHELL"
echo ""
echo "🔌 プラグイン:"
if [ "$INSTALL_COMPLETIONS" = "1" ]; then
  echo "  zsh-completions: $([ -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-completions" ] && echo 'インストール済み' || echo '未インストール')"
fi
if [ "$INSTALL_AUTOSUGGESTIONS" = "1" ]; then
  echo "  zsh-autosuggestions: $([ -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ] && echo 'インストール済み' || echo '未インストール')"
fi
if [ "$INSTALL_HISTORY_SUBSTRING_SEARCH" = "1" ]; then
  echo "  zsh-history-substring-search: $([ -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-history-substring-search" ] && echo 'インストール済み' || echo '未インストール')"
fi
if [ "$INSTALL_SYNTAX_HIGHLIGHTING" = "1" ]; then
  echo "  zsh-syntax-highlighting: $([ -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" ] && echo 'インストール済み' || echo '未インストール')"
fi
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "次のステップ:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. ターミナルを完全に閉じて再ログイン:"
echo "   exit"
echo ""
echo "2. 開発環境のセットアップを実行:"
echo "   ./scripts/setup-local-ubuntu.sh"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
if [ -n "$SETUP_LOG" ]; then
  echo "ℹ️  セットアップログ: $LOG_FILE"
  echo ""
fi
