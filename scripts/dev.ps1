Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Write-Host 'Starting dev mode (db + mail in docker, local backend/frontend)...'
docker compose up -d db mail
Start-Process -FilePath ./mvnw -ArgumentList 'spring-boot:run','-Dspring-boot.run.profiles=mock,local-h2'
Push-Location socialnetworkingapp-front
Start-Process -FilePath npx -ArgumentList 'ng','serve','--proxy-config','proxy.conf.json'
Pop-Location
Write-Host 'Launched. Stop containers later with: docker compose down'
