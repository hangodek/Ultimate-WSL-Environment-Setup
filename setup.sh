#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Ensure local user binaries, Go binaries, and OpenCode binaries are in PATH during script execution
export PATH="$HOME/.local/bin:$HOME/go/bin:$HOME/.opencode/bin:$PATH"

echo "=== 1. Update System & Install Base Dependencies (WSL Tools) ==="
sudo apt update && sudo apt install -y \
  build-essential pkg-config autoconf bison clang rustc pipx \
  libssl-dev libreadline-dev zlib1g-dev libyaml-dev libncurses5-dev libffi-dev libgdbm-dev libjemalloc2 \
  libvips imagemagick libmagickwand-dev mupdf mupdf-tools \
  redis-tools sqlite3 libsqlite3-0 default-libmysqlclient-dev libpq-dev postgresql-client postgresql-client-common \
  curl git ripgrep fd-find unzip tar dirmngr gpg gawk \
  wl-clipboard xclip xsel ca-certificates lsb-release

# Create symlinks for Debian/Ubuntu package name quirks (fdfind -> fd, batcat -> bat)
if command -v fdfind &>/dev/null && ! command -v fd &>/dev/null; then
  sudo ln -sf "$(which fdfind)" /usr/local/bin/fd
fi

# Install win32yank for reliable WSL host clipboard integration
if ! command -v win32yank.exe &>/dev/null; then
  echo "Installing win32yank for WSL clipboard..."
  curl -sLo /tmp/win32yank.zip https://github.com/equalsraf/win32yank/releases/download/v0.1.1/win32yank-x64.zip
  unzip -p /tmp/win32yank.zip win32yank.exe > /tmp/win32yank.exe
  chmod +x /tmp/win32yank.exe
  sudo mv /tmp/win32yank.exe /usr/local/bin/win32yank.exe
  rm -f /tmp/win32yank.zip
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

echo "=== 4. Install mise (Version Manager) ==="
curl https://mise.run | sh
if ! grep -q 'mise activate bash' ~/.bashrc; then
  echo 'eval "$(~/.local/bin/mise activate bash)"' >>~/.bashrc
fi
eval "$($HOME/.local/bin/mise activate bash)" || true

echo "=== 5. Install Node.js, Go, and Ruby via mise ==="
mise use --global node@lts
mise use --global go@latest
mise use --global ruby@latest

echo "=== 6. Install Ruby on Rails ==="
eval "$($HOME/.local/bin/mise env 2>/dev/null)" || true
gem install rails || echo "Rails installation finished."

echo "=== 7. Setup Custom Aliases ==="
# Remove legacy alias if present
sed -i '/alias n="nvim"/d' ~/.bashrc 2>/dev/null || true

if ! grep -q 'Dev Custom Aliases' ~/.bashrc; then
  cat <<'EOF' >>~/.bashrc

# =========================
# Dev Custom Aliases
# =========================
# System & Package Management
alias upd="sudo apt update && sudo apt upgrade"

# Frameworks & Dev
alias r="rails"

# Database On-Demand (WSL RAM Saver)
alias db-pg="docker compose -f ~/.config/dev-services/docker-compose.yml --profile pg --profile redis up -d"
alias db-mysql="docker compose -f ~/.config/dev-services/docker-compose.yml --profile mysql --profile redis up -d"
alias db-all="docker compose -f ~/.config/dev-services/docker-compose.yml --profile all up -d"
alias db-stop="docker compose -f ~/.config/dev-services/docker-compose.yml down"
alias db-status="docker ps"
EOF
fi

echo "=== 8. Install Zellij (Optional Terminal Multiplexer) ==="
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

# Configure Zellij theme (available on-demand via 'zellij', without auto-starting)
mkdir -p ~/.config/zellij
cat <<'EOF' >~/.config/zellij/config.kdl
// ==========================================================
// Zellij Configuration — WSL Development Environment (Nord)
// ==========================================================
theme "nord"
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

themes {
    nord {
        fg "#d8dee9"
        bg "#2e3440"
        black "#3b4252"
        red "#bf616a"
        green "#a3be8c"
        yellow "#ebcb8b"
        blue "#81a1c1"
        magenta "#b48ead"
        cyan "#88c0d0"
        white "#e5e9f0"
        orange "#d08770"
    }
}
EOF

# Ensure any legacy Zellij auto-start is removed from .bashrc for clean VS Code integrated terminal
sed -i '/# Zellij Auto-Start/,/fi/d' ~/.bashrc 2>/dev/null || true

echo "=== 9. Install Antigravity CLI (agy) & Alias ==="
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

echo "=== 10. Install OpenCode v2 Major Release & AI Agentic Architecture ==="
if ! command -v opencode &>/dev/null && [ ! -f "$HOME/.opencode/bin/opencode" ]; then
  echo "Installing OpenCode v2 Major Release..."
  curl -fsSL https://opencode.ai/v2/install | bash || echo "OpenCode v2 installer finished."
else
  # Ensure it is upgraded to OpenCode v2
  OC_VER=$(opencode --version 2>/dev/null || echo "")
  if [[ "$OC_VER" == *"v1."* ]] || [[ "$OC_VER" == "1."* ]]; then
    echo "Upgrading OpenCode to v2..."
    curl -fsSL https://opencode.ai/v2/install | bash || echo "OpenCode v2 installer finished."
  else
    echo "OpenCode v2 is already installed ($OC_VER)."
  fi
fi

# Ensure opencode is symlinked to ~/.local/bin and in PATH
if [ -f "$HOME/.opencode/bin/opencode" ]; then
  mkdir -p "$HOME/.local/bin"
  ln -sf "$HOME/.opencode/bin/opencode" "$HOME/.local/bin/opencode"
fi

if ! grep -q 'OpenCode CLI & Aliases' ~/.bashrc; then
  cat <<'EOF' >>~/.bashrc

# =========================
# OpenCode CLI & Aliases
# =========================
export PATH="$HOME/.opencode/bin:$PATH"
alias oc='opencode'
alias oca='opencode --auto'
EOF
fi

# Deploy Base OpenCode Directories
mkdir -p "$HOME/.config/opencode/skills" "$HOME/.config/opencode/commands" "$HOME/.config/opencode/command"
mkdir -p "$HOME/.config/antigravity/skills" "$HOME/.config/antigravity/commands"
mkdir -p "$HOME/.agents/skills"
mkdir -p "$HOME/.config/ponytail"

# Deploy paste-img CLI (Extract Windows clipboard screenshot to WSL path)
if [ -f "$SCRIPT_DIR/scripts/paste-img" ]; then
  mkdir -p "$HOME/.local/bin"
  cp "$SCRIPT_DIR/scripts/paste-img" "$HOME/.local/bin/paste-img"
  chmod +x "$HOME/.local/bin/paste-img"
fi

# Auto-install VS Code Terminal Image Paste extension and configure keybindings
if command -v code &>/dev/null; then
  code --install-extension cybersader.terminal-image-paste --force 2>/dev/null || true
fi
if command -v powershell.exe &>/dev/null; then
  powershell.exe -NoProfile -Command "
  try {
    \$kbPath = Join-Path \$env:APPDATA 'Code\User\keybindings.json'
    \$kbDir = Split-Path \$kbPath
    if (!(Test-Path \$kbDir)) { New-Item -ItemType Directory -Path \$kbDir -Force | Out-Null }
    \$list = @()
    if (Test-Path \$kbPath) {
      try { \$list = @(Get-Content \$kbPath -Raw -Encoding UTF8 | ConvertFrom-Json) } catch {}
    }
    \$exists = \$false
    foreach (\$item in \$list) {
      if (\$item.command -eq 'terminal-paste-image.pasteImage') { \$exists = \$true; break }
    }
    if (!\$exists) {
      \$list += [PSCustomObject]@{
        key = 'ctrl+shift+v'
        command = 'terminal-paste-image.pasteImage'
        when = 'terminalFocus'
      }
      \$list | ConvertTo-Json -Depth 5 | Set-Content \$kbPath -Encoding UTF8
    }
  } catch {}
  " 2>/dev/null || true
fi

# Deploy MCP Web Search & URL Fetcher (Zero-Keyless Real-Time Grounding)
if [ -f "$SCRIPT_DIR/scripts/mcp-websearch.js" ]; then
  cp "$SCRIPT_DIR/scripts/mcp-websearch.js" "$HOME/.config/opencode/mcp-websearch.js"
  chmod +x "$HOME/.config/opencode/mcp-websearch.js"
fi

# Deploy Ponytail Ultra Configuration (Default ON)
if [ -f "$SCRIPT_DIR/configs/ponytail.json" ]; then
  cp "$SCRIPT_DIR/configs/ponytail.json" "$HOME/.config/ponytail/config.json"
fi

# Deploy Core Engineering Standards (AGENTS.md)
if [ -f "$SCRIPT_DIR/configs/AGENTS.md" ]; then
  cp "$SCRIPT_DIR/configs/AGENTS.md" "$HOME/.config/opencode/AGENTS.md"
  cp "$SCRIPT_DIR/configs/AGENTS.md" "$HOME/.config/antigravity/AGENTS.md"
  cp "$SCRIPT_DIR/configs/AGENTS.md" "$HOME/.agents/AGENTS.md"
fi

# Deploy 3 Core Skills (agystack, karpathy, ponytail)
if [ -d "$SCRIPT_DIR/skills" ]; then
  for s in agystack karpathy ponytail; do
    if [ -d "$SCRIPT_DIR/skills/$s" ]; then
      cp -r "$SCRIPT_DIR/skills/$s" "$HOME/.config/opencode/skills/"
      cp -r "$SCRIPT_DIR/skills/$s" "$HOME/.config/antigravity/skills/"
      cp -r "$SCRIPT_DIR/skills/$s" "$HOME/.agents/skills/"
    fi
  done
fi

# Deploy Slash Commands (/agystack, /karpathy, /ponytail)
if [ -d "$SCRIPT_DIR/commands" ]; then
  cp "$SCRIPT_DIR/commands/"*.md "$HOME/.config/opencode/commands/" 2>/dev/null || true
  cp "$SCRIPT_DIR/commands/"*.md "$HOME/.config/opencode/command/" 2>/dev/null || true
  cp "$SCRIPT_DIR/commands/"*.md "$HOME/.config/antigravity/commands/" 2>/dev/null || true
fi

# Ensure default opencode.json exists and has MCP Websearch + Core Instructions configured
OPENCODE_CONFIG="$HOME/.config/opencode/opencode.json"
if [ ! -f "$OPENCODE_CONFIG" ] && [ -f "$SCRIPT_DIR/configs/opencode.json" ]; then
  cp "$SCRIPT_DIR/configs/opencode.json" "$OPENCODE_CONFIG"
else
  # Patch existing opencode.json with Web Search MCP & AGENTS.md instruction
  python3 -c "
import json, os
p = '$OPENCODE_CONFIG'
if os.path.exists(p):
    try:
        with open(p, 'r', encoding='utf-8') as f: d = json.load(f)
        mcp = d.setdefault('mcp', {})
        if 'websearch' not in mcp:
            mcp['websearch'] = {
                'type': 'local',
                'command': ['node', os.path.expanduser('~/.config/opencode/mcp-websearch.js')]
            }
        inst = d.setdefault('instructions', [])
        agents_rule = os.path.expanduser('~/.config/opencode/AGENTS.md')
        if agents_rule not in inst:
            inst.insert(0, agents_rule)
        with open(p, 'w', encoding='utf-8') as f: json.dump(d, f, indent=2)
    except Exception: pass
" 2>/dev/null || true
fi

# Deploy Concat Video Editor MCP Bridge for OpenCode
if command -v powershell.exe &>/dev/null; then
  WIN_USERPROFILE=$(powershell.exe -NoProfile -Command "Write-Output \$env:USERPROFILE" 2>/dev/null | tr -d '\r')
  if [ -n "$WIN_USERPROFILE" ]; then
    WIN_USERDIR=$(wslpath "$WIN_USERPROFILE" 2>/dev/null)
    WIN_PY_PATH=$(powershell.exe -NoProfile -Command "(Get-Command python.exe -ErrorAction SilentlyContinue).Source" 2>/dev/null | tr -d '\r')
    if [ -d "$WIN_USERDIR" ] && [ -f "$SCRIPT_DIR/scripts/concat_mcp.py" ]; then
      cp "$SCRIPT_DIR/scripts/concat_mcp.py" "$WIN_USERDIR/concat_mcp.py" 2>/dev/null || true
      WIN_CONCAT_SETTINGS="$WIN_USERDIR/AppData/Roaming/app.concat.editor/settings.json"
      if [ -f "$WIN_CONCAT_SETTINGS" ]; then
        python3 -c "
import json
try:
    with open('$WIN_CONCAT_SETTINGS', 'r') as f: d = json.load(f)
    if not d.get('server', {}).get('token'):
        d.setdefault('server', {})['token'] = 'kucing123'
        with open('$WIN_CONCAT_SETTINGS', 'w') as f: json.dump(d, f, indent=2)
except Exception: pass
" 2>/dev/null || true
      fi
      if [ -f "$SCRIPT_DIR/configs/concat_rules.md" ]; then
        mkdir -p "$HOME/.config/opencode"
        cp "$SCRIPT_DIR/configs/concat_rules.md" "$HOME/.config/opencode/concat_rules.md" 2>/dev/null || true
      fi
      if [ -f "$OPENCODE_CONFIG" ] && [ -n "$WIN_PY_PATH" ]; then
        python3 -c "
import json, subprocess
try:
    with open('$OPENCODE_CONFIG', 'r') as f: d = json.load(f)
    mcp = d.setdefault('mcp', {})
    if 'concat' not in mcp:
        win_py_wsl = '$WIN_PY_PATH'
        try: win_py_wsl = subprocess.check_output(['wslpath', '$WIN_PY_PATH']).decode().strip()
        except Exception: pass
        mcp['concat'] = {
            'type': 'local',
            'command': [win_py_wsl, '$WIN_USERPROFILE\\\\concat_mcp.py'],
            'environment': {'CONCAT_TOKEN': 'kucing123'}
        }
    inst = d.setdefault('instructions', [])
    rule_path = '$HOME/.config/opencode/concat_rules.md'
    if rule_path not in inst:
        inst.append(rule_path)
    with open('$OPENCODE_CONFIG', 'w') as f: json.dump(d, f, indent=2)
except Exception: pass
" 2>/dev/null || true
      fi
    fi
  fi
else
  # Native Linux Ubuntu environment
  if [ -f "$SCRIPT_DIR/configs/concat_rules.md" ]; then
    mkdir -p "$HOME/.config/opencode"
    cp "$SCRIPT_DIR/configs/concat_rules.md" "$HOME/.config/opencode/concat_rules.md" 2>/dev/null || true
  fi

  LINUX_CONCAT_DIR="$HOME/.config/app.concat.editor"
  LINUX_CONCAT_SETTINGS="$LINUX_CONCAT_DIR/settings.json"
  mkdir -p "$LINUX_CONCAT_DIR"
  python3 -c "
import json, os
p = '$LINUX_CONCAT_SETTINGS'
d = {}
if os.path.exists(p):
    try:
        with open(p, 'r', encoding='utf-8') as f: d = json.load(f)
    except Exception: d = {}
if not d.get('server', {}).get('token'):
    d.setdefault('server', {})['token'] = 'kucing123'
    try:
        with open(p, 'w', encoding='utf-8') as f: json.dump(d, f, indent=2)
    except Exception: pass
" 2>/dev/null || true

  if [ -f "$OPENCODE_CONFIG" ] && [ -f "$SCRIPT_DIR/scripts/concat_mcp.py" ]; then
    python3 -c "
import json
p = '$OPENCODE_CONFIG'
try:
    with open(p, 'r', encoding='utf-8') as f: d = json.load(f)
    mcp = d.setdefault('mcp', {})
    if 'concat' not in mcp:
        mcp['concat'] = {
            'type': 'local',
            'command': ['python3', '$SCRIPT_DIR/scripts/concat_mcp.py'],
            'environment': {'CONCAT_TOKEN': 'kucing123'}
        }
    inst = d.setdefault('instructions', [])
    rule_path = '$HOME/.config/opencode/concat_rules.md'
    if rule_path not in inst:
        inst.append(rule_path)
    with open(p, 'w', encoding='utf-8') as f: json.dump(d, f, indent=2)
except Exception: pass
" 2>/dev/null || true
  fi
fi

echo "=== 11. Install 9router AI Gateway & Auto-Start Service ==="
eval "$($HOME/.local/bin/mise activate bash)" || true
if ! command -v 9router &>/dev/null; then
  $HOME/.local/bin/mise exec node -- npm install -g 9router || npm install -g 9router || echo "9router installation finished."
else
  echo "9router is already installed."
fi

# Configure 9router system-level systemd service to auto-start on WSL boot
sudo tee /etc/systemd/system/9router.service >/dev/null <<EOF
[Unit]
Description=9router AI Gateway
After=network.target

[Service]
Type=simple
User=$USER
Group=$USER
WorkingDirectory=$HOME
Environment=HOME=$HOME
Environment=PATH=$HOME/.local/share/mise/shims:$HOME/.local/bin:$HOME/.opencode/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ExecStart=$HOME/.local/bin/mise exec -- 9router --tray --no-browser --skip-update
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Clean up obsolete user-level service if present
systemctl --user stop 9router.service 2>/dev/null || true
systemctl --user disable 9router.service 2>/dev/null || true
rm -f ~/.config/systemd/user/9router.service

sudo systemctl daemon-reload
sudo systemctl enable 9router.service
sudo systemctl restart 9router.service

echo "=== 12. Configure Case-Insensitive Bash Tab Completion ==="
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

echo "=== 13. Install fzf (Fuzzy Finder) ==="
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
export FZF_DEFAULT_OPTS='--height 40% --border --color=bg+:#3b4252,bg:#2e3440,spinner:#88c0d0,hl:#81a1c1 --color=fg:#d8dee9,header:#81a1c1,info:#ebcb8b,pointer:#88c0d0 --color=marker:#a3be8c,fg+:#eceff4,prompt:#81a1c1,hl+:#88c0d0'
EOF
fi

echo "=== 14. Install zoxide (Smart cd) ==="
sudo apt install -y zoxide

echo "=== 14b. Install JetBrainsMono Nerd Font (Linux & Windows Host Sync) ==="
if [ ! -f "$HOME/.local/share/fonts/JetBrainsMonoNerdFont-Regular.ttf" ]; then
  echo "Installing JetBrainsMono Nerd Font in ~/.local/share/fonts..."
  mkdir -p "$HOME/.local/share/fonts"
  FONT_TMP=$(mktemp -d)
  if curl -fsSL -o "$FONT_TMP/JetBrainsMono.tar.xz" "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.5.1/JetBrainsMono.tar.xz"; then
    tar -xf "$FONT_TMP/JetBrainsMono.tar.xz" -C "$FONT_TMP"
    cp "$FONT_TMP"/*.ttf "$HOME/.local/share/fonts/" 2>/dev/null || true
    fc-cache -f "$HOME/.local/share/fonts" 2>/dev/null || true
    echo "✓ JetBrainsMono Nerd Font installed in ~/.local/share/fonts."
  fi
  rm -rf "$FONT_TMP"
fi

# Auto-sync fonts to Windows host user font directory if running in WSL
if [ -d "/mnt/c/Users" ]; then
  for win_user_fonts in /mnt/c/Users/*/AppData/Local/Microsoft/Windows/Fonts; do
    if [ -d "$win_user_fonts" ] && [ ! -f "$win_user_fonts/JetBrainsMonoNerdFont-Regular.ttf" ]; then
      echo "Syncing JetBrainsMono Nerd Font to Windows user fonts ($win_user_fonts)..."
      cp -u "$HOME/.local/share/fonts"/JetBrainsMonoNerdFont*.ttf "$win_user_fonts/" 2>/dev/null || true
    fi
  done
fi

echo "=== 15. Install eza (Modern ls) ==="
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

echo "=== 16. Install bat (Syntax-Highlighted cat) ==="
sudo apt install -y bat
if command -v batcat &>/dev/null && ! command -v bat &>/dev/null; then
  sudo ln -sf "$(which batcat)" /usr/local/bin/bat
fi
if ! grep -q "alias bat=" ~/.bashrc; then
  cat <<'EOF' >>~/.bashrc

# =========================
# bat (Syntax-Highlighted cat — Nord theme)
# =========================
export BAT_THEME="Nord"
alias cat='batcat --paging=never'
alias bat='batcat'
EOF
fi

echo "=== 17. Install lazygit (TUI Git Client) ==="
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

echo "=== 18. Install lazydocker (TUI Docker Manager) ==="
if ! command -v lazydocker &>/dev/null; then
  eval "$($HOME/.local/bin/mise activate bash)" || true
  go install github.com/jesseduffield/lazydocker@latest || echo "lazydocker installation finished."
  if ! grep -q 'go/bin' ~/.bashrc; then
    echo 'export PATH="$HOME/go/bin:$PATH"' >>~/.bashrc
  fi
else
  echo "lazydocker is already installed."
fi

echo "=== 19. Install GitHub CLI (gh) ==="
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

echo "=== 20. Install git-delta (Syntax-Highlighted Git Diffs) ==="
sudo apt install -y git-delta || echo "git-delta package check complete."
git config --global core.pager delta
git config --global interactive.diffFilter "delta --color-only"
git config --global delta.line-numbers true
git config --global delta.dark true
git config --global delta.syntax-theme "Nord"

echo "=== 21. Configure Better Bash History ==="
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

echo "=== 22. Configure SSH Agent Auto-Start ==="
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

echo "=== 23. Install Starship Prompt (LAST — wraps prompt) ==="
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
success_symbol = "[❯](bold #81a1c1)"
error_symbol = "[❯](bold #bf616a)"
vimcmd_symbol = "[❮](bold #a3be8c)"

[directory]
style = "bold #88c0d0"
truncation_length = 3
truncation_symbol = "…/"
read_only = " 󰌾"
read_only_style = "red"

[git_branch]
symbol = " "
style = "bold #b48ead"
format = "on [$symbol$branch]($style) "

[git_status]
style = "bold #bf616a"
format = "([$all_status$ahead_behind]($style) )"

[nodejs]
symbol = " "
style = "bold #a3be8c"
format = "via [$symbol($version )]($style)"

[golang]
symbol = " "
style = "bold #88c0d0"
format = "via [$symbol($version )]($style)"

[ruby]
symbol = " "
style = "bold #bf616a"
format = "via [$symbol($version )]($style)"

[rust]
symbol = " "
style = "bold #d08770"
format = "via [$symbol($version )]($style)"

[docker_context]
symbol = " "
style = "bold #81a1c1"
format = "via [$symbol$context]($style) "

[cmd_duration]
min_time = 2_000
style = "bold #ebcb8b"
format = "took [$duration]($style) "
EOF

# Starship wraps prompt components
if ! grep -q 'starship init bash' ~/.bashrc; then
  cat <<'EOF' >>~/.bashrc

# =========================
# Starship Prompt
# =========================
eval "$(starship init bash)"
EOF
fi

echo "=== 24. Configure zoxide (Must be initialized AFTER Starship at the end of .bashrc) ==="
# Remove any previous zoxide block that may have been placed before Starship
sed -i '/zoxide (Smart Directory Jumper)/{N;N;N;N;d}' ~/.bashrc 2>/dev/null || true
sed -i '/eval "\$(zoxide init bash)"/d' ~/.bashrc 2>/dev/null || true
sed -i "/alias cd='z'/d" ~/.bashrc 2>/dev/null || true

if ! grep -q 'zoxide init bash' ~/.bashrc; then
  cat <<'EOF' >>~/.bashrc

# =========================
# zoxide (Smart Directory Jumper — Initialized after Starship to avoid doctor warning)
# =========================
eval "$(zoxide init bash)"
alias cd='z'
EOF
fi

echo "=== 25. Configure WSLg Wayland Runtime Path (Fixes Clipboard & Image Paste) ==="
if ! grep -q 'WSLg Wayland Runtime Fix' ~/.bashrc; then
  cat <<'EOF' >>~/.bashrc

# ==========================================================
# WSLg Wayland Runtime Fix (Fixes clipboard / image paste)
# ==========================================================
if [ -d "/mnt/wslg/runtime-dir" ]; then
  export XDG_RUNTIME_DIR="/mnt/wslg/runtime-dir"
  export WAYLAND_DISPLAY="wayland-0"
fi
EOF
fi

if [ -f ~/.profile ] && ! grep -q 'WSLg Wayland Runtime Fix' ~/.profile; then
  cat <<'EOF' >>~/.profile

# WSLg Wayland Runtime Fix
if [ -d "/mnt/wslg/runtime-dir" ]; then
  export XDG_RUNTIME_DIR="/mnt/wslg/runtime-dir"
  export WAYLAND_DISPLAY="wayland-0"
fi
EOF
fi

echo "=========================================="
echo " 🎉 Setup Complete!"
echo " Open your project in VS Code anytime via:"
echo "   code ."
echo "=========================================="
