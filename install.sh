#!/usr/bin/env bash
set -euo pipefail

readonly REPO_OWNER="ozzy-labs"
readonly REPO_NAME="bootstrap"
readonly DEFAULT_REF="${WSL_DEV_SETUP_REF:-main}"

usage() {
  cat <<'EOF'
Usage:
  ./install.sh [zsh|local|all|update] [--ref <git-ref>]
  curl -fsSL https://raw.githubusercontent.com/ozzy-labs/bootstrap/main/install.sh | bash -s -- [zsh|local|all|update] [--ref <git-ref>]

Commands:
  zsh     Run scripts/setup-zsh-ubuntu.sh
  local   Run scripts/setup-local-ubuntu.sh
  all     Run both setup scripts in order (default)
  update  Run scripts/update-tools.sh (batch-update mise/uv/npm managed tools)

Options:
  --ref <git-ref>  Download scripts from the specified branch, tag, or commit
  -h, --help       Show this help message

Environment:
  WSL_DEV_SETUP_REF  Default git ref to download when running remotely
  SETUP_LOG          Passed through to the underlying setup/update script(s)
EOF
}

log() {
  printf '%s\n' "$*"
}

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"
}

download_to_stdout() {
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$1"
    return
  fi

  if command -v wget >/dev/null 2>&1; then
    wget -qO- "$1"
    return
  fi

  die "curl or wget is required to download setup files"
}

run_script() {
  local script_path="$1"

  [ -x "$script_path" ] || chmod +x "$script_path"
  log ""
  log "==> Running $(basename "$script_path")"
  "$script_path"
}

run_local() {
  local target="$1"
  local base_dir="$2"

  case "$target" in
  zsh)
    run_script "$base_dir/scripts/setup-zsh-ubuntu.sh"
    ;;
  local)
    run_script "$base_dir/scripts/setup-local-ubuntu.sh"
    ;;
  all)
    run_script "$base_dir/scripts/setup-zsh-ubuntu.sh"
    run_script "$base_dir/scripts/setup-local-ubuntu.sh"
    ;;
  update)
    run_script "$base_dir/scripts/update-tools.sh"
    ;;
  *)
    die "Unknown command: $target"
    ;;
  esac
}

main() {
  local target="all"
  local ref="$DEFAULT_REF"

  while [ "$#" -gt 0 ]; do
    case "$1" in
    zsh | local | all | update)
      target="$1"
      ;;
    --ref)
      [ "$#" -ge 2 ] || die "--ref requires a value"
      ref="$2"
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      die "Unknown argument: $1"
      ;;
    esac
    shift
  done

  if [ -n "${BASH_SOURCE[0]:-}" ]; then
    local source_path
    source_path="${BASH_SOURCE[0]}"
    if [ -f "$source_path" ]; then
      local script_dir
      script_dir="$(cd "$(dirname "$source_path")" && pwd)"
      if [ -f "$script_dir/scripts/setup-zsh-ubuntu.sh" ] && [ -f "$script_dir/scripts/setup-local-ubuntu.sh" ]; then
        run_local "$target" "$script_dir"
        return
      fi
    fi
  fi

  require_command tar
  require_command mktemp

  local tmp_dir
  tmp_dir="$(mktemp -d)"
  # trap は EXIT 発火時点（main 関数を抜けた後）にも評価されるため、
  # local 変数を遅延展開すると set -u 下で unbound variable になる。
  # ここでは tmp_dir の値を即時展開して固定文字列としてトラップに焼き込む。
  # mktemp -d はシングルクォートを含むパスを返さないため安全。
  # shellcheck disable=SC2064  # 即時展開は意図的（local スコープ問題の回避）
  trap "rm -rf -- '$tmp_dir'" EXIT

  local archive_url
  archive_url="https://codeload.github.com/${REPO_OWNER}/${REPO_NAME}/tar.gz/${ref}"

  log "==> Downloading ${REPO_OWNER}/${REPO_NAME} (${ref})"
  download_to_stdout "$archive_url" | tar -xzf - -C "$tmp_dir"

  local extracted_dir
  extracted_dir="$(find "$tmp_dir" -mindepth 1 -maxdepth 1 -type d | sort | head -n 1)"
  [ -n "$extracted_dir" ] || die "Failed to unpack downloaded archive"

  run_local "$target" "$extracted_dir"
}

main "$@"
