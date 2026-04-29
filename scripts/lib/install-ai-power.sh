#!/bin/bash
# scripts/lib/install-ai-power.sh
# AI パワーツール（markitdown, tesseract-ocr, ffmpeg, ast-grep, yq）のインストール。
# 前提: lib/mise.sh が事前に source されていること。

# 9. AI パワーツールのインストール
# AI エージェントの文書読み込み・コード検索・データ操作を強化するツール群
# - markitdown: PDF/Office/画像/音声 → Markdown 変換（uv tool）
# - tesseract-ocr(+jpn): OCR 基盤（apt、markitdown の画像/PDF 対応を有効化）
# - ffmpeg: 音声・動画処理基盤（apt、markitdown の音声転写を有効化）
# - ast-grep: 構造的コード検索・置換（mise）
# - yq: YAML クエリツール（mise、jq の YAML 版）
install_ai_power_tools() {
  [ "$INSTALL_AI_POWER_TOOLS" != "1" ] && return

  ensure_mise_installed || return 1

  echo ""
  echo "🧠 AI パワーツールをインストール中..."

  # apt: OS 依存ライブラリ（markitdown の OCR/音声機能を有効化）
  local apt_targets=(tesseract-ocr tesseract-ocr-jpn ffmpeg)
  local apt_pkg
  for apt_pkg in "${apt_targets[@]}"; do
    if ! dpkg -l "$apt_pkg" 2>/dev/null | grep -q "^ii"; then
      sudo apt-get install -y "$apt_pkg"
      echo "  ✅ $apt_pkg インストール完了"
    else
      sudo apt-get install -y --only-upgrade "$apt_pkg" >/dev/null 2>&1
      echo "  ⏭️  $apt_pkg は最新版です"
    fi
  done

  # mise: 横断的な CLI ツール（バージョン固定・一括更新が容易）
  mise_use_global "ast-grep@latest" "ast-grep"
  mise_use_global "yq@latest" "yq"

  # uv tool: Python 製 AI 向け文書変換 CLI
  # uv はすでに mise 経由で導入済み想定。念のためコマンド存在確認
  if command -v uv &>/dev/null; then
    if ! uv tool list 2>/dev/null | grep -q "^markitdown"; then
      uv tool install "markitdown[all]" >/dev/null
      echo "  ✅ markitdown[all] インストール完了"
    else
      uv tool upgrade markitdown >/dev/null 2>&1 || true
      echo "  ⏭️  markitdown は導入済み・最新化しました"
    fi
  else
    echo "  ⚠️  uv が見つからないため markitdown はスキップしました"
    echo "ℹ️  対処法: Python 環境（mise + uv）を有効にして再実行してください"
  fi

  echo "✅ AI パワーツールインストール完了"
}
