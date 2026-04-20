#!/bin/bash
# =======================================================================
# tests/integration/run.sh
# -----------------------------------------------------------------------
# ローカルで Docker 統合テストを走らせるハーネス。
#
# Usage:
#   ./tests/integration/run.sh                 # デフォルト (24.04)
#   ./tests/integration/run.sh 22.04           # 単一バージョン
#   ./tests/integration/run.sh 22.04 24.04     # 複数バージョン逐次
#   ./tests/integration/run.sh devel           # Canary（次期 Ubuntu）
# =======================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

if ! command -v docker >/dev/null 2>&1; then
  echo "⚠️  docker コマンドが見つかりません"
  exit 1
fi

# mise が GitHub API をレートリミット無しで叩けるよう、利用可能ならトークンを渡す
# 優先順位: GITHUB_TOKEN env > gh CLI のトークン
DOCKER_ENV_ARGS=()
TOKEN_SOURCE=""
if [ -n "${GITHUB_TOKEN:-}" ]; then
  DOCKER_ENV_ARGS+=(-e "GITHUB_TOKEN=${GITHUB_TOKEN}")
  TOKEN_SOURCE="env"
elif command -v gh >/dev/null 2>&1; then
  if _token=$(gh auth token 2>/dev/null); then
    DOCKER_ENV_ARGS+=(-e "GITHUB_TOKEN=${_token}")
    TOKEN_SOURCE="gh"
  fi
fi
if [ -n "$TOKEN_SOURCE" ]; then
  echo "ℹ️  GITHUB_TOKEN を container に渡します (source: $TOKEN_SOURCE)"
fi

VERSIONS=("$@")
if [ "${#VERSIONS[@]}" -eq 0 ]; then
  VERSIONS=("24.04")
fi

FAILED_VERSIONS=()

for version in "${VERSIONS[@]}"; do
  printf '\n═══════════════════════════════════════════\n'
  printf '🐳 Testing against ubuntu:%s\n' "$version"
  printf '═══════════════════════════════════════════\n'

  tag="bootstrap-test:${version//[^A-Za-z0-9._-]/-}"

  if ! docker build \
    --build-arg "UBUNTU_VERSION=${version}" \
    -t "$tag" \
    -f "$SCRIPT_DIR/Dockerfile" \
    "$REPO_ROOT"; then
    echo "❌ docker build failed for ubuntu:${version}"
    FAILED_VERSIONS+=("$version")
    continue
  fi

  if ! docker run --rm "${DOCKER_ENV_ARGS[@]}" "$tag"; then
    echo "❌ docker run failed for ubuntu:${version}"
    FAILED_VERSIONS+=("$version")
    continue
  fi

  printf '\n✅ ubuntu:%s passed\n' "$version"
done

printf '\n═══════════════════════════════════════════\n'
if [ "${#FAILED_VERSIONS[@]}" -eq 0 ]; then
  printf '✅ All %d version(s) passed\n' "${#VERSIONS[@]}"
  exit 0
else
  printf '❌ %d version(s) failed: %s\n' "${#FAILED_VERSIONS[@]}" "${FAILED_VERSIONS[*]}"
  exit 1
fi
