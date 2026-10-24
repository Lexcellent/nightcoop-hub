[CmdletBinding()]
param(
    # Entry UDP port; extra shards listen from Port + 10 onward.
    [ValidateRange(1, 65535)]
    [int]$Port = 47800,
    # Number of server threads, or auto to use the available CPU cores.
    [ValidatePattern('^(auto|[1-9][0-9]*)$')]
    [string]$Shards = 'auto',
    # Maximum simultaneous ENet connections per thread (ENet limit: 4095).
    [ValidateRange(1, 4095)]
    [int]$MaxClients = 512,
    # Persistent key directory; relative paths are resolved from the repo root.
    [string]$DataDir = 'data',
    # Human-readable hub name shown to players.
    [string]$HubName = 'My NightCoop hub',
    # Optional region label shown to players.
    [string]$Region = ''
)

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
$exe = Join-Path $repoRoot 'build/windows/Release/nightcoop_hub.exe'
if (!(Test-Path -LiteralPath $exe)) {
    throw 'Build the Release executable first: tools/hub/windows/build.ps1'
}
if (![System.IO.Path]::IsPathRooted($DataDir)) {
    $DataDir = Join-Path $repoRoot $DataDir
}
New-Item -ItemType Directory -Path $DataDir -Force | Out-Null
$hubArgs = @("$Port", '--shards', $Shards, '--max-clients', "$MaxClients",
    '--sign-key-auto', (Join-Path $DataDir 'hub-sign.key'), '--hub-name', $HubName)
if ($Region) { $hubArgs += @('--region', $Region) }
& $exe @hubArgs
exit $LASTEXITCODE
