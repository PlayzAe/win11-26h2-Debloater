@echo off
title PlayzDebloat - Windows 11 26H2 Tactical Optimizer
cd /d "%~dp0"

:: 1. Check for Administrative Rights
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ==============================================================
    echo  Requesting Administrator privileges...
    echo ==============================================================
    powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

:: 2. Ensure Dependencies and Build
echo ==============================================================
echo  Launching PlayzDebloat - Tactical Optimizer...
echo ==============================================================

if not exist "node_modules" (
    echo Installing core runtime dependencies...
    call npm install --no-audit --no-fund
)

if not exist "out\main\index.cjs" (
    echo Compiling production UI bundle...
    call node scripts\build.mjs
)

:: 3. Launch Portable Electron App
if exist "node_modules\.bin\electron.cmd" (
    call .\node_modules\.bin\electron.cmd .
) else (
    call npx electron .
)

exit /b
