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

# add-apt-repository を Launchpad への一時的な接続失敗に対してリトライする
# api.launchpad.net への TCP 接続タイムアウトが間欠的に発生するため、
# 指数バックオフで最大 3 回試行する。
# $@: add-apt-repository に渡す引数（例: -y ppa:git-core/ppa）
#
# 戻り値: 0 = 成功、非 0 = 全試行失敗
apt_add_repository_with_retry() {
  local max_attempts=3
  local delay=5
  local attempt=1

  while ((attempt <= max_attempts)); do
    if sudo add-apt-repository "$@"; then
      return 0
    fi
    if ((attempt < max_attempts)); then
      echo "  ⚠️  add-apt-repository 失敗 (試行 ${attempt}/${max_attempts})、${delay}s 待機して再試行..."
      sleep "$delay"
      delay=$((delay * 3))
    fi
    attempt=$((attempt + 1))
  done

  echo "  ❌ add-apt-repository が ${max_attempts} 回試行しても失敗しました（Launchpad への接続不能の可能性）"
  return 1
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
