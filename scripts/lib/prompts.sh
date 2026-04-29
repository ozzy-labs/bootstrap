#!/bin/bash
# scripts/lib/prompts.sh
# 対話プロンプトヘルパー。非対話モード（CI / BOOTSTRAP_ASSUME_YES）では自動応答する。
# このファイルは source して利用する。前提: lib/detect.sh が事前に source されていること。

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

# パイプ実行時 (curl ... | bash) でも対話プロンプトが動作するよう、
# stdin が tty でなく /dev/tty が読める場合は /dev/tty にフォールバックする。
# 非対話モード（CI / ASSUME_YES）ではフォールバックしない。
# 呼び出し側スクリプト先頭で `_attach_tty_if_needed` を呼ぶ。
_attach_tty_if_needed() {
  if [ ! -t 0 ] && [ -r /dev/tty ] && ! _is_non_interactive; then
    exec </dev/tty
  fi
}
