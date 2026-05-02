#!/usr/bin/env bats
# =======================================================================
# tests/unit/apt.bats
# -----------------------------------------------------------------------
# scripts/lib/apt.sh のヘルパー関数を sudo / apt-get / dpkg / command を
# モックして検証する。実際の apt 操作は行わない。
# =======================================================================

setup() {
  SCRIPT_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
  # shellcheck disable=SC1091
  source "$SCRIPT_ROOT/scripts/lib/apt.sh"

  # モック呼び出しログのファイル
  export MOCK_LOG="$BATS_TEST_TMPDIR/mock.log"
  : >"$MOCK_LOG"
}

# モック: sudo は引数をそのままログして 0 を返す
sudo() {
  echo "sudo $*" >>"$MOCK_LOG"
  return 0
}
export -f sudo

# モック: apt-get は引数をログして 0 を返す
apt-get() {
  echo "apt-get $*" >>"$MOCK_LOG"
  return 0
}
export -f apt-get

# ------------------------------------------------------------------
# apt_install_or_upgrade: コマンド未存在 → install
# ------------------------------------------------------------------

@test "apt_install_or_upgrade: installs when command is missing" {
  # command -v をモックして「未存在」を返す
  command() {
    if [ "$1" = "-v" ]; then
      return 1
    fi
    builtin command "$@"
  }
  export -f command

  run apt_install_or_upgrade "tree" "tree" "tree-missing-command"
  [ "$status" -eq 0 ]
  [[ "$output" == *"インストール完了"* ]]
  grep -q "apt-get install -y tree" "$MOCK_LOG"
}

# ------------------------------------------------------------------
# apt_install_or_upgrade: コマンド存在 → upgrade
# ------------------------------------------------------------------

@test "apt_install_or_upgrade: upgrades when command exists" {
  # command -v をモックして「存在」を返す（必ず /bin/true 等の実在コマンドを使う）
  run apt_install_or_upgrade "bash" "bash" "bash"
  [ "$status" -eq 0 ]
  [[ "$output" == *"最新版です"* ]]
  grep -q "apt-get install -y --only-upgrade bash" "$MOCK_LOG"
}

# ------------------------------------------------------------------
# apt_install_or_upgrade: display_name 省略時は package_name を表示
# ------------------------------------------------------------------

@test "apt_install_or_upgrade: defaults display_name to package_name" {
  run apt_install_or_upgrade "bash"
  [ "$status" -eq 0 ]
  [[ "$output" == *"bash"* ]]
}

# ------------------------------------------------------------------
# apt_add_repository_with_retry: 1 回目で成功 → リトライしない
# ------------------------------------------------------------------

@test "apt_add_repository_with_retry: succeeds on first attempt" {
  run apt_add_repository_with_retry -y ppa:test/ppa
  [ "$status" -eq 0 ]
  local count
  count=$(grep -c "sudo add-apt-repository" "$MOCK_LOG")
  [ "$count" -eq 1 ]
}

# ------------------------------------------------------------------
# apt_add_repository_with_retry: 失敗 → リトライして成功
# ------------------------------------------------------------------

@test "apt_add_repository_with_retry: retries on failure and eventually succeeds" {
  export MOCK_FAILS_LEFT=2
  sudo() {
    echo "sudo $*" >>"$MOCK_LOG"
    if [ "$1" = "add-apt-repository" ] && [ "${MOCK_FAILS_LEFT:-0}" -gt 0 ]; then
      MOCK_FAILS_LEFT=$((MOCK_FAILS_LEFT - 1))
      export MOCK_FAILS_LEFT
      return 1
    fi
    return 0
  }
  export -f sudo

  # バックオフ待機をスキップしてテストを高速化
  sleep() { :; }
  export -f sleep

  run apt_add_repository_with_retry -y ppa:test/ppa
  [ "$status" -eq 0 ]
  local count
  count=$(grep -c "sudo add-apt-repository" "$MOCK_LOG")
  [ "$count" -eq 3 ]
  [[ "$output" == *"再試行"* ]]
}

# ------------------------------------------------------------------
# apt_add_repository_with_retry: 最大試行回数まで失敗 → 非 0 を返す
# ------------------------------------------------------------------

@test "apt_add_repository_with_retry: fails after max attempts" {
  sudo() {
    echo "sudo $*" >>"$MOCK_LOG"
    if [ "$1" = "add-apt-repository" ]; then
      return 1
    fi
    return 0
  }
  export -f sudo

  sleep() { :; }
  export -f sleep

  run apt_add_repository_with_retry -y ppa:test/ppa
  [ "$status" -ne 0 ]
  local count
  count=$(grep -c "sudo add-apt-repository" "$MOCK_LOG")
  [ "$count" -eq 3 ]
  [[ "$output" == *"接続不能"* ]]
}
