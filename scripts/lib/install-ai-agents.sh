#!/bin/bash
# scripts/lib/install-ai-agents.sh
# AI エージェント CLI（Claude Code / Codex / Copilot / Gemini）のインストール。
# 前提: lib/mise.sh が事前に source されていること（_mise_at_home, MISE_BIN を利用）。

# 8. AIツールのインストール
install_ai_tools() {
  local any_installed=0

  # Claude Code（Native Install — 自動更新対応）
  if [ "$INSTALL_CLAUDE_CODE" = "1" ]; then
    [ "$any_installed" = "0" ] && {
      echo ""
      echo "🤖 AIツールをインストール中..."
      any_installed=1
    }

    if ! command -v claude &>/dev/null; then
      curl -fsSL https://claude.ai/install.sh | bash >/dev/null 2>&1
      echo "  ✅ Claude Code インストール完了"
    else
      echo "  ℹ️  Claude Code を最新版に更新中..."
      timeout 10 claude update </dev/null >/dev/null 2>&1 || true
      echo "  ⏭️  Claude Code は最新版です ($(claude --version 2>/dev/null || echo '不明'))"
    fi
  fi

  # Codex CLI
  if [ "$INSTALL_CODEX_CLI" = "1" ]; then
    [ "$any_installed" = "0" ] && {
      echo ""
      echo "🤖 AIツールをインストール中..."
      any_installed=1
    }

    if ! command -v codex &>/dev/null; then
      npm install -g @openai/codex
      echo "  ✅ Codex CLI インストール完了"
    else
      echo "  ℹ️  Codex CLI を最新版に更新中..."
      npm update -g @openai/codex >/dev/null 2>&1 || true
      echo "  ⏭️  Codex CLI は最新版です"
    fi
  fi

  # GitHub Copilot CLI（Install Script — 自動更新対応）
  if [ "$INSTALL_COPILOT_CLI" = "1" ]; then
    [ "$any_installed" = "0" ] && {
      echo ""
      echo "🤖 AIツールをインストール中..."
      any_installed=1
    }

    # VS Code 拡張の shim（~/.vscode-server/...）はスタンドアロン CLI ではないため除外
    local copilot_path
    copilot_path=$(command -v copilot 2>/dev/null || true)
    if [ -z "$copilot_path" ] || [[ "$copilot_path" == *".vscode-server"* ]]; then
      curl -fsSL https://gh.io/copilot-install | bash >/dev/null 2>&1
      echo "  ✅ GitHub Copilot CLI インストール完了"
    else
      echo "  ℹ️  GitHub Copilot CLI を最新版に更新中..."
      timeout 10 copilot update </dev/null >/dev/null 2>&1 || true
      echo "  ⏭️  GitHub Copilot CLI は最新版です ($(copilot --version 2>/dev/null | head -n1 || echo '不明'))"
    fi
  fi

  # Gemini CLI
  if [ "$INSTALL_GEMINI_CLI" = "1" ]; then
    [ "$any_installed" = "0" ] && {
      echo ""
      echo "🤖 AIツールをインストール中..."
      any_installed=1
    }

    if ! command -v gemini &>/dev/null; then
      npm install -g @google/gemini-cli
      echo "  ✅ Gemini CLI インストール完了"
    else
      echo "  ℹ️  Gemini CLI を最新版に更新中..."
      npm update -g @google/gemini-cli >/dev/null 2>&1 || true
      echo "  ⏭️  Gemini CLI は最新版です"
    fi
  fi

  # mise 管理下の node で npm グローバルインストールした CLI のシムを生成
  # （Codex / Gemini 等の新規バイナリを ~/.local/share/mise/shims 経由で使えるようにする）
  if [ "$any_installed" = "1" ] && [ -x "$MISE_BIN" ]; then
    _mise_at_home reshim >/dev/null 2>&1 || true
  fi

  [ "$any_installed" = "1" ] && echo "✅ AIツールインストール完了"
}
