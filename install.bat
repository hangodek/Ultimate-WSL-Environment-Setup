@echo off
setlocal
title Installing Alacritty ^& WSL Environment...

:: Launch PowerShell with execution policy bypassed for this script
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0install-terminal.ps1" %*

if %ERRORLEVEL% neq 0 (
    echo.
    echo [ERROR] An error occurred during installation (Exit code: %ERRORLEVEL%).
)

echo.
pause
