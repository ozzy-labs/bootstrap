#!/bin/bash
# scripts/lib/detect.sh
# 環境判定ヘルパー（OS / 対話モード / WSL / Ubuntu/Debian 互換性）
# このファイルは source して利用する。直接実行しない。

# 非対話モードかどうかを判定
# BOOTSTRAP_ASSUME_YES=1（旧名 WSL_DEV_SETUP_ASSUME_YES も後方互換で受理）
# または CI=true でプロンプトを自動回答する
_is_non_interactive() {
  [ "${BOOTSTRAP_ASSUME_YES:-${WSL_DEV_SETUP_ASSUME_YES:-0}}" = "1" ] || [ "${CI:-}" = "true" ]
}

# /etc/os-release を読み Ubuntu/Debian 系かを判定
_is_ubuntu_or_debian() {
  [ -f /etc/os-release ] && grep -qi "ubuntu\|debian" /etc/os-release 2>/dev/null
}

# /etc/os-release から PRETTY_NAME を取得
_os_pretty_name() {
  if [ -f /etc/os-release ]; then
    grep PRETTY_NAME /etc/os-release | cut -d'"' -f2
  else
    uname -s
  fi
}
