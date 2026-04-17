#!/bin/bash
# =======================================================================
# update-tools.sh
# -----------------------------------------------------------------------
# mise / uv tool / npm グローバル経由で導入済みツールを一括更新する。
# setup-local-ubuntu.sh のハイブリッドメンテ方針を踏襲:
#   - mise: mise self-update + mise upgrade
#   - uv tool: uv tool upgrade --all（markitdown 等）
#   - npm global: AI エージェント CLI（Codex / Gemini）
#   - Native installer: Claude Code / GitHub Copilot CLI
#
# Usage:
#   ./scripts/update-tools.sh            # 通常実行
#   ./scripts/update-tools.sh --dry-run  # 実際の更新は行わず、対象だけ表示
#   SETUP_LOG=1 ./scripts/update-tools.sh
#
# 冪等で、任意のツールが未インストールでも失敗しない設計。
# =======================================================================
set -e

DRY_RUN=0
while [ "$#" -gt 0 ]; do
  case "$1" in
  --dry-run | -n)
    DRY_RUN=1
    ;;
  -h | --help)
    sed -n '2,18p' "$0"
    exit 0
    ;;
  *)
    echo "⚠️  未知の引数: $1" >&2
    exit 1
    ;;
  esac
  shift
done

# ログ出力機能（SETUP_LOG 環境変数が設定されている場合）
if [ -n "$SETUP_LOG" ]; then
  if [ "$SETUP_LOG" = "1" ] || [ "$SETUP_LOG" = "true" ]; then
    LOG_FILE="$HOME/update-tools-$(date +%Y%m%d-%H%M%S).log"
  else
    LOG_FILE="$SETUP_LOG"
  fi
  exec > >(tee -a "$LOG_FILE") 2>&1
  echo "ℹ️  ログを $LOG_FILE に記録します"
fi

MISE_BIN="$HOME/.local/bin/mise"

run_or_preview() {
  local description="$1"
  shift
  if [ "$DRY_RUN" = "1" ]; then
    printf '  [dry-run] %s\n' "$description"
    printf '            $ %s\n' "$*"
  else
    echo "  ▶ $description"
    "$@" || echo "    ⚠️  コマンドが失敗しました: $*（続行します）"
  fi
}

echo "🔄 ツール一括更新を開始 ($([ "$DRY_RUN" = "1" ] && echo 'dry-run' || echo 'live'))"
echo ""

# -----------------------------------------------------------------------
# 1. mise 本体 + mise 管理下のツール
# -----------------------------------------------------------------------
if [ -x "$MISE_BIN" ]; then
  echo "⚡ mise の更新:"
  run_or_preview "mise 本体の自己更新" "$MISE_BIN" self-update -y
  run_or_preview "mise 管理ツールの最新化" "$MISE_BIN" upgrade
  run_or_preview "シムの再生成" "$MISE_BIN" reshim
else
  echo "⏭️  mise が未インストールのためスキップ"
fi

echo ""

# -----------------------------------------------------------------------
# 2. uv tool（markitdown など）
# -----------------------------------------------------------------------
if command -v uv &>/dev/null; then
  echo "🐍 uv tool の更新:"
  run_or_preview "uv tool upgrade --all" uv tool upgrade --all
else
  echo "⏭️  uv が未インストールのためスキップ"
fi

echo ""

# -----------------------------------------------------------------------
# 3. npm グローバル（AI エージェント CLI のうち npm 配布分）
# -----------------------------------------------------------------------
if command -v npm &>/dev/null; then
  echo "📦 npm グローバルの更新:"
  # 対象: 本ツールで導入する npm グローバル
  npm_targets=("@openai/codex" "@google/gemini-cli")
  for pkg in "${npm_targets[@]}"; do
    if npm ls -g --depth=0 "$pkg" >/dev/null 2>&1; then
      run_or_preview "$pkg を更新" npm update -g "$pkg"
    else
      echo "  ⏭️  $pkg は未インストール"
    fi
  done
else
  echo "⏭️  npm が未インストールのためスキップ"
fi

echo ""

# -----------------------------------------------------------------------
# 4. 独自インストーラ（Claude Code / GitHub Copilot CLI）
# -----------------------------------------------------------------------
echo "🤖 独自インストーラ系 AI CLI の更新:"
if command -v claude &>/dev/null; then
  run_or_preview "Claude Code" bash -c 'timeout 20 claude update </dev/null || true'
else
  echo "  ⏭️  claude は未インストール"
fi

if command -v copilot &>/dev/null && [[ "$(command -v copilot 2>/dev/null)" != *".vscode-server"* ]]; then
  run_or_preview "GitHub Copilot CLI" bash -c 'timeout 20 copilot update </dev/null || true'
else
  echo "  ⏭️  copilot は未インストール（または VS Code shim）"
fi

echo ""
echo "✅ ツール一括更新を完了しました"

if [ -n "${LOG_FILE:-}" ]; then
  echo "ℹ️  更新ログ: $LOG_FILE"
fi
