# WSL Development Environment Setup

Skrip otomatisasi untuk menyiapkan lingkungan pengembangan di **Windows Subsystem for Linux (WSL)** berbasis Ubuntu/Debian.

## 🚀 Fitur & Stack yang Di-install

- **Sistem Dependensi Base**: Paket esensial untuk kompilasi (Ruby, Go, Node), pencarian cepat Neovim, dan dukungan clipboard WSL ke Windows (`xclip`, `xsel`).
- **Neovim (v0.10+)**: Versi terbaru via PPA resmi.
- **LazyVim**: Neovim setup berbasis LazyVim starter.
- **mise**: Version manager serbaguna (pengganti nvm, rbenv, asdf, dll).
- **Node.js**: Versi LTS via `mise`.
- **Go**: Versi terbaru via `mise`.
- **Ruby**: Versi terbaru via `mise`.
- **Ruby on Rails**: Installed via Ruby Gem.

---

## 📜 Skrip Instalasi (`setup.sh`)

Buat file bernama `setup.sh` di lingkungan WSL kamu, lalu isi dengan skrip berikut:

```bash
#!/bin/bash
set -e

echo "=== 1. Update Sistem & Install Dependency Base ==="
sudo apt update && sudo apt install -y \
  curl git build-essential \
  libssl-dev libreadline-dev zlib1g-dev libyaml-dev libffi-dev libgdbm-dev \
  ripgrep fd-find unzip tar pkg-config \
  dirmngr gpg gawk \
  xclip xsel

echo "=== 2. Install Neovim Terbaru (via PPA) ==="
sudo add-apt-repository ppa:neovim-ppa/unstable -y
sudo apt update
sudo apt install neovim -y

echo "=== 3. Setup LazyVim ==="
# Backup konfigurasi Neovim lama jika ada
mv ~/.config/nvim ~/.config/nvim.bak 2>/dev/null || true
mv ~/.local/share/nvim ~/.local/share/nvim.bak 2>/dev/null || true
mv ~/.local/state/nvim ~/.local/state/nvim.bak 2>/dev/null || true
mv ~/.cache/nvim ~/.cache/nvim.bak 2>/dev/null || true

# Clone starter LazyVim
git clone [https://github.com/LazyVim/starter](https://github.com/LazyVim/starter) ~/.config/nvim
rm -rf ~/.config/nvim/.git

echo "=== 4. Install mise (Version Manager) ==="
curl [https://mise.run](https://mise.run) | sh

# Integrasi mise ke ~/.bashrc
if ! grep -q 'mise activate bash' ~/.bashrc; then
  echo 'eval "$(~/.local/bin/mise activate bash)"' >> ~/.bashrc
fi
eval "$($HOME/.local/bin/mise activate bash)"

echo "=== 5. Install Node.js, Go, dan Ruby via mise ==="
mise use --global node@lts
mise use --global go@latest
mise use --global ruby@latest

echo "=== 6. Install Ruby on Rails ==="
# Memastikan Ruby dari mise aktif di environment saat ini
eval "$($HOME/.local/bin/mise env)"
gem install rails

echo "=========================================="
echo " Setup Selesai!"
echo " Jalankan: 'source ~/.bashrc' untuk memperbarui shell kamu."
echo " Lalu ketik 'nvim' untuk membuka LazyVim dan menyelesaikan instalasi plugin."
echo "=========================================="
