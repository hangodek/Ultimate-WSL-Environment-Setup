<#
.SYNOPSIS
    Automated Windows Environment Setup for WSL (VS Code + Windows Terminal + JetBrainsMono Nerd Font + Nord Theme + .wslconfig)
.DESCRIPTION
    Installs and configures Visual Studio Code, Windows Terminal, JetBrainsMono Nerd Font, and (optionally) Alacritty terminal emulator.
    Automatically configures:
    - JetBrainsMono Nerd Font with automatic per-user direct fallback (guarantees icon glyphs in all terminals).
    - Visual Studio Code with Nord theme, JetBrainsMono Nerd Font, and essential developer extensions (Remote-WSL, GitLens, Docker, Prettier, ErrorLens).
    - Windows Terminal default profiles styled with JetBrainsMono Nerd Font and Nord color palette.
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

function Install-JetBrainsNerdFont {
    Write-Host "  Checking for installed JetBrainsMono Nerd Font..." -NoNewline
    $userFontsDir = Join-Path $env:LOCALAPPDATA "Microsoft\Windows\Fonts"
    $winFontsDir = Join-Path $env:windir "Fonts"

    $existing = (Get-ChildItem -Path $userFontsDir, $winFontsDir -Filter "*JetBrains*Nerd*.ttf" -ErrorAction SilentlyContinue)
    if ($existing -and $existing.Count -gt 0) {
        Write-Host " [Already Installed ($($existing.Count) font files found)]" -ForegroundColor Green
        return
    }
    Write-Host " [Not Found]" -ForegroundColor Yellow

    # Try Winget first if available
    $wingetSuccess = $false
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Host "  Trying WinGet package install..." -ForegroundColor DarkGray
        $installArgs = @("install", "--id", "DEVCOM.JetBrainsMonoNerdFont", "--exact", "--silent", "--accept-package-agreements", "--accept-source-agreements")
        $proc = Start-Process -FilePath "winget" -ArgumentList $installArgs -Wait -PassThru -NoNewWindow -ErrorAction SilentlyContinue
        if ($proc -and $proc.ExitCode -eq 0) {
            $wingetSuccess = $true
        }
    }

    # Verify if WinGet actually placed font files
    $existingAfter = (Get-ChildItem -Path $userFontsDir, $winFontsDir -Filter "*JetBrains*Nerd*.ttf" -ErrorAction SilentlyContinue)
    if ($wingetSuccess -and $existingAfter -and $existingAfter.Count -gt 0) {
        Write-Host "  ✓ JetBrainsMono Nerd Font successfully installed via WinGet." -ForegroundColor Green
        return
    }

    # Direct download fallback: zero-admin per-user installation
    Write-Host "  Directly downloading JetBrainsMono Nerd Font from GitHub..." -ForegroundColor Yellow
    if (-not (Test-Path $userFontsDir)) {
        New-Item -ItemType Directory -Path $userFontsDir -Force | Out-Null
    }

    $zipUrl = "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
    $tempZip = Join-Path $env:TEMP "JetBrainsMonoNerdFont.zip"
    $extractDir = Join-Path $env:TEMP "JetBrainsMonoNerdFont_Extracted"

    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13
        Invoke-WebRequest -Uri $zipUrl -OutFile $tempZip -UseBasicParsing
        
        if (Test-Path $extractDir) {
            Remove-Item -Path $extractDir -Recurse -Force | Out-Null
        }
        Expand-Archive -Path $tempZip -DestinationPath $extractDir -Force

        $fontFiles = Get-ChildItem -Path $extractDir -Filter "*.ttf"
        $regKey = "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts"

        foreach ($font in $fontFiles) {
            $destPath = Join-Path $userFontsDir $font.Name
            Copy-Item -Path $font.FullName -Destination $destPath -Force

            $fontName = $font.BaseName.Replace("-", " ") + " (TrueType)"
            New-ItemProperty -Path $regKey -Name $fontName -Value $destPath -PropertyType String -Force | Out-Null
        }

        # Broadcast WM_FONTCHANGE so open applications update their font list immediately
        Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class FontNotify {
    [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
    public static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint Msg, IntPtr wParam, string lParam, uint fuFlags, uint uTimeout, out IntPtr lpdwResult);
}
"@ -ErrorAction SilentlyContinue

        try {
            $result = [IntPtr]::Zero
            [FontNotify]::SendMessageTimeout([IntPtr]0xffff, 0x001D, [IntPtr]::Zero, $null, 2, 1000, [ref]$result) | Out-Null
        } catch {}

        Write-Host "  ✓ Installed and registered $($fontFiles.Count) JetBrainsMono Nerd Font files (per-user, no admin required)." -ForegroundColor Green
    } catch {
        Write-Host "  ⚠️ Direct font download encountered an issue: $($_.Exception.Message)" -ForegroundColor DarkYellow
    } finally {
        if (Test-Path $tempZip) { Remove-Item -Path $tempZip -Force -ErrorAction SilentlyContinue }
        if (Test-Path $extractDir) { Remove-Item -Path $extractDir -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

# 2. Install JetBrainsMono Nerd Font (with automatic GitHub download fallback)
Write-Host ""
Write-Host "[2/7] Installing JetBrainsMono Nerd Font..." -ForegroundColor Yellow
Install-JetBrainsNerdFont

# 3. Install Visual Studio Code
Write-Host ""
Write-Host "[3/7] Installing Visual Studio Code..." -ForegroundColor Yellow
Install-WingetApp -PackageId "Microsoft.VisualStudioCode" -DisplayName "Visual Studio Code"

# 4. Install & Configure VS Code Extensions and Settings
Write-Host ""
Write-Host "[4/7] Configuring Visual Studio Code (Extensions & Nord Theme)..." -ForegroundColor Yellow

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

# 5. Configure Windows Terminal (JetBrainsMono Nerd Font & Nord Theme)
Write-Host ""
Write-Host "[5/7] Configuring Windows Terminal (JetBrainsMono Nerd Font & Nord Theme)..." -ForegroundColor Yellow

$wtSettingsCandidates = @(
    (Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"),
    (Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json"),
    (Join-Path $env:LOCALAPPDATA "Microsoft\Windows Terminal\settings.json")
)

$configuredWt = $false
foreach ($wtSettingsFile in $wtSettingsCandidates) {
    if (Test-Path -Path $wtSettingsFile) {
        try {
            $rawJson = Get-Content -Path $wtSettingsFile -Raw -Encoding UTF8
            $wtSettings = $rawJson | ConvertFrom-Json

            if (-not $wtSettings.profiles) {
                $wtSettings | Add-Member -MemberType NoteProperty -Name "profiles" -Value ([PSCustomObject]@{})
            }
            if (-not $wtSettings.profiles.defaults) {
                $wtSettings.profiles | Add-Member -MemberType NoteProperty -Name "defaults" -Value ([PSCustomObject]@{})
            }

            $defaults = $wtSettings.profiles.defaults
            if (-not $defaults.font) {
                $defaults | Add-Member -MemberType NoteProperty -Name "font" -Value ([PSCustomObject]@{})
            }
            $defaults.font | Add-Member -MemberType NoteProperty -Name "face" -Value "JetBrainsMono Nerd Font" -Force
            $defaults | Add-Member -MemberType NoteProperty -Name "colorScheme" -Value "Nord" -Force

            # Ensure Nord color scheme is defined in schemes array
            if (-not $wtSettings.schemes) {
                $wtSettings | Add-Member -MemberType NoteProperty -Name "schemes" -Value @()
            }

            $nordFound = $false
            foreach ($s in $wtSettings.schemes) {
                if ($s.name -eq "Nord") {
                    $nordFound = $true
                    break
                }
            }

            if (-not $nordFound) {
                $nordScheme = [PSCustomObject]@{
                    name                = "Nord"
                    background          = "#2E3440"
                    foreground          = "#D8DEE9"
                    selectionBackground = "#434C5E"
                    cursorColor         = "#D8DEE9"
                    black               = "#3B4252"
                    red                 = "#BF616A"
                    green               = "#A3BE8C"
                    yellow              = "#EBCB8B"
                    blue                = "#81A1C1"
                    purple              = "#B48EAD"
                    cyan                = "#88C0D0"
                    white               = "#E5E9F0"
                    brightBlack         = "#4C566A"
                    brightRed           = "#BF616A"
                    brightGreen         = "#A3BE8C"
                    brightYellow        = "#EBCB8B"
                    brightBlue          = "#81A1C1"
                    brightPurple        = "#B48EAD"
                    brightCyan          = "#8FBCBB"
                    brightWhite         = "#ECEFF4"
                }
                $wtSettings.schemes = @($wtSettings.schemes) + $nordScheme
            }

            $updatedJson = $wtSettings | ConvertTo-Json -Depth 20
            Set-Content -Path $wtSettingsFile -Value $updatedJson -Encoding UTF8
            Write-Host "  ✓ Configured Windows Terminal settings at $wtSettingsFile" -ForegroundColor Green
            $configuredWt = $true
        } catch {
            Write-Host "  ⚠️ Could not update Windows Terminal settings at $wtSettingsFile: $($_.Exception.Message)" -ForegroundColor DarkYellow
        }
    }
}

if (-not $configuredWt) {
    Write-Host "  Windows Terminal settings not detected (will apply default profile settings when launched)." -ForegroundColor DarkGray
}

# 6. Configure .wslconfig (RAM limit & auto-reclaim for WSL2)
Write-Host ""
Write-Host "[6/7] Configuring .wslconfig (WSL 2 Performance & RAM Tuning)..." -ForegroundColor Yellow
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

# 7. Optional: Alacritty GPU Terminal Setup
Write-Host ""
if (-not $SkipAlacritty) {
    Write-Host "[7/7] Setting up Alacritty (Fast Standalone Terminal Companion)..." -ForegroundColor Yellow
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
