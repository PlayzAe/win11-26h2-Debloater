$ErrorActionPreference = 'Stop'
$src = "c:\Users\Moses\Desktop\Dev Code\win 11 26h2 deblaot"
$dst = "C:\Users\Moses\Documents\GitHub\win11 26h2 Debloater"

Write-Host "Syncing files from $src to $dst..."

$dirs = @('src', 'scripts', 'out', 'modules', 'config', 'tests')
foreach ($d in $dirs) {
    $targetDir = Join-Path $dst $d
    if (Test-Path $targetDir) {
        Remove-Item $targetDir -Recurse -Force
    }
    Copy-Item -Path (Join-Path $src $d) -Destination $targetDir -Recurse -Force
}

$files = @(
    'package.json',
    'tsconfig.json',
    'vite.config.mts',
    'start.bat',
    '.gitignore',
    'README.md',
    'Win26H2-Debloat.ps1',
    'CHANGELOG.md',
    'LICENSE'
)

foreach ($f in $files) {
    $srcFile = Join-Path $src $f
    if (Test-Path $srcFile) {
        Copy-Item -Path $srcFile -Destination (Join-Path $dst $f) -Force
    }
}

Write-Host "Sync completed successfully."
