#!/bin/bash
# scripts/lib/install-git.sh
# Git および GitHub CLI のインストール。gitleaks は languages.sh で mise 経由で導入。

# 3. Gitツールのインストール
install_git_tools() {
  [ "$INSTALL_GIT_TOOLS" != "1" ] && return

  echo ""
  echo "🔧 バージョン管理ツールをインストール中..."

  # Git公式PPAが既に追加されているかチェック
  if ! compgen -G "/etc/apt/sources.list.d/git-core-ubuntu-ppa-*.list" >/dev/null 2>&1; then
    apt_add_repository_with_retry -y ppa:git-core/ppa >/dev/null
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

  # gitleaks は mise 経由で導入（install_git_security_tools で実行）
  # シークレットスキャンはプロジェクト単位で lefthook 等のフックに組み込む運用を想定

  echo "✅ バージョン管理ツールインストール完了"
}
