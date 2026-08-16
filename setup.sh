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
# Add Docker's official GPG key:
sudo apt update
sudo apt install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
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
    # Fallback release if GitHub API rate-limited
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

