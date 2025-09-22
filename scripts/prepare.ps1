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
  ./mvnw -q dependency:go-offline
  Push-Location socialnetworkingapp-front
  npm ci
  Pop-Location
  Write-Host 'Running offline verification (advisory)...'
  if (pwsh -File "$PSScriptRoot/offline-verify.ps1") { Write-Host 'Offline verification passed.' }
  else { Write-Host '(Advisory) Offline verification reported potential external refs.' }
  Write-Host 'Fallback prepare complete. Run scripts/start.ps1'
}
