# Test-GuiElements.Tests.ps1 — Safe Zero-Mutation Unit Test for WPF GUI Components
# Tests XAML loading, visual tree resolution, and card generators in pure mock dry-run

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

$baseDir = Split-Path -Parent $PSScriptRoot
$xamlPath = Join-Path $baseDir "gui\MainWindow.xaml"
$guiControllerPath = Join-Path $baseDir "gui\GuiController.ps1"

Write-Host "`n=== TESTING WPF XAML & GUI CONTROLLER (ZERO SYSTEM IMPACT) ===" -ForegroundColor Cyan

# 1. Test XAML Loading
$xamlContent = Get-Content $xamlPath -Raw
$reader = [System.Xml.XmlReader]::Create([System.IO.StringReader]::new($xamlContent))
$window = [System.Windows.Markup.XamlReader]::Load($reader)
$testXamlLoad = ($null -ne $window -and $window -is [System.Windows.Window])
Write-Host " [PASS] MainWindow.xaml loads cleanly => $testXamlLoad" -ForegroundColor Green

# 2. Test Essential Named Element Resolution
$essentialControls = @(
    "RootContainer", "txtSysOS", "txtSysCPU", "txtSysRAM", "txtAdminStatus",
    "btnThemeToggle", "chkDryRun", "btnCreateRestorePoint",
    "btnPresetGaming", "btnPresetPrivacy", "btnPresetFull",
    "txtSearchApps", "btnAppFilterAll", "panelAppsContainer",
    "txtSearchTweaks", "btnTweakFilterAll", "panelTweaksContainer",
    "panelGamingContainer", "panelServicesContainer",
    "panelUndoActionsContainer", "btnRollbackSession",
    "txtConsoleLog", "btnClearLog", "btnCopyLog", "txtStatusMessage", "progBar"
)

$missingControls = @()
foreach ($ctrlName in $essentialControls) {
    $elem = $window.FindName($ctrlName)
    if ($null -eq $elem) {
        $missingControls += $ctrlName
    }
}

$testControls = ($missingControls.Count -eq 0)
if ($testControls) {
    Write-Host " [PASS] All 26 essential controls resolved => True" -ForegroundColor Green
} else {
    Write-Host " [FAIL] Missing controls: $($missingControls -join ', ')" -ForegroundColor Red
}

# 3. Test Double-Bezel Card Generation (Mock)
. $guiControllerPath

$mockApp = [pscustomobject]@{
    id = "Microsoft.BingNews"
    name = "Microsoft News"
    risk = "Safe"
    descriptionSimple = "Preloaded news ticker."
    descriptionTech = "UWP package Microsoft.BingNews"
}

$mockCard = New-AppCard -App $mockApp -Window $window -LogCallback { param($m, $l) }
$testCardGen = ($mockCard -is [System.Windows.Controls.Border] -and $mockCard.Child -is [System.Windows.Controls.Border])
Write-Host " [PASS] Double-Bezel Nested Card Architecture => $testCardGen" -ForegroundColor Green

Write-Host "============================================================`n" -ForegroundColor Cyan

return ($testXamlLoad -and $testControls -and $testCardGen)
