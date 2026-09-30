# ServiceManager.psm1 — Windows 11 Service Management & Protection Engine

Import-Module -Name (Join-Path $PSScriptRoot "Core.psm1") -ErrorAction SilentlyContinue

$script:ServiceStateFile = $null

function Initialize-ServiceManager {
    param([string]$BaseDir = (Get-Location).Path)
    $script:ServiceStateFile = Join-Path $BaseDir "backups\services_state.json"
}

function Set-DebloatServiceState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$ServiceName,
        [Parameter(Mandatory=$true)][ValidateSet("Automatic", "Manual", "Disabled")][string]$TargetStartType,
        [Parameter(Mandatory=$false)][switch]$ForceProtectBypass,
        [Parameter(Mandatory=$false)][switch]$DryRun
    )

    # Protected services check
    $protectedServices = @("bthserv", "BluetoothUserService", "XboxGipSvc", "XblAuthManager", "AudioEndpointBuilder", "Audiosrv")
    if ($protectedServices -contains $ServiceName -and -not $ForceProtectBypass.IsPresent -and $TargetStartType -eq "Disabled") {
        Write-DebloatLog "SAFETY BLOCK: Service '$ServiceName' is a protected gaming/hardware service. Refusing to disable." -Level "WARN"
        return $false
    }

    try {
        $svc = Get-Service -Name $ServiceName -ErrorAction Stop
    } catch {
        Write-DebloatLog "Service '$ServiceName' not found on this system. Skipping." -Level "INFO"
        return $true
    }

    $originalStartType = $svc.StartType.ToString()
    Write-DebloatLog "Service '$ServiceName': Current StartType = $originalStartType, Target = $TargetStartType" -Level "INFO"

    if ($originalStartType -eq $TargetStartType) {
        Write-DebloatLog "Service '$ServiceName' is already $TargetStartType. No change needed." -Level "INFO"
        return $true
    }

    if ($DryRun.IsPresent) {
        Write-DebloatLog "[DRY-RUN] Simulated setting service '$ServiceName' to $TargetStartType" -Level "SUCCESS"
        Register-SessionAction -ActionType "Service" -TargetId $ServiceName -Description "Service: $ServiceName" `
            -UndoCommand "    # [DRY-RUN] Restore service $ServiceName to $originalStartType" `
            -Metadata @{ ServiceName = $ServiceName; OriginalStartType = $originalStartType }
        return $true
    }

    try {
        # Save snapshot
        Save-ServiceStateSnapshot -ServiceName $ServiceName -OriginalStartType $originalStartType

        # Apply state
        Set-Service -Name $ServiceName -StartupType $TargetStartType -ErrorAction Stop
        if ($TargetStartType -eq "Disabled" -and $svc.Status -eq "Running") {
            Stop-Service -Name $ServiceName -Force -ErrorAction SilentlyContinue
        }

        # Register Undo command
        $undoCmd = @"
    Set-Service -Name "$ServiceName" -StartupType "$originalStartType" -ErrorAction SilentlyContinue
    if ("$originalStartType" -ne "Disabled") {
        Start-Service -Name "$ServiceName" -ErrorAction SilentlyContinue
    }
"@
        Register-SessionAction -ActionType "Service" -TargetId $ServiceName -Description "Service: $ServiceName" `
            -UndoCommand $undoCmd `
            -Metadata @{ ServiceName = $ServiceName; OriginalStartType = $originalStartType }

        Write-DebloatLog "Successfully set service '$ServiceName' to $TargetStartType." -Level "SUCCESS"
        return $true
    }
    catch {
        Write-DebloatLog "Failed to configure service '$ServiceName': $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
}

function Save-ServiceStateSnapshot {
    param([string]$ServiceName, [string]$OriginalStartType)
    if (-not $script:ServiceStateFile) { return }

    $state = @{}
    if (Test-Path $script:ServiceStateFile) {
        try {
            $content = Get-Content $script:ServiceStateFile -Raw -ErrorAction SilentlyContinue
            if ($content) { $state = $content | ConvertFrom-Json -AsHashtable }
        } catch {}
    }

    if (-not $state.ContainsKey($ServiceName)) {
        $state[$ServiceName] = $OriginalStartType
        try {
            $state | ConvertTo-Json -Depth 3 | Set-Content -Path $script:ServiceStateFile -Force
        } catch {}
    }
}

function Restore-DebloatServiceState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$ServiceName,
        [Parameter(Mandatory=$false)][switch]$DryRun
    )

    if (-not (Test-Path $script:ServiceStateFile)) {
        Write-DebloatLog "No service snapshot file found. Defaulting to 'Manual' startup type." -Level "WARN"
        $origStartType = "Manual"
    } else {
        $state = (Get-Content $script:ServiceStateFile -Raw | ConvertFrom-Json -AsHashtable)
        $origStartType = if ($state.ContainsKey($ServiceName)) { $state[$ServiceName] } else { "Manual" }
    }

    Write-DebloatLog "Undoing service '$ServiceName' -> Restoring to $origStartType..." -Level "UNDO"

    if ($DryRun.IsPresent) {
        Write-DebloatLog "[DRY-RUN] Simulated restoring service '$ServiceName' to $origStartType" -Level "SUCCESS"
        return $true
    }

    try {
        Set-Service -Name $ServiceName -StartupType $origStartType -ErrorAction Stop
        if ($origStartType -ne "Disabled") {
            Start-Service -Name $ServiceName -ErrorAction SilentlyContinue
        }
        Write-DebloatLog "Service '$ServiceName' restored to $origStartType." -Level "SUCCESS"
        return $true
    } catch {
        Write-DebloatLog "Failed to restore service '$ServiceName': $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
}

Set-Alias -Name Undo-DebloatServiceState -Value Restore-DebloatServiceState

Export-ModuleMember -Function Initialize-ServiceManager, Set-DebloatServiceState, Restore-DebloatServiceState -Alias Undo-DebloatServiceState

