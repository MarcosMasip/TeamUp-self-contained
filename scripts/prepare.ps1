Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$Mode = 'docker'
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) { $Mode = 'fallback' }
else {
  try { docker info | Out-Null } catch { $Mode = 'fallback' }
}
if (-not (Test-Path .env)) { Copy-Item .env.example .env; Write-Host 'Created .env from template' }
Write-Host "[prepare] Mode: $Mode"
if ($Mode -eq 'docker') {
  Write-Host 'Building backend image...'
  docker build -t teamup-backend:local .
  Write-Host 'Building frontend image...'
  docker build -t teamup-frontend:local socialnetworkingapp-front
  Write-Host 'Pulling dependent images (postgres, mailpit)...'
  try { docker pull postgres:13.11-alpine } catch {}
  try { docker pull axllent/mailpit:v1.18 } catch {}
  Write-Host 'Running offline verification...'
  if (pwsh -File "$PSScriptRoot/offline-verify.ps1") { Write-Host 'Offline verification passed.' }
  else { throw 'Offline verification failed.' }
  Write-Host 'Done. Run scripts/start.ps1'
} else {
  Write-Host 'Fallback mode (no Docker). Ensuring Java & Node present.'
  if (-not (Get-Command java -ErrorAction SilentlyContinue)) { throw 'Java not found' }
  if (-not (Get-Command node -ErrorAction SilentlyContinue)) { throw 'Node not found' }
  try { $nodeVer = (node -v) } catch { $nodeVer = '' }
  if ($nodeVer -match '^v([0-9]+)') {
    $major = [int]$Matches[1]
    if ($major -ge 18) {
      Write-Host "[warn] Detected Node $major.x. Using adaptive install: skipping strict 'npm ci' (legacy Angular lock not fully compatible with modern npm)." -ForegroundColor Yellow
    } else {
      Write-Host "[info] Node $major.x within legacy target range; will attempt strict 'npm ci'." -ForegroundColor Cyan
    }
  }
  ./mvnw -q dependency:go-offline
  Push-Location socialnetworkingapp-front
  $attemptCi = $true
  if ($major -ge 18) { $attemptCi = $false }
  if (-not (Test-Path package-lock.json)) { $attemptCi = $false }
  if ($attemptCi) {
    Write-Host "[info] Attempting deterministic install with 'npm ci'..." -ForegroundColor Cyan
    $ciSucceeded = $true
    try { npm ci } catch { $ciSucceeded = $false }
    if ($ciSucceeded) {
      Write-Host "[info] npm ci succeeded (strict mode)." -ForegroundColor Green
    } else {
      Write-Host "[info] npm ci failed (engine or lock metadata). Falling back to resilient install..." -ForegroundColor Cyan
      $attemptCi = $false
    }
  }
  if (-not $attemptCi) {
    Write-Host "[info] Performing resilient install: 'npm install --legacy-peer-deps' (may update lock)." -ForegroundColor Cyan
    if (Test-Path package-lock.json) { Remove-Item package-lock.json -Force }
    $installOk = $true
    try { npm install --legacy-peer-deps } catch { $installOk = $false }
    if (-not $installOk) { throw '[error] Resilient install failed even with --legacy-peer-deps. Try Node 14.x (see .nvmrc) or inspect peer conflicts.' }
    Write-Host "[info] Resilient install complete. Future runs under Node 14 will use npm ci." -ForegroundColor Green
  }
  Pop-Location
  Write-Host 'Running offline verification (advisory)...'
  if (pwsh -File "$PSScriptRoot/offline-verify.ps1") { Write-Host 'Offline verification passed.' }
  else { Write-Host '(Advisory) Offline verification reported potential external refs.' }
  Write-Host 'Fallback prepare complete. Run scripts/start.ps1'
}
