Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

Write-Host "1. Testing XAML parsing..." -ForegroundColor Cyan
$xamlPath = Join-Path (Get-Location).Path "gui\MainWindow.xaml"
$xamlContent = Get-Content $xamlPath -Raw
$reader = [System.Xml.XmlReader]::Create([System.IO.StringReader]::new($xamlContent))
$window = [System.Windows.Markup.XamlReader]::Load($reader)
if ($window) {
    Write-Host "   -> XAML loaded and parsed successfully!" -ForegroundColor Green
} else {
    Write-Host "   -> Failed to parse XAML." -ForegroundColor Red
}

Write-Host "`n2. Testing PowerShell Module Parsing..." -ForegroundColor Cyan
$files = Get-ChildItem -Path (Get-Location).Path -Include *.ps1, *.psm1 -Recurse
foreach ($file in $files) {
    $errs = $null
    [void][System.Management.Automation.Language.Parser]::ParseInput((Get-Content $file.FullName -Raw), [ref]$null, [ref]$errs)
    if ($errs.Count -gt 0) {
        Write-Host "   [FAIL] $($file.Name): $($errs[0].Message)" -ForegroundColor Red
    } else {
        Write-Host "   [PASS] $($file.Name)" -ForegroundColor Green
    }
}
