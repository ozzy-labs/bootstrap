#!/usr/bin/env bats
# =======================================================================
# tests/unit/doctor-checks.bats
# -----------------------------------------------------------------------
# scripts/lib/doctor-checks.sh の各 check_* 関数を検証する。
# system / mise / chezmoi をモックして、結果バケット _DOCTOR_RESULTS の
# 内容で判定する。
# =======================================================================

setup() {
  SCRIPT_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
  export SCRIPT_DIR="$SCRIPT_ROOT/scripts"

  # 実ホームを汚染しない
  export HOME="$BATS_TEST_TMPDIR"
  export PATH="$BATS_TEST_TMPDIR/bin:$PATH"
  mkdir -p "$BATS_TEST_TMPDIR/bin"

  # 必要 lib を source
  # shellcheck disable=SC1091
  source "$SCRIPT_ROOT/scripts/lib/detect.sh"
  # shellcheck disable=SC1091
  source "$SCRIPT_ROOT/scripts/lib/shell_config.sh"
  # shellcheck disable=SC1091
  source "$SCRIPT_ROOT/scripts/lib/mise.sh"
  # shellcheck disable=SC1091
  source "$SCRIPT_ROOT/scripts/lib/doctor-checks.sh"

  # 結果バケットと doctor_record をテスト用に定義
  _DOCTOR_RESULTS=()
  doctor_record() {
    _DOCTOR_RESULTS+=("$1|$2|$3|${4:-}")
  }
  export -f doctor_record

  # MISE_BIN をテスト用 tmpdir に向ける（実ホストの mise を見ない）
  export MISE_BIN="$BATS_TEST_TMPDIR/mise"
}

# 結果配列から特定 status のエントリ数をカウント
_count_status() {
  local target="$1"
  local count=0
  local entry
  for entry in "${_DOCTOR_RESULTS[@]}"; do
    [[ "$entry" == "$target|"* ]] && count=$((count + 1))
  done
  printf '%d\n' "$count"
}

# 結果配列に特定 category のエントリが特定 status で存在するか
_has_status_for_category() {
  local status="$1"
  local category="$2"
  local entry
  for entry in "${_DOCTOR_RESULTS[@]}"; do
    [[ "$entry" == "$status|$category|"* ]] && return 0
  done
  return 1
}

# ------------------------------------------------------------------
# check_system_tools
# ------------------------------------------------------------------

@test "check_system_tools: records ok for tools that exist on host (curl, git)" {
  # curl と git は CI 含めほぼ常に存在する想定
  check_system_tools
  _has_status_for_category "ok" "system-tools"
}

@test "check_system_tools: records error with fix hint for missing tool" {
  # サブシェルで PATH を変更し、teardown が rm 等を呼べる環境を保つ
  mkdir -p "$BATS_TEST_TMPDIR/empty-bin"
  local results
  results=$(
    PATH="$BATS_TEST_TMPDIR/empty-bin"
    _DOCTOR_RESULTS=()
    check_system_tools
    printf '%s\n' "${_DOCTOR_RESULTS[@]}"
  )

  # error が複数件出るはず（curl/git/unzip/xz/tar すべて欠落）
  local error_count
  error_count=$(printf '%s\n' "$results" | grep -c "^error|system-tools|" || true)
  [ "$error_count" -ge 1 ]

  # fix_hint に apt-get または brew が含まれるはず
  printf '%s\n' "$results" | grep -qE "(apt-get|brew)"
}

# ------------------------------------------------------------------
# check_mise
# ------------------------------------------------------------------

@test "check_mise: records error when mise binary is missing" {
  # MISE_BIN を存在しないパスに
  export MISE_BIN="$BATS_TEST_TMPDIR/nonexistent-mise"
  check_mise
  _has_status_for_category "error" "mise"
}

@test "check_mise: records ok when mise binary exists" {
  # ダミーの mise バイナリを作成
  cat >"$MISE_BIN" <<'EOF'
#!/bin/bash
echo "2026.4.1 macos-arm64 (2026-04-01)"
EOF
  chmod +x "$MISE_BIN"

  check_mise
  _has_status_for_category "ok" "mise"
}

# ------------------------------------------------------------------
# check_mise_managed_tools
# ------------------------------------------------------------------

@test "check_mise_managed_tools: skips silently when mise is not installed" {
  # MISE_BIN は存在しない
  export MISE_BIN="$BATS_TEST_TMPDIR/nonexistent-mise"
  _DOCTOR_RESULTS=()
  check_mise_managed_tools

  # 何も記録されないことを確認
  [ "${#_DOCTOR_RESULTS[@]}" -eq 0 ]
}

@test "check_mise_managed_tools: records warn for tools not under mise" {
  # ダミーの mise バイナリ。`ls --global` で何も出さない（管理下に何もない）
  cat >"$MISE_BIN" <<'EOF'
#!/bin/bash
case "$1" in
  ls) ;;  # empty output
  current) ;;
esac
EOF
  chmod +x "$MISE_BIN"

  check_mise_managed_tools

  # node / pnpm / python / uv が warn として記録される
  _has_status_for_category "warn" "mise-tools"
  # 4 つすべて warn
  [ "$(_count_status warn)" -eq 4 ]
}

# ------------------------------------------------------------------
# check_zshrc_d
# ------------------------------------------------------------------

@test "check_zshrc_d: records warn when ~/.zshrc.d/ does not exist" {
  # HOME は BATS_TEST_TMPDIR で .zshrc.d は無い
  check_zshrc_d
  _has_status_for_category "warn" "zshrc.d"
}

@test "check_zshrc_d: records ok when ~/.zshrc has zshrc.d sourcing" {
  mkdir -p "$HOME/.zshrc.d"
  cat >"$HOME/.zshrc" <<'EOF'
if [ -d ~/.zshrc.d ]; then
  for file in ~/.zshrc.d/*.zsh; do
    [ -r "$file" ] && source "$file"
  done
fi
EOF
  check_zshrc_d
  _has_status_for_category "ok" "zshrc.d"
}

@test "check_zshrc_d: records warn when ~/.zshrc.d/ exists but ~/.zshrc lacks sourcing" {
  mkdir -p "$HOME/.zshrc.d"
  # NOTE: コメント文字列に "zshrc.d" を含めない（grep が誤検知するため）
  echo "# basic zshrc without sourcing logic" >"$HOME/.zshrc"
  check_zshrc_d
  _has_status_for_category "warn" "zshrc.d"
}

# ------------------------------------------------------------------
# check_chezmoi_drift
# ------------------------------------------------------------------

@test "check_chezmoi_drift: records warn when chezmoi is not installed" {
  # サブシェルで PATH を変更し teardown を保護
  mkdir -p "$BATS_TEST_TMPDIR/empty-bin"
  local results
  results=$(
    PATH="$BATS_TEST_TMPDIR/empty-bin"
    _DOCTOR_RESULTS=()
    check_chezmoi_drift
    printf '%s\n' "${_DOCTOR_RESULTS[@]}"
  )
  printf '%s\n' "$results" | grep -q "^warn|chezmoi|"
}
