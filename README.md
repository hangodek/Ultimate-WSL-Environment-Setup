# 🚀 Ultimate WSL Development Environment

An automated, two-part setup to give you a **99% bare-metal Linux experience** inside Windows Subsystem for Linux (WSL 2) with zero lag, GPU-accelerated rendering, and a gorgeous unified **Tokyo Night** aesthetic.

Inspired by **Omakub** (by DHH), but heavily optimized for Windows + WSL 2:
- **GPU-Accelerated Window**: Replaces sluggish Windows Terminal with **Alacritty**.
- **Modern Multiplexer**: Pre-configured **Zellij** for tabs, panes, floating terminals, and session persistence.
- **Unified Tokyo Night Theme**: Seamless colors across Alacritty, Zellij, Neovim (LazyVim), and CLI tools.
- **RAM-Efficient Databases**: On-demand Docker containers that consume zero idle memory.
- **True Clipboard Sync**: Native copy/paste across Windows and Linux via `xclip` / `xsel` and Alacritty bindings.

---

## 🏛️ Architecture

```
┌────────────────────────────────────────────────────────┐
│  Windows 11 / 10 Host                                  │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Alacritty Terminal (GPU-Accelerated)            │  │
│  │  • JetBrainsMono Nerd Font                       │  │
│  │  • Tokyo Night Dark Color Scheme                 │  │
│  │  • Directly launches `wsl.exe --cd ~`            │  │
│  └────────────────────────┬─────────────────────────┘  │
└───────────────────────────┼────────────────────────────┘
                            │ (Zero Latency)
┌───────────────────────────▼────────────────────────────┐
│  WSL 2 (Ubuntu / Debian)                               │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Zellij Workspace Multiplexer (Auto-starts)       │  │
│  │  ┌─────────────────────┐  ┌────────────────────┐ │  │
│  │  │ Tab 1: Editor       │  │ Tab 2: Servers     │ │  │
│  │  │ Neovim (LazyVim)    │  │ Rails / Go / Node  │ │  │
│  │  └─────────────────────┘  └────────────────────┘ │  │
│  └──────────────────────────────────────────────────┘  │
│  • mise (Node, Go, Ruby, Rails)                        │
│  • Docker On-Demand DBs (PostgreSQL, MySQL, Redis)     │
└────────────────────────────────────────────────────────┘
```

---

## ⚡ Quick Start (2-Step Installation)

Choose either of these easy methods on Windows:

#### Method A: Double-Click or run `install.bat` (Easiest)
Simply **double-click** `install.bat` in Windows File Explorer (or run `.\install.bat` in Command Prompt/PowerShell). It automatically handles ExecutionPolicy bypass for you.

#### Method B: Single PowerShell One-Liner (No download required)
Open **PowerShell** and paste:
```powershell
irm https://raw.githubusercontent.com/hangodek/WSL-Environtment-Setup/main/install-terminal.ps1 | iex
```

#### Method C: Manual PowerShell Script
```powershell
powershell -ExecutionPolicy Bypass -File .\install-terminal.ps1
```

> **What this does:**
> 1. Installs **Alacritty** and **JetBrainsMono Nerd Font** via WinGet (idempotent, skips if already installed).
> 2. Auto-generates `%APPDATA%\alacritty\alacritty.toml` configured with Tokyo Night colors, Nerd Font glyphs, and auto-launching into WSL `~`.

---

### Step 2: Run Environment Setup inside WSL (Linux)

Launch your new **Alacritty** terminal (or open your WSL shell) and run:

```bash
chmod +x setup.sh
./setup.sh
```

> **What this does:**
> 1. Installs build tools, Rust/C/C++ compilers, image/PDF processing libs, and clipboard sync.
> 2. Installs official **Docker CE** & **Docker Compose**.
> 3. Configures **On-Demand DB Services** (Postgres 16, MySQL 8.4, Redis 7).
> 4. Installs latest **Neovim (v0.10+)** & initializes **LazyVim**.
> 5. Installs **mise** and provisions **Node.js (LTS)**, **Go (latest)**, **Ruby (latest)**, and **Rails**.
> 6. Installs **Zellij** multiplexer and configures auto-start on interactive login.
> 7. Configures custom aliases for database and editor workflows.

---

## ✨ Features & Stack

| Component | Tool | Description |
| :--- | :--- | :--- |
| **Terminal Emulator** | **Alacritty** | GPU-accelerated, ultra-fast rendering on Windows host. |
| **Multiplexer** | **Zellij** | Intuitive terminal workspace with panes, tabs, floating windows, and status bar. |
| **Typography** | **JetBrainsMono NF** | Crisp font with full Nerd Font symbol & powerline glyph support. |
| **Editor** | **Neovim + LazyVim** | Modern IDE experience with LSP, treesitter, fuzzy find, and file tree. |
| **Version Manager**| **mise** | Blazing-fast runtime manager for Node.js, Go, Ruby, Python, and more. |
| **Containers** | **Docker Engine** | Official Docker CE daemon & Compose plugin. |
| **Databases** | **Docker Profiles** | Instant PostgreSQL 16, MySQL 8.4, and Redis 7 on `127.0.0.1` without passwords. |
| **Theme** | **Tokyo Night** | Unified aesthetic across terminal, multiplexer, and editor. |

---

## ⌨️ Shortcuts & Cheatsheet

### Alacritty (Windows Host)
| Shortcut | Action |
| :--- | :--- |
| `Ctrl + Shift + C` | Copy selected text |
| `Ctrl + Shift + V` | Paste from clipboard |
| `Ctrl + Plus (+)` | Increase font size |
| `Ctrl + Minus (-)` | Decrease font size |
| `Ctrl + 0` | Reset font size |

### Zellij (WSL Multiplexer)
| Shortcut | Action | Description |
| :--- | :--- | :--- |
| `Ctrl + p` | **Pane mode** | Press `n` for new pane, `x` to close, `f` to fullscreen |
| `Ctrl + t` | **Tab mode** | Press `n` for new tab, `x` to close, `[` / `]` to switch tabs |
| `Ctrl + s` | **Scroll mode** | Search text (`/`), scroll history with `j`/`k` or mouse wheel |
| `Ctrl + o` | **Session mode** | Press `d` to detach session, `w` to switch session |
| `Alt + n` | **Quick Pane** | Open a new pane directly |
| `Alt + [` / `Alt + ]` | **Quick Tab** | Cycle through open tabs |

---

## 🛠️ Custom Terminal Aliases

### 1. Editor & Frameworks

| Alias | Command | Description | Usage Examples |
| :--- | :--- | :--- | :--- |
| **`n`** | `nvim` | Shortcut to open Neovim editor. | • `n .`<br>• `n app/models/user.rb` |
| **`r`** | `rails` | Shortcut for Ruby on Rails CLI. | • `r s` *(run server)*<br>• `r c` *(open console)*<br>• `r g migration CreateUsers` |

---

### 2. Database On-Demand (WSL RAM Saver)

Databases are managed through Docker Compose profiles. They only consume memory when running.

| Alias | Command / Action | Description & Advantages |
| :--- | :--- | :--- |
| **`db-pg`** | Starts PostgreSQL & Redis | Runs PostgreSQL 16 and Redis 7 in background (`-d`). |
| **`db-mysql`** | Starts MySQL & Redis | Runs MySQL 8.4 and Redis 7 in background (`-d`). |
| **`db-all`** | Starts all services | Launches PostgreSQL, MySQL, and Redis simultaneously. |
| **`db-stop`** | Stops all containers | Shuts down all active database containers to free RAM. |
| **`db-status`** | `docker ps` | View active database containers, ports, and health status. |

---

## 📜 Manual Script Execution

If you prefer to inspect or run commands manually, here is the full `setup.sh` reference:

```bash
#!/bin/bash
set -e

echo "=== 1. Update System & Install Base Dependencies (Omakub + WSL Tools) ==="
sudo apt update && sudo apt install -y \
  build-essential pkg-config autoconf bison clang rustc pipx \
  libssl-dev libreadline-dev zlib1g-dev libyaml-dev libncurses5-dev libffi-dev libgdbm-dev libjemalloc2 \
  libvips imagemagick libmagickwand-dev mupdf mupdf-tools \
  redis-tools sqlite3 libsqlite3-0 default-libmysqlclient-dev libpq-dev postgresql-client postgresql-client-common \
  curl git ripgrep fd-find unzip tar dirmngr gpg gawk \
  xclip xsel ca-certificates lsb-release

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
mv ~/.config/nvim ~/.config/nvim.bak 2>/dev/null || true
mv ~/.local/share/nvim ~/.local/share/nvim.bak 2>/dev/null || true
mv ~/.local/state/nvim ~/.local/state/nvim.bak 2>/dev/null || true
mv ~/.cache/nvim ~/.cache/nvim.bak 2>/dev/null || true

git clone https://github.com/LazyVim/starter ~/.config/nvim
rm -rf ~/.config/nvim/.git

echo "=== 6. Install mise (Version Manager) ==="
curl https://mise.run | sh
if ! grep -q 'mise activate bash' ~/.bashrc; then
  echo 'eval "$(~/.local/bin/mise activate bash)"' >>~/.bashrc
fi
eval "$($HOME/.local/bin/mise activate bash)"

echo "=== 7. Install Node.js, Go, and Ruby via mise ==="
mise use --global node@lts
mise use --global go@latest
mise use --global ruby@latest

echo "=== 8. Install Ruby on Rails ==="
eval "$($HOME/.local/bin/mise env)"
gem install rails

echo "=== 9. Setup Custom Aliases ==="
if ! grep -q 'Dev Custom Aliases' ~/.bashrc; then
  cat <<'EOF' >>~/.bashrc

# Send current directory path to windows ( you can leverage windows split terminal without zelliJ )
PROMPT_COMMAND=${PROMPT_COMMAND:+"$PROMPT_COMMAND; "}'printf "\\e]9;9;%s\\e\\\\" "$(wslpath -w "$PWD")"'

# =========================
# Dev Custom Aliases
# =========================
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
copy_on_select true
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

echo "=========================================="
echo " 🎉 Setup Complete!"
echo " IMPORTANT: Please CLOSE this terminal and REOPEN it (via Alacritty) to start your new environment."
echo "=========================================="
```
