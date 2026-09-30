@echo off
title Win11 26H2 Debloater ^& Gaming Optimizer Launcher
cd /d "%~dp0"

:: Check for Administrative Rights
net session >nul 2>&1
if %errorLevel% == 0 (
    goto :RunElevated
) else (
    echo ==============================================================
    echo  Requesting Administrator privileges to launch GUI...
    echo ==============================================================
    powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

:RunElevated
echo ==============================================================
echo  Launching Windows 11 26H2 Debloater ^& Gaming Optimizer...
echo ==============================================================
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Win26H2-Debloat.ps1"

if %errorLevel% neq 0 (
    echo.
    echo An error occurred while running the debloater.
    pause
)
exit /b
