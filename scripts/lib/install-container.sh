#!/bin/bash
# scripts/lib/install-container.sh
# コンテナ / サンドボックスツール（Docker, Docker Compose, bubblewrap）のインストール。
# 前提: lib/apt.sh, lib/docker.sh が事前に source されていること。

# 6. コンテナ / サンドボックスツールのインストール
install_container_tools() {
  [ "$INSTALL_CONTAINER" != "1" ] && return

  echo ""
  echo "🐳 コンテナ / サンドボックスツールをインストール中..."

  # bubblewrap
  apt_install_or_upgrade "bubblewrap" "bubblewrap" "bwrap"

  # Docker のインストール・アップデート
  if ! command -v docker &>/dev/null; then
    if install_docker_engine_and_compose; then
      echo "  ✅ Docker + Docker Compose インストール完了"
    else
      echo "  ⚠️  Docker のインストールに失敗しました"
      return 1
    fi
  else
    echo "  ℹ️  Docker を最新安定版に更新中..."
    setup_docker_repository
    sudo apt-get update >/dev/null 2>&1
    sudo apt-get install -y --only-upgrade docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin >/dev/null 2>&1
    echo "  ⏭️  Docker は最新安定版です"
  fi

  # Docker サービスの起動
  if ! sudo service docker status >/dev/null 2>&1; then
    sudo service docker start >/dev/null
    echo "  ✅ Docker サービス起動完了"
  else
    echo "  ⏭️  Docker サービスは既に起動しています"
  fi

  # 現在のユーザーを docker グループに追加
  if ! groups | grep -q docker; then
    sudo usermod -aG docker "$USER"
    echo "  ✅ dockerグループに追加しました（次回ログイン時から有効）"
  else
    echo "  ⏭️  既にdockerグループに所属しています"
  fi

  echo "✅ コンテナ / サンドボックスツールインストール完了"
}
