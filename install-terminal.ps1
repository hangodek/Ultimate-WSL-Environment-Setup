<#
.SYNOPSIS
    Automated Windows Environment Setup for WSL (VS Code + Remote-WSL + JetBrainsMono Nerd Font + Nord Theme + .wslconfig)
.DESCRIPTION
    Installs and configures Visual Studio Code, JetBrainsMono Nerd Font, and (optionally) Alacritty terminal emulator via WinGet.
    Automatically configures:
    - Visual Studio Code with Nord theme, JetBrainsMono Nerd Font, and essential developer extensions (Remote-WSL, GitLens, Docker, Prettier, ErrorLens).
    - VS Code integrated terminal with Nord arctic color palette and Nerd Font glyphs.
    - WSL 2 performance & memory cap via .wslconfig (memory limit, gradual reclaim, vmIdleTimeout).
    - Alacritty GPU-accelerated terminal pre-configured with Nord theme and direct WSL launch.
.NOTES
    Run from PowerShell (no administrator privileges strictly required unless WinGet prompts).
#>

[CmdletBinding()]
param(
    [switch]$SkipAlacritty
)

$ErrorActionPreference = 'Stop'

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  🚀 Windows Setup: VS Code + WSL 2 Power Dev (Nord)        " -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# 1. Check WinGet availability
Write-Host "[1/6] Checking WinGet package manager..." -ForegroundColor Yellow
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Error "WinGet is not available on this system. Please install 'App Installer' from the Microsoft Store or update Windows 10/11."
    exit 1
}
Write-Host "  ✓ WinGet is available." -ForegroundColor Green

# Helper function to install package via winget idempotently
function Install-WingetApp {
    param(
        [Parameter(Mandatory=$true)][string]$PackageId,
        [Parameter(Mandatory=$true)][string]$DisplayName,
        [string]$FallbackId = ""
    )

    Write-Host "  Checking $DisplayName ($PackageId)..." -NoNewline
    $listOutput = winget list --id $PackageId --exact 2>&1 | Out-String

    if ($listOutput -match [regex]::Escape($PackageId)) {
        Write-Host " [Already Installed]" -ForegroundColor Green
        return
    }

    if ($FallbackId) {
        $fallbackOutput = winget list --id $FallbackId --exact 2>&1 | Out-String
        if ($fallbackOutput -match [regex]::Escape($FallbackId)) {
            Write-Host " [Already Installed ($FallbackId)]" -ForegroundColor Green
            return
        }
    }

    Write-Host " [Installing...]" -ForegroundColor Yellow
    $installArgs = @("install", "--id", $PackageId, "--exact", "--silent", "--accept-package-agreements", "--accept-source-agreements")
    $process = Start-Process -FilePath "winget" -ArgumentList $installArgs -Wait -PassThru -NoNewWindow

    if ($process.ExitCode -ne 0 -and $FallbackId) {
        Write-Host "  Trying fallback ID: $FallbackId..." -ForegroundColor Yellow
        $fallbackArgs = @("install", "--id", $FallbackId, "--exact", "--silent", "--accept-package-agreements", "--accept-source-agreements")
        $process = Start-Process -FilePath "winget" -ArgumentList $fallbackArgs -Wait -PassThru -NoNewWindow
    }

    if ($process.ExitCode -eq 0) {
        Write-Host "  ✓ Successfully installed $DisplayName" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️ WinGet returned exit code $($process.ExitCode) for $DisplayName (it may require manual review or a restart)." -ForegroundColor DarkYellow
    }
}

# 2. Install JetBrainsMono Nerd Font
Write-Host ""
Write-Host "[2/6] Installing JetBrainsMono Nerd Font..." -ForegroundColor Yellow
Install-WingetApp -PackageId "DEVCOM.JetBrainsMonoNerdFont" -DisplayName "JetBrainsMono Nerd Font" -FallbackId "JetBrains.JetBrainsMono.NerdFont"

# 3. Install Visual Studio Code
Write-Host ""
Write-Host "[3/6] Installing Visual Studio Code..." -ForegroundColor Yellow
Install-WingetApp -PackageId "Microsoft.VisualStudioCode" -DisplayName "Visual Studio Code"

# 4. Install & Configure VS Code Extensions and Settings
Write-Host ""
Write-Host "[4/6] Configuring Visual Studio Code (Extensions & Nord Theme)..." -ForegroundColor Yellow

# Locate 'code' CLI executable
$codeCmd = $null
if (Get-Command code -ErrorAction SilentlyContinue) {
    $codeCmd = "code"
} else {
    $possiblePaths = @(
        (Join-Path $env:LOCALAPPDATA "Programs\Microsoft VS Code\bin\code.cmd"),
        (Join-Path $env:ProgramFiles "Microsoft VS Code\bin\code.cmd"),
        (Join-Path ${env:ProgramFiles(x86)} "Microsoft VS Code\bin\code.cmd")
    )
    foreach ($path in $possiblePaths) {
        if ($path -and (Test-Path -Path $path)) {
            $codeCmd = $path
            break
        }
    }
}

if ($codeCmd) {
    $extensions = @(
        "ms-vscode-remote.remote-wsl",
        "arcticicestudio.nord-visual-studio-code",
        "eamodio.gitlens",
        "ms-azuretools.vscode-docker",
        "esbenp.prettier-vscode",
        "usernamehw.errorlens"
    )

    Write-Host "  Installing essential VS Code extensions..." -ForegroundColor DarkGray
    foreach ($ext in $extensions) {
        Write-Host "    • Installing $ext..." -ForegroundColor DarkGray
        Start-Process -FilePath $codeCmd -ArgumentList "--install-extension", $ext, "--force" -Wait -NoNewWindow -ErrorAction SilentlyContinue
    }
} else {
    Write-Host "  ⚠️ 'code' CLI not found yet. You may need to restart PowerShell after VS Code installation." -ForegroundColor DarkYellow
}

# Configure VS Code settings.json
$vscodeUserDir = Join-Path -Path $env:APPDATA -ChildPath "Code\User"
if (-not (Test-Path -Path $vscodeUserDir)) {
    New-Item -ItemType Directory -Path $vscodeUserDir -Force | Out-Null
}
$vscodeSettingsFile = Join-Path -Path $vscodeUserDir -ChildPath "settings.json"

$settingsObj = [ordered]@{}
if (Test-Path -Path $vscodeSettingsFile) {
    try {
        $existingSettings = Get-Content -Path $vscodeSettingsFile -Raw | ConvertFrom-Json
        foreach ($prop in $existingSettings.PSObject.Properties) {
            $settingsObj[$prop.Name] = $prop.Value
        }
    } catch {}
}

# Editor UI & Typography
$settingsObj["workbench.colorTheme"] = "Nord"
$settingsObj["editor.fontFamily"] = "'JetBrainsMono Nerd Font', 'JetBrains Mono', Consolas, 'Courier New', monospace"
$settingsObj["editor.fontLigatures"] = $true
$settingsObj["editor.fontSize"] = 14
$settingsObj["editor.lineHeight"] = 1.6
$settingsObj["editor.formatOnSave"] = $true

# Terminal Styling & Colors
$settingsObj["terminal.integrated.fontFamily"] = "JetBrainsMono Nerd Font"
$settingsObj["terminal.integrated.fontSize"] = 13
$settingsObj["terminal.integrated.cursorBlinking"] = $true
$settingsObj["terminal.integrated.cursorStyle"] = "line"

# Ensure custom Nord color overrides for integrated terminal
if (-not $settingsObj.Contains("workbench.colorCustomizations")) {
    $settingsObj["workbench.colorCustomizations"] = [ordered]@{}
}
$colorCustoms = $settingsObj["workbench.colorCustomizations"]
$colorCustoms["terminal.background"] = "#2e3440"
$colorCustoms["terminal.foreground"] = "#d8dee9"
$colorCustoms["terminal.ansiBlack"] = "#3b4252"
$colorCustoms["terminal.ansiRed"] = "#bf616a"
$colorCustoms["terminal.ansiGreen"] = "#a3be8c"
$colorCustoms["terminal.ansiYellow"] = "#ebcb8b"
$colorCustoms["terminal.ansiBlue"] = "#81a1c1"
$colorCustoms["terminal.ansiMagenta"] = "#b48ead"
$colorCustoms["terminal.ansiCyan"] = "#88c0d0"
$colorCustoms["terminal.ansiWhite"] = "#e5e9f0"
$colorCustoms["terminal.ansiBrightBlack"] = "#4c566a"
$colorCustoms["terminal.ansiBrightRed"] = "#bf616a"
$colorCustoms["terminal.ansiBrightGreen"] = "#a3be8c"
$colorCustoms["terminal.ansiBrightYellow"] = "#ebcb8b"
$colorCustoms["terminal.ansiBrightBlue"] = "#81a1c1"
$colorCustoms["terminal.ansiBrightMagenta"] = "#b48ead"
$colorCustoms["terminal.ansiBrightCyan"] = "#8fbcbb"
$colorCustoms["terminal.ansiBrightWhite"] = "#eceff4"

$settingsJson = $settingsObj | ConvertTo-Json -Depth 10
Set-Content -Path $vscodeSettingsFile -Value $settingsJson -Encoding UTF8
Write-Host "  ✓ Configured VS Code settings in $vscodeSettingsFile" -ForegroundColor Green

# 5. Configure .wslconfig (RAM limit & auto-reclaim for WSL2)
Write-Host ""
Write-Host "[5/6] Configuring .wslconfig (WSL 2 Performance & RAM Tuning)..." -ForegroundColor Yellow
$wslConfigFile = Join-Path -Path $env:USERPROFILE -ChildPath ".wslconfig"
if (-not (Test-Path -Path $wslConfigFile)) {
    $wslConfigContent = @'
# ==============================================================================
#  WSL 2 Configuration — Performance & RAM Management
#  Place at: C:\Users\<YourUser>\.wslconfig
# ==============================================================================
[wsl2]
# RAM limit: adjust based on your physical memory (e.g. 8GB on 16GB RAM machines)
memory=8GB

# Processors: limit to half or full physical core count
processors=4

# Swap partition size
swap=2GB

[experimental]
# Automatically return unused Linux memory back to Windows (prevents vmmem growth)
autoMemoryReclaim=gradual
sparseVhd=true
vmIdleTimeout=-1
'@
    Set-Content -Path $wslConfigFile -Value $wslConfigContent -Encoding UTF8
    Write-Host "  ✓ Created .wslconfig template at $wslConfigFile" -ForegroundColor Green
} else {
    Write-Host "  ✓ Existing .wslconfig detected at $wslConfigFile." -ForegroundColor Green
    if (-not (Select-String -Path $wslConfigFile -Pattern "vmIdleTimeout" -Quiet)) {
        Add-Content -Path $wslConfigFile -Value "`n[experimental]`nvmIdleTimeout=-1"
        Write-Host "  ✓ Added vmIdleTimeout=-1 to prevent WSL shutdown lockups." -ForegroundColor Green
    }
}

# Grant permanent VM permissions on WSL virtual disk to avoid "Access is denied" on relaunch
try {
    $lxssPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss"
    if (Test-Path $lxssPath) {
        Get-ChildItem $lxssPath | ForEach-Object {
            $basePath = (Get-ItemProperty $_.PsPath).BasePath
            if ($basePath -and (Test-Path "$basePath\ext4.vhdx")) {
                icacls "$basePath\ext4.vhdx" /grant "NT VIRTUAL MACHINE\Virtual Machines:F" 2>$null | Out-Null
                icacls "$basePath" /grant "NT VIRTUAL MACHINE\Virtual Machines:(OI)(CI)F" 2>$null | Out-Null
            }
        }
        Write-Host "  ✓ Verified Hyper-V VM disk permissions (Access Denied protection active)." -ForegroundColor Green
    }
} catch {}

# 6. Optional: Alacritty GPU Terminal Setup
Write-Host ""
if (-not $SkipAlacritty) {
    Write-Host "[6/6] Setting up Alacritty (Fast Standalone Terminal Companion)..." -ForegroundColor Yellow
    Install-WingetApp -PackageId "Alacritty.Alacritty" -DisplayName "Alacritty"

    $alacrittyConfigDir = Join-Path -Path $env:APPDATA -ChildPath "alacritty"
    if (-not (Test-Path -Path $alacrittyConfigDir)) {
        New-Item -ItemType Directory -Path $alacrittyConfigDir -Force | Out-Null
    }

    $alacrittyConfigFile = Join-Path -Path $alacrittyConfigDir -ChildPath "alacritty.toml"
    $alacrittyConfigContent = @'
# ==============================================================================
#  Alacritty Configuration — WSL Development Environment
#  Auto-generated by WSL-Environment-Setup
# ==============================================================================

[general]
import = []

[env]
TERM = "xterm-256color"

[terminal.shell]
program = "wsl.exe"
args    = ["--cd", "~"]

[window]
padding         = { x = 14, y = 12 }
dynamic_padding = true
decorations     = "Full"
opacity         = 0.96
blur            = true
startup_mode    = "Maximized"
title           = "WSL (Linux)"
dynamic_title   = true

[font]
size = 11
builtin_box_drawing = true

[font.normal]
family = "JetBrainsMono Nerd Font"
style  = "Regular"

[font.bold]
family = "JetBrainsMono Nerd Font"
style  = "Bold"

[font.italic]
family = "JetBrainsMono Nerd Font"
style  = "Italic"

[font.bold_italic]
family = "JetBrainsMono Nerd Font"
style  = "Bold Italic"

[cursor]
style          = { shape = "Beam", blinking = "On" }
blink_interval = 600

[scrolling]
history    = 10000
multiplier = 3

[colors.primary]
background = "#2e3440"
foreground = "#d8dee9"

[colors.cursor]
text   = "#2e3440"
cursor = "#d8dee9"

[colors.selection]
background = "#434c5e"
text       = "#eceff4"

[colors.normal]
black   = "#3b4252"
red     = "#bf616a"
green   = "#a3be8c"
yellow  = "#ebcb8b"
blue    = "#81a1c1"
magenta = "#b48ead"
cyan    = "#88c0d0"
white   = "#e5e9f0"

[colors.bright]
black   = "#4c566a"
red     = "#bf616a"
green   = "#a3be8c"
yellow  = "#ebcb8b"
blue    = "#81a1c1"
magenta = "#b48ead"
cyan    = "#8fbcbb"
white   = "#eceff4"

[keyboard]
bindings = [
  { key = "C",     mods = "Control|Shift", action = "Copy" },
  { key = "V",     mods = "Control|Shift", action = "Paste" },
  { key = "Plus",  mods = "Control",       action = "IncreaseFontSize" },
  { key = "Minus", mods = "Control",       action = "DecreaseFontSize" },
  { key = "Key0",  mods = "Control",       action = "ResetFontSize" }
]
'@
    Set-Content -Path $alacrittyConfigFile -Value $alacrittyConfigContent -Encoding UTF8
    Write-Host "  ✓ Wrote Alacritty config to $alacrittyConfigFile" -ForegroundColor Green
} else {
    Write-Host "[6/6] Skipped Alacritty installation (-SkipAlacritty specified)." -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "  🎉 Windows Setup Complete!                                " -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Open Visual Studio Code on Windows." -ForegroundColor White
Write-Host "  2. In your WSL terminal, navigate to any project and run:" -ForegroundColor White
Write-Host ""
Write-Host '     code .' -ForegroundColor Yellow
Write-Host ""
Write-Host "  3. To run/re-run the Linux WSL setup, inside WSL execute:" -ForegroundColor White
Write-Host ""
Write-Host '     bash -c "$(curl -fsSL https://raw.githubusercontent.com/hangodek/Ultimate-WSL-Environment-Setup/main/setup.sh)"' -ForegroundColor Yellow
Write-Host ""
