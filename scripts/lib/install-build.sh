#!/bin/bash
# scripts/lib/install-build.sh
# ビルドツール（build-essential）のインストール。
# 前提: lib/apt.sh が事前に source されていること。

# 1. ビルドツールのインストール（最も基本的な依存）
install_build_tools() {
  [ "$INSTALL_BUILD_TOOLS" != "1" ] && return

  echo ""
  echo "🔨 ビルドツールをインストール中..."

  apt_install_pkg "build-essential"

  echo "✅ ビルドツールインストール完了"
}
