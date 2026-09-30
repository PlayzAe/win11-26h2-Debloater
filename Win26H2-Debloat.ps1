# Win26H2-Debloat.ps1 — Main Entry Point for Windows 11 26H2 Debloater & Gaming Optimizer

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)][switch]$DryRun
)

# 1. Self-Elevation Check
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = [Security.Principal.WindowsPrincipal]$identity
$isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "Elevating to Administrator privileges..." -ForegroundColor Yellow
    $dryArg = if ($DryRun.IsPresent) { "-DryRun" } else { "" }
    try {
        Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" $dryArg" -Verb RunAs
        exit 0
    } catch {
        Write-Host "Admin elevation was cancelled. Launching in non-elevated mode (some tweaks will be simulated or fail)." -ForegroundColor Red
    }
}

# 2. Set Execution Environment
Set-Location -Path $PSScriptRoot
$host.UI.RawUI.WindowTitle = "Win11 26H2 Debloater & Gaming Optimizer"

# 3. Load GUI Controller
$guiControllerPath = Join-Path $PSScriptRoot "gui\GuiController.ps1"
if (-not (Test-Path $guiControllerPath)) {
    Write-Host "Error: Cannot locate gui\GuiController.ps1 at $guiControllerPath" -ForegroundColor Red
    Pause
    exit 1
}

. $guiControllerPath

# 4. Start GUI
Start-WinDebloatGui -DryRun:$DryRun
