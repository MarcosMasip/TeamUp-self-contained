Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
Write-Host "[offline-verify] Scanning for external URLs..."
$files = Get-ChildItem -Path $Root -Recurse -File -ErrorAction SilentlyContinue | Where-Object {
    $_.FullName -notmatch '\\node_modules\\' -and
    $_.FullName -notmatch '\\dist\\' -and
    $_.FullName -notmatch '\\target\\' -and
    $_.FullName -notmatch '\\.git\\' -and
    $_.Extension -notin '.pdf'
}
$pattern = 'https?://'
$matches = @()
foreach ($f in $files) {
  $content = Get-Content -LiteralPath $f.FullName -ErrorAction SilentlyContinue
  foreach ($line in $content) {
    if ($line -match $pattern) {
      $matches += [PSCustomObject]@{File=$f.FullName;Line=$line}
    }
  }
}
$filtered = $matches | Where-Object { $_.Line -notmatch 'localhost|127.0.0.1|mailpit' }
if (-not $filtered) {
  Write-Host '[offline-verify] PASS: No external URL references detected.'
  exit 0
} else {
  Write-Host '[offline-verify] WARNING: Potential external references found:' -ForegroundColor Yellow
  $filtered | ForEach-Object { Write-Host ("{0}: {1}" -f $_.File,$_.Line) }
  exit 1
}
