#!/bin/bash
# scripts/lib/shell_config.sh
# シェル設定ファイル（~/.zshrc, ~/.bashrc 等）への冪等な行追加ヘルパー。
# このファイルは source して利用する。

# シェル設定ファイルに行を追加する関数
# $1: 対象ファイル
# $2: 既存判定用の grep パターン（contentに含まれる文字列を指定）
# $3: 追加する内容（複数行可）
# $4: ログ表示用の説明文
add_to_shell_config() {
  local file="$1"
  local pattern="$2"
  local lines="$3"
  local description="$4"

  if [ -f "$file" ]; then
    if grep -q "$pattern" "$file" 2>/dev/null; then
      echo "  ⏭️  $file には既に設定済み"
    else
      echo "" >>"$file"
      echo "$lines" >>"$file"
      echo "  ✅ $description"
    fi
  else
    if [ "$file" = "$HOME/.zshrc" ]; then
      echo "  ⚠️  $file が見つかりません（zsh を使用していない場合は問題ありません）"
    else
      echo "  ⚠️  $file が見つかりません"
    fi
  fi
}
