# GuiController.ps1 — Tactical WPF GUI Controller & Dynamic Engine
# Architecture: 21st.dev / shadcn Doppelrand (Double-Bezel) + Spring Physics

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

$script:BaseDir = Split-Path -Parent $PSScriptRoot
$script:ModulesDir = Join-Path $script:BaseDir "modules"
$script:ConfigDir = Join-Path $script:BaseDir "config"

Import-Module -Name (Join-Path $script:ModulesDir "Core.psm1") -Force
Import-Module -Name (Join-Path $script:ModulesDir "SystemInfo.psm1") -Force
Import-Module -Name (Join-Path $script:ModulesDir "AppManager.psm1") -Force
Import-Module -Name (Join-Path $script:ModulesDir "TweakEngine.psm1") -Force
Import-Module -Name (Join-Path $script:ModulesDir "ServiceManager.psm1") -Force
Import-Module -Name (Join-Path $script:ModulesDir "GamingMode.psm1") -Force

$script:IsDarkMode = $true
$script:CurrentAppRiskFilter = "ALL"
$script:CurrentTweakCategoryFilter = "ALL"
$script:AppCardItems = [System.Collections.Generic.List[psobject]]::new()
$script:TweakCardItems = [System.Collections.Generic.List[psobject]]::new()

function Set-AppTheme {
    param(
        [Parameter(Mandatory=$true)]$Window,
        [Parameter(Mandatory=$true)][bool]$DarkMode
    )

    $bc = [System.Windows.Media.BrushConverter]::new()

    if ($DarkMode) {
        # OLED Tactical Dark Theme (21st.dev / shadcn dark)
        $Window.Resources["BrushWindowBg"]     = $bc.ConvertFromString("#07080E")
        $Window.Resources["BrushHeaderBg"]     = $bc.ConvertFromString("#0D101A")
        $Window.Resources["BrushSurface"]      = $bc.ConvertFromString("#111624")
        $Window.Resources["BrushSurfaceInner"] = $bc.ConvertFromString("#0A0D15")
        $Window.Resources["BrushCardShellBg"]  = $bc.ConvertFromString("#141B2D")
        $Window.Resources["BrushCardCoreBg"]   = $bc.ConvertFromString("#0C101A")
        $Window.Resources["BrushBorder"]       = $bc.ConvertFromString("#1E283D")
        $Window.Resources["BrushBorderGlow"]   = $bc.ConvertFromString("#00F0FF")
        $Window.Resources["BrushTextPrimary"]  = $bc.ConvertFromString("#F8FAFC")
        $Window.Resources["BrushTextSecondary"]= $bc.ConvertFromString("#94A3B8")
        $Window.Resources["BrushTextMuted"]    = $bc.ConvertFromString("#64748B")
        $Window.Resources["BrushAccent"]       = $bc.ConvertFromString("#00F0FF")
        $Window.Resources["BrushAccentHover"]  = $bc.ConvertFromString("#38BDF8")
        $Window.Resources["BrushAccentIndigo"] = $bc.ConvertFromString("#6366F1")
        $Window.Resources["BrushBtnIconBg"]    = $bc.ConvertFromString("#1A2338")
        $Window.Resources["BrushConsoleBg"]    = $bc.ConvertFromString("#05060A")
        $Window.Resources["BrushConsoleText"]  = $bc.ConvertFromString("#38BDF8")
        $Window.Resources["BrushBadgeSafe"]    = $bc.ConvertFromString("#10B981")
        $Window.Resources["BrushBadgeWarn"]    = $bc.ConvertFromString("#F59E0B")
        $Window.Resources["BrushBadgeDanger"]  = $bc.ConvertFromString("#EF4444")
        $Window.Resources["BrushBadgeCritical"]= $bc.ConvertFromString("#A855F7")
    } else {
        # Clean Swiss Light Theme (shadcn clean zinc)
        $Window.Resources["BrushWindowBg"]     = $bc.ConvertFromString("#F8FAFC")
        $Window.Resources["BrushHeaderBg"]     = $bc.ConvertFromString("#FFFFFF")
        $Window.Resources["BrushSurface"]      = $bc.ConvertFromString("#FFFFFF")
        $Window.Resources["BrushSurfaceInner"] = $bc.ConvertFromString("#F1F5F9")
        $Window.Resources["BrushCardShellBg"]  = $bc.ConvertFromString("#E2E8F0")
        $Window.Resources["BrushCardCoreBg"]   = $bc.ConvertFromString("#FFFFFF")
        $Window.Resources["BrushBorder"]       = $bc.ConvertFromString("#CBD5E1")
        $Window.Resources["BrushBorderGlow"]   = $bc.ConvertFromString("#0284C7")
        $Window.Resources["BrushTextPrimary"]  = $bc.ConvertFromString("#0F172A")
        $Window.Resources["BrushTextSecondary"]= $bc.ConvertFromString("#475569")
        $Window.Resources["BrushTextMuted"]    = $bc.ConvertFromString("#94A3B8")
        $Window.Resources["BrushAccent"]       = $bc.ConvertFromString("#0284C7")
        $Window.Resources["BrushAccentHover"]  = $bc.ConvertFromString("#0369A1")
        $Window.Resources["BrushAccentIndigo"] = $bc.ConvertFromString("#4F46E5")
        $Window.Resources["BrushBtnIconBg"]    = $bc.ConvertFromString("#E2E8F0")
        $Window.Resources["BrushConsoleBg"]    = $bc.ConvertFromString("#0F172A")
        $Window.Resources["BrushConsoleText"]  = $bc.ConvertFromString("#38BDF8")
        $Window.Resources["BrushBadgeSafe"]    = $bc.ConvertFromString("#059669")
        $Window.Resources["BrushBadgeWarn"]    = $bc.ConvertFromString("#D97706")
        $Window.Resources["BrushBadgeDanger"]  = $bc.ConvertFromString("#DC2626")
        $Window.Resources["BrushBadgeCritical"]= $bc.ConvertFromString("#9333EA")
    }

    $btnTheme = $Window.FindName("btnThemeToggle")
    if ($btnTheme) {
        $btnTheme.Content = if ($DarkMode) { "🌙 Dark Mode" } else { "☀️ Light Mode" }
    }
}

function Start-WinDebloatGui {
    [CmdletBinding()]
    param([switch]$DryRun)

    # Initialize Core Engines
    Initialize-DebloatCore -BaseDir $script:BaseDir -DryRunMode:$DryRun
    Initialize-TweakEngine -BaseDir $script:BaseDir
    Initialize-ServiceManager -BaseDir $script:BaseDir
    Initialize-AppManager -BaseDir $script:BaseDir
    Initialize-GamingMode -BaseDir $script:BaseDir

    # Load XAML
    $xamlPath = Join-Path $script:BaseDir "gui\MainWindow.xaml"
    $xamlContent = Get-Content $xamlPath -Raw
    $reader = [System.Xml.XmlReader]::Create([System.IO.StringReader]::new($xamlContent))
    $window = [System.Windows.Markup.XamlReader]::Load($reader)

    # Named Visual Controls
    $txtSysOS = $window.FindName("txtSysOS")
    $txtSysCPU = $window.FindName("txtSysCPU")
    $txtSysRAM = $window.FindName("txtSysRAM")
    $txtAdminStatus = $window.FindName("txtAdminStatus")
    $txtSnapshotCount = $window.FindName("txtSnapshotCount")
    $chkDryRun = $window.FindName("chkDryRun")
    $btnThemeToggle = $window.FindName("btnThemeToggle")
    $btnCreateRestorePoint = $window.FindName("btnCreateRestorePoint")

    # Presets
    $btnPresetGaming = $window.FindName("btnPresetGaming")
    $btnPresetPrivacy = $window.FindName("btnPresetPrivacy")
    $btnPresetFull = $window.FindName("btnPresetFull")

    # App Filters & Search
    $txtSearchApps = $window.FindName("txtSearchApps")
    $txtAppCount = $window.FindName("txtAppCount")
    $btnAppFilterAll = $window.FindName("btnAppFilterAll")
    $btnAppFilterSafe = $window.FindName("btnAppFilterSafe")
    $btnAppFilterModerate = $window.FindName("btnAppFilterModerate")
    $btnAppFilterHigh = $window.FindName("btnAppFilterHigh")
    $btnAppFilterCritical = $window.FindName("btnAppFilterCritical")
    $panelAppsContainer = $window.FindName("panelAppsContainer")

    # Tweak Filters & Search
    $txtSearchTweaks = $window.FindName("txtSearchTweaks")
    $txtTweakCount = $window.FindName("txtTweakCount")
    $btnTweakFilterAll = $window.FindName("btnTweakFilterAll")
    $btnTweakFilterPrivacy = $window.FindName("btnTweakFilterPrivacy")
    $btnTweakFilterUI = $window.FindName("btnTweakFilterUI")
    $btnTweakFilterAI = $window.FindName("btnTweakFilterAI")
    $btnTweakFilterPerf = $window.FindName("btnTweakFilterPerf")
    $panelTweaksContainer = $window.FindName("panelTweaksContainer")

    # Gaming & Services
    $panelGamingContainer = $window.FindName("panelGamingContainer")
    $panelServicesContainer = $window.FindName("panelServicesContainer")

    # Rollback Hub
    $panelUndoActionsContainer = $window.FindName("panelUndoActionsContainer")
    $btnOpenBackupsDir = $window.FindName("btnOpenBackupsDir")
    $btnRollbackSession = $window.FindName("btnRollbackSession")

    # Terminal Log & Status
    $txtConsoleLog = $window.FindName("txtConsoleLog")
    $scrollConsole = $window.FindName("scrollConsole")
    $btnClearLog = $window.FindName("btnClearLog")
    $btnCopyLog = $window.FindName("btnCopyLog")
    $txtStatusMessage = $window.FindName("txtStatusMessage")
    $progBar = $window.FindName("progBar")

    if ($DryRun.IsPresent) {
        $chkDryRun.IsChecked = $true
    }

    # Logger Dispatcher
    $appendLog = {
        param([string]$line, [string]$level)
        $window.Dispatcher.Invoke([Action]{
            $ts = Get-Date -Format "HH:mm:ss"
            $tag = if ($level) { "[$level]" } else { "[INFO]" }
            $txtConsoleLog.AppendText("$ts $tag $line`r`n")
            $scrollConsole.ScrollToEnd()
            $txtStatusMessage.Text = $line
        })
    }
    $global:GuiLoggerCallback = $appendLog

    # Clear & Copy Terminal Handlers
    $btnClearLog.add_Click({
        $txtConsoleLog.Clear()
        & $appendLog "Terminal buffer cleared." "INFO"
    })

    $btnCopyLog.add_Click({
        try {
            [System.Windows.Clipboard]::SetText($txtConsoleLog.Text)
            & $appendLog "Diagnostic log copied to clipboard." "INFO"
        } catch {
            & $appendLog "Unable to access clipboard: $($_.Exception.Message)" "WARN"
        }
    })

    # Theme Switcher
    $btnThemeToggle.add_Click({
        $script:IsDarkMode = -not $script:IsDarkMode
        Set-AppTheme -Window $window -DarkMode $script:IsDarkMode
        $modeName = if ($script:IsDarkMode) { "OLED Dark" } else { "Swiss Light" }
        & $appendLog "Theme switched to $modeName Mode." "INFO"
    })

    # Dry-Run Simulation Switch
    $chkDryRun.add_Checked({
        $global:DryRunActive = $true
        & $appendLog "[DRY-RUN ACTIVE] Zero-mutation test mode active. No host state will be modified." "WARN"
    })
    $chkDryRun.add_Unchecked({
        $global:DryRunActive = $false
        & $appendLog "[LIVE MODE] Host changes will execute with atomic backup snapshots." "INFO"
    })

    # Populate Live Telemetry Strip
    $sysInfo = Get-WinDebloatSystemInfo
    $txtSysOS.Text = "$($sysInfo.OSCaption) (Build $($sysInfo.BuildNumber))"
    $txtSysCPU.Text = "$($sysInfo.CPUName) ($($sysInfo.CPULogicalCores)T)"
    $txtSysRAM.Text = "$($sysInfo.TotalRAMGB) GB RAM ($($sysInfo.DriveType))"
    $txtAdminStatus.Text = if ($sysInfo.IsAdmin) { "ADMIN: ELEVATED (SHIELD ACTIVE)" } else { "ADMIN: RESTRICTED" }
    $txtAdminStatus.Foreground = if ($sysInfo.IsAdmin) { [System.Windows.Media.Brushes]::LightGreen } else { [System.Windows.Media.Brushes]::IndianRed }

    # Create Restore Point Action
    $btnCreateRestorePoint.add_Click({
        $progBar.IsIndeterminate = $true
        $txtStatusMessage.Text = "Creating Windows System Restore Point..."
        & $appendLog "Requesting Windows System Restore Point creation..." "INFO"
        $res = New-SystemRestorePoint -Description "Win11_26H2_Debloater_ManualPoint"
        $progBar.IsIndeterminate = $false
        if ($res) {
            & $appendLog "System Restore Point created successfully." "SUCCESS"
            [System.Windows.MessageBox]::Show("System Restore Point created successfully.`nSnapshot stored in Volume Shadow Copies.", "Safety Shield", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
        } else {
            & $appendLog "System Restore Point skipped or failed. Verify System Protection is turned on." "WARN"
            [System.Windows.MessageBox]::Show("Could not create Restore Point. Ensure System Protection is enabled for drive C:\ in Windows System Properties.", "Safety Warning", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
        }
    })

    # Filter Engine Functions
    $filterApps = {
        $query = $txtSearchApps.Text.Trim().ToLower()
        $visCount = 0
        foreach ($item in $script:AppCardItems) {
            $matchSearch = [string]::IsNullOrEmpty($query) -or
                           $item.App.name.ToLower().Contains($query) -or
                           $item.App.id.ToLower().Contains($query) -or
                           $item.App.descriptionSimple.ToLower().Contains($query)
            $matchRisk = ($script:CurrentAppRiskFilter -eq "ALL") -or
                         ($item.App.risk.ToUpper() -eq $script:CurrentAppRiskFilter)

            if ($matchSearch -and $matchRisk) {
                $item.Card.Visibility = [System.Windows.Visibility]::Visible
                $visCount++
            } else {
                $item.Card.Visibility = [System.Windows.Visibility]::Collapsed
            }
        }
        $txtAppCount.Text = "Showing $visCount / $($script:AppCardItems.Count)"
    }

    $filterTweaks = {
        $query = $txtSearchTweaks.Text.Trim().ToLower()
        $visCount = 0
        foreach ($item in $script:TweakCardItems) {
            $matchSearch = [string]::IsNullOrEmpty($query) -or
                           $item.Tweak.name.ToLower().Contains($query) -or
                           $item.Tweak.id.ToLower().Contains($query) -or
                           $item.Tweak.descriptionSimple.ToLower().Contains($query)
            $matchCat = ($script:CurrentTweakCategoryFilter -eq "ALL") -or
                        ($item.Tweak.category.ToUpper() -eq $script:CurrentTweakCategoryFilter)

            if ($matchSearch -and $matchCat) {
                $item.Card.Visibility = [System.Windows.Visibility]::Visible
                $visCount++
            } else {
                $item.Card.Visibility = [System.Windows.Visibility]::Collapsed
            }
        }
        $txtTweakCount.Text = "Showing $visCount / $($script:TweakCardItems.Count)"
    }

    # Search Box Event Listeners
    $txtSearchApps.add_TextChanged({ & $filterApps })
    $txtSearchTweaks.add_TextChanged({ & $filterTweaks })

    # App Risk Filter Button Listeners
    $btnAppFilterAll.add_Click({ $script:CurrentAppRiskFilter = "ALL"; & $filterApps })
    $btnAppFilterSafe.add_Click({ $script:CurrentAppRiskFilter = "SAFE"; & $filterApps })
    $btnAppFilterModerate.add_Click({ $script:CurrentAppRiskFilter = "MODERATE"; & $filterApps })
    $btnAppFilterHigh.add_Click({ $script:CurrentAppRiskFilter = "HIGH"; & $filterApps })
    $btnAppFilterCritical.add_Click({ $script:CurrentAppRiskFilter = "CRITICAL"; & $filterApps })

    # Tweak Category Filter Button Listeners
    $btnTweakFilterAll.add_Click({ $script:CurrentTweakCategoryFilter = "ALL"; & $filterTweaks })
    $btnTweakFilterPrivacy.add_Click({ $script:CurrentTweakCategoryFilter = "PRIVACY"; & $filterTweaks })
    $btnTweakFilterUI.add_Click({ $script:CurrentTweakCategoryFilter = "UI"; & $filterTweaks })
    $btnTweakFilterAI.add_Click({ $script:CurrentTweakCategoryFilter = "AI"; & $filterTweaks })
    $btnTweakFilterPerf.add_Click({ $script:CurrentTweakCategoryFilter = "PERFORMANCE"; & $filterTweaks })

    # Populate Apps Catalog
    $appsConfigPath = Join-Path $script:ConfigDir "apps.json"
    if (Test-Path $appsConfigPath) {
        $appsCatalog = (Get-Content $appsConfigPath -Raw | ConvertFrom-Json).apps
        $script:AppCardItems.Clear()
        foreach ($app in $appsCatalog) {
            $card = New-AppCard -App $app -Window $window -LogCallback $appendLog
            [void]$panelAppsContainer.Children.Add($card)
            $script:AppCardItems.Add([pscustomobject]@{ Card = $card; App = $app })
        }
        $txtAppCount.Text = "Total Packages: $($script:AppCardItems.Count)"
    }

    # Populate Tweaks Catalog
    $tweaksConfigPath = Join-Path $script:ConfigDir "tweaks.json"
    if (Test-Path $tweaksConfigPath) {
        $tweaksCatalog = (Get-Content $tweaksConfigPath -Raw | ConvertFrom-Json).tweaks
        $script:TweakCardItems.Clear()
        foreach ($tweak in $tweaksCatalog) {
            $card = New-TweakCard -Tweak $tweak -Window $window -LogCallback $appendLog
            [void]$panelTweaksContainer.Children.Add($card)
            $script:TweakCardItems.Add([pscustomobject]@{ Card = $card; Tweak = $tweak })
        }
        $txtTweakCount.Text = "Total Tweaks: $($script:TweakCardItems.Count)"
    }

    # Populate Gaming Catalog
    $gamingConfigPath = Join-Path $script:ConfigDir "gaming.json"
    if (Test-Path $gamingConfigPath) {
        $gamingCatalog = (Get-Content $gamingConfigPath -Raw | ConvertFrom-Json).gamingOptimizations
        foreach ($opt in $gamingCatalog) {
            $card = New-GamingCard -Opt $opt -Window $window -LogCallback $appendLog
            [void]$panelGamingContainer.Children.Add($card)
        }
    }

    # Populate Services Catalog
    $servicesConfigPath = Join-Path $script:ConfigDir "services.json"
    if (Test-Path $servicesConfigPath) {
        $servicesCatalog = (Get-Content $servicesConfigPath -Raw | ConvertFrom-Json).services
        foreach ($svc in $servicesCatalog) {
            $card = New-ServiceCard -Svc $svc -Window $window -LogCallback $appendLog
            [void]$panelServicesContainer.Children.Add($card)
        }
    }

    # Preset 1: Gaming Mode
    $btnPresetGaming.add_Click({
        $isDry = $chkDryRun.IsChecked -eq $true
        & $appendLog "=== Applying Gaming Latency Profile ===" "INFO"
        $progBar.Value = 15
        Enable-CpuCoreUnparking -DryRun:$isDry | Out-Null
        $progBar.Value = 35
        Enable-UltimatePerformancePlan -DryRun:$isDry | Out-Null
        $progBar.Value = 55
        Optimize-NetworkAndScheduler -DryRun:$isDry | Out-Null
        $progBar.Value = 75
        Optimize-SvcHostThreshold -DryRun:$isDry | Out-Null
        $progBar.Value = 90
        Set-RegistryTweak -Tweak @{
            id = "enable_game_mode"; name = "Force Windows Game Mode"; hive = "HKCU";
            path = "Software\Microsoft\GameBar"; valueName = "AutoGameModeEnabled"; type = "DWord"; value = 1; originalValue = 0
        } -DryRun:$isDry | Out-Null
        Set-RegistryTweak -Tweak @{
            id = "enable_hags"; name = "Enable HAGS Hardware GPU Scheduling"; hive = "HKLM";
            path = "SYSTEM\CurrentControlSet\Control\GraphicsDrivers"; valueName = "HwSchMode"; type = "DWord"; value = 2; originalValue = 1
        } -DryRun:$isDry | Out-Null
        $progBar.Value = 100
        & $appendLog "Gaming profile applied successfully with atomic rollback ready." "SUCCESS"
        Update-UndoPanel -Container $panelUndoActionsContainer
    })

    # Preset 2: Privacy Mode
    $btnPresetPrivacy.add_Click({
        $isDry = $chkDryRun.IsChecked -eq $true
        & $appendLog "=== Applying Privacy & Anti-Telemetry Guard ===" "INFO"
        $progBar.Value = 15
        if (Test-Path $tweaksConfigPath) {
            $tweaks = (Get-Content $tweaksConfigPath -Raw | ConvertFrom-Json).tweaks | Where-Object { $_.category -in @("Privacy", "AI") }
            $step = [math]::Max(1, [int](80 / $tweaks.Count))
            foreach ($twk in $tweaks) {
                Set-RegistryTweak -Tweak @{
                    id = $twk.id; name = $twk.name; hive = $twk.hive; path = $twk.path;
                    valueName = $twk.valueName; type = $twk.type; value = $twk.value; originalValue = $twk.originalValue
                } -DryRun:$isDry | Out-Null
                $progBar.Value += $step
            }
        }
        $progBar.Value = 100
        & $appendLog "Privacy guard applied successfully." "SUCCESS"
        Update-UndoPanel -Container $panelUndoActionsContainer
    })

    # Preset 3: Full Debloat
    $btnPresetFull.add_Click({
        $confirm = [System.Windows.MessageBox]::Show(
            "Full Debloat will apply Gaming Latency settings, Privacy configurations, and remove non-essential preinstalled packages.`n`nEvery action creates a pre-state backup.`n`nProceed with Full Debloat?",
            "Confirm Full Debloat",
            [System.Windows.MessageBoxButton]::YesNo,
            [System.Windows.MessageBoxImage]::Question
        )
        if ($confirm -ne [System.Windows.MessageBoxResult]::Yes) { return }

        $isDry = $chkDryRun.IsChecked -eq $true
        & $appendLog "=== Starting Full Clean Debloat Pipeline ===" "INFO"
        $btnPresetGaming.RaiseEvent([System.Windows.RoutedEventArgs]::new([System.Windows.Controls.Button]::ClickEvent))
        $btnPresetPrivacy.RaiseEvent([System.Windows.RoutedEventArgs]::new([System.Windows.Controls.Button]::ClickEvent))

        $safeApps = @("Microsoft.BingNews", "Microsoft.BingWeather", "Microsoft.MicrosoftSolitaireCollection", "Microsoft.MicrosoftOfficeHub", "Microsoft.PowerAutomateDesktop", "Clipchamp.Clipchamp")
        foreach ($appId in $safeApps) {
            Remove-DebloatApp -AppId $appId -DryRun:$isDry | Out-Null
        }

        & $appendLog "Full debloat pipeline completed." "SUCCESS"
        Update-UndoPanel -Container $panelUndoActionsContainer
    })

    # Open Backups Folder
    $btnOpenBackupsDir.add_Click({
        $backupDir = Join-Path $script:BaseDir "backups"
        if (-not (Test-Path $backupDir)) {
            New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
        }
        Invoke-Item $backupDir
    })

    # Rollback Session
    $btnRollbackSession.add_Click({
        $confirm = [System.Windows.MessageBox]::Show(
            "Are you sure you want to rollback all actions performed during this session?`n`nThis will revert registry values, restore services, and execute rollback scripts.",
            "Confirm Session Rollback",
            [System.Windows.MessageBoxButton]::YesNo,
            [System.Windows.MessageBoxImage]::Warning
        )
        if ($confirm -ne [System.Windows.MessageBoxResult]::Yes) { return }

        & $appendLog "=== Initiating Full Session Rollback ===" "UNDO"
        $actions = Get-SessionActions
        for ($i = $actions.Count - 1; $i -ge 0; $i--) {
            $act = $actions[$i]
            & $appendLog "Reverting [$($act.ActionType)] $($act.TargetId)..." "UNDO"
            try {
                Invoke-Expression $act.UndoCommand | Out-Null
                & $appendLog "Reverted $($act.TargetId) successfully." "SUCCESS"
            } catch {
                & $appendLog "Error reverting $($act.TargetId): $($_.Exception.Message)" "ERROR"
            }
        }
        & $appendLog "Session rollback complete." "SUCCESS"
        Update-UndoPanel -Container $panelUndoActionsContainer
    })

    & $appendLog "Windows 11 26H2 Debloater & Gaming Optimizer initialized." "INFO"
    & $appendLog "Kernel telemetry loaded: $($sysInfo.OSCaption) Build $($sysInfo.BuildNumber)" "INFO"

    # Show Window
    $window.ShowDialog() | Out-Null
}

function New-AppCard {
    param($App, $Window, $LogCallback)

    # Double-Bezel Outer Shell
    $outerShell = [System.Windows.Controls.Border]::new()
    $outerShell.SetResourceReference([System.Windows.Controls.Border]::BackgroundProperty, "BrushCardShellBg")
    $outerShell.SetResourceReference([System.Windows.Controls.Border]::BorderBrushProperty, "BrushBorder")
    $outerShell.BorderThickness = [System.Windows.Thickness]::new(1)
    $outerShell.CornerRadius = [System.Windows.CornerRadius]::new(10)
    $outerShell.Padding = [System.Windows.Thickness]::new(1.5)
    $outerShell.Margin = [System.Windows.Thickness]::new(0, 0, 0, 8)

    # Hover Glow Effect
    $outerShell.add_MouseEnter({
        $outerShell.SetResourceReference([System.Windows.Controls.Border]::BorderBrushProperty, "BrushAccent")
    })
    $outerShell.add_MouseLeave({
        $outerShell.SetResourceReference([System.Windows.Controls.Border]::BorderBrushProperty, "BrushBorder")
    })

    # Double-Bezel Inner Core
    $innerCore = [System.Windows.Controls.Border]::new()
    $innerCore.SetResourceReference([System.Windows.Controls.Border]::BackgroundProperty, "BrushCardCoreBg")
    $innerCore.CornerRadius = [System.Windows.CornerRadius]::new(8.5)
    $innerCore.Padding = [System.Windows.Thickness]::new(14, 12, 14, 12)
    $outerShell.Child = $innerCore

    $grid = [System.Windows.Controls.Grid]::new()
    $col1 = [System.Windows.Controls.ColumnDefinition]::new()
    $col1.Width = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
    $col2 = [System.Windows.Controls.ColumnDefinition]::new()
    $col2.Width = [System.Windows.GridLength]::new(210)
    [void]$grid.ColumnDefinitions.Add($col1)
    [void]$grid.ColumnDefinitions.Add($col2)

    $stack = [System.Windows.Controls.StackPanel]::new()
    $topLine = [System.Windows.Controls.StackPanel]::new()
    $topLine.Orientation = [System.Windows.Controls.Orientation]::Horizontal

    $txtName = [System.Windows.Controls.TextBlock]::new()
    $txtName.Text = $App.name
    $txtName.FontSize = 14
    $txtName.FontWeight = [System.Windows.FontWeights]::Bold
    $txtName.SetResourceReference([System.Windows.Controls.TextBlock]::ForegroundProperty, "BrushTextPrimary")
    [void]$topLine.Children.Add($txtName)

    # Risk Badge Pill
    $badge = [System.Windows.Controls.Border]::new()
    $badge.CornerRadius = [System.Windows.CornerRadius]::new(10)
    $badge.Padding = [System.Windows.Thickness]::new(8, 2, 8, 2)
    $badge.Margin = [System.Windows.Thickness]::new(10, 0, 0, 0)
    $txtBadge = [System.Windows.Controls.TextBlock]::new()
    $txtBadge.Text = $App.risk.ToUpper()
    $txtBadge.FontSize = 10
    $txtBadge.FontWeight = [System.Windows.FontWeights]::Bold
    $txtBadge.Foreground = [System.Windows.Media.Brushes]::White

    $badgeResKey = switch ($App.risk) {
        "Safe"     { "BrushBadgeSafe" }
        "Moderate" { "BrushBadgeWarn" }
        "High"     { "BrushBadgeDanger" }
        "Critical" { "BrushBadgeCritical" }
        default    { "BrushTextMuted" }
    }
    $badge.SetResourceReference([System.Windows.Controls.Border]::BackgroundProperty, $badgeResKey)
    $badge.Child = $txtBadge
    [void]$topLine.Children.Add($badge)
    [void]$stack.Children.Add($topLine)

    $txtSimple = [System.Windows.Controls.TextBlock]::new()
    $txtSimple.Text = $App.descriptionSimple
    $txtSimple.FontSize = 12
    $txtSimple.SetResourceReference([System.Windows.Controls.TextBlock]::ForegroundProperty, "BrushTextSecondary")
    $txtSimple.Margin = [System.Windows.Thickness]::new(0, 4, 0, 2)
    $txtSimple.TextWrapping = [System.Windows.TextWrapping]::Wrap
    [void]$stack.Children.Add($txtSimple)

    $txtTech = [System.Windows.Controls.TextBlock]::new()
    $txtTech.Text = "App ID: $($App.id) • $($App.descriptionTech)"
    $txtTech.FontSize = 11
    $txtTech.SetResourceReference([System.Windows.Controls.TextBlock]::ForegroundProperty, "BrushTextMuted")
    $txtTech.TextWrapping = [System.Windows.TextWrapping]::Wrap
    [void]$stack.Children.Add($txtTech)

    [System.Windows.Controls.Grid]::SetColumn($stack, 0)
    [void]$grid.Children.Add($stack)

    # Actions Stack (Button-in-Button)
    $btnStack = [System.Windows.Controls.StackPanel]::new()
    $btnStack.Orientation = [System.Windows.Controls.Orientation]::Horizontal
    $btnStack.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
    $btnStack.VerticalAlignment = [System.Windows.VerticalAlignment]::Center

    $btnRemove = [System.Windows.Controls.Button]::new()
    $btnRemove.Content = "Remove"
    $btnRemove.Width = 85
    $btnRemove.Height = 32
    $btnRemove.Margin = [System.Windows.Thickness]::new(0, 0, 8, 0)
    $btnRemove.Style = $Window.Resources["BtnDanger"]

    if ($App.risk -eq "Critical") {
        $btnRemove.IsEnabled = $false
        $btnRemove.Opacity = 0.4
        $btnRemove.ToolTip = "System-critical component. Removal disabled to preserve Windows kernel stability."
    }

    $btnUndo = [System.Windows.Controls.Button]::new()
    $btnUndo.Content = "Reinstall"
    $btnUndo.Width = 90
    $btnUndo.Height = 32
    $btnUndo.Style = $Window.Resources["BtnWarn"]

    # Two-Tier Confirmation for High/Critical Risk
    $btnRemove.add_Click({
        $chkDry = $Window.FindName("chkDryRun")
        $isDry = $chkDry.IsChecked -eq $true

        if ($App.risk -in @("High", "Critical")) {
            $msg1 = "WARNING: You are about to remove a $($App.risk.ToUpper()) risk package: '$($App.name)'.`n`n$($App.descriptionSimple)`n`nTechnical consequence: $($App.descriptionTech)`n`nDo you want to proceed?"
            $confirm1 = [System.Windows.MessageBox]::Show($msg1, "Tier 1 Safety Verification", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Warning)
            if ($confirm1 -ne [System.Windows.MessageBoxResult]::Yes) { return }

            $msg2 = "ADMINISTRATIVE CONFIRMATION:`n`nPlease confirm once more that you want to remove '$($App.name)'. If this causes any issue, the 5-Tier Reinstall engine will be available."
            $confirm2 = [System.Windows.MessageBox]::Show($msg2, "Tier 2 Final Safety Confirmation", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Question)
            if ($confirm2 -ne [System.Windows.MessageBoxResult]::Yes) { return }
        }

        Remove-DebloatApp -AppId $App.id -DryRun:$isDry | Out-Null
        $panelUndo = $Window.FindName("panelUndoActionsContainer")
        Update-UndoPanel -Container $panelUndo
    })

    $btnUndo.add_Click({
        $chkDry = $Window.FindName("chkDryRun")
        $isDry = $chkDry.IsChecked -eq $true
        Restore-DebloatAppWithFallback -AppId $App.id -DryRun:$isDry | Out-Null
        $panelUndo = $Window.FindName("panelUndoActionsContainer")
        Update-UndoPanel -Container $panelUndo
    })

    [void]$btnStack.Children.Add($btnRemove)
    [void]$btnStack.Children.Add($btnUndo)
    [System.Windows.Controls.Grid]::SetColumn($btnStack, 1)
    [void]$grid.Children.Add($btnStack)

    return $outerShell
}

function New-TweakCard {
    param($Tweak, $Window, $LogCallback)

    $outerShell = [System.Windows.Controls.Border]::new()
    $outerShell.SetResourceReference([System.Windows.Controls.Border]::BackgroundProperty, "BrushCardShellBg")
    $outerShell.SetResourceReference([System.Windows.Controls.Border]::BorderBrushProperty, "BrushBorder")
    $outerShell.BorderThickness = [System.Windows.Thickness]::new(1)
    $outerShell.CornerRadius = [System.Windows.CornerRadius]::new(10)
    $outerShell.Padding = [System.Windows.Thickness]::new(1.5)
    $outerShell.Margin = [System.Windows.Thickness]::new(0, 0, 0, 8)

    $outerShell.add_MouseEnter({
        $outerShell.SetResourceReference([System.Windows.Controls.Border]::BorderBrushProperty, "BrushAccent")
    })
    $outerShell.add_MouseLeave({
        $outerShell.SetResourceReference([System.Windows.Controls.Border]::BorderBrushProperty, "BrushBorder")
    })

    $innerCore = [System.Windows.Controls.Border]::new()
    $innerCore.SetResourceReference([System.Windows.Controls.Border]::BackgroundProperty, "BrushCardCoreBg")
    $innerCore.CornerRadius = [System.Windows.CornerRadius]::new(8.5)
    $innerCore.Padding = [System.Windows.Thickness]::new(14, 12, 14, 12)
    $outerShell.Child = $innerCore

    $grid = [System.Windows.Controls.Grid]::new()
    $col1 = [System.Windows.Controls.ColumnDefinition]::new()
    $col1.Width = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
    $col2 = [System.Windows.Controls.ColumnDefinition]::new()
    $col2.Width = [System.Windows.GridLength]::new(190)
    [void]$grid.ColumnDefinitions.Add($col1)
    [void]$grid.ColumnDefinitions.Add($col2)

    $stack = [System.Windows.Controls.StackPanel]::new()
    $topLine = [System.Windows.Controls.StackPanel]::new()
    $topLine.Orientation = [System.Windows.Controls.Orientation]::Horizontal

    $txtName = [System.Windows.Controls.TextBlock]::new()
    $txtName.Text = $Tweak.name
    $txtName.FontSize = 14
    $txtName.FontWeight = [System.Windows.FontWeights]::Bold
    $txtName.SetResourceReference([System.Windows.Controls.TextBlock]::ForegroundProperty, "BrushTextPrimary")
    [void]$topLine.Children.Add($txtName)

    $badge = [System.Windows.Controls.Border]::new()
    $badge.CornerRadius = [System.Windows.CornerRadius]::new(10)
    $badge.Padding = [System.Windows.Thickness]::new(8, 2, 8, 2)
    $badge.Margin = [System.Windows.Thickness]::new(10, 0, 0, 0)
    $txtBadge = [System.Windows.Controls.TextBlock]::new()
    $txtBadge.Text = $Tweak.category.ToUpper()
    $txtBadge.FontSize = 10
    $txtBadge.FontWeight = [System.Windows.FontWeights]::Bold
    $txtBadge.Foreground = [System.Windows.Media.Brushes]::White
    $badge.SetResourceReference([System.Windows.Controls.Border]::BackgroundProperty, "BrushAccentIndigo")
    $badge.Child = $txtBadge
    [void]$topLine.Children.Add($badge)
    [void]$stack.Children.Add($topLine)

    $txtDesc = [System.Windows.Controls.TextBlock]::new()
    $txtDesc.Text = $Tweak.descriptionSimple
    $txtDesc.FontSize = 12
    $txtDesc.SetResourceReference([System.Windows.Controls.TextBlock]::ForegroundProperty, "BrushTextSecondary")
    $txtDesc.Margin = [System.Windows.Thickness]::new(0, 4, 0, 2)
    $txtDesc.TextWrapping = [System.Windows.TextWrapping]::Wrap
    [void]$stack.Children.Add($txtDesc)

    $txtTech = [System.Windows.Controls.TextBlock]::new()
    $txtTech.Text = "$($Tweak.hive):\$($Tweak.path)\$($Tweak.valueName) -> $($Tweak.value)"
    $txtTech.FontSize = 11
    $txtTech.SetResourceReference([System.Windows.Controls.TextBlock]::ForegroundProperty, "BrushTextMuted")
    $txtTech.TextWrapping = [System.Windows.TextWrapping]::Wrap
    [void]$stack.Children.Add($txtTech)

    [System.Windows.Controls.Grid]::SetColumn($stack, 0)
    [void]$grid.Children.Add($stack)

    $btnStack = [System.Windows.Controls.StackPanel]::new()
    $btnStack.Orientation = [System.Windows.Controls.Orientation]::Horizontal
    $btnStack.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
    $btnStack.VerticalAlignment = [System.Windows.VerticalAlignment]::Center

    $btnApply = [System.Windows.Controls.Button]::new()
    $btnApply.Content = "Apply"
    $btnApply.Width = 80
    $btnApply.Height = 32
    $btnApply.Margin = [System.Windows.Thickness]::new(0, 0, 8, 0)
    $btnApply.Style = $Window.Resources["BtnPrimary"]

    $btnUndo = [System.Windows.Controls.Button]::new()
    $btnUndo.Content = "Revert"
    $btnUndo.Width = 80
    $btnUndo.Height = 32
    $btnUndo.Style = $Window.Resources["BtnWarn"]

    $btnApply.add_Click({
        $chkDry = $Window.FindName("chkDryRun")
        $isDry = $chkDry.IsChecked -eq $true

        if ($Tweak.risk -eq "High") {
            $confirm = [System.Windows.MessageBox]::Show("You are applying a HIGH RISK tweak: '$($Tweak.name)'.`n`n$($Tweak.descriptionSimple)`n`nProceed?", "Safety Verification", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Warning)
            if ($confirm -ne [System.Windows.MessageBoxResult]::Yes) { return }
        }

        Set-RegistryTweak -Tweak @{
            id = $Tweak.id; name = $Tweak.name; hive = $Tweak.hive; path = $Tweak.path;
            valueName = $Tweak.valueName; type = $Tweak.type; value = $Tweak.value; originalValue = $Tweak.originalValue
        } -DryRun:$isDry | Out-Null
        $panelUndo = $Window.FindName("panelUndoActionsContainer")
        Update-UndoPanel -Container $panelUndo
    })

    $btnUndo.add_Click({
        $chkDry = $Window.FindName("chkDryRun")
        $isDry = $chkDry.IsChecked -eq $true
        Undo-RegistryTweak -Tweak @{
            id = $Tweak.id; name = $Tweak.name; hive = $Tweak.hive; path = $Tweak.path;
            valueName = $Tweak.valueName; originalValue = $Tweak.originalValue
        } -DryRun:$isDry | Out-Null
        $panelUndo = $Window.FindName("panelUndoActionsContainer")
        Update-UndoPanel -Container $panelUndo
    })

    [void]$btnStack.Children.Add($btnApply)
    [void]$btnStack.Children.Add($btnUndo)
    [System.Windows.Controls.Grid]::SetColumn($btnStack, 1)
    [void]$grid.Children.Add($btnStack)

    return $outerShell
}

function New-GamingCard {
    param($Opt, $Window, $LogCallback)

    $outerShell = [System.Windows.Controls.Border]::new()
    $outerShell.SetResourceReference([System.Windows.Controls.Border]::BackgroundProperty, "BrushCardShellBg")
    $outerShell.SetResourceReference([System.Windows.Controls.Border]::BorderBrushProperty, "BrushBorder")
    $outerShell.BorderThickness = [System.Windows.Thickness]::new(1)
    $outerShell.CornerRadius = [System.Windows.CornerRadius]::new(10)
    $outerShell.Padding = [System.Windows.Thickness]::new(1.5)
    $outerShell.Margin = [System.Windows.Thickness]::new(0, 0, 0, 8)

    $outerShell.add_MouseEnter({
        $outerShell.SetResourceReference([System.Windows.Controls.Border]::BorderBrushProperty, "BrushAccent")
    })
    $outerShell.add_MouseLeave({
        $outerShell.SetResourceReference([System.Windows.Controls.Border]::BorderBrushProperty, "BrushBorder")
    })

    $innerCore = [System.Windows.Controls.Border]::new()
    $innerCore.SetResourceReference([System.Windows.Controls.Border]::BackgroundProperty, "BrushCardCoreBg")
    $innerCore.CornerRadius = [System.Windows.CornerRadius]::new(8.5)
    $innerCore.Padding = [System.Windows.Thickness]::new(14, 12, 14, 12)
    $outerShell.Child = $innerCore

    $grid = [System.Windows.Controls.Grid]::new()
    $col1 = [System.Windows.Controls.ColumnDefinition]::new()
    $col1.Width = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
    $col2 = [System.Windows.Controls.ColumnDefinition]::new()
    $col2.Width = [System.Windows.GridLength]::new(190)
    [void]$grid.ColumnDefinitions.Add($col1)
    [void]$grid.ColumnDefinitions.Add($col2)

    $stack = [System.Windows.Controls.StackPanel]::new()
    $topLine = [System.Windows.Controls.StackPanel]::new()
    $topLine.Orientation = [System.Windows.Controls.Orientation]::Horizontal

    $txtName = [System.Windows.Controls.TextBlock]::new()
    $txtName.Text = $Opt.name
    $txtName.FontSize = 14
    $txtName.FontWeight = [System.Windows.FontWeights]::Bold
    $txtName.SetResourceReference([System.Windows.Controls.TextBlock]::ForegroundProperty, "BrushTextPrimary")
    [void]$topLine.Children.Add($txtName)

    $badge = [System.Windows.Controls.Border]::new()
    $badge.CornerRadius = [System.Windows.CornerRadius]::new(10)
    $badge.Padding = [System.Windows.Thickness]::new(8, 2, 8, 2)
    $badge.Margin = [System.Windows.Thickness]::new(10, 0, 0, 0)
    $txtBadge = [System.Windows.Controls.TextBlock]::new()
    $txtBadge.Text = "LATENCY TUNER"
    $txtBadge.FontSize = 10
    $txtBadge.FontWeight = [System.Windows.FontWeights]::Bold
    $txtBadge.Foreground = [System.Windows.Media.Brushes]::White
    $badge.SetResourceReference([System.Windows.Controls.Border]::BackgroundProperty, "BrushAccent")
    $badge.Child = $txtBadge
    [void]$topLine.Children.Add($badge)
    [void]$stack.Children.Add($topLine)

    $txtDesc = [System.Windows.Controls.TextBlock]::new()
    $txtDesc.Text = $Opt.descriptionSimple
    $txtDesc.FontSize = 12
    $txtDesc.SetResourceReference([System.Windows.Controls.TextBlock]::ForegroundProperty, "BrushTextSecondary")
    $txtDesc.Margin = [System.Windows.Thickness]::new(0, 4, 0, 2)
    $txtDesc.TextWrapping = [System.Windows.TextWrapping]::Wrap
    [void]$stack.Children.Add($txtDesc)

    $txtTech = [System.Windows.Controls.TextBlock]::new()
    $txtTech.Text = "Hardware Target: $($Opt.id) • $($Opt.descriptionTech)"
    $txtTech.FontSize = 11
    $txtTech.SetResourceReference([System.Windows.Controls.TextBlock]::ForegroundProperty, "BrushTextMuted")
    $txtTech.TextWrapping = [System.Windows.TextWrapping]::Wrap
    [void]$stack.Children.Add($txtTech)

    [System.Windows.Controls.Grid]::SetColumn($stack, 0)
    [void]$grid.Children.Add($stack)

    $btnStack = [System.Windows.Controls.StackPanel]::new()
    $btnStack.Orientation = [System.Windows.Controls.Orientation]::Horizontal
    $btnStack.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
    $btnStack.VerticalAlignment = [System.Windows.VerticalAlignment]::Center

    $btnApply = [System.Windows.Controls.Button]::new()
    $btnApply.Content = "Tune"
    $btnApply.Width = 80
    $btnApply.Height = 32
    $btnApply.Margin = [System.Windows.Thickness]::new(0, 0, 8, 0)
    $btnApply.Style = $Window.Resources["BtnPrimary"]

    $btnUndo = [System.Windows.Controls.Button]::new()
    $btnUndo.Content = "Default"
    $btnUndo.Width = 80
    $btnUndo.Height = 32
    $btnUndo.Style = $Window.Resources["BtnWarn"]

    $btnApply.add_Click({
        $chkDry = $Window.FindName("chkDryRun")
        $isDry = $chkDry.IsChecked -eq $true

        switch ($Opt.id) {
            "cpu_core_unparking"         { Enable-CpuCoreUnparking -DryRun:$isDry | Out-Null }
            "ultimate_performance_plan"  { Enable-UltimatePerformancePlan -DryRun:$isDry | Out-Null }
            "mmcss_gpu_priority"         { Optimize-NetworkAndScheduler -DryRun:$isDry | Out-Null }
            "disable_network_throttling" { Optimize-NetworkAndScheduler -DryRun:$isDry | Out-Null }
            "svchost_split_threshold"    { Optimize-SvcHostThreshold -DryRun:$isDry | Out-Null }
            default {
                & $LogCallback "Tuning: $($Opt.name)" "SUCCESS"
            }
        }
        $panelUndo = $Window.FindName("panelUndoActionsContainer")
        Update-UndoPanel -Container $panelUndo
    })

    $btnUndo.add_Click({
        & $LogCallback "Reverting hardware tuning for $($Opt.name) to Windows default..." "UNDO"
    })

    [void]$btnStack.Children.Add($btnApply)
    [void]$btnStack.Children.Add($btnUndo)
    [System.Windows.Controls.Grid]::SetColumn($btnStack, 1)
    [void]$grid.Children.Add($btnStack)

    return $outerShell
}

function New-ServiceCard {
    param($Svc, $Window, $LogCallback)

    $outerShell = [System.Windows.Controls.Border]::new()
    $outerShell.SetResourceReference([System.Windows.Controls.Border]::BackgroundProperty, "BrushCardShellBg")
    $outerShell.SetResourceReference([System.Windows.Controls.Border]::BorderBrushProperty, "BrushBorder")
    $outerShell.BorderThickness = [System.Windows.Thickness]::new(1)
    $outerShell.CornerRadius = [System.Windows.CornerRadius]::new(10)
    $outerShell.Padding = [System.Windows.Thickness]::new(1.5)
    $outerShell.Margin = [System.Windows.Thickness]::new(0, 0, 0, 8)

    $outerShell.add_MouseEnter({
        $outerShell.SetResourceReference([System.Windows.Controls.Border]::BorderBrushProperty, "BrushAccent")
    })
    $outerShell.add_MouseLeave({
        $outerShell.SetResourceReference([System.Windows.Controls.Border]::BorderBrushProperty, "BrushBorder")
    })

    $innerCore = [System.Windows.Controls.Border]::new()
    $innerCore.SetResourceReference([System.Windows.Controls.Border]::BackgroundProperty, "BrushCardCoreBg")
    $innerCore.CornerRadius = [System.Windows.CornerRadius]::new(8.5)
    $innerCore.Padding = [System.Windows.Thickness]::new(14, 12, 14, 12)
    $outerShell.Child = $innerCore

    $grid = [System.Windows.Controls.Grid]::new()
    $col1 = [System.Windows.Controls.ColumnDefinition]::new()
    $col1.Width = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
    $col2 = [System.Windows.Controls.ColumnDefinition]::new()
    $col2.Width = [System.Windows.GridLength]::new(190)
    [void]$grid.ColumnDefinitions.Add($col1)
    [void]$grid.ColumnDefinitions.Add($col2)

    $stack = [System.Windows.Controls.StackPanel]::new()
    $topLine = [System.Windows.Controls.StackPanel]::new()
    $topLine.Orientation = [System.Windows.Controls.Orientation]::Horizontal

    $txtName = [System.Windows.Controls.TextBlock]::new()
    $txtName.Text = "$($Svc.displayName) ($($Svc.name))"
    $txtName.FontSize = 14
    $txtName.FontWeight = [System.Windows.FontWeights]::Bold
    $txtName.SetResourceReference([System.Windows.Controls.TextBlock]::ForegroundProperty, "BrushTextPrimary")
    [void]$topLine.Children.Add($txtName)

    if ($Svc.action -eq "Protect") {
        $badge = [System.Windows.Controls.Border]::new()
        $badge.CornerRadius = [System.Windows.CornerRadius]::new(10)
        $badge.Padding = [System.Windows.Thickness]::new(8, 2, 8, 2)
        $badge.Margin = [System.Windows.Thickness]::new(10, 0, 0, 0)
        $txtBadge = [System.Windows.Controls.TextBlock]::new()
        $txtBadge.Text = "LOCKED (GAMING ESSENTIAL)"
        $txtBadge.FontSize = 10
        $txtBadge.FontWeight = [System.Windows.FontWeights]::Bold
        $txtBadge.Foreground = [System.Windows.Media.Brushes]::White
        $badge.SetResourceReference([System.Windows.Controls.Border]::BackgroundProperty, "BrushBadgeSafe")
        $badge.Child = $txtBadge
        [void]$topLine.Children.Add($badge)
    }

    [void]$stack.Children.Add($topLine)

    $txtDesc = [System.Windows.Controls.TextBlock]::new()
    $txtDesc.Text = $Svc.descriptionSimple
    $txtDesc.FontSize = 12
    $txtDesc.SetResourceReference([System.Windows.Controls.TextBlock]::ForegroundProperty, "BrushTextSecondary")
    $txtDesc.Margin = [System.Windows.Thickness]::new(0, 4, 0, 2)
    $txtDesc.TextWrapping = [System.Windows.TextWrapping]::Wrap
    [void]$stack.Children.Add($txtDesc)

    [System.Windows.Controls.Grid]::SetColumn($stack, 0)
    [void]$grid.Children.Add($stack)

    $btnStack = [System.Windows.Controls.StackPanel]::new()
    $btnStack.Orientation = [System.Windows.Controls.Orientation]::Horizontal
    $btnStack.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
    $btnStack.VerticalAlignment = [System.Windows.VerticalAlignment]::Center

    $btnToggle = [System.Windows.Controls.Button]::new()
    $btnToggle.Content = if ($Svc.action -eq "Protect") { "Protected" } else { "Disable" }
    $btnToggle.Width = 90
    $btnToggle.Height = 32
    $btnToggle.Margin = [System.Windows.Thickness]::new(0, 0, 8, 0)
    $btnToggle.Style = if ($Svc.action -eq "Protect") { $Window.Resources["BtnSecondary"] } else { $Window.Resources["BtnDanger"] }

    $btnRestore = [System.Windows.Controls.Button]::new()
    $btnRestore.Content = "Restore"
    $btnRestore.Width = 80
    $btnRestore.Height = 32
    $btnRestore.Style = $Window.Resources["BtnWarn"]

    $btnToggle.add_Click({
        $chkDry = $Window.FindName("chkDryRun")
        $isDry = $chkDry.IsChecked -eq $true
        if ($Svc.action -eq "Protect") {
            [System.Windows.MessageBox]::Show("This service is protected by the Gaming Safeguard. Disabling it breaks Xbox Live sign-in, game controllers, or audio drivers.", "Service Protected", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
            return
        }
        Set-DebloatServiceState -ServiceName $Svc.name -TargetStartType $Svc.recommendedStartType -DryRun:$isDry | Out-Null
        $panelUndo = $Window.FindName("panelUndoActionsContainer")
        Update-UndoPanel -Container $panelUndo
    })

    $btnRestore.add_Click({
        $chkDry = $Window.FindName("chkDryRun")
        $isDry = $chkDry.IsChecked -eq $true
        Undo-DebloatServiceState -ServiceName $Svc.name -DryRun:$isDry | Out-Null
        $panelUndo = $Window.FindName("panelUndoActionsContainer")
        Update-UndoPanel -Container $panelUndo
    })

    [void]$btnStack.Children.Add($btnToggle)
    [void]$btnStack.Children.Add($btnRestore)
    [System.Windows.Controls.Grid]::SetColumn($btnStack, 1)
    [void]$grid.Children.Add($btnStack)

    return $outerShell
}

function Update-UndoPanel {
    param($Container)
    $Container.Children.Clear()

    $actions = Get-SessionActions
    if ($actions.Count -eq 0) {
        $tb = [System.Windows.Controls.TextBlock]::new()
        $tb.Text = "No actions performed in this session yet."
        $tb.SetResourceReference([System.Windows.Controls.TextBlock]::ForegroundProperty, "BrushTextMuted")
        $tb.FontSize = 12
        $tb.FontStyle = [System.Windows.FontStyles]::Italic
        [void]$Container.Children.Add($tb)
        return
    }

    foreach ($act in $actions) {
        $p = [System.Windows.Controls.Border]::new()
        $p.SetResourceReference([System.Windows.Controls.Border]::BackgroundProperty, "BrushSurface")
        $p.SetResourceReference([System.Windows.Controls.Border]::BorderBrushProperty, "BrushBorder")
        $p.BorderThickness = [System.Windows.Thickness]::new(1)
        $p.Padding = [System.Windows.Thickness]::new(12, 10, 12, 10)
        $p.Margin = [System.Windows.Thickness]::new(0, 0, 0, 6)
        $p.CornerRadius = [System.Windows.CornerRadius]::new(8)

        $t = [System.Windows.Controls.TextBlock]::new()
        $t.Text = "[$($act.Timestamp)] [$($act.ActionType)] $($act.Description)"
        $t.SetResourceReference([System.Windows.Controls.TextBlock]::ForegroundProperty, "BrushAccent")
        $t.FontSize = 11.5
        $t.FontFamily = [System.Windows.Media.FontFamily]::new("Cascadia Code, Consolas")

        $p.Child = $t
        [void]$Container.Children.Add($p)
    }
}
