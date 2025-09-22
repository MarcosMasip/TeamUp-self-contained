Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
function Show-Version {
  param([string]$Name,[string]$Command,[string]$Args='')
  if (Get-Command $Command -ErrorAction SilentlyContinue) {
    Write-Host "$Name:" -NoNewline
    try { & $Command $Args } catch { Write-Host ' (error invoking)' }
  } else { Write-Host "$Name: NOT FOUND" }
}
Show-Version -Name 'Java' -Command 'java' -Args '-version'
Show-Version -Name 'Node' -Command 'node' -Args '-v'
Show-Version -Name 'NPM' -Command 'npm' -Args '-v'
Show-Version -Name 'Docker' -Command 'docker' -Args '--version'
if (Get-Command docker -ErrorAction SilentlyContinue) {
  try { docker compose version | Out-Null; Write-Host 'Docker Compose: plugin available' } catch {
    if (Get-Command docker-compose -ErrorAction SilentlyContinue) { Write-Host 'Docker Compose: legacy binary available' } else { Write-Host 'Docker Compose: NOT FOUND' }
  }
}
