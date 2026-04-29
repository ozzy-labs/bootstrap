#!/bin/bash
# scripts/lib/apt.sh
# apt-get の冪等インストール/アップグレードヘルパー。
# このファイルは source して利用する。

# パッケージを冪等にインストール、または既存なら最新化する
# $1: package_name（apt パッケージ名）
# $2: display_name（表示名、省略時は package_name）
# $3: detect_command（コマンド存在確認用、省略時は package_name）
#
# 戻り値: 0 = 成功、非 0 = 失敗
apt_install_or_upgrade() {
  local pkg="$1"
  local display="${2:-$1}"
  local cmd="${3:-$1}"

  if ! command -v "$cmd" &>/dev/null; then
    sudo apt-get install -y "$pkg"
    echo "  ✅ $display インストール完了"
  else
    sudo apt-get install -y --only-upgrade "$pkg" >/dev/null 2>&1
    echo "  ⏭️  $display は最新版です"
  fi
}

# dpkg のインストール状態をベースにした冪等インストール（コマンドではなくパッケージで判定）
# build-essential のような複合パッケージ向け
apt_install_pkg() {
  local pkg="$1"
  local display="${2:-$1}"

  if ! dpkg -l "$pkg" 2>/dev/null | grep -q "^ii"; then
    sudo apt-get install -y "$pkg"
    echo "  ✅ $display インストール完了"
  else
    sudo apt-get install -y --only-upgrade "$pkg" >/dev/null 2>&1
    echo "  ⏭️  $display は最新版です"
  fi
}
