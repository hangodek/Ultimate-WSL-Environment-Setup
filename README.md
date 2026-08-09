# 🚀 Ultimate WSL Development Environment

An automated script to set up a modern, lightweight, and powerful development environment in **Windows Subsystem for Linux (WSL)** (Ubuntu/Debian-based). 

This setup is heavily inspired by **Omakub** (by DHH) for its comprehensive dependencies and database management approach, but it is specifically optimized for WSL users to **minimize RAM usage** and maintain seamless Windows compatibility (e.g., clipboard synchronization).

## ✨ Features & Stack

1. **System Core (Omakub + WSL)**: Essential build tools, Rust/C/C++ compilers, image/PDF processing (for Rails Active Storage), database CLI clients (`psql`, `mysql`, `redis-cli`), and Windows clipboard sync (`xclip`, `xsel`).
2. **Docker & Docker Compose**: Official container engine for running local services without cluttering your OS.
3. **On-Demand Databases (Docker Profiles)**: 
   - Uses **Non-Alpine (Standard)** images for 100% production compatibility.
   - **Zero-Config & Secure**: Bound to `127.0.0.1` without passwords (safe for local development).
   - **RAM Efficient**: Databases only spin up when explicitly called; they do not run continuously in the background.
4. **Neovim & LazyVim**: Modern text editor (v0.10+) pre-configured as a fully-featured IDE via LazyVim.
5. **mise**: Multi-language version manager (a faster replacement for NVM, Rbenv, ASDF).
6. **Languages & Frameworks**: Node.js (LTS), Go (Latest), Ruby (Latest), and Ruby on Rails.
7. **Custom Aliases**: Smart terminal shortcuts to supercharge your productivity.

## 🛠️ Custom Terminal Aliases

### 1. Editor & Frameworks

| Alias | Command | Description | Usage Examples |
| :--- | :--- | :--- | :--- |
| **`n`** | `nvim` | Shortcut to open the Neovim editor. | • `n .`<br>• `n app/models/user.rb` |
| **`r`** | `rails` | Shortcut for Ruby on Rails CLI commands. | • `r s` *(run server)*<br>• `r c` *(open console)*<br>• `r g migration CreateUsers` |

---

### 2. Database On-Demand (WSL RAM Saver)

Using Docker Compose profiles ensures database containers only run when explicitly activated, preventing idle memory consumption in WSL 2.

| Alias | Command / Action | Description & Advantages |
| :--- | :--- | :--- |
| **`db-pg`** | Starts PostgreSQL & Redis | Runs PostgreSQL and Redis in the background (`-d`). Saves RAM by keeping MySQL inactive. |
| **`db-mysql`** | Starts MySQL & Redis | Runs MySQL and Redis in the background (`-d`). Saves RAM by keeping PostgreSQL inactive. |
| **`db-all`** | Starts all services | Launches PostgreSQL, MySQL, and Redis simultaneously using the `--profile all` flag. |
| **`db-stop`** | Stops all containers | Brings down (`docker compose down`) all running services. Uses `--profile '*'` to ensure all active profiled containers are stopped. |
| **`db-status`** | `docker ps` | Shortcut to view active containers, assigned ports, and health status. |

---

## 📜 Installation

Create a file named `setup.sh` in your WSL home directory and paste the following script. Or you can clone this project > give permissions to `setup.sh` > ./setup.sh

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

cat << 'EOF' > ~/.config/dev-services/docker-compose.yml
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
  echo 'eval "$(~/.local/bin/mise activate bash)"' >> ~/.bashrc
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
cat << 'EOF' >> ~/.bashrc

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

echo "=========================================="
echo " Setup Complete!"
echo " Run 'newgrp docker' or restart your shell to activate Docker permissions."
echo "=========================================="

echo "=========================================="
echo " Setup Complete!"
echo " IMPORTANT: Please CLOSE this terminal and REOPEN it to apply Docker group permissions."
echo "=========================================="
