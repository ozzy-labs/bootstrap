#!/bin/bash
# scripts/lib/install-languages.sh
# mise + 言語環境（Node.js + pnpm + Python + uv）と gitleaks のインストール。
# 前提: lib/mise.sh が事前に source されていること。

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
