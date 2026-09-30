# Core.psm1 — Core Safety, Logging, Restore Point, and Undo Engine

$script:CurrentSessionId = (Get-Date -Format "yyyyMMdd_HHmmss")
$script:SessionActions = [System.Collections.ArrayList]::new()
$script:LogFilePath = $null
$script:UndoFilePath = $null
$script:DryRun = $false

function Initialize-DebloatCore {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)][string]$BaseDir = (Get-Location).Path,
        [Parameter(Mandatory=$false)][switch]$DryRunMode
    )

    $script:DryRun = $DryRunMode.IsPresent

    # Ensure directories exist
    $backupDir = Join-Path $BaseDir "backups"
    $logDir = Join-Path $backupDir "logs"
    $regDir = Join-Path $backupDir "registry"
    $undoDir = Join-Path $BaseDir "undo"

    foreach ($dir in @($backupDir, $logDir, $regDir, $undoDir)) {
        if (-not (Test-Path $dir)) {
            [void](New-Item -ItemType Directory -Path $dir -Force)
        }
    }

    $script:LogFilePath = Join-Path $logDir "session_$($script:CurrentSessionId).log"
    $script:UndoFilePath = Join-Path $undoDir "undo_$($script:CurrentSessionId).ps1"

    Write-DebloatLog "Core initialized. Session ID: $($script:CurrentSessionId)" -Level "INFO"
    if ($script:DryRun) {
        Write-DebloatLog "DRY-RUN MODE ENABLED: No system modifications will be written to disk/registry." -Level "WARN"
    }

    return [PSCustomObject]@{
        SessionId = $script:CurrentSessionId
        LogFile   = $script:LogFilePath
        UndoFile  = $script:UndoFilePath
        DryRun    = $script:DryRun
    }
}

function Write-DebloatLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$Message,
        [Parameter(Mandatory=$false)][ValidateSet("INFO", "WARN", "ERROR", "SUCCESS", "UNDO")][string]$Level = "INFO",
        [Parameter(Mandatory=$false)][scriptblock]$GuiCallback = $null
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logLine = "[$timestamp] [$Level] $Message"

    # Color output for console
    $color = switch ($Level) {
        "INFO"    { "Cyan" }
        "WARN"    { "Yellow" }
        "ERROR"   { "Red" }
        "SUCCESS" { "Green" }
        "UNDO"    { "Magenta" }
        default   { "White" }
    }

    Write-Host $logLine -ForegroundColor $color

    # Append to file
    if ($script:LogFilePath) {
        try {
            Add-Content -Path $script:LogFilePath -Value $logLine -ErrorAction SilentlyContinue
        } catch {}
    }

    # Trigger GUI callback if registered
    if ($null -ne $GuiCallback) {
        try {
            & $GuiCallback $logLine $Level
        } catch {}
    }
}

function New-SystemRestorePoint {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)][string]$Description = "Win11_26H2_Debloater_PreChange"
    )

    if ($script:DryRun) {
        Write-DebloatLog "[DRY-RUN] Simulated creation of System Restore Point: '$Description'" -Level "WARN"
        return $true
    }

    Write-DebloatLog "Checking System Restore status..." -Level "INFO"
    try {
        # Enable restore on system drive if disabled
        Enable-ComputerRestore -Drive $env:SystemDrive -ErrorAction SilentlyContinue

        # Create restore point
        Write-DebloatLog "Creating System Restore Point: '$Description'..." -Level "INFO"
        Checkpoint-Computer -Description $Description -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
        Write-DebloatLog "System Restore Point created successfully." -Level "SUCCESS"
        return $true
    } catch {
        Write-DebloatLog "Could not create Restore Point: $($_.Exception.Message). Continuing with localized .reg and undo backups." -Level "WARN"
        return $false
    }
}

function Register-SessionAction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$ActionType,
        [Parameter(Mandatory=$true)][string]$TargetId,
        [Parameter(Mandatory=$true)][string]$Description,
        [Parameter(Mandatory=$true)][string]$UndoCommand,
        [Parameter(Mandatory=$false)][hashtable]$Metadata = @{}
    )

    $actionRecord = [PSCustomObject]@{
        Timestamp   = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        ActionType  = $ActionType
        TargetId    = $TargetId
        Description = $Description
        UndoCommand = $UndoCommand
        Metadata    = $Metadata
    }

    [void]$script:SessionActions.Add($actionRecord)
    Update-UndoScript
}

function Update-UndoScript {
    if (-not $script:UndoFilePath) { return }

    $header = @"
# Auto-generated Win11 26H2 Debloater Session Rollback Script
# Session: $($script:CurrentSessionId)
# Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
# Run this script as Administrator to roll back all changes made in this session.

Write-Host "=== Rolling back Win11 26H2 Debloater changes (Session $($script:CurrentSessionId)) ===" -ForegroundColor Cyan

"@

    $commands = [System.Collections.ArrayList]::new()
    [void]$commands.Add($header)

    # Reversing actions in LIFO (Last-In-First-Out) order
    for ($i = $script:SessionActions.Count - 1; $i -ge 0; $i--) {
        $act = $script:SessionActions[$i]
        $cmdBlock = @"
# Undo: $($act.Description)
Write-Host "Reverting [$($act.ActionType)] $($act.TargetId)..." -ForegroundColor Yellow
try {
$($act.UndoCommand)
    Write-Host "  -> Reverted successfully." -ForegroundColor Green
} catch {
    Write-Host "  -> Failed to revert: `$_" -ForegroundColor Red
}

"@
        [void]$commands.Add($cmdBlock)
    }

    [void]$commands.Add('Write-Host "`n=== Rollback Completed ===" -ForegroundColor Cyan')

    try {
        Set-Content -Path $script:UndoFilePath -Value ($commands -join "`n") -Force
    } catch {}
}

function Get-SessionActions {
    return @($script:SessionActions)
}

Export-ModuleMember -Function Initialize-DebloatCore, Write-DebloatLog, New-SystemRestorePoint, Register-SessionAction, Get-SessionActions, Update-UndoScript
