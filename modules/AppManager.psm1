# AppManager.psm1 — Windows 11 AppX Debloat & 5-Tier Fallback Restoration Pipeline

Import-Module -Name (Join-Path $PSScriptRoot "Core.psm1") -ErrorAction SilentlyContinue

$script:AppBackupStateFile = $null

function Initialize-AppManager {
    param([string]$BaseDir = (Get-Location).Path)
    $script:AppBackupStateFile = Join-Path $BaseDir "backups\apps_state.json"
}

function Get-InstalledDebloatApps {
    [CmdletBinding()]
    param([string]$AppsConfigPath)

    if (-not (Test-Path $AppsConfigPath)) { return @() }

    $catalog = (Get-Content $AppsConfigPath -Raw | ConvertFrom-Json).apps
    $installedPackages = Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue

    $results = [System.Collections.ArrayList]::new()

    foreach ($app in $catalog) {
        $matching = $installedPackages | Where-Object { $_.Name -like "*$($app.id)*" } | Select-Object -First 1
        $isInstalled = ($null -ne $matching)

        $obj = [PSCustomObject]@{
            Id                 = $app.id
            Name               = $app.name
            Risk               = $app.risk
            DescriptionSimple  = $app.descriptionSimple
            DescriptionTech    = $app.descriptionTech
            GamingImpact       = $app.gamingImpact
            CanUndo            = $app.canUndo
            RecommendedAction  = $app.recommendedAction
            IsInstalled        = $isInstalled
            PackageFullName    = if ($isInstalled) { $matching.PackageFullName } else { $null }
            InstallLocation    = if ($isInstalled) { $matching.InstallLocation } else { $null }
        }
        [void]$results.Add($obj)
    }

    return @($results)
}

function Remove-DebloatApp {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$AppId,
        [Parameter(Mandatory=$false)][switch]$ForceProtectBypass,
        [Parameter(Mandatory=$false)][switch]$DryRun
    )

    # 1. Critical System-Breaking Block
    $criticalApps = @("Microsoft.WindowsStore", "Microsoft.DesktopAppInstaller", "Microsoft.Windows.ShellExperienceHost", "Microsoft.Windows.StartMenuExperienceHost")
    if ($criticalApps -contains $AppId -and -not $ForceProtectBypass.IsPresent) {
        Write-DebloatLog "CRITICAL PROTECTION: '$AppId' is essential for system stability. Removal is BLOCKED." -Level "ERROR"
        return $false
    }

    # 2. Query package
    $package = Get-AppxPackage -AllUsers | Where-Object { $_.Name -like "*$AppId*" } | Select-Object -First 1
    if (-not $package) {
        Write-DebloatLog "Package matching '$AppId' is not currently installed." -Level "INFO"
        return $true
    }

    $pkgFullName = $package.PackageFullName
    $installLoc = $package.InstallLocation
    $manifestPath = Join-Path $installLoc "AppXManifest.xml"

    Write-DebloatLog "Removing package: $pkgFullName..." -Level "INFO"

    if ($DryRun.IsPresent) {
        Write-DebloatLog "[DRY-RUN] Simulated removal of $pkgFullName" -Level "SUCCESS"
        Register-SessionAction -ActionType "AppX" -TargetId $AppId -Description "Removed App: $AppId" `
            -UndoCommand "    # [DRY-RUN] Reinstall app $AppId via 5-Tier Fallback" `
            -Metadata @{ AppId = $AppId; PackageFullName = $pkgFullName; ManifestPath = $manifestPath }
        return $true
    }

    try {
        # Snapshot state
        Save-AppBackupSnapshot -AppId $AppId -PackageFullName $pkgFullName -InstallLocation $installLoc -ManifestPath $manifestPath

        # Remove provisioned package so new users don't get it
        $provisioned = Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -like "*$AppId*" }
        if ($provisioned) {
            Remove-AppxProvisionedPackage -Online -PackageName $provisioned.PackageName -ErrorAction SilentlyContinue | Out-Null
        }

        # Remove user package
        Remove-AppxPackage -Package $pkgFullName -AllUsers -ErrorAction Stop

        # Register Undo Command (pointing to our 5-Tier Fallback Engine)
        $undoCmd = "    Restore-DebloatAppWithFallback -AppId `"$AppId`""
        Register-SessionAction -ActionType "AppX" -TargetId $AppId -Description "Removed App: $AppId" `
            -UndoCommand $undoCmd `
            -Metadata @{ AppId = $AppId; PackageFullName = $pkgFullName; ManifestPath = $manifestPath }

        Write-DebloatLog "Successfully removed: $AppId" -Level "SUCCESS"
        return $true
    }
    catch {
        Write-DebloatLog "Failed to remove package '$AppId': $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
}

function Save-AppBackupSnapshot {
    param($AppId, $PackageFullName, $InstallLocation, $ManifestPath)
    if (-not $script:AppBackupStateFile) { return }

    $state = @{}
    if (Test-Path $script:AppBackupStateFile) {
        try {
            $content = Get-Content $script:AppBackupStateFile -Raw -ErrorAction SilentlyContinue
            if ($content) { $state = $content | ConvertFrom-Json -AsHashtable }
        } catch {}
    }

    $state[$AppId] = @{
        PackageFullName = $PackageFullName
        InstallLocation = $InstallLocation
        ManifestPath    = $ManifestPath
        RemovedAt       = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }

    try {
        $state | ConvertTo-Json -Depth 4 | Set-Content -Path $script:AppBackupStateFile -Force
    } catch {}
}

# The Resilient 5-Tier Fallback Restoration Pipeline
function Restore-DebloatAppWithFallback {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$AppId,
        [Parameter(Mandatory=$false)][switch]$DryRun
    )

    Write-DebloatLog "Starting 5-Tier Fallback Restoration for: [$AppId]..." -Level "UNDO"

    if ($DryRun.IsPresent) {
        Write-DebloatLog "[DRY-RUN] Simulated 5-Tier Fallback restoration for $AppId" -Level "SUCCESS"
        return $true
    }

    # Fetch snapshot metadata if available
    $snapshot = $null
    if (Test-Path $script:AppBackupStateFile) {
        $state = Get-Content $script:AppBackupStateFile -Raw | ConvertFrom-Json -AsHashtable
        if ($state.ContainsKey($AppId)) {
            $snapshot = $state[$AppId]
        }
    }

    # TIER 1: Native In-Box Manifest Registration
    Write-DebloatLog "Tier 1: Attempting local AppxManifest registration..." -Level "INFO"
    if ($snapshot -and (Test-Path $snapshot.ManifestPath)) {
        try {
            Add-AppxPackage -DisableDevelopmentMode -Register $snapshot.ManifestPath -ErrorAction Stop
            Write-DebloatLog "Tier 1 Success: App restored via local manifest." -Level "SUCCESS"
            return $true
        } catch {
            Write-DebloatLog "Tier 1 failed: $($_.Exception.Message). Falling back to Tier 2..." -Level "WARN"
        }
    } else {
        # Check WinSxS / SystemApps directory
        $manifest = Get-ChildItem -Path "$env:ProgramFiles\WindowsApps", "$env:SystemRoot\SystemApps" -Filter "AppXManifest.xml" -Recurse -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -like "*$AppId*" } | Select-Object -First 1

        if ($manifest) {
            try {
                Add-AppxPackage -DisableDevelopmentMode -Register $manifest.FullName -ErrorAction Stop
                Write-DebloatLog "Tier 1 Success: App restored from system component directory." -Level "SUCCESS"
                return $true
            } catch {
                Write-DebloatLog "Tier 1 failed: $($_.Exception.Message). Falling back to Tier 2..." -Level "WARN"
            }
        }
    }

    # TIER 2: Protocol / Winget / wsreset Deployment
    Write-DebloatLog "Tier 2: Attempting WinGet or protocol launch..." -Level "INFO"
    try {
        if ($AppId -eq "Microsoft.WindowsStore") {
            Start-Process "wsreset.exe" -ArgumentList "-i" -Wait -NoNewWindow
            Write-DebloatLog "Tier 2 Success: wsreset -i executed to reinstall Store." -Level "SUCCESS"
            return $true
        } else {
            $wingetCmd = Get-Command "winget" -ErrorAction SilentlyContinue
            if ($wingetCmd) {
                & winget install $AppId --accept-package-agreements --accept-source-agreements --silent 2>$null
                if ($LASTEXITCODE -eq 0) {
                    Write-DebloatLog "Tier 2 Success: Installed via WinGet." -Level "SUCCESS"
                    return $true
                }
            }
        }
    } catch {
        Write-DebloatLog "Tier 2 failed. Falling back to Tier 3..." -Level "WARN"
    }

    # TIER 3: Provisioned Package Re-Registration
    Write-DebloatLog "Tier 3: Attempting provisioned package re-registration..." -Level "INFO"
    try {
        $prov = Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -like "*$AppId*" } | Select-Object -First 1
        if ($prov) {
            Add-AppxPackage -RegisterByFamilyName -MainPackage $prov.PackageName -ErrorAction Stop
            Write-DebloatLog "Tier 3 Success: Registered provisioned package family." -Level "SUCCESS"
            return $true
        }
    } catch {
        Write-DebloatLog "Tier 3 failed. Falling back to Tier 4..." -Level "WARN"
    }

    # TIER 4: DISM Component Store Restore
    Write-DebloatLog "Tier 4: Checking DISM component servicing..." -Level "INFO"
    try {
        Write-DebloatLog "Invoking DISM image integrity check..." -Level "INFO"
        & dism.exe /Online /Cleanup-Image /RestoreHealth /NoRestart | Out-Null
        # Re-check AppX
        $manifest = Get-ChildItem -Path "$env:ProgramFiles\WindowsApps" -Filter "AppXManifest.xml" -Recurse -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -like "*$AppId*" } | Select-Object -First 1
        if ($manifest) {
            Add-AppxPackage -DisableDevelopmentMode -Register $manifest.FullName -ErrorAction Stop
            Write-DebloatLog "Tier 4 Success: App restored after DISM repair." -Level "SUCCESS"
            return $true
        }
    } catch {
        Write-DebloatLog "Tier 4 failed. Falling back to Tier 5..." -Level "WARN"
    }

    # TIER 5: Fallback Rescue Guidance
    Write-DebloatLog "Tier 5: Deep recovery guidance: Please run Store or ISO repair if offline packages were wiped." -Level "WARN"
    return $false
}

Export-ModuleMember -Function Initialize-AppManager, Get-InstalledDebloatApps, Remove-DebloatApp, Restore-DebloatAppWithFallback
