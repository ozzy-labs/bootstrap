# =======================================================================
# tests/integration/Dockerfile
# -----------------------------------------------------------------------
# Ubuntu ベースイメージ上で install.sh local を非対話モードで実行し、
# 主要ツール導入と冪等性を検証するための統合テスト環境。
#
# ARG UBUNTU_VERSION には "22.04" / "24.04" / "devel" / "rolling" 等を指定。
# =======================================================================
ARG UBUNTU_VERSION=24.04
FROM ubuntu:${UBUNTU_VERSION}

# apt インストール時の対話プロンプト（tzdata 等）を抑制
ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Asia/Tokyo \
    LANG=C.UTF-8 \
    CI=true

# 最小限の前提パッケージ: スクリプトが自力でインストールする前段として必要
# - git: Git 設定の事前構成のため（最新版は setup-local-linux.sh が PPA から入れ直す）
# - gnupg: add-apt-repository が PPA の GPG 鍵をインポートする際に gpg-agent を必要とする。
#   ubuntu:22.04 の minimal イメージには未同梱のため明示的に追加する。
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        sudo \
        git \
        gnupg \
        locales \
        tzdata \
        software-properties-common \
    && rm -rf /var/lib/apt/lists/*

# 非 root のテストユーザー + passwordless sudo
RUN useradd --create-home --shell /bin/bash testuser \
    && echo 'testuser ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/testuser \
    && chmod 0440 /etc/sudoers.d/testuser

# リポジトリをコピー
WORKDIR /workspace
COPY --chown=testuser:testuser . /workspace

USER testuser

# Git の最低限の設定（setup-local-linux.sh の Git 設定プロンプトを回避）
RUN git config --global user.name "Test User" \
    && git config --global user.email "test@example.com"

# コンテナ内では動かせないツールを事前に除外:
#   - Docker Engine: DinD 必要のため INSTALL_CONTAINER=0
#   - Azure/GCP CLI: 重量級 opt-in のためデフォルト 0 のまま
ENV INSTALL_CONTAINER=0

ENTRYPOINT ["/workspace/tests/integration/entrypoint.sh"]
