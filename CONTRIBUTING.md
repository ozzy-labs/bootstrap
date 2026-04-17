# Contributing

本プロジェクトは [ozzy-labs](https://github.com/ozzy-labs) が個人で運用しており、外部コントリビューションは受け付けていません。バグ報告や機能要望は Issue で歓迎します。

## 言語ポリシー

- 外部ユーザー向けドキュメント（`README.md` / `CHANGELOG.md`）は英語・日本語の両方を用意
- 内部成果物（コミット description / PR / Issue / コードコメント / CI 設定など）は**日本語**
- 形式規約（Conventional Commits の `<type>:` プレフィックス、ブランチ名の `<type>/<slug>` 構造）は英語
- 詳細は [`.claude/rules/git-workflow.md`](./.claude/rules/git-workflow.md) を参照

## テスト

### 非対話モード

CI / Docker で対話プロンプトをスキップする際は、以下のいずれかを設定します：

```bash
WSL_DEV_SETUP_ASSUME_YES=1 ./install.sh local    # 明示的 opt-in
CI=true ./install.sh local                        # ほとんどの CI で自動設定される標準変数
```

挙動：

- `[Y/n]` プロンプト → 自動 `Y`（インストール）
- `[y/N]` プロンプト（Azure CLI / Google Cloud CLI / 非 Ubuntu 確認）→ 自動 `N`（スキップ / 中止）
- Git ユーザー名 / メール: 事前に `git config --global user.{name,email}` で設定しておけば既存の「設定済み」パスに乗る

### ローカルでのテスト実行

```bash
# L0: Smoke tests（約 500ms、ネットワーク不要）
./tests/smoke/run.sh

# L1: Static analysis（通常は lefthook が commit 時に自動実行）
mise exec -- shellcheck --severity=warning install.sh scripts/*.sh tests/smoke/run.sh tests/integration/*.sh
mise exec -- shfmt -d install.sh scripts/*.sh tests/smoke/run.sh tests/integration/*.sh
mise exec -- markdownlint-cli2 '**/*.md'
mise exec -- yamllint -c .yamllint.yaml .github/workflows .mise.toml .yamllint.yaml lefthook.yaml lefthook-base.yaml .markdownlint-cli2.yaml
mise exec -- actionlint .github/workflows/*.yaml
mise exec -- gitleaks detect --no-banner --redact -v

# L2: BATS ユニットテスト
mise exec -- bats tests/unit/

# L3: Docker 統合テスト（バージョン毎に約 5-10 分）
./tests/integration/run.sh                 # デフォルト: ubuntu:24.04
./tests/integration/run.sh 22.04 24.04     # 複数バージョン
./tests/integration/run.sh devel           # Canary（次期 Ubuntu）
```

`tests/integration/run.sh` は `GITHUB_TOKEN`（環境変数 or `gh auth token`）を自動検出してコンテナに渡します。これにより mise の GitHub API レートリミットが 60 req/hr → 5000 req/hr に拡大し、短時間で繰り返しテストしても詰まらなくなります。

### CI（GitHub Actions）

| ワークフロー | トリガー | 内容 |
|---|---|---|
| `lint.yaml` | PR + main push | shellcheck / shfmt / markdownlint / yamllint / gitleaks |
| `test-smoke.yaml` | PR + main push | `tests/smoke/run.sh` を実行（Docker 不要） |
| `test-unit.yaml` | PR + main push | `mise` 経由で BATS スイートを実行 |
| `test-integration.yaml` | main push / 手動 / `ci:integration` ラベル付き PR | 22.04 + 24.04 matrix で `tests/integration/run.sh` を実行 |
| `canary.yaml` | 週次（月曜 03:00 UTC）+ 手動 | `ubuntu:devel` / `ubuntu:rolling` で統合 harness を実行し、失敗時に Issue 自動起票 |

統合テストは PR では opt-in（1 バージョン約 5 分）で、コード変更のみの PR のフィードバックを高速に保ちます。`scripts/setup-local-ubuntu.sh` や `tests/integration/` を変更する PR では `ci:integration` ラベルを付与してください。

### Canary トリアージ

Canary ワークフローが失敗すると、`canary` + `investigation-needed` ラベル付きの Issue が自動起票されます。Issue 本文には run URL とトリアージチェックリストが含まれます：

1. **apt パッケージ名の変更・削除** — 次期 Ubuntu でパッケージが rename / 廃止された可能性（例: `tesseract-ocr-jpn`）
2. **PPA が新 Ubuntu 未対応** — `ppa:git-core/ppa` など
3. **上流ツールの破壊的変更** — mise / gitleaks / ast-grep 等のメジャーバンプ
4. **インストーラ仕様変更** — `mise.run` / `astral.sh/uv` 等の flag 変更
5. **一時的なネットワーク問題** — `gh workflow run canary.yaml` で再実行して緑なら "transient" として close

Canary 失敗はメインラインをブロックしません。次期 LTS リリース前に上流変更を検知し、事前対応の時間を確保するための仕組みです。

### WSL2 実機スモークチェックリスト（リリース前）

Docker は Ubuntu userspace を再現しますが、WSL2 固有要素（systemd / `wslu` / Windows interop）までは再現できません。リリース前に実機の WSL2/Ubuntu で以下を確認してください：

- [ ] `install.sh zsh` が完走し、新しいターミナルで `echo $SHELL` が zsh を指す
- [ ] `install.sh local` が完走し、`mise --version` / `node --version` / `pnpm --version` / `python3 --version` / `uv --version` / `gitleaks version` が動作する
- [ ] 既存セットアップ済み環境で `install.sh update` がエラーなく完了する
- [ ] `wslview https://example.com` で Windows 既定ブラウザが開く
- [ ] `sudo service docker start` が成功し、`docker run --rm hello-world` が動作する
- [ ] `echo $LANG` が `ja_JP.UTF-8`、`date` が JST 表示
- [ ] `git config --global user.name` / `user.email` が意図通り設定されている
- [ ] AI CLI 認証フロー（`claude auth login` / `codex auth login` / `copilot` / `gemini`）が正しく起動する

### ブランチ保護の推奨設定（repo owner 向け）

- `main` への直接 push 禁止
- 必須ステータスチェック: `lint` / `test-smoke` / `test-unit`
- `test-integration` は任意（`ci:integration` ラベル付き PR または main push で自動実行）

## ライセンス

本プロジェクトへの関与により、提供されるコントリビューションは [MIT License](LICENSE) で配布されることに同意するものとします。
