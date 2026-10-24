[CmdletBinding()]
param(
    # Build configuration; Release is recommended for running a hub.
    [ValidateSet('Release', 'Debug', 'RelWithDebInfo')]
    [string]$Configuration = 'Release',
    # Optional offline ENet checkout at the revision pinned in CMakeLists.txt.
    [string]$EnetSourceDir = ''
)

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
$buildDir = Join-Path $repoRoot 'build/windows'
$cmakeCommand = Get-Command cmake -ErrorAction SilentlyContinue
if ($cmakeCommand) {
    $cmake = $cmakeCommand.Source
} else {
    $vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio/Installer/vswhere.exe'
    if (Test-Path -LiteralPath $vswhere) {
        $vsPath = & $vswhere -latest -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
        if ($vsPath) {
            $cmake = Join-Path $vsPath 'Common7/IDE/CommonExtensions/Microsoft/CMake/CMake/bin/cmake.exe'
        }
    }
}
if (!$cmake -or !(Test-Path -LiteralPath $cmake)) {
    throw 'Install Visual Studio 2022 or newer with Desktop development with C++ and C++ CMake tools for Windows.'
}

$configureArgs = @('-S', $repoRoot, '-B', $buildDir, '-A', 'x64')
if ($EnetSourceDir) {
    $configureArgs += "-DFETCHCONTENT_SOURCE_DIR_ENET=$((Resolve-Path -LiteralPath $EnetSourceDir).Path)"
}
& $cmake @configureArgs
if ($LASTEXITCODE -ne 0) { throw 'CMake configuration failed.' }
& $cmake --build $buildDir --config $Configuration --parallel 1
if ($LASTEXITCODE -ne 0) { throw 'Build failed.' }
Write-Host "Built: $buildDir/$Configuration/nightcoop_hub.exe"
