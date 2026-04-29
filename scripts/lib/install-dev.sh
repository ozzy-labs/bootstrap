#!/bin/bash
# shellcheck disable=SC2088  # チルダはログメッセージ内の表示用であり、パス展開は不要
# scripts/lib/install-dev.sh
# 開発補助ツール（just, zoxide, shellcheck, chezmoi）のインストールと dotfiles 適用。
# 前提: lib/mise.sh, lib/shell_config.sh, lib/detect.sh が事前に source されていること。
#       SCRIPT_DIR 変数が呼び出し元で設定されていること（chezmoi の dotfiles パス解決用）。

# 10. 開発補助ツールのインストール
install_dev_tools() {
  [ "$INSTALL_DEV_TOOLS" != "1" ] && return

  echo ""
  echo "🛠️ 開発補助ツールをインストール中..."

  ensure_mise_installed || return 1

  # just / zoxide / shellcheck / chezmoi をすべて mise 経由で導入
  # （公式インストーラは GitHub API レートリミットで詰まりやすいため mise に統一）
  mise_use_global "just@latest" "just"
  mise_use_global "zoxide@latest" "zoxide"
  mise_use_global "shellcheck@latest" "shellcheck"
  mise_use_global "chezmoi@latest" "chezmoi"

  # zoxide のシェル初期化を追加（初回のみ）
  add_to_shell_config ~/.bashrc "zoxide init bash" 'eval "$(zoxide init bash)"' "~/.bashrc に zoxide 初期化を追加しました"
  add_to_shell_config ~/.zshrc "zoxide init zsh" 'eval "$(zoxide init zsh)"' "~/.zshrc に zoxide 初期化を追加しました"

  # ~/.zshrc.d/ 方式のセットアップ
  echo "📁 ~/.zshrc.d/ を準備中..."
  mkdir -p ~/.zshrc.d
  add_to_shell_config ~/.zshrc "zshrc.d" '# OzzyLabs 推奨設定の読み込み（~/.zshrc.d/*.zsh）
if [ -d ~/.zshrc.d ]; then
  for file in ~/.zshrc.d/*.zsh; do
    [ -r "$file" ] && source "$file"
  done
  unset file
fi' "~/.zshrc に ~/.zshrc.d/ の読み込み設定を追加しました"

  # chezmoi による設定適用（ADR-0003）
  # SCRIPT_DIR は scripts/ ディレクトリなので、1つ上がプロジェクトルート
  local repo_root
  repo_root="$(dirname "$SCRIPT_DIR")"
  if [ -d "$repo_root/dotfiles" ]; then
    echo ""
    echo "🏠 chezmoi で推奨設定を適用中..."
    # --force: 既存ファイルを上書き（chezmoi は内部でバックアップを保持する）
    # --source: リポジトリ内の dotfiles ディレクトリを指定
    if _is_non_interactive; then
      _mise_at_home exec chezmoi -- chezmoi apply --force --source "$repo_root/dotfiles"
    else
      _mise_at_home exec chezmoi -- chezmoi apply --interactive --source "$repo_root/dotfiles"
    fi
    echo "  ✅ chezmoi による設定適用完了"
  fi

  echo "✅ 開発補助ツールインストール完了"
}
