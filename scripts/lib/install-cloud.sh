#!/bin/bash
# scripts/lib/install-cloud.sh
# クラウド CLI（AWS / Azure / GCP）のインストール。

# 7. クラウドツールのインストール
install_cloud_tools() {
  local any_installed=0

  # AWS CLI
  if [ "$INSTALL_AWS_CLI" = "1" ]; then
    [ "$any_installed" = "0" ] && {
      echo ""
      echo "☁️ クラウドツールをインストール中..."
      any_installed=1
    }

    if ! command -v aws &>/dev/null; then
      curl "https://awscli.amazonaws.com/awscli-exe-linux-$(uname -m).zip" -o "/tmp/awscliv2.zip"
      unzip -q /tmp/awscliv2.zip -d /tmp
      sudo /tmp/aws/install >/dev/null
      rm -rf /tmp/aws /tmp/awscliv2.zip
      echo "  ✅ AWS CLI インストール完了"
    else
      echo "  ℹ️  AWS CLI を最新版に更新中..."
      curl "https://awscli.amazonaws.com/awscli-exe-linux-$(uname -m).zip" -o "/tmp/awscliv2.zip"
      unzip -q /tmp/awscliv2.zip -d /tmp
      sudo /tmp/aws/install --update >/dev/null 2>&1
      rm -rf /tmp/aws /tmp/awscliv2.zip
      echo "  ⏭️  AWS CLI は最新版です"
    fi
  fi

  # Azure CLI
  if [ "$INSTALL_AZURE_CLI" = "1" ]; then
    [ "$any_installed" = "0" ] && {
      echo ""
      echo "☁️ クラウドツールをインストール中..."
      any_installed=1
    }

    if ! command -v az &>/dev/null; then
      curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
      echo "  ✅ Azure CLI インストール完了"
    else
      echo "  ℹ️  Azure CLI を最新版に更新中..."
      sudo apt-get update >/dev/null 2>&1
      if sudo apt-get install -y --only-upgrade azure-cli >/dev/null 2>&1; then
        echo "  ⏭️  Azure CLI は最新版です"
      else
        # パッケージが見つからない場合は再インストール
        curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash >/dev/null 2>&1
        echo "  ⏭️  Azure CLI は最新版です"
      fi
    fi
  fi

  # Google Cloud CLI
  if [ "$INSTALL_GCLOUD_CLI" = "1" ]; then
    [ "$any_installed" = "0" ] && {
      echo ""
      echo "☁️ クラウドツールをインストール中..."
      any_installed=1
    }

    if ! command -v gcloud &>/dev/null; then
      echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" |
        sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list >/dev/null
      curl https://packages.cloud.google.com/apt/doc/apt-key.gpg |
        sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add - >/dev/null 2>&1
      sudo apt-get update >/dev/null 2>&1
      sudo apt-get install -y google-cloud-cli >/dev/null
      echo "  ✅ Google Cloud CLI インストール完了"
    else
      echo "  ℹ️  Google Cloud CLI を最新版に更新中..."
      sudo apt-get update >/dev/null 2>&1
      if sudo apt-get install -y --only-upgrade google-cloud-cli >/dev/null 2>&1; then
        echo "  ⏭️  Google Cloud CLI は最新版です"
      else
        # パッケージが見つからない場合はスキップ（既にインストール済み）
        echo "  ⏭️  Google Cloud CLI は既にインストール済みです"
      fi
    fi
  fi

  [ "$any_installed" = "1" ] && echo "✅ クラウドツールインストール完了"
}
