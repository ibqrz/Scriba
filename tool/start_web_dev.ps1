param(
  [int]$WebPort = 1623
)

$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
Push-Location $projectRoot

$proxyProcess = $null
$retries = 0
$maxRetries = 30

function Test-ProxyReady {
  try {
    $response = Invoke-WebRequest -Uri "http://localhost:8080/health" -TimeoutSec 2 -ErrorAction SilentlyContinue
    return $response.StatusCode -eq 200
  }
  catch {
    return $false
  }
}

try {
  Write-Host "🚀 Iniciando proxy Scriba na porta 8080..." -ForegroundColor Cyan
  $proxyProcess = Start-Process -FilePath "dart" -ArgumentList "run", "tool/api_proxy_server.dart" `
    -PassThru -RedirectStandardOutput "proxy.log" -RedirectStandardError "proxy.error.log"
  
  Write-Host "Aguardando proxy ficar pronto..." -ForegroundColor Yellow
  while (-not (Test-ProxyReady) -and $retries -lt $maxRetries) {
    Write-Host "." -NoNewline
    Start-Sleep -Milliseconds 500
    $retries++
  }
  
  if (Test-ProxyReady) {
    Write-Host "`n✅ Proxy pronto em http://localhost:8080" -ForegroundColor Green
  }
  else {
    Write-Host "`n❌ Proxy não respondeu. Verifique proxy.error.log" -ForegroundColor Red
    Get-Content "proxy.error.log" -ErrorAction SilentlyContinue
    exit 1
  }

  Write-Host "🌐 Iniciando Flutter Web..." -ForegroundColor Cyan
  flutter run -d chrome --web-port $WebPort --dart-define=SCRIBA_PROXY_BASE_URL=http://localhost:8080
}
finally {
  if ($null -ne $proxyProcess -and -not $proxyProcess.HasExited) {
    Write-Host "`n🛑 Encerrando proxy..." -ForegroundColor Yellow
    Stop-Process -Id $proxyProcess.Id -Force -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 500
  }

  Pop-Location
}
