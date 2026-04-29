#!/usr/bin/env bats
# =======================================================================
# tests/unit/prompts.bats
# -----------------------------------------------------------------------
# scripts/lib/prompts.sh の対話プロンプト関数を非対話モードで検証する。
# 対話モード（実際の read）はテスト困難なため、CI=true 経路のみ確認する。
#
# 注意: REPLY を検証するため、サブシェル経由ではなく現在のシェルで関数を呼ぶ。
# 出力は一時ファイルにリダイレクトしてから検査する。
# =======================================================================

setup() {
  SCRIPT_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
  # shellcheck disable=SC1091
  source "$SCRIPT_ROOT/scripts/lib/detect.sh"
  # shellcheck disable=SC1091
  source "$SCRIPT_ROOT/scripts/lib/prompts.sh"
  OUT_FILE="$BATS_TEST_TMPDIR/out.txt"
}

# ------------------------------------------------------------------
# _prompt_default_yes (non-interactive)
# ------------------------------------------------------------------

@test "_prompt_default_yes: sets REPLY=Y and prints suffix in non-interactive mode" {
  CI=true
  unset BOOTSTRAP_ASSUME_YES WSL_DEV_SETUP_ASSUME_YES
  REPLY=""
  _prompt_default_yes "Continue? [Y/n]: " >"$OUT_FILE"
  [ "$REPLY" = "Y" ]
  grep -q "Y (non-interactive)" "$OUT_FILE"
}

@test "_prompt_default_yes: respects BOOTSTRAP_ASSUME_YES=1" {
  BOOTSTRAP_ASSUME_YES=1
  unset CI WSL_DEV_SETUP_ASSUME_YES
  REPLY=""
  _prompt_default_yes "Continue? [Y/n]: " >"$OUT_FILE"
  [ "$REPLY" = "Y" ]
  grep -q "Y (non-interactive)" "$OUT_FILE"
}

# ------------------------------------------------------------------
# _prompt_default_no (non-interactive)
# ------------------------------------------------------------------

@test "_prompt_default_no: sets REPLY=N and prints suffix in non-interactive mode" {
  CI=true
  unset BOOTSTRAP_ASSUME_YES WSL_DEV_SETUP_ASSUME_YES
  REPLY=""
  _prompt_default_no "Continue? [y/N]: " >"$OUT_FILE"
  [ "$REPLY" = "N" ]
  grep -q "N (non-interactive)" "$OUT_FILE"
}

@test "_prompt_default_no: respects legacy WSL_DEV_SETUP_ASSUME_YES=1" {
  WSL_DEV_SETUP_ASSUME_YES=1
  unset BOOTSTRAP_ASSUME_YES CI
  REPLY=""
  _prompt_default_no "Continue? [y/N]: " >"$OUT_FILE"
  [ "$REPLY" = "N" ]
}
