# OzzyLabs 共通 Zsh 設定
# このファイルは chezmoi によって管理され、~/.zshrc.d/ozzylabs.zsh に配置されます。

# 補完設定の強化
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# エイリアス
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# プロンプト（シンプルな設定例）
PROMPT='%F{cyan}%n@%m%f:%F{yellow}%~%f$ '
