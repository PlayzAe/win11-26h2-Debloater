# GamingMode.psm1 — Windows 11 Gaming Performance & Low-Latency Engine

Import-Module -Name (Join-Path $PSScriptRoot "Core.psm1") -ErrorAction SilentlyContinue

$script:OriginalPowerPlan = $null

function Initialize-GamingMode {
    param([string]$BaseDir = (Get-Location).Path)
    try {
        $schemeOutput = powercfg /getactivescheme
        if ($schemeOutput -match "GUID:\s+([a-f0-9\-]+)") {
            $script:OriginalPowerPlan = $matches[1]
        }
    } catch {}
}

function Enable-CpuCoreUnparking {
    [CmdletBinding()]
    param([switch]$DryRun)

    Write-DebloatLog "Configuring CPU Core Unparking (100% core availability)..." -Level "INFO"

    if ($DryRun.IsPresent) {
        Write-DebloatLog "[DRY-RUN] Simulated CPU core unparking to 100%" -Level "SUCCESS"
        Register-SessionAction -ActionType "Gaming" -TargetId "cpu_core_unparking" -Description "CPU Core Unparking" `
            -UndoCommand "    # [DRY-RUN] Revert CPU core parking attributes"
        return $true
    }

    try {
        # Unhide Core Parking attributes in PowerCfg
        & powercfg -attributes SUB_PROCESSOR CPMINCORES -ATTRIB_HIDE 2>$null | Out-Null
        & powercfg -attributes SUB_PROCESSOR CPMAXCORES -ATTRIB_HIDE 2>$null | Out-Null

        # Set minimum unparked cores to 100% on AC and DC for active scheme
        & powercfg -setacvalueindex SCHEME_CURRENT SUB_PROCESSOR CPMINCORES 100 2>$null | Out-Null
        & powercfg -setdcvalueindex SCHEME_CURRENT SUB_PROCESSOR CPMINCORES 100 2>$null | Out-Null
        & powercfg -setacvalueindex SCHEME_CURRENT SUB_PROCESSOR CPMAXCORES 100 2>$null | Out-Null
        & powercfg -setdcvalueindex SCHEME_CURRENT SUB_PROCESSOR CPMAXCORES 100 2>$null | Out-Null
        & powercfg -setactive SCHEME_CURRENT 2>$null | Out-Null

        $undoCmd = @"
    powercfg -setacvalueindex SCHEME_CURRENT SUB_PROCESSOR CPMINCORES 10 2>`$null | Out-Null
    powercfg -setactive SCHEME_CURRENT 2>`$null | Out-Null
"@
        Register-SessionAction -ActionType "Gaming" -TargetId "cpu_core_unparking" -Description "CPU Core Unparking" `
            -UndoCommand $undoCmd

        Write-DebloatLog "CPU Core Unparking applied successfully. All cores awake." -Level "SUCCESS"
        return $true
    } catch {
        Write-DebloatLog "Failed to unpark CPU cores: $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
}

function Enable-UltimatePerformancePlan {
    [CmdletBinding()]
    param([switch]$DryRun)

    Write-DebloatLog "Activating Ultimate Performance Power Plan..." -Level "INFO"

    if ($DryRun.IsPresent) {
        Write-DebloatLog "[DRY-RUN] Simulated activation of Ultimate Performance Power Plan" -Level "SUCCESS"
        Register-SessionAction -ActionType "Gaming" -TargetId "ultimate_performance_plan" -Description "Ultimate Performance Plan" `
            -UndoCommand "    # [DRY-RUN] Restore original power plan $script:OriginalPowerPlan"
        return $true
    }

    try {
        # Check if already installed
        $list = powercfg /list
        $guid = $null

        if ($list -match "([a-f0-9\-]+)\s+\(Ultimate Performance\)") {
            $guid = $matches[1]
        } else {
            # Duplicate the hidden ultimate performance scheme
            $dupOutput = powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61
            if ($dupOutput -match "GUID:\s+([a-f0-9\-]+)") {
                $guid = $matches[1]
            }
        }

        if ($guid) {
            & powercfg /setactive $guid
            Write-DebloatLog "Ultimate Performance Plan activated: $guid" -Level "SUCCESS"

            $origGuid = if ($script:OriginalPowerPlan) { $script:OriginalPowerPlan } else { "381b4222-f694-41f0-9685-ff5bb260df2e" }
            $undoCmd = "    powercfg /setactive $origGuid"

            Register-SessionAction -ActionType "Gaming" -TargetId "ultimate_performance_plan" -Description "Ultimate Performance Plan" `
                -UndoCommand $undoCmd
            return $true
        } else {
            Write-DebloatLog "Could not generate Ultimate Performance plan. Applying High Performance fallback." -Level "WARN"
            & powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>$null | Out-Null
            return $true
        }
    } catch {
        Write-DebloatLog "Failed to set power scheme: $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
}

function Optimize-NetworkAndScheduler {
    [CmdletBinding()]
    param([switch]$DryRun)

    Write-DebloatLog "Optimizing Network Throttling & MMCSS GPU Priority..." -Level "INFO"

    if ($DryRun.IsPresent) {
        Write-DebloatLog "[DRY-RUN] Simulated MMCSS & Network Throttling tweaks" -Level "SUCCESS"
        return $true
    }

    try {
        $sysProfile = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
        if (-not (Test-Path $sysProfile)) { [void](New-Item -Path $sysProfile -Force) }
        Set-ItemProperty -Path $sysProfile -Name "NetworkThrottlingIndex" -Value 0xFFFFFFFF -Type DWord -Force
        Set-ItemProperty -Path $sysProfile -Name "SystemResponsiveness" -Value 0 -Type DWord -Force

        $gamesTask = "$sysProfile\Tasks\Games"
        if (-not (Test-Path $gamesTask)) { [void](New-Item -Path $gamesTask -Force) }
        Set-ItemProperty -Path $gamesTask -Name "GPU Priority" -Value 8 -Type DWord -Force
        Set-ItemProperty -Path $gamesTask -Name "Priority" -Value 6 -Type DWord -Force
        Set-ItemProperty -Path $gamesTask -Name "Scheduling Category" -Value "High" -Type String -Force
        Set-ItemProperty -Path $gamesTask -Name "SFIO Priority" -Value "High" -Type String -Force

        $undoCmd = @"
    Set-ItemProperty -Path "$sysProfile" -Name "NetworkThrottlingIndex" -Value 10 -Type DWord -Force
    Set-ItemProperty -Path "$sysProfile" -Name "SystemResponsiveness" -Value 20 -Type DWord -Force
    Set-ItemProperty -Path "$gamesTask" -Name "GPU Priority" -Value 8 -Type DWord -Force
    Set-ItemProperty -Path "$gamesTask" -Name "Priority" -Value 2 -Type DWord -Force
"@
        Register-SessionAction -ActionType "Gaming" -TargetId "mmcss_network_optimization" -Description "MMCSS & Network Scheduler" `
            -UndoCommand $undoCmd

        Write-DebloatLog "MMCSS GPU scheduling & Network Throttling optimized." -Level "SUCCESS"
        return $true
    } catch {
        Write-DebloatLog "Failed to configure MMCSS: $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
}

function Optimize-SvcHostThreshold {
    [CmdletBinding()]
    param([switch]$DryRun)

    Write-DebloatLog "Optimizing SvcHostSplitThreshold based on installed RAM..." -Level "INFO"

    try {
        $os = Get-CimInstance Win32_OperatingSystem
        $totalRamKB = [int]$os.TotalVisibleMemorySize

        if ($DryRun.IsPresent) {
            Write-DebloatLog "[DRY-RUN] Simulated setting SvcHostSplitThreshold to $totalRamKB KB" -Level "SUCCESS"
            return $true
        }

        $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control"
        Set-ItemProperty -Path $regPath -Name "SvcHostSplitThresholdInKB" -Value $totalRamKB -Type DWord -Force

        Register-SessionAction -ActionType "Gaming" -TargetId "svchost_split_threshold" -Description "SvcHost Split Threshold" `
            -UndoCommand "    Set-ItemProperty -Path `"$regPath`" -Name `"SvcHostSplitThresholdInKB`" -Value 3670016 -Type DWord -Force"

        Write-DebloatLog "SvcHostSplitThreshold set to $totalRamKB KB." -Level "SUCCESS"
        return $true
    } catch {
        Write-DebloatLog "Failed to configure SvcHost threshold: $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
}

Export-ModuleMember -Function Initialize-GamingMode, Enable-CpuCoreUnparking, Enable-UltimatePerformancePlan, Optimize-NetworkAndScheduler, Optimize-SvcHostThreshold
