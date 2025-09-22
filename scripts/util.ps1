<#
  Utility functions for Windows PowerShell equivalents of bash helpers.
#>
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Test-PortFree {
    param(
        [Parameter(Mandatory=$true)][int]$Port
    )
    try {
        $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, $Port)
        $listener.Start()
        $listener.Stop()
        return $true
    } catch {
        return $false
    }
}

function Wait-ForPort {
    param(
        [Parameter(Mandatory=$true)][string]$Host,
        [Parameter(Mandatory=$true)][int]$Port,
        [int]$Attempts = 30,
        [int]$DelaySeconds = 1
    )
    for ($i = 1; $i -le $Attempts; $i++) {
        try {
            $client = New-Object System.Net.Sockets.TcpClient
            $iar = $client.BeginConnect($Host, $Port, $null, $null)
            $success = $iar.AsyncWaitHandle.WaitOne(500)
            if ($success -and $client.Connected) {
                $client.EndConnect($iar) | Out-Null
                $client.Close()
                return $true
            }
            $client.Close()
        } catch {}
        Start-Sleep -Seconds $DelaySeconds
    }
    return $false
}

function Retry-Command {
    param(
        [Parameter(Mandatory=$true)][int]$Attempts,
        [Parameter(Mandatory=$true)][int]$DelaySeconds,
        [Parameter(Mandatory=$true)][scriptblock]$ScriptBlock
    )
    for ($i = 1; $i -le $Attempts; $i++) {
        try {
            & $ScriptBlock
            if ($LASTEXITCODE -eq 0 -or $? ) { return $true }
        } catch {
            Write-Host "[retry] Attempt $i failed: $($_.Exception.Message)" -ForegroundColor Yellow
        }
        if ($i -lt $Attempts) { Start-Sleep -Seconds $DelaySeconds }
    }
    Write-Host "[retry] All attempts failed" -ForegroundColor Red
    return $false
}

Export-ModuleMember -Function Test-PortFree, Wait-ForPort, Retry-Command
