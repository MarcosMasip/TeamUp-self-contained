Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/util.ps1" | Out-Null
$Mode = 'docker'
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) { $Mode = 'fallback' } else { try { docker info | Out-Null } catch { $Mode = 'fallback' } }
if (-not (Test-Path .env)) { throw '.env missing. Run scripts/prepare.ps1 first.' }
Get-Content .env | ForEach-Object { if ($_ -match '^[A-Za-z_][A-Za-z0-9_]*=') { $name,$val = $_.Split('=',2); Set-Item -Path Env:$name -Value $val } }
if ($Mode -eq 'docker') {
  Write-Host 'Starting services (docker compose)...'
  docker compose up -d db mail
  Write-Host 'Waiting for database readiness via pg_isready...'
  $pgUser = $Env:POSTGRES_USER; $pgDb = $Env:POSTGRES_DB
  Retry-Command -Attempts 10 -DelaySeconds 2 -ScriptBlock { docker compose exec -T db pg_isready -U $pgUser -d $pgDb }
  docker compose up -d backend
  Write-Host 'Waiting for backend health...'
  $backendPort = if ($Env:APP_BACKEND_PORT) { [int]$Env:APP_BACKEND_PORT } else { 8443 }
  for ($i=1; $i -le 30; $i++) {
    try {
      $resp = curl -k -s https://localhost:$backendPort/api/health
      if ($resp -match 'UP') { break }
    } catch {}
    Start-Sleep -Seconds 2
  }
  docker compose up -d frontend
  $frontendPort = if ($Env:APP_FRONTEND_PORT) { [int]$Env:APP_FRONTEND_PORT } else { 4200 }
  Write-Host 'Application started.'
  Write-Host "Frontend: http://localhost:$frontendPort"
  Write-Host "Backend API: https://localhost:$backendPort/api"
  Write-Host 'Mail UI: http://localhost:8025 (if using mail)'
  Write-Host 'Admin login: admin@admin.com / adminadmin'
} else {
  Write-Host 'Starting fallback local mode...'
  $backendPort = if ($Env:APP_BACKEND_PORT) { [int]$Env:APP_BACKEND_PORT } else { 8443 }
  $frontendPort = if ($Env:APP_FRONTEND_PORT) { [int]$Env:APP_FRONTEND_PORT } else { 4200 }
  foreach ($p in @($backendPort,$frontendPort)) {
    if (-not (Test-PortFree -Port $p)) { throw "Port $p already in use. Abort." }
  }
  Start-Process -FilePath ./mvnw -ArgumentList 'spring-boot:run','-Dspring-boot.run.profiles=local-h2'
  Push-Location socialnetworkingapp-front
  if (Get-Command node -ErrorAction SilentlyContinue) {
    try { $nodeVer = node -v } catch { $nodeVer = '' }
    if ($nodeVer -match '^v([0-9]+)') {
      $nodeMajor = [int]$Matches[1]
      if ($nodeMajor -ge 17) {
        if (-not $Env:NODE_OPTIONS -or ($Env:NODE_OPTIONS -notmatch '--openssl-legacy-provider')) {
          $Env:NODE_OPTIONS = ("$($Env:NODE_OPTIONS) --openssl-legacy-provider").Trim()
          Write-Host "[info] Applied --openssl-legacy-provider for Webpack 4 compatibility (Node $nodeMajor)." -ForegroundColor Cyan
        }
      }
    }
  }
  Start-Process -FilePath npx -ArgumentList 'ng','serve'
  Pop-Location
  Write-Host 'Processes started (check separate windows).' 
}
