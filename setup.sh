#!/bin/bash
set -e

# Ensure local user binaries and Go binaries are in PATH during script execution
export PATH="$HOME/.local/bin:$HOME/go/bin:$PATH"

echo "=== 1. Update System & Install Base Dependencies (Omakub + WSL Tools) ==="
sudo apt update && sudo apt install -y \
  build-essential pkg-config autoconf bison clang rustc pipx \
  libssl-dev libreadline-dev zlib1g-dev libyaml-dev libncurses5-dev libffi-dev libgdbm-dev libjemalloc2 \
  libvips imagemagick libmagickwand-dev mupdf mupdf-tools \
  redis-tools sqlite3 libsqlite3-0 default-libmysqlclient-dev libpq-dev postgresql-client postgresql-client-common \
  curl git ripgrep fd-find unzip tar dirmngr gpg gawk \
  xclip xsel ca-certificates lsb-release

# Create symlinks for Debian/Ubuntu package name quirks (fdfind -> fd, batcat -> bat)
if command -v fdfind &>/dev/null && ! command -v fd &>/dev/null; then
  sudo ln -sf "$(which fdfind)" /usr/local/bin/fd
fi

echo "=== 2. Install Docker & Docker Compose (Official Docker Repo) ==="
sudo apt update
sudo apt install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl start docker || true
sudo groupadd docker 2>/dev/null || true
sudo usermod -aG docker $USER

echo "=== 3. Setup Docker Containers (PostgreSQL, MySQL, Redis) ==="
mkdir -p ~/.config/dev-services

cat <<'EOF' >~/.config/dev-services/docker-compose.yml
services:
  postgres:
    image: postgres:16
    container_name: dev-postgres
    restart: unless-stopped
    profiles: ["pg", "all"]
    environment:
      POSTGRES_HOST_AUTH_METHOD: trust
    ports:
      - "127.0.0.1:5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

  mysql:
    image: mysql:8.4
    container_name: dev-mysql
    restart: unless-stopped
    profiles: ["mysql", "all"]
    environment:
      MYSQL_ALLOW_EMPTY_PASSWORD: "true"
    ports:
      - "127.0.0.1:3306:3306"
    volumes:
      - mysql_data:/var/lib/mysql

  redis:
    image: redis:7
    container_name: dev-redis
    restart: unless-stopped
    profiles: ["redis", "all"]
    ports:
      - "127.0.0.1:6379:6379"
    volumes:
      - redis_data:/data

volumes:
  postgres_data:
  mysql_data:
  redis_data:
EOF

echo "=== 4. Install Latest Neovim (via PPA) ==="
sudo add-apt-repository ppa:neovim-ppa/unstable -y
sudo apt update
sudo apt install neovim -y

echo "=== 5. Setup LazyVim ==="
if [ -d ~/.config/nvim ] && [ -f ~/.config/nvim/init.lua ]; then
  echo "LazyVim/Neovim configuration already exists in ~/.config/nvim (skipping clone)."
else
  if [ -d ~/.config/nvim ]; then
    BACKUP_DIR=~/.config/nvim.bak.$(date +%Y%m%d%H%M%S)
    mv ~/.config/nvim "$BACKUP_DIR"
    echo "Backed up existing non-LazyVim nvim config to $BACKUP_DIR"
  fi
  git clone https://github.com/LazyVim/starter ~/.config/nvim
  rm -rf ~/.config/nvim/.git
fi

echo "=== 6. Install mise (Version Manager) ==="
curl https://mise.run | sh
if ! grep -q 'mise activate bash' ~/.bashrc; then
  echo 'eval "$(~/.local/bin/mise activate bash)"' >>~/.bashrc
fi
eval "$($HOME/.local/bin/mise activate bash)" || true

echo "=== 7. Install Node.js, Go, and Ruby via mise ==="
mise use --global node@lts
mise use --global go@latest
mise use --global ruby@latest

echo "=== 8. Install Ruby on Rails ==="
eval "$($HOME/.local/bin/mise env 2>/dev/null)" || true
gem install rails || echo "Rails installation finished."

echo "=== 9. Setup Custom Aliases ==="
if ! grep -q 'Dev Custom Aliases' ~/.bashrc; then
  cat <<'EOF' >>~/.bashrc

# =========================
# Dev Custom Aliases
# =========================
# System & Package Management
alias upd="sudo apt update && sudo apt upgrade"

# Editor & Frameworks
alias n="nvim"
alias r="rails"

# Database On-Demand (WSL RAM Saver)
alias db-pg="docker compose -f ~/.config/dev-services/docker-compose.yml --profile pg --profile redis up -d"
alias db-mysql="docker compose -f ~/.config/dev-services/docker-compose.yml --profile mysql --profile redis up -d"
alias db-all="docker compose -f ~/.config/dev-services/docker-compose.yml --profile all up -d"
alias db-stop="docker compose -f ~/.config/dev-services/docker-compose.yml down"
alias db-status="docker ps"
EOF
fi

echo "=== 10. Install Zellij (Terminal Multiplexer) ==="
if ! command -v zellij &>/dev/null; then
  echo "Fetching latest Zellij release for Linux..."
  ZELLIJ_VERSION=$(curl -s https://api.github.com/repos/zellij-org/zellij/releases/latest | grep '"tag_name"' | cut -d '"' -f 4)
  if [ -z "$ZELLIJ_VERSION" ]; then
    ZELLIJ_VERSION="v0.41.2"
  fi
  echo "Downloading Zellij ($ZELLIJ_VERSION)..."
  curl -Lo /tmp/zellij.tar.gz "https://github.com/zellij-org/zellij/releases/download/${ZELLIJ_VERSION}/zellij-x86_64-unknown-linux-musl.tar.gz"
  tar -xf /tmp/zellij.tar.gz -C /tmp/
  chmod +x /tmp/zellij
  sudo mv /tmp/zellij /usr/local/bin/zellij
  rm -f /tmp/zellij.tar.gz
  echo "Zellij installed successfully."
else
  echo "Zellij is already installed ($(zellij --version))."
fi

# Configure Zellij
mkdir -p ~/.config/zellij
if [ ! -f ~/.config/zellij/config.kdl ]; then
  cat <<'EOF' >~/.config/zellij/config.kdl
// ==========================================================
// Zellij Configuration — WSL Development Environment
// ==========================================================
theme "tokyo-night-dark"
default_shell "bash"
pane_frames false
mouse_mode true
copy_clipboard_on_select true
simplified_ui false

ui {
    pane_frames {
        rounded_corners true
        hide_session_name false
    }
}
EOF
fi

echo "=== 11. Configure Zellij Auto-Start in .bashrc ==="
if ! grep -q 'Zellij Auto-Start' ~/.bashrc; then
  cat <<'EOF' >>~/.bashrc

# =========================
# Zellij Auto-Start
# =========================
# Automatically start Zellij in interactive sessions (outside nested Zellij/TMUX/VSCode)
if command -v zellij &>/dev/null && [ -z "$ZELLIJ" ] && [ -z "$TMUX" ] && [ -z "$VSCODE_INJECTION" ] && [ -t 1 ]; then
    exec zellij
fi
EOF
fi

echo "=== 12. Install Antigravity CLI (agy) & Alias ==="
if ! command -v agy &>/dev/null; then
  curl -fsSL https://antigravity.google/cli/install.sh | bash || echo "Antigravity installer finished."
else
  echo "Antigravity CLI is already installed."
fi

if ! grep -q 'Antigravity Alias' ~/.bashrc; then
  cat <<'EOF' >>~/.bashrc

# =========================
# Antigravity Alias
# =========================
alias agyd='agy --dangerously-skip-permissions'
EOF
fi

echo "=== 13. Install OpenCode CLI ==="
if ! command -v opencode &>/dev/null; then
  curl -fsSL https://opencode.ai/install | bash || echo "OpenCode installer finished."
else
  echo "OpenCode CLI is already installed."
fi

echo "=== 14. Install 9router AI Gateway ==="
eval "$($HOME/.local/bin/mise activate bash)" || true
if ! command -v 9router &>/dev/null; then
  $HOME/.local/bin/mise exec node -- npm install -g 9router || npm install -g 9router || echo "9router installation finished."
else
  echo "9router is already installed."
fi

echo "=== 15. Configure Case-Insensitive Bash Tab Completion ==="
if ! grep -q 'completion-ignore-case' ~/.inputrc 2>/dev/null; then
  cat <<'EOF' >>~/.inputrc

# ==========================================================
# Case-Insensitive Tab Completion
# ==========================================================
$include /etc/inputrc
set completion-ignore-case on
set completion-map-case on
EOF
fi

echo "=== 16. Configure Neovim / LazyVim Optimizations ==="
OPTIONS_FILE=~/.config/nvim/lua/config/options.lua
if [ -f "$OPTIONS_FILE" ] && ! grep -q 'snacks_animate' "$OPTIONS_FILE"; then
  echo '' >>"$OPTIONS_FILE"
  echo '-- Disable animations' >>"$OPTIONS_FILE"
  echo 'vim.g.snacks_animate = false' >>"$OPTIONS_FILE"
fi

SNACKS_PLUGIN=~/.config/nvim/lua/plugins/snacks.lua
if [ ! -f "$SNACKS_PLUGIN" ]; then
  mkdir -p ~/.config/nvim/lua/plugins
  cat <<'EOF' >"$SNACKS_PLUGIN"
return {
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        sources = {
          explorer = {
            layout = {
              auto_hide = { "input" },
            },
          },
        },
      },
    },
  },
}
EOF
fi

echo "=== 17. Install fzf (Fuzzy Finder) ==="
# Download official binary release if fzf is missing or outdated (< 0.48 without --bash flag)
if ! command -v fzf &>/dev/null || ! fzf --bash &>/dev/null; then
  echo "Downloading latest fzf binary from GitHub..."
  FZF_VERSION=$(curl -s "https://api.github.com/repos/junegunn/fzf/releases/latest" | grep -Po '"tag_name": "\K[^"]*' || echo "v0.60.3")
  FZF_CLEAN_VER="${FZF_VERSION#v}"
  curl -Lo /tmp/fzf.tar.gz "https://github.com/junegunn/fzf/releases/download/${FZF_VERSION}/fzf-${FZF_CLEAN_VER}-linux_amd64.tar.gz"
  tar -xf /tmp/fzf.tar.gz -C /tmp/
  chmod +x /tmp/fzf
  sudo mv /tmp/fzf /usr/local/bin/fzf
  rm -f /tmp/fzf.tar.gz
  echo "fzf ($FZF_VERSION) installed successfully."
else
  echo "fzf is already up to date ($(fzf --version 2>/dev/null || echo 'fzf'))."
fi

if ! grep -q 'fzf Fuzzy Finder' ~/.bashrc; then
  cat <<'EOF' >>~/.bashrc

# =========================
# fzf Fuzzy Finder (Ctrl+R history, Ctrl+T files, Alt+C dirs)
# =========================
if fzf --bash &>/dev/null; then
  eval "$(fzf --bash)"
elif [ -f /usr/share/doc/fzf/examples/key-bindings.bash ]; then
  source /usr/share/doc/fzf/examples/key-bindings.bash
  source /usr/share/doc/fzf/examples/completion.bash 2>/dev/null || true
elif [ -f /usr/share/fzf/key-bindings.bash ]; then
  source /usr/share/fzf/key-bindings.bash
  source /usr/share/fzf/completion.bash 2>/dev/null || true
fi
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_DEFAULT_OPTS='--height 40% --border --color=bg+:#283457,bg:#1a1b26,spinner:#7dcfff,hl:#f7768e --color=fg:#c0caf5,header:#f7768e,info:#7aa2f7,pointer:#7aa2f7 --color=marker:#9ece6a,fg+:#c0caf5,prompt:#7aa2f7,hl+:#f7768e'
EOF
fi

echo "=== 18. Install zoxide (Smart cd) ==="
sudo apt install -y zoxide
if ! grep -q 'zoxide init bash' ~/.bashrc; then
  cat <<'EOF' >>~/.bashrc

# =========================
# zoxide (Smart Directory Jumper)
# =========================
eval "$(zoxide init bash)"
alias cd='z'
EOF
fi

echo "=== 19. Install eza (Modern ls) ==="
if ! command -v eza &>/dev/null; then
  sudo mkdir -p /etc/apt/keyrings
  wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg || true
  echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
  sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list 2>/dev/null || true
  sudo apt update && sudo apt install -y eza || echo "eza installed via apt."
fi
if ! grep -q 'eza aliases' ~/.bashrc; then
  cat <<'EOF' >>~/.bashrc

# =========================
# eza (Modern ls with icons and git status)
# =========================
# eza aliases
alias ls='eza --icons --group-directories-first'
alias ll='eza -lh --icons --git --group-directories-first'
alias la='eza -lah --icons --git --group-directories-first'
alias lt='eza --tree --icons --level=2 --group-directories-first'
EOF
fi

echo "=== 20. Install bat (Syntax-Highlighted cat) ==="
sudo apt install -y bat
if command -v batcat &>/dev/null && ! command -v bat &>/dev/null; then
  sudo ln -sf "$(which batcat)" /usr/local/bin/bat
fi
if ! grep -q "alias bat=" ~/.bashrc; then
  cat <<'EOF' >>~/.bashrc

# =========================
# bat (Syntax-Highlighted cat)
# =========================
alias cat='batcat --paging=never'
alias bat='batcat'
EOF
fi

echo "=== 21. Install lazygit (TUI Git Client) ==="
if ! command -v lazygit &>/dev/null; then
  LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*' || echo "0.44.1")
  curl -Lo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
  tar -xf /tmp/lazygit.tar.gz -C /tmp/ lazygit
  sudo install /tmp/lazygit -D -t /usr/local/bin/
  rm -f /tmp/lazygit.tar.gz /tmp/lazygit
  echo "lazygit installed successfully."
else
  echo "lazygit is already installed."
fi

echo "=== 22. Install lazydocker (TUI Docker Manager) ==="
if ! command -v lazydocker &>/dev/null; then
  eval "$($HOME/.local/bin/mise activate bash)" || true
  go install github.com/jesseduffield/lazydocker@latest || echo "lazydocker installation finished."
  if ! grep -q 'go/bin' ~/.bashrc; then
    echo 'export PATH="$HOME/go/bin:$PATH"' >>~/.bashrc
  fi
else
  echo "lazydocker is already installed."
fi

echo "=== 23. Install GitHub CLI (gh) ==="
if ! command -v gh &>/dev/null; then
  (type -p wget >/dev/null || sudo apt install wget -y) \
  && sudo mkdir -p -m 755 /etc/apt/keyrings \
  && wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null \
  && sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null \
  && sudo apt update \
  && sudo apt install -y gh
else
  echo "GitHub CLI (gh) is already installed."
fi

echo "=== 24. Install git-delta (Syntax-Highlighted Git Diffs) ==="
sudo apt install -y git-delta || echo "git-delta package check complete."
if ! git config --global core.pager 2>/dev/null | grep -q delta; then
  git config --global core.pager delta
  git config --global interactive.diffFilter "delta --color-only"
  git config --global delta.line-numbers true
  git config --global delta.dark true
  git config --global delta.syntax-theme "Tokyo Night"
fi

echo "=== 25. Configure Better Bash History ==="
if ! grep -q 'Better Bash History' ~/.bashrc; then
  cat <<'EOF' >>~/.bashrc

# =========================
# Better Bash History
# =========================
export HISTSIZE=100000
export HISTFILESIZE=200000
export HISTCONTROL=ignoreboth:erasedups
export HISTTIMEFORMAT="%F %T  "
shopt -s histappend
shopt -s cmdhist
PROMPT_COMMAND="history -a; ${PROMPT_COMMAND}"
EOF
fi

echo "=== 26. Configure SSH Agent Auto-Start ==="
if ! grep -q 'SSH Agent Auto-Start' ~/.bashrc; then
  cat <<'EOF' >>~/.bashrc

# =========================
# SSH Agent Auto-Start
# =========================
if [ -z "$SSH_AUTH_SOCK" ]; then
  eval "$(ssh-agent -s)" >/dev/null 2>&1
fi
EOF
fi

echo "=== 27. Install Starship Prompt (LAST — wraps prompt) ==="
if ! command -v starship &>/dev/null; then
  curl -sS https://starship.rs/install.sh | sh -s -- --yes
else
  echo "Starship is already installed."
fi
mkdir -p ~/.config
cat <<'EOF' >~/.config/starship.toml
"$schema" = 'https://starship.rs/config-schema.json'

add_newline = true

# Clean, modern & minimal prompt layout
format = """
$directory\
$git_branch\
$git_status\
$nodejs\
$golang\
$ruby\
$rust\
$docker_context\
$package\
$cmd_duration\
$line_break\
$character"""

[character]
success_symbol = "[❯](bold #7aa2f7)"
error_symbol = "[❯](bold #f7768e)"
vimcmd_symbol = "[❮](bold #9ece6a)"

[directory]
style = "bold #7dcfff"
truncation_length = 3
truncation_symbol = "…/"
read_only = " 󰌾"
read_only_style = "red"

[git_branch]
symbol = " "
style = "bold #bb9af7"
format = "on [$symbol$branch]($style) "

[git_status]
style = "bold #f7768e"
format = "([$all_status$ahead_behind]($style) )"

[nodejs]
symbol = " "
style = "bold #9ece6a"
format = "via [$symbol($version )]($style)"

[golang]
symbol = " "
style = "bold #7dcfff"
format = "via [$symbol($version )]($style)"

[ruby]
symbol = " "
style = "bold #f7768e"
format = "via [$symbol($version )]($style)"

[rust]
symbol = " "
style = "bold #ff9e64"
format = "via [$symbol($version )]($style)"

[docker_context]
symbol = " "
style = "bold #7aa2f7"
format = "via [$symbol$context]($style) "

[cmd_duration]
min_time = 2_000
style = "bold #e0af68"
format = "took [$duration]($style) "
EOF

# Starship MUST be the last eval in .bashrc to wrap all prompt components properly
if ! grep -q 'starship init bash' ~/.bashrc; then
  cat <<'EOF' >>~/.bashrc

# =========================
# Starship Prompt (Must be last in .bashrc)
# =========================
eval "$(starship init bash)"
EOF
fi

echo "=========================================="
echo " 🎉 Setup Complete!"
echo " IMPORTANT: Please CLOSE this terminal and REOPEN it (via Alacritty) to start your new environment."
echo "=========================================="
