#!/bin/bash
# scripts/lib/docker.sh
# Docker 公式リポジトリのセットアップと Docker Engine / Compose のインストール。
# このファイルは source して利用する。

# Docker 公式リポジトリをセットアップする関数
setup_docker_repository() {
  # Docker 公式リポジトリが既に設定されているかを確認
  if [ -f /etc/apt/sources.list.d/docker.list ] && grep -q "download.docker.com" /etc/apt/sources.list.d/docker.list 2>/dev/null; then
    echo "  ⏭️  Docker 公式リポジトリは既にセットアップ済みです"
    return
  fi

  echo "  ℹ️  Docker 公式リポジトリをセットアップしています..."

  # 依存パッケージのインストール
  sudo apt-get install -y ca-certificates curl gnupg >/dev/null

  # GPG キーの登録
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  sudo chmod a+r /etc/apt/keyrings/docker.gpg

  # リポジトリの追加
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
      https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" |
    sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

  # パッケージリストの更新
  sudo apt-get update >/dev/null

  echo "  ✅ Docker 公式リポジトリをセットアップしました"
}

# Docker Compose (CLIプラグイン) をインストールするフォールバック実装
install_docker_compose_binary() {
  local compose_version="${DOCKER_COMPOSE_VERSION:-v2.27.0}"
  local arch
  case "$(uname -m)" in
  x86_64 | amd64)
    arch="x86_64"
    ;;
  aarch64 | arm64)
    arch="aarch64"
    ;;
  *)
    echo "  ⚠️  未対応アーキテクチャ ($(uname -m)) のため、Docker Compose バイナリの自動インストールに失敗しました"
    return 1
    ;;
  esac

  local plugin_dir="$HOME/.docker/cli-plugins"
  mkdir -p "$plugin_dir"

  echo "  ℹ️  Docker Compose バイナリ (${compose_version}, ${arch}) をダウンロードしています..."
  if curl -fsSL "https://github.com/docker/compose/releases/download/${compose_version}/docker-compose-linux-${arch}" \
    -o "${plugin_dir}/docker-compose"; then
    chmod +x "${plugin_dir}/docker-compose"
    echo "  ✅ Docker Compose バイナリを ${plugin_dir} に配置しました"
    return 0
  fi

  echo "  ⚠️  Docker Compose バイナリのダウンロードに失敗しました"
  return 1
}

# Docker Engine と Compose Plugin をインストールする関数
install_docker_engine_and_compose() {
  setup_docker_repository

  # Docker Engine + Compose Plugin をインストール
  if sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin; then
    return 0
  fi

  echo "  ⚠️  Docker 公式パッケージのインストールに失敗しました"
  return 1
}
