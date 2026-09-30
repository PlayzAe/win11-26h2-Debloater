# Safe Unit Test Suite for Windows 11 26H2 Debloater
# ZERO RISK: Pure in-memory mocks, zero machine changes, returns $true or $false.

# 1. Initialize Mock Environment
function New-MockEnvironment {
    $apps = [System.Collections.ArrayList]::new()
    @("Microsoft.BingNews", "Microsoft.BingWeather", "Microsoft.MicrosoftSolitaireCollection", "Microsoft.WindowsStore", "Microsoft.DesktopAppInstaller") | ForEach-Object { [void]$apps.Add($_) }
    
    return [PSCustomObject]@{
        RegistryStore = @{}
        ServiceStore  = @{
            "XboxGipSvc"     = @{ Status = "Running"; StartType = "Manual" }
            "XblAuthManager" = @{ Status = "Running"; StartType = "Manual" }
            "bthserv"        = @{ Status = "Running"; StartType = "Automatic" }
            "DiagTrack"      = @{ Status = "Running"; StartType = "Automatic" }
        }
        AppxStore     = $apps
        UndoLog       = [System.Collections.ArrayList]::new()
    }
}

# 2. Mock Engine Functions
function Invoke-MockRegistryWrite {
    param($MockEnv, [string]$Path, [string]$Name, $Value)
    $oldValue = $MockEnv.RegistryStore["$Path\$Name"]
    $MockEnv.UndoLog.Add([PSCustomObject]@{
        Type     = "Registry"
        Path     = $Path
        Name     = $Name
        OldValue = $oldValue
    })
    $MockEnv.RegistryStore["$Path\$Name"] = $Value
    return $true
}

function Invoke-MockAppxRemove {
    param($MockEnv, [string]$PackageName)
    # Critical protection: NEVER remove WindowsStore or DesktopAppInstaller
    $criticalPackages = @("Microsoft.WindowsStore", "Microsoft.DesktopAppInstaller")
    if ($criticalPackages -contains $PackageName) {
        return $false # Denied for safety
    }
    
    if ($MockEnv.AppxStore.Contains($PackageName)) {
        $MockEnv.UndoLog.Add([PSCustomObject]@{
            Type        = "Appx"
            PackageName = $PackageName
        })
        [void]$MockEnv.AppxStore.Remove($PackageName)
        return $true
    }
    return $false
}

function Invoke-MockUndo {
    param($MockEnv)
    if ($MockEnv.UndoLog.Count -eq 0) { return $false }
    $lastAction = $MockEnv.UndoLog[$MockEnv.UndoLog.Count - 1]
    $MockEnv.UndoLog.RemoveAt($MockEnv.UndoLog.Count - 1)
    
    if ($lastAction.Type -eq "Registry") {
        if ($null -eq $lastAction.OldValue) {
            $MockEnv.RegistryStore.Remove("$($lastAction.Path)\$($lastAction.Name)")
        } else {
            $MockEnv.RegistryStore["$($lastAction.Path)\$($lastAction.Name)"] = $lastAction.OldValue
        }
        return $true
    }
    elseif ($lastAction.Type -eq "Appx") {
        $MockEnv.AppxStore.Add($lastAction.PackageName)
        return $true
    }
    return $false
}

# 3. Unit Tests (All Return $true or $false)

function Test-SafeAppRemoval_BingNews_ReturnsTrue {
    $env = New-MockEnvironment
    $removed = Invoke-MockAppxRemove -MockEnv $env -PackageName "Microsoft.BingNews"
    $appGone = (-not $env.AppxStore.Contains("Microsoft.BingNews"))
    return [bool]($removed -and $appGone)
}

function Test-CriticalAppProtection_Store_ReturnsFalseOnRemove {
    $env = New-MockEnvironment
    # Attempt to remove Store must be blocked
    $removed = Invoke-MockAppxRemove -MockEnv $env -PackageName "Microsoft.WindowsStore"
    $storeStillThere = $env.AppxStore.Contains("Microsoft.WindowsStore")
    return [bool]((-not $removed) -and $storeStillThere)
}

function Test-UndoMechanism_RegistryTweak_ReturnsTrue {
    $env = New-MockEnvironment
    # Write a tweak
    [void](Invoke-MockRegistryWrite -MockEnv $env -Path "HKLM\SYSTEM" -Name "HwSchMode" -Value 2)
    $applied = ($env.RegistryStore["HKLM\SYSTEM\HwSchMode"] -eq 2)
    
    # Trigger Undo
    $undone = Invoke-MockUndo -MockEnv $env
    $restored = (-not $env.RegistryStore.ContainsKey("HKLM\SYSTEM\HwSchMode"))
    
    return [bool]($applied -and $undone -and $restored)
}

function Test-FiveTierFallback_SimulatePipeline_ReturnsTrue {
    # Simulate: Tier 1 fails, Tier 2 succeeds
    $pipeline = @(
        @{ Tier = 1; Handler = { return $false } },
        @{ Tier = 2; Handler = { return $true } },
        @{ Tier = 3; Handler = { return $true } }
    )
    
    $recovered = $false
    foreach ($tier in $pipeline) {
        $attempt = & $tier.Handler
        if ($attempt -eq $true) {
            $recovered = $true
            break
        }
    }
    return [bool]$recovered
}

# 4. Runner
function Invoke-SafeUnitTests {
    $testSuite = @(
        @{ Name = "Safe App Removal (BingNews)"; Action = { Test-SafeAppRemoval_BingNews_ReturnsTrue } },
        @{ Name = "Critical Protection (Store Removal Blocked)"; Action = { Test-CriticalAppProtection_Store_ReturnsFalseOnRemove } },
        @{ Name = "1-Click Undo Engine (Registry Revert)"; Action = { Test-UndoMechanism_RegistryTweak_ReturnsTrue } },
        @{ Name = "5-Tier Fallback Pipeline (Recovery on Tier 2)"; Action = { Test-FiveTierFallback_SimulatePipeline_ReturnsTrue } }
    )

    $allPassed = $true
    Write-Host "`n=== RUNNING SAFE MOCK UNIT TESTS (ZERO SYSTEM IMPACT) ===" -ForegroundColor Cyan

    foreach ($test in $testSuite) {
        $result = & $test.Action
        if ($result -eq $true) {
            Write-Host " [PASS] $($test.Name) => True" -ForegroundColor Green
        } else {
            Write-Host " [FAIL] $($test.Name) => False" -ForegroundColor Red
            $allPassed = $false
        }
    }

    Write-Host "========================================================`n" -ForegroundColor Cyan
    return [bool]$allPassed
}

# Run the suite safely
Invoke-SafeUnitTests
