# wsl-dev-setup

**WSL2/Ubuntu Host Environment Setup Scripts for Dev Container Development**

**English | [日本語](README.ja.md)**

A comprehensive collection of shell scripts to set up development tools on WSL2/Ubuntu environments. The toolkit focuses on fast, repeatable host bootstrap workflows for Dev Container-centric development, ensuring consistent setups across teams.

## Table of Contents

- [1. Repository Background](#1-repository-background)
- [2. Repository Structure](#2-repository-structure)
- [3. Features](#3-features)
- [4. Quick Start](#4-quick-start)
- [5. Prerequisites](#5-prerequisites)
- [6. Scripts](#6-scripts)
  - [6.1 setup-zsh-ubuntu.sh](#61-setup-zsh-ubuntush)
  - [6.2 setup-local-ubuntu.sh](#62-setup-local-ubuntush)
- [7. Troubleshooting](#7-troubleshooting)
- [8. Contributing](#8-contributing)
- [9. Changelog](#9-changelog)

## 1. Repository Background

- Built to provide a single source of truth for host provisioning scripts targeting Dev Container workflows on WSL2/Ubuntu.
- Emphasizes idempotent execution, detailed diagnostics, and modern tooling defaults (Volta, uv, pnpm, Docker, AI CLIs).
- Versioned independently from application repositories so host requirements can evolve quickly, with the initial public release matching v1.0.0 of the original scripts.

## 2. Repository Structure

```
wsl-dev-setup/
├── install.sh
├── README.md
├── README.ja.md
└── scripts/
    ├── setup-local-ubuntu.sh
    └── setup-zsh-ubuntu.sh
```

## 3. Features

- 🤖 **AI Development Tools** - Supports Claude Code, Codex CLI, GitHub Copilot CLI, and Gemini CLI
- 🐳 **Container Development** - Docker Engine and Docker Compose (essential for Dev Containers)
- 📦 **Modern Package Management** - Volta (Node.js LTS), uv (Python latest stable), pnpm
- ☁️ **Cloud Development** - AWS CLI v2, GitHub CLI
- 🔒 **Security** - Global git-secrets configuration (prevents accidental commits of sensitive data)
- 🎨 **Enhanced Shell Experience** - zsh + oh-my-zsh + plugins
- ✅ **Idempotency** - Safe to run multiple times
- 📝 **Detailed Logging** - Optional log output for troubleshooting
- 🛠️ **Unified Error Handling** - Clear error messages with actionable solutions

## 4. Quick Start

```bash
# 1. Set up zsh (recommended first)
curl -fsSL https://raw.githubusercontent.com/ozzy-labs/wsl-dev-setup/main/install.sh | bash -s -- zsh

# 2. Restart your terminal
exit
# Open a new terminal

# 3. Set up development tools
curl -fsSL https://raw.githubusercontent.com/ozzy-labs/wsl-dev-setup/main/install.sh | bash -s -- local

# 4. Complete required authentications
aws configure      # or: aws configure sso
gh auth login
claude auth login
codex auth login
copilot             # authenticate with /login on first launch
gemini              # authenticate with Google account on first launch
```

If you prefer to inspect the repository first:

```bash
git clone https://github.com/ozzy-labs/wsl-dev-setup.git
cd wsl-dev-setup
./install.sh zsh
./install.sh local
```

## 5. Prerequisites

These scripts are designed to set up the **WSL2/Ubuntu environment (host side)**.

- **Development Style**: Assumes development within Dev Containers
- **Target Environment**: WSL2/Ubuntu (host side)
- **Purpose**: Setting up the host environment to run Dev Containers

Dev Container environments are automatically built from `.devcontainer/` configuration, so you don't need to set them up directly with these scripts.

## 6. Scripts

### 6.1 setup-zsh-ubuntu.sh

Sets up zsh + oh-my-zsh + plugins on WSL2/Ubuntu environment.

You can run it either through `install.sh` or directly via `scripts/setup-zsh-ubuntu.sh`.

**6.1.1 What Gets Installed**

- **curl** - Required for oh-my-zsh installation
- **git** - Required for plugin installation
- **zsh** - Shell itself
- **oh-my-zsh** - zsh framework
- **zsh-completions** - Additional completion definitions
- **zsh-autosuggestions** - Command auto-completion
- **zsh-history-substring-search** - Enhanced history search
- **zsh-syntax-highlighting** - Command syntax highlighting
- Automatic `.zshrc` plugins configuration
- Interactive plugin selection (install all or choose individually)

**6.1.2 Key Features**

- ✅ **Idempotency** - Safe to run multiple times
  - Robust plugin detection (handles existing `plugins=(git docker)` etc.)
  - Adds new plugins while preserving existing ones
- ✅ **Environment Check** - Only runs on Ubuntu/Debian systems
- ✅ **Automatic Dependency Resolution** - Pre-installs curl and git
- ✅ **Automatic Configuration** - Automatically updates .zshrc plugin settings
  - Supports various plugin configurations (handles different space-separated variations)
- ✅ **Default Shell Change** - Sets zsh as default shell (provides fallback instructions on failure)
- ✅ **Error Handling** - Error checking for all critical operations
- ✅ **Logging Feature** - Optional log output for troubleshooting
- ✅ **Detailed Comments** - Explanatory comments for complex processes

**6.1.3 Usage**

```bash
# Via install.sh (recommended for first-time setup)
curl -fsSL https://raw.githubusercontent.com/ozzy-labs/wsl-dev-setup/main/install.sh | bash -s -- zsh

# Basic execution from a cloned repository
./install.sh zsh

# Direct script execution
./scripts/setup-zsh-ubuntu.sh

# With logging
SETUP_LOG=1 ./install.sh zsh

# Specify custom log file path
SETUP_LOG=/path/to/setup.log ./install.sh zsh

# Restart shell (activates zsh)
exec zsh
```

**6.1.4 Post-Setup Verification**

```bash
# Check if zsh is running
echo $SHELL

# Check oh-my-zsh version
omz version

# Verify plugins are enabled
echo $plugins
```

**6.1.5 Notes**

- For WSL2/Ubuntu environment **outside** Dev Container
- Inside Dev Container, it's automatically set up via Dockerfile
- Safe to run multiple times (idempotent)
- If default shell change fails, manual setup instructions will be displayed

---

### 6.2 setup-local-ubuntu.sh

Comprehensive setup script that installs required development tools on WSL2/Ubuntu environment.

You can run it either through `install.sh` or directly via `scripts/setup-local-ubuntu.sh`.

**6.2.1 Installed Tools**

1. **System Configuration**
   - **Locale/Timezone** - Automatically sets ja_JP.UTF-8 and Asia/Tokyo
   - **Dev Container mount directories** - `~/.aws`, `~/.claude`, `~/.gemini`, `~/.config/gh`, `~/.local/share/pnpm`, etc.
2. **Basic CLI Tools**
   - **build-essential** - C/C++ compilers and build tools
   - **tree** - Directory structure visualization
   - **fzf** - Fuzzy finder (Ctrl+R for history search)
   - **jq** - JSON processing
   - **ripgrep** - Fast text search tool
   - **fd-find** - Fast and user-friendly alternative to find
   - **unzip** - Archive extraction (required for AWS CLI)
   - **wslu** - Utility for opening browsers on WSL2
3. **Node.js Ecosystem**
   - **Volta** - Node.js version manager (recommended)
   - **Node.js LTS** - JavaScript runtime
   - **pnpm** - Fast package manager
4. **Python Ecosystem**
   - **uv** - Fast Python package installer
   - **Python (latest stable)** - Python runtime
5. **Version Control Tools**
   - **Git** - Version control system
   - **GitHub CLI** - GitHub operations
   - **git-secrets** - Prevents accidental commits of sensitive data (globally configured)
   - **Git basic config** - user.name, user.email, core.editor, etc.
6. **Container Tools**
   - **Docker Engine** - Container runtime
   - **Docker Compose** - Multi-container management tool (essential for Dev Containers)
   - **Docker service auto-start** - Service startup on WSL2
7. **Cloud Tools**
   - **AWS CLI v2** - AWS resource operations
   - **Azure CLI** - Microsoft Azure resource operations
   - **Google Cloud CLI** - Google Cloud Platform resource operations
8. **AI Tools**
   - **Claude Code** - Interactive development tool with Claude AI
   - **Codex CLI** - OpenAI Codex CLI (code generation AI)
   - **GitHub Copilot CLI** - GitHub Copilot coding agent for the terminal
   - **Gemini CLI** - Google Gemini AI agent for the terminal
   - Multi-agent support: shared skills in `.agents/skills/` (Agent Skills standard), `AGENTS.md` as common entry point, Claude Code overlays in `.claude/skills/`
9. **Development Utilities**
   - **just** - Task runner
   - **zoxide** - Smarter cd command with directory jumping

**6.2.2 Key Features**

- ✅ **Interactive Tool Selection** - Choose which tools to install (install all or select individually)
- ✅ **Idempotency** - Safe to run multiple times
- ✅ **Environment Check** - Only runs on Ubuntu/Debian systems
- ✅ **Unified Error Handling** - Error checking for all critical operations
  - Unified format (cause analysis + solution + manual commands)
  - Easy troubleshooting
- ✅ **Detailed Error Messages** - Provides troubleshooting hints
- ✅ **Input Validation** - Git email address format checking
- ✅ **Logging Feature** - Optional log output for troubleshooting
- ✅ **DRY Principle** - Minimizes code duplication
  - Consistent use of `add_to_shell_config` function
  - Unified shell configuration management
- ✅ **Interactive Configuration** - Interactive Git username/email setup
- ✅ **Security Features** - Automates git-secrets global configuration
- ✅ **Detailed Summary Display** - Easy verification of installation results
- ✅ **Clear Variable Management** - Explicit initialization and scope management of global variables
- ✅ **Detailed Comments** - Explanatory comments for complex processes (pipelines, regex, etc.)

**6.2.3 Usage**

```bash
# Via install.sh (recommended for first-time setup)
curl -fsSL https://raw.githubusercontent.com/ozzy-labs/wsl-dev-setup/main/install.sh | bash -s -- local

# Basic execution from a cloned repository
./install.sh local

# Direct script execution
./scripts/setup-local-ubuntu.sh

# With logging (default path: ~/setup-local-ubuntu-YYYYMMDD-HHMMSS.log)
SETUP_LOG=1 ./install.sh local

# Specify custom log file path
SETUP_LOG=/var/log/setup.log ./install.sh local

# Completely close and re-login to terminal
# (exec is not sufficient to ensure PATH is applied)
exit
```

**6.2.4 Recommended Post-Setup Steps**

1. **Configure AWS credentials**:

   ```bash
   aws configure      # For IAM user
   aws configure sso  # For SSO
   ```

2. **GitHub authentication**:

   ```bash
   gh auth login
   ```

3. **AI tool authentication**:

   ```bash
   claude auth login   # Claude Code
   codex auth login    # Codex CLI
   copilot             # GitHub Copilot CLI (authenticate with /login on first launch)
   gemini              # Gemini CLI (authenticate with Google account on first launch)
   ```

4. **Verify tool installation**:

   ```bash
   # Version checks
   volta --version
   node --version
   pnpm --version
   uv --version
   python3 --version
   aws --version
   gh --version
   claude --version
   codex --version
   copilot --version
   gemini --version
   docker --version
   docker compose version
   command -v git-secrets  # git-secrets doesn't have --version option
   just --version
   ```

**6.2.5 Git Configuration**

The following settings are configured interactively during script execution:

- `user.name` - Git username (default: current username)
- `user.email` - Git email address (with format validation)
- `core.editor` - Default editor (vim)
- `init.defaultBranch` - Default branch (main)
- `core.autocrlf` - Line ending configuration (input)
- `core.fileMode` - Track execution permissions (true)

**6.2.6 Error Handling**

All critical operations include error checking with detailed information in a unified format:

**Unified Error Message Format**:

```
⚠️  Error message
ℹ️  Possible causes:
    - Cause 1
    - Cause 2
ℹ️  Solutions:
    1. Step 1
    2. Step 2
ℹ️  Manual verification/execution: command
```

**Example 1: apt update failure**

```bash
⚠️  システムパッケージの更新に失敗しました
ℹ️  考えられる原因:
    - ネットワーク接続の問題
    - パッケージリポジトリの障害
    - /etc/apt/sources.list の設定ミス
ℹ️  手動で確認: sudo apt update
```

**Example 2: Volta not found**

```bash
⚠️  Volta が見つかりません
ℹ️  考えられる原因:
    - Volta のインストールが完了していない
    - インストール直後で PATH が反映されていない
ℹ️  対処法:
    1. ターミナルを完全に閉じて再ログイン（exit）
    2. このスクリプトを再実行
ℹ️  手動で確認: volta --version
```

**Example 3: Docker service startup failure**

```bash
⚠️  Docker サービスの起動に失敗しました
ℹ️  考えられる原因:
    - Docker のインストールが不完全
    - システムのサービス管理に問題がある
    - カーネルモジュールが読み込まれていない
ℹ️  対処法:
    1. Docker のインストール状態を確認: dpkg -l | grep docker
    2. サービスの詳細なステータスを確認: sudo service docker status
ℹ️  手動で起動する場合: sudo service docker start
```

**6.2.7 Log Files**

Setting the `SETUP_LOG` environment variable records all output to a log file:

```bash
# Record to default path (~/setup-local-ubuntu-YYYYMMDD-HHMMSS.log)
SETUP_LOG=1 ./install.sh local

# Record to custom path
SETUP_LOG=/tmp/setup.log ./install.sh local
```

Logs include:

- All output messages
- Error messages
- User input (Git configuration, etc.)
- Installation results

**6.2.8 Notes**

- For WSL2/Ubuntu environment **outside** Dev Container
- Inside Dev Container, necessary tools are already installed
- Safe to run multiple times (idempotent)
- On non-Ubuntu/Debian systems, a warning is displayed and confirmation is requested
- If Git username/email is not set, interactive configuration is prompted
- Whitespace-only input and invalid email addresses are validated

---

## 7. Troubleshooting

### 7.1 Common Issues

**7.1.1 apt update fails**

```bash
# Error message example
⚠️  Failed to update system packages

# Solution
1. Check network connection
2. Run sudo apt update manually to see detailed errors
3. Validate /etc/apt/sources.list configuration
```

**7.1.2 Volta/uv not found**

```bash
# Error message example
⚠️  Volta not found
ℹ️  Possible causes:
    - Volta installation did not finish successfully
    - PATH is not refreshed right after installation
ℹ️  Solutions:
    1. Completely close the terminal (exit) and reopen
    2. Rerun this script
ℹ️  Manual verification: volta --version

# Additional verification steps
1. Close terminal and reopen
2. Check PATH via: echo $PATH
3. Confirm Volta installation: ls -la ~/.volta
```

**7.1.3 Docker won't start**

```bash
# Error message example
⚠️  Failed to start Docker service
ℹ️  Possible causes:
    - Docker installation incomplete
    - Service manager issues
    - Kernel modules not loaded
ℹ️  Solutions:
    1. Check installation state: dpkg -l | grep docker
    2. Inspect service status: sudo service docker status
ℹ️  Manual start: sudo service docker start

# Additional verification steps
sudo service docker status  # Check status
sudo service docker start   # Manual start
sudo docker run hello-world # Verify operation
```

**7.1.4 Docker Compose not found**

```bash
# Error message example
⚠️  Failed to install Docker Compose
ℹ️  Possible causes:
    - docker-compose-plugin not available in repository
    - Docker Engine installation incomplete
ℹ️  Solutions:
    1. Check Docker packages: dpkg -l | grep docker
    2. Install manually: sudo apt-get install -y docker-compose-plugin
ℹ️  Manual verification: docker compose version

# Additional verification steps
docker compose version
dpkg -l | grep docker-compose
sudo apt-get update
sudo apt-get install -y docker-compose-plugin
```

**7.1.5 Invalid Git email address**

```bash
# Error message example
⚠️  Invalid email format

# Solution
Enter valid format: user@example.com
Or configure later: git config --global user.email "you@example.com"
```

### 7.2 Checking Logs

```bash
# When executed with logging enabled
SETUP_LOG=1 ./install.sh local

# Log file path will be shown, e.g.:
ℹ️  Logs stored at /home/user/setup-local-ubuntu-20250109-123456.log

# View log
cat /home/user/setup-local-ubuntu-20250109-123456.log
```

---

## 8. Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

For detailed review process, see:

- [Review Process Guide](docs/review-process.md)
- [Review Checklist](docs/review-checklist.md)

---

## 9. Changelog

See [CHANGELOG.md](CHANGELOG.md) for a detailed history of changes to this project.
