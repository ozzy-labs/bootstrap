#!/bin/bash
# =======================================================================
# tests/integration/entrypoint.sh
# -----------------------------------------------------------------------
# コンテナ内で install.sh local を 2 回実行し、主要ツールの導入と
# 冪等性を検証する。
# =======================================================================
set -eo pipefail

RUN1_LOG="/tmp/run1.log"
RUN2_LOG="/tmp/run2.log"
ASSERT_SCRIPT="/workspace/tests/integration/assert-tools.sh"

printf '\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
printf '🔵 1st run — setup from scratch\n'
printf '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
if ! /workspace/install.sh local 2>&1 | tee "$RUN1_LOG"; then
  echo "❌ 1st run failed"
  exit 1
fi

printf '\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
printf '🔍 Asserting tool installations\n'
printf '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'

# 新しく設定された PATH / シェル統合を反映してから assert を実行
# shellcheck disable=SC1091
source "$HOME/.bashrc" || true
if ! bash "$ASSERT_SCRIPT"; then
  echo "❌ Tool assertions failed after 1st run"
  exit 1
fi

printf '\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
printf '🔵 2nd run — idempotency check\n'
printf '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
if ! /workspace/install.sh local 2>&1 | tee "$RUN2_LOG"; then
  echo "❌ 2nd run failed"
  exit 1
fi

printf '\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
printf '📊 Idempotency verdict\n'
printf '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'

# 冪等性の判定基準:
#   1. 2 回目実行が正常終了している（ここまで到達した時点で set -e により保証）
#   2. ~/.bashrc 内のシェル設定行が重複していない（add_to_shell_config の冪等性）
#   3. 2 回目は「すでに導入済み」マーカー (⏭️) が少なくとも 1 件以上出ている
#      （完全に再インストールしているわけではないことを示す）
RUN2_INSTALL_COUNT=$(grep -c 'インストール完了' "$RUN2_LOG" || true)
RUN2_SKIP_COUNT=$(grep -c '⏭️' "$RUN2_LOG" || true)

printf '2nd run "インストール完了" markers: %s\n' "$RUN2_INSTALL_COUNT"
printf '2nd run "⏭️" markers:              %s\n' "$RUN2_SKIP_COUNT"

if [ "$RUN2_SKIP_COUNT" -lt 5 ]; then
  echo "❌ Expected many '⏭️' markers on 2nd run but saw only $RUN2_SKIP_COUNT"
  echo "   (scripts should mostly skip already-installed tools)"
  exit 1
fi

# シェル設定の重複チェック（唯一のアンカー行だけを見る）
# PNPM_HOME ブロックは `export PNPM_HOME=` と `export PATH="$PNPM_HOME:..."` の 2 行を
# 含むため、単純な "PNPM_HOME" カウントでは 2 回マッチしてしまう。
# add_to_shell_config は冒頭コメント行（"# ..."）を一意なアンカーとして挿入するため、
# そのコメント行の出現回数をチェックするのが最も堅牢。
for anchor in \
  "# mise（バージョン管理）" \
  "# pnpm グローバルパッケージ" \
  "# ローカルユーザー向けバイナリ" \
  "# WSL2 でブラウザを開くための設定" \
  'eval "$(zoxide init bash)"'; do
  count=$(grep -cF "$anchor" "$HOME/.bashrc" || true)
  if [ "$count" -gt 1 ]; then
    echo "❌ Shell config duplication: '$anchor' appears $count times in ~/.bashrc"
    exit 1
  fi
done

printf '\n✅ Integration test passed (both runs completed, no shell config duplication)\n'
