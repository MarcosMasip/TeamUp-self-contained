Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$backendPort = if ($Env:APP_BACKEND_PORT) { [int]$Env:APP_BACKEND_PORT } else { 8443 }
$frontendPort = if ($Env:APP_FRONTEND_PORT) { [int]$Env:APP_FRONTEND_PORT } else { 4200 }
Write-Host 'Checking backend...'
try {
  $resp = curl -k -s https://localhost:$backendPort/api/health
  if ($resp -match 'UP') { Write-Host 'Backend OK' } else { throw 'Backend FAIL' }
} catch { throw 'Backend FAIL' }
Write-Host 'Checking frontend...'
try {
  $page = curl -s http://localhost:$frontendPort/
  if ($page -match '<app-root') { Write-Host 'Frontend OK' } else { throw 'Frontend FAIL' }
} catch { throw 'Frontend FAIL' }
Write-Host 'All healthy.'
