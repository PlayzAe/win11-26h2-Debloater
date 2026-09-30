Import-Module "C:\Users\Moses\.antigravity-ide\extensions\ms-vscode.powershell-2025.4.0-universal\modules\PSScriptAnalyzer\1.24.0\PSScriptAnalyzer.psd1"

$files = @(
    "gui\GuiController.ps1",
    "tests\Test-GuiElements.Tests.ps1",
    "tests\Test-SafeDebloatMock.Tests.ps1",
    "Win26H2-Debloat.ps1"
) + (Get-ChildItem "modules\*.psm1" | ForEach-Object { $_.FullName })

$results = foreach ($f in $files) {
    Invoke-ScriptAnalyzer -Path $f | Where-Object {
        $_.RuleName -in @("PSUseApprovedVerbs", "PSPossibleIncorrectComparisonWithNull")
    }
}

if ($results) {
    Write-Host "VIOLATIONS FOUND:" -ForegroundColor Red
    $results | Select-Object ScriptName, Line, RuleName, Message | Format-Table -AutoSize
    exit 1
} else {
    Write-Host "ALL CLEAN: 0 PSUseApprovedVerbs, 0 PSPossibleIncorrectComparisonWithNull across all project files!" -ForegroundColor Green
    exit 0
}
