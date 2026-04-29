#!/bin/bash
# shellcheck disable=SC2088  # チルダはログメッセージ内の表示用であり、パス展開は不要
# shellcheck disable=SC2016  # シェル設定に遅延展開させる文字列をそのまま書き込む
# scripts/lib/mise.sh
# mise のインストール・初期化・グローバルツール管理ヘルパー。
# このファイルは source して利用する。前提: lib/shell_config.sh が事前に source されていること。

# mise バイナリのパス
MISE_BIN="${MISE_BIN:-$HOME/.local/bin/mise}"

# mise を初期化（未インストールならインストール、既存なら自己更新）
# 複数の install 関数から共通利用される冪等なエントリーポイント
ensure_mise_installed() {
  # 既に初期化済みの場合は再実行しない（同一セッション内のガード）
  if [ "${_MISE_INITIALIZED:-0}" = "1" ]; then
    return 0
  fi

  echo ""
  echo "⚡ mise（バージョン管理）を準備中..."

  if ! [ -x "$MISE_BIN" ]; then
    # 注意: curl | sh パターンは mise 公式のインストール方法（HTTPS使用）
    if ! curl -fsSL https://mise.run | sh >/dev/null 2>&1; then
      echo "⚠️  mise のインストールに失敗しました"
      echo "ℹ️  考えられる原因:"
      echo "    - ネットワーク接続の問題"
      echo "    - curl が利用できない"
      echo "ℹ️  対処法:"
      echo "    1. ネットワーク接続を確認"
      echo "    2. curl のインストール状態を確認: command -v curl"
      echo "ℹ️  手動で確認: curl -fsSL https://mise.run | sh"
      return 1
    fi
    echo "  ✅ mise インストール完了"
  else
    echo "  ℹ️  mise を最新版に更新中..."
    "$MISE_BIN" self-update -y >/dev/null 2>&1 || true
    echo "  ⏭️  mise は最新版です ($("$MISE_BIN" --version 2>/dev/null | head -n1))"
  fi

  # 以降のコマンドで mise とそのシム（node, npm, python, gitleaks 等）を使えるようにする
  export PATH="$HOME/.local/share/mise/shims:$HOME/.local/bin:$PATH"

  # シェル統合（mise activate）を設定
  # 注意: パターンは書き込まれた文字列内に実在する部分列を使う必要がある。
  # eval 行には `" activate zsh)"` のように途中に `"` が入るため、
  # コメント行の固定文字列（"# mise（バージョン管理）"）をアンカーとして利用する。
  add_to_shell_config ~/.zshrc '# mise（バージョン管理）' '# mise（バージョン管理）
eval "$("$HOME/.local/bin/mise" activate zsh)"' "~/.zshrc に mise 初期化を追加しました"
  add_to_shell_config ~/.bashrc '# mise（バージョン管理）' '# mise（バージョン管理）
eval "$("$HOME/.local/bin/mise" activate bash)"' "~/.bashrc に mise 初期化を追加しました"

  _MISE_INITIALIZED=1
  return 0
}

# mise を $HOME ディレクトリで実行するラッパー
# リポジトリ内（CWD に .mise.toml がある場所）で `--global` 操作を行うと
# mise が「ローカル設定がグローバルを上書きする」WARN を毎回出すため、
# サブシェルで $HOME に移動してから呼び出す。`--global` の書き先は
# ~/.config/mise/config.toml で CWD の影響を受けないため、挙動は同じ。
_mise_at_home() {
  (cd "$HOME" && "$MISE_BIN" "$@")
}

# mise でグローバルツールを導入する汎用ヘルパー
# $1: tool_spec（例: node@lts, python@latest, gitleaks@latest）
# $2: display_name（表示名）
mise_use_global() {
  local tool_spec="$1"
  local display_name="$2"
  local tool_name="${tool_spec%%@*}"

  if ! [ -x "$MISE_BIN" ]; then
    echo "  ⚠️  mise が利用できません（$display_name はスキップ）"
    return 1
  fi

  # 既にグローバル設定済みかを確認
  if _mise_at_home ls --global 2>/dev/null | awk '{print $1}' | grep -qx "$tool_name"; then
    _mise_at_home use --global "$tool_spec" >/dev/null 2>&1 || true
    _mise_at_home install "$tool_spec" >/dev/null 2>&1 || true
    echo "  ⏭️  $display_name は導入済み・最新化しました"
  else
    if _mise_at_home use --global "$tool_spec" >/dev/null; then
      echo "  ✅ $display_name インストール完了"
    else
      echo "  ⚠️  $display_name のインストールに失敗しました"
      echo "ℹ️  手動で確認: mise use --global $tool_spec"
      return 1
    fi
  fi
}
