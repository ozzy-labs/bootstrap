#!/usr/bin/env bats
# =======================================================================
# tests/unit/mise.bats
# -----------------------------------------------------------------------
# scripts/lib/mise.sh の純関数（外部 mise バイナリに依存しない部分）を
# 検証する。`_mise_at_home` をモックして mise 呼び出しは行わない。
# =======================================================================

setup() {
  SCRIPT_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
  # MISE_BIN を実体のないテスト用パスに固定（mise.sh が source 時に
  # $HOME/.local/bin/mise を見にいくのを避ける）
  export MISE_BIN="$BATS_TEST_TMPDIR/fake-mise-bin"
  : >"$MISE_BIN"
  chmod +x "$MISE_BIN"

  # shellcheck disable=SC1091
  source "$SCRIPT_ROOT/scripts/lib/mise.sh"

  export MOCK_LOG="$BATS_TEST_TMPDIR/mock.log"
  : >"$MOCK_LOG"

  # モック: _mise_at_home は引数をログして 0 を返す。
  # source の後に定義しないと mise.sh の同名関数で上書きされる。
  _mise_at_home() {
    echo "_mise_at_home $*" >>"$MOCK_LOG"
    return 0
  }
  export -f _mise_at_home
}

# ------------------------------------------------------------------
# mise_trust_repo_config: .mise.toml が無い → 何もせず 0
# ------------------------------------------------------------------

@test "mise_trust_repo_config: no-op when .mise.toml is absent" {
  local repo="$BATS_TEST_TMPDIR/empty-repo"
  mkdir -p "$repo"

  run mise_trust_repo_config "$repo"
  [ "$status" -eq 0 ]
  [ ! -s "$MOCK_LOG" ]
}

# ------------------------------------------------------------------
# mise_trust_repo_config: MISE_BIN 未設置 → 何もせず 0
# ------------------------------------------------------------------

@test "mise_trust_repo_config: no-op when MISE_BIN is not executable" {
  local repo="$BATS_TEST_TMPDIR/repo"
  mkdir -p "$repo"
  : >"$repo/.mise.toml"

  rm -f "$MISE_BIN"

  run mise_trust_repo_config "$repo"
  [ "$status" -eq 0 ]
  [ ! -s "$MOCK_LOG" ]
}

# ------------------------------------------------------------------
# mise_trust_repo_config: .mise.toml あり + MISE_BIN あり → trust 呼び出し
# ------------------------------------------------------------------

@test "mise_trust_repo_config: invokes 'mise trust' on the bundled .mise.toml" {
  local repo="$BATS_TEST_TMPDIR/repo"
  mkdir -p "$repo"
  : >"$repo/.mise.toml"

  run mise_trust_repo_config "$repo"
  [ "$status" -eq 0 ]
  [[ "$output" == *"mise の信頼設定に登録しました"* ]]
  grep -q "_mise_at_home trust ${repo}/.mise.toml" "$MOCK_LOG"
}

# ------------------------------------------------------------------
# mise_trust_repo_config: trust 呼び出しが失敗しても 0 を返す（警告のみ）
# ------------------------------------------------------------------

@test "mise_trust_repo_config: warns but returns 0 when trust fails" {
  local repo="$BATS_TEST_TMPDIR/repo"
  mkdir -p "$repo"
  : >"$repo/.mise.toml"

  _mise_at_home() {
    echo "_mise_at_home $*" >>"$MOCK_LOG"
    return 1
  }
  export -f _mise_at_home

  run mise_trust_repo_config "$repo"
  [ "$status" -eq 0 ]
  [[ "$output" == *"trust 登録に失敗しました"* ]]
}
