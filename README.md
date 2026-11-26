# 🚀 Ultimate WSL 2 Development Environment

> [!NOTE]
> ✅ **Verified & Tested**: This entire setup has been tested and is fully functional on WSL 2 (Ubuntu 24.04 LTS / 22.04 LTS & Debian) paired with Windows 11 / 10.

An automated, two-part setup to give you a **high-performance, VS Code-centric development environment** inside Windows Subsystem for Linux (WSL 2). Combines the full graphical power of Visual Studio Code on Windows with the speed, toolchain versatility, and modern CLI tools of bare-metal Linux in a unified **Nord** arctic aesthetic.

---

## 🌟 Highlights

- **Modern GUI IDE**: Pre-configured **Visual Studio Code** on Windows connected directly to WSL 2 via the official `Remote - WSL` extension with zero file-system latency.
- **Unified Nord Arctic Theme**: Seamless color harmony across VS Code, integrated terminal, Starship prompt, `bat`, `fzf`, `git-delta`, and Zellij.
- **Starship Prompt**: Instantaneous, informative prompt with git branch, dirty status, execution duration, and runtime version indicators (Node, Go, Ruby, Docker).
- **Fuzzy Search Everywhere**: **fzf** for history search (`Ctrl+R`), interactive file selection (`Ctrl+T`), and smart directory navigation (`Alt+C`).
- **Smart Directory Jumping**: **zoxide** (`z <folder>`) automatically learns your frequent directories.
- **Modern Linux Coreutils**: **eza** (icon & git-aware `ls`), **bat** (Nord syntax-highlighted `cat`), and **git-delta** (Nord syntax diffs).
- **TUI Git & Docker**: **lazygit** for lightning-fast Git workflows and **lazydocker** for container operations right in your terminal.
- **AI Tooling Built-in**: **Antigravity CLI** (`agy` / `agyd`), **OpenCode** (`opencode` / `oc` / `oca`), and **9router** AI gateway running as a systemd service.
- **Polyglot Runtime Manager**: **mise** managing global and project-specific versions of Node.js LTS, Go, and Ruby on Rails.
- **RAM-Efficient WSL 2**: Auto-configured `.wslconfig` memory limits (8GB cap, `autoMemoryReclaim`) and on-demand Docker databases (PostgreSQL, MySQL, Redis).
- **True Clipboard Integration**: Native copy/paste across Windows and Linux via `win32yank` and WSLg runtime fixes.

---

## 🏛️ Architecture

```
┌────────────────────────────────────────────────────────────────────────┐
│  Windows 11 / 10 Host                                                  │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │  Visual Studio Code (Primary IDE)                                │  │
│  │  • Remote - WSL Extension (Native Linux filesystem speed)       │  │
│  │  • JetBrainsMono Nerd Font with Font Ligatures                   │  │
│  │  • Unified Nord Theme (Arctic blue color palette)                │  │
│  │  • Curated Dev Extensions (GitLens, Docker, Prettier, ErrorLens) │  │
│  │  • Integrated Terminal configured with Nord colors               │  │
│  └─────────────────────────────────┬────────────────────────────────┘  │
│  • Memory Cap configured in %USERPROFILE%\.wslconfig (8GB)             │
│  • Optional: Alacritty GPU-accelerated terminal companion              │
└────────────────────────────────────┼───────────────────────────────────┘
                                     │ (WSL Remote Bridge / IPC)
┌────────────────────────────────────▼───────────────────────────────────┐
│  WSL 2 (Ubuntu 24.04 / Debian)                                         │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │  Linux Shell (VS Code Integrated Terminal / Standalone)          │  │
│  │  • Starship Prompt (Nord theme, git status, runtime versions)   │  │
│  │  • fzf (Ctrl+R history, Ctrl+T files, Alt+C dirs)                │  │
│  │  • Modern CLI: eza (ls), bat (cat), zoxide (z), git-delta       │  │
│  │  • TUI Tools: lazygit (Git), lazydocker (Docker), gh CLI         │  │
│  │  • AI CLI Suite: Antigravity (agy), OpenCode (oc), 9router       │  │
│  │  • Version Manager (mise): Node.js, Go, Ruby on Rails            │  │
│  │  • On-Demand Docker DBs: Postgres 16, MySQL 8.4, Redis 7         │  │
│  │  • Optional Multiplexer: Zellij on-demand (`zellij`)             │  │
│  └──────────────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────────────┘
```

---

## ⚡ Quick Start (2 Steps)

### Step 1: Run Windows Setup (Host Configuration)

Choose either of these easy methods on Windows:

#### Method A: Double-Click `install.bat` (Easiest)
Simply **double-click** `install.bat` in Windows File Explorer (or run `.\install.bat` in Command Prompt / PowerShell). It automatically handles ExecutionPolicy bypass for you.

#### Method B: Single PowerShell One-Liner (No download required)
Open **PowerShell** on Windows and run:
```powershell
curl.exe -fsSL "https://raw.githubusercontent.com/hangodek/Ultimate-WSL-Environment-Setup/main/install-terminal.ps1" -o "$env:TEMP\install-terminal.ps1"; powershell -NoProfile -ExecutionPolicy Bypass -File "$env:TEMP\install-terminal.ps1"
```
> **Note:** `irm ... | iex` intentionally not used — the script starts with a `param()` block, which `Invoke-Expression` cannot execute. Downloading to a temp file and running with `-File` is the reliable one-shot path.

#### Method C: Manual PowerShell Execution
```powershell
powershell -ExecutionPolicy Bypass -File .\install-terminal.ps1
```

> **What this does on Windows:**
> 1. Installs **Visual Studio Code** and **JetBrainsMono Nerd Font** (WinGet + automatic zero-admin direct GitHub fallback).
> 2. Automatically installs essential VS Code extensions (`Remote - WSL`, `Nord Theme`, `GitLens`, `Docker`, `Prettier`, `ErrorLens`).
> 3. Configures `%APPDATA%\Code\User\settings.json` with Nord colors, font ligatures, format on save, and terminal styling.
> 4. Configures **Windows Terminal** default profile with `JetBrainsMono Nerd Font` and the **Nord** color scheme.
> 5. Generates `%USERPROFILE%\.wslconfig` with memory caps (8GB limit, `autoMemoryReclaim = gradual`, `vmIdleTimeout = -1`).
> 6. Configures **Alacritty** as an optional standalone GPU terminal companion.

---

### Step 2: Run Linux Setup inside WSL

Open any WSL terminal (or Windows Terminal running Ubuntu) and run:

#### Method A: Single Linux One-Liner (Recommended)
```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/hangodek/Ultimate-WSL-Environment-Setup/main/setup.sh)"
```
> The script auto-fetches its repo assets (`scripts/`, `configs/`, `skills/`, `commands/`) in one-shot mode, so no manual clone is needed. It runs tolerantly: a single failed step (apt mirror hiccup, systemd not enabled, etc.) will not abort the whole setup.

#### Method B: Manual Run (If already cloned)
```bash
chmod +x setup.sh
./setup.sh
```

> **What this does inside WSL:**
> 1. Updates base packages and installs essential build tools and libraries.
> 2. Configures Docker CE official repository & Docker compose.
> 3. Sets up on-demand Docker Compose databases (PostgreSQL 16, MySQL 8.4, Redis 7).
> 4. Installs `mise` and provisions Node.js (LTS), Go (latest), and Ruby with Rails.
> 5. Installs **JetBrainsMono Nerd Font** in `~/.local/share/fonts` and auto-syncs with Windows user fonts.
> 6. Installs modern CLI tools: `starship`, `zoxide`, `fzf`, `eza`, `bat`, `lazygit`, `lazydocker`, `gh`, and `git-delta`.
> 7. Installs and configures AI tools: `agy` (Antigravity CLI), `opencode`, Concat MCP bridge, and `9router` systemd service.
> 8. Configures case-insensitive bash tab completion, high-capacity bash history, and SSH agent auto-start.

---

## 💻 Daily Workflow & Commands

### 1. Opening Projects in VS Code
From any directory in your WSL shell, simply run:
```bash
code .
```
This launches VS Code on Windows instantly connected to your WSL directory with full language server support and native Linux I/O speeds.

### 2. VS Code Integrated Terminal
Press `Ctrl + ~` (or `Ctrl + ` `) inside VS Code to open the integrated terminal.
- Prompt: Styled with **Starship** and **Nord** colors.
- Icons: Rendered with **JetBrainsMono Nerd Font**.

### 3. Modern CLI Replacements
| Classic Command | Enhanced Command | Description |
| :--- | :--- | :--- |
| `ls` | `eza --icons` | Modern `ls` with filetype icons |
| `ll` | `eza -lh --icons --git` | Detailed list with Git file status |
| `la` | `eza -lah --icons --git` | Detailed list including hidden files |
| `lt` | `eza --tree --level=2` | Visual folder tree structure |
| `cat <file>` | `bat <file>` | Syntax-highlighted viewer with Nord palette |
| `cd <path>` | `z <query>` | Smart jump to frequent directories |
| `Ctrl + R` | **fzf** History | Interactive fuzzy search of shell command history |
| `Ctrl + T` | **fzf** Files | Interactive fuzzy search to select files into command line |
| `git diff` | **git-delta** | Side-by-side syntax-highlighted diffs |

### 4. Git & Docker Workflow
- **lazygit**: Run `lazygit` in any Git repository for an intuitive, keyboard-driven Git TUI.
- **lazydocker**: Run `lazydocker` to inspect containers, logs, CPU/RAM usage, and restart services.
- **GitHub CLI**: Run `gh auth login`, `gh pr create`, `gh repo clone`.

### 5. On-Demand Databases (WSL RAM Saver)
Databases run only when you need them, saving gigabytes of host RAM:
```bash
db-pg      # Starts PostgreSQL 16 + Redis 7 in background
db-mysql   # Starts MySQL 8.4 + Redis 7 in background
db-all     # Starts PostgreSQL + MySQL + Redis
db-stop    # Stops all dev database containers
db-status  # Displays running Docker containers
```

### 6. AI Development Tools & Image Pasting
- **Antigravity CLI**:
  ```bash
  agy      # Launch Antigravity interactive assistant
  agyd     # Launch Antigravity skipping permission prompts
  ```
- **OpenCode CLI**:
  ```bash
  oc       # Launch OpenCode AI agent
  oca      # Launch OpenCode in autonomous mode
  ```
- **9router**: Automatically runs in background on port `20128` as a systemd service.
- **Direct Image Pasting in VS Code Terminal (Screenshots / OpenCode / Claude)**:
  - **Built-in `Ctrl + Shift + V`**: Pre-configured out of the box via `cybersader.terminal-image-paste`. Take a screenshot on Windows (`Win + Shift + S`) or copy any image, click into the terminal, and press **`Ctrl + Shift + V`** (or `Ctrl + Alt + V`). The image is automatically extracted, saved to `.cp-images/`, and its path is inserted directly into your prompt!
  - **CLI Helper**: Run `paste-img` to save clipboard image directly to `~/.cache/pasted-images/` and output its WSL path (e.g. `oc "explain this: $(paste-img)"`).
  - **Drag & Drop**: Hold `Shift` while dragging any image file from VS Code Explorer sidebar directly into the terminal cursor.
- **Auto-Handoff for Claude Code**: Session state is saved to disk, so a new chat continues where the last one stopped.
  - A `SessionStart` hook injects `~/.claude/session-logs/<project>/HANDOFF.md` into every new session (startup, resume, `/clear`, `/compact`).
  - Fully automatic, no commands. A `PostToolUse`/`UserPromptSubmit` hook watches the context. At about **150k tokens** it has Claude save `HANDOFF.md` mid-task and keep working. `CLAUDE_CODE_AUTO_COMPACT_WINDOW=200000` (set in `settings.json` env) makes Claude Code auto-compact early without stopping, and the `SessionStart` hook re-injects `HANDOFF.md` after it. Tune with `HANDOFF_THRESHOLD`.
  - The `/handoff` command runs the same skill by hand.
  - Each session writes its own log, so parallel sessions in one project do not overwrite each other.
  - Deployed by `scripts/install-handoff.sh`. It merges into `~/.claude/settings.json` and `~/.claude/CLAUDE.md` without removing your own entries.

---

## 🎨 Aesthetic & Theming

Every component uses the official **Nord** color palette:

| Element | Color Hex | Role |
| :--- | :--- | :--- |
| **Polar Night (Dark)** | `#2e3440` | Editor & Terminal Background |
| **Polar Night (Accent)** | `#3b4252` | Status bars, line highlights, borders |
| **Snow Storm (Light)** | `#d8dee9` / `#eceff4` | Text foreground & prompt symbols |
| **Frost (Blue/Cyan)** | `#88c0d0` / `#81a1c1` | Directories, git branches, highlights |
| **Aurora (Green)** | `#a3be8c` | Success symbols, Node version indicator |
| **Aurora (Yellow/Orange)** | `#ebcb8b` / `#d08770` | Duration timer, Rust indicator |
| **Aurora (Red)** | `#bf616a` | Error indicators, Ruby version |

---

## 🛠️ RAM & Performance Tuning

WSL 2 memory management is handled by `%USERPROFILE%\.wslconfig`:
```ini
[wsl2]
memory=8GB
processors=4
swap=2GB

[experimental]
autoMemoryReclaim=gradual
sparseVhd=true
vmIdleTimeout=-1
```
- **`autoMemoryReclaim=gradual`**: Automatically returns freed Linux memory back to Windows so `vmmem` doesn't consume all your host RAM.
- **`sparseVhd=true`**: Shrinks the WSL virtual disk when files are deleted.
- **`vmIdleTimeout=-1`**: Prevents unexpected VM shutdowns.

To apply changes to `.wslconfig`, run in PowerShell:
```powershell
wsl --shutdown
```

---

## 📄 License
MIT License. Free to use, adapt, and share.
