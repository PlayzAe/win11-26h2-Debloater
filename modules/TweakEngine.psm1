# TweakEngine.psm1 — Registry Tweaks & Atomic Rollback Engine

Import-Module -Name (Join-Path $PSScriptRoot "Core.psm1") -ErrorAction SilentlyContinue

$script:BackupRegDir = $null

function Initialize-TweakEngine {
    param([string]$BaseDir = (Get-Location).Path)
    $script:BackupRegDir = Join-Path $BaseDir "backups\registry"
    if (-not (Test-Path $script:BackupRegDir)) {
        [void](New-Item -ItemType Directory -Path $script:BackupRegDir -Force)
    }
}

function Set-RegistryTweak {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][hashtable]$Tweak,
        [Parameter(Mandatory=$false)][switch]$DryRun
    )

    $id = $Tweak.id
    $name = $Tweak.name
    $hive = $Tweak.hive
    $path = $Tweak.path
    $valueName = $Tweak.valueName
    $type = $Tweak.type
    $value = $Tweak.value
    $origValue = $Tweak.originalValue

    $fullPSPath = "$($hive):\$($path)"
    $fullRegPath = "$($hive)\$($path)"

    Write-DebloatLog "Applying tweak: [$name] -> $fullRegPath ($valueName = $value)" -Level "INFO"

    if ($DryRun.IsPresent) {
        Write-DebloatLog "[DRY-RUN] Simulated setting $fullRegPath ($valueName) = $value" -Level "SUCCESS"
        Register-SessionAction -ActionType "Registry" -TargetId $id -Description "Tweak: $name" `
            -UndoCommand "# [DRY-RUN] Revert $fullRegPath $valueName" `
            -Metadata @{ Hive = $hive; Path = $path; ValueName = $valueName; OriginalValue = $origValue }
        return $true
    }

    try {
        # 1. Snapshot original key/value before mutation
        $backupFile = Join-Path $script:BackupRegDir "$($id)_prechange.reg"
        $regExportCmd = "reg.exe export `"$fullRegPath`" `"$backupFile`" /y"
        Invoke-Expression $regExportCmd 2>$null | Out-Null

        # 2. Ensure parent registry path exists
        if (-not (Test-Path $fullPSPath)) {
            [void](New-Item -Path $fullPSPath -Force)
        }

        # 3. Apply the registry value
        if ([string]::IsNullOrEmpty($valueName)) {
            # Default value for key
            Set-Item -Path $fullPSPath -Value $value -Force
        } else {
            Set-ItemProperty -Path $fullPSPath -Name $valueName -Value $value -Type $type -Force
        }

        # 4. Prepare Undo command
        $undoCmd = ""
        if (Test-Path $backupFile) {
            $undoCmd = "    reg.exe import `"$backupFile`""
        } elseif ($null -ne $origValue) {
            $undoCmd = "    Set-ItemProperty -Path `"$fullPSPath`" -Name `"$valueName`" -Value $origValue -Force"
        } else {
            $undoCmd = "    Remove-ItemProperty -Path `"$fullPSPath`" -Name `"$valueName`" -ErrorAction SilentlyContinue"
        }

        # 5. Register in session
        Register-SessionAction -ActionType "Registry" -TargetId $id -Description "Tweak: $name" `
            -UndoCommand $undoCmd `
            -Metadata @{ BackupFile = $backupFile; FullPath = $fullPSPath; ValueName = $valueName; OriginalValue = $origValue }

        Write-DebloatLog "Successfully applied tweak: $name" -Level "SUCCESS"
        return $true
    }
    catch {
        Write-DebloatLog "Failed to apply tweak '$name': $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
}

function Restore-RegistryTweak {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][hashtable]$Tweak,
        [Parameter(Mandatory=$false)][switch]$DryRun
    )

    $id = $Tweak.id
    $name = $Tweak.name
    $hive = $Tweak.hive
    $path = $Tweak.path
    $valueName = $Tweak.valueName
    $origValue = $Tweak.originalValue

    $fullPSPath = "$($hive):\$($path)"
    $backupFile = Join-Path $script:BackupRegDir "$($id)_prechange.reg"

    Write-DebloatLog "Undoing tweak: [$name]..." -Level "UNDO"

    if ($DryRun.IsPresent) {
        Write-DebloatLog "[DRY-RUN] Simulated reverting tweak $name" -Level "SUCCESS"
        return $true
    }

    try {
        if (Test-Path $backupFile) {
            & reg.exe import "$backupFile" 2>$null | Out-Null
            Write-DebloatLog "Restored from snapshot .reg file: $backupFile" -Level "SUCCESS"
            return $true
        }
        elseif ($null -ne $origValue) {
            Set-ItemProperty -Path $fullPSPath -Name $valueName -Value $origValue -Force
            Write-DebloatLog "Restored original value: $origValue" -Level "SUCCESS"
            return $true
        }
        else {
            Remove-ItemProperty -Path $fullPSPath -Name $valueName -ErrorAction SilentlyContinue
            Write-DebloatLog "Removed tweak value (was non-existent originally)." -Level "SUCCESS"
            return $true
        }
    }
    catch {
        Write-DebloatLog "Failed to undo tweak '$name': $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
}

Set-Alias -Name Undo-RegistryTweak -Value Restore-RegistryTweak

Export-ModuleMember -Function Initialize-TweakEngine, Set-RegistryTweak, Restore-RegistryTweak -Alias Undo-RegistryTweak

