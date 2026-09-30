# SystemInfo.psm1 — Windows 11 26H2 System & Hardware Inspector

function Get-WinDebloatSystemInfo {
    [CmdletBinding()]
    param()

    # Detect OS Build & Version
    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    $osVersion = $os.Version
    $buildNumber = [int]$os.BuildNumber
    $osCaption = $os.Caption
    $is26H2 = ($buildNumber -ge 26100)

    # Detect CPU
    $cpu = Get-CimInstance -ClassName Win32_Processor | Select-Object -First 1
    $cpuName = $cpu.Name.Trim()
    $cpuCores = $cpu.NumberOfCores
    $cpuLogical = $cpu.NumberOfLogicalProcessors

    # Detect RAM
    $totalRamBytes = [int64]$os.TotalVisibleMemorySize * 1024
    $totalRamGB = [math]::Round($totalRamBytes / 1GB, 1)

    # Detect Drive Type (SSD vs HDD for System Drive C:)
    $systemDriveLetter = $env:SystemDrive.TrimEnd(':')
    $driveType = "Unknown"
    try {
        $partition = Get-Partition -DriveLetter $systemDriveLetter -ErrorAction SilentlyContinue
        if ($partition) {
            $disk = Get-Disk -Number $partition.DiskNumber -ErrorAction SilentlyContinue
            if ($disk) {
                $driveType = $disk.MediaType
                $busType = $disk.BusType
                if ($busType -eq "NVMe") {
                    $driveType = "NVMe SSD"
                }
            }
        }
    } catch {
        $driveType = "SSD/HDD"
    }

    # Detect GPU
    $gpu = Get-CimInstance -ClassName Win32_VideoController | Where-Object { $_.Name -notlike "*Basic*" } | Select-Object -First 1
    $gpuName = if ($gpu) { $gpu.Name } else { "Generic Display" }

    # Detect Admin Privileges
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]$identity
    $isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    # Detect Active Power Scheme
    $activeSchemeGuid = "Unknown"
    try {
        $schemeOutput = powercfg /getactivescheme
        if ($schemeOutput -match "GUID:\s+([a-f0-9\-]+)") {
            $activeSchemeGuid = $matches[1]
        }
    } catch {}

    return [PSCustomObject]@{
        OSCaption         = $osCaption
        OSVersion         = $osVersion
        BuildNumber       = $buildNumber
        Is26H2OrNewer     = $is26H2
        CPUName           = $cpuName
        CPUCores          = $cpuCores
        CPULogicalCores   = $cpuLogical
        TotalRAMGB        = $totalRamGB
        DriveType         = $driveType
        GPUName           = $gpuName
        IsAdmin           = $isAdmin
        ActiveSchemeGuid  = $activeSchemeGuid
    }
}

Export-ModuleMember -Function Get-WinDebloatSystemInfo
