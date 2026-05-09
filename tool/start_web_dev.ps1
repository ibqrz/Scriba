param(
  [int]$WebPort = 0  # 0 = deixar Flutter escolher porta disponível
)

$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
Push-Location $projectRoot

$proxyProcess = $null
$retries = 0
$maxRetries = 30
$detectedPort = $null

function Test-ProxyReady {
  try {
    $response = Invoke-WebRequest -Uri "http://localhost:8080/health" -TimeoutSec 2 -ErrorAction SilentlyContinue
    return $response.StatusCode -eq 200
  }
  catch {
    return $false
  }
}

function Detect-FlutterWebPort {
  param([int]$InitialPort)
  
  # Se a porta foi especificada, return ela
  if ($InitialPort -gt 0) {
    return $InitialPort
  }
  
  # Se nenhuma porta foi dada, Flutter vai escolher uma disponível
  # Vamos procurar nos logs qual porta foi usada
  $attempts = 0
  while ($attempts -lt 30) {
    $logs = flutter run -d chrome 2>&1 | Select-String "Web app" -First 1
    if ($logs -match "localhost:(\d+)") {
      return [int]$matches[1]
    }
    Start-Sleep -Milliseconds 500
    $attempts++
  }
  
  # Fallback para porta padrão
  return 1623
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
  
  # Montar comando do Flutter
  $flutterArgs = @("-d", "chrome")
  
  if ($WebPort -gt 0) {
    $flutterArgs += @("--web-port", $WebPort.ToString())
    $detectedPort = $WebPort
    Write-Host "📍 Usando porta web fixa: $WebPort" -ForegroundColor Cyan
  }
  else {
    Write-Host "📍 Deixando Flutter escolher porta disponível..." -ForegroundColor Cyan
  }
  
  # Sempre passar dart-define para proxy
  $flutterArgs += @("--dart-define=SCRIBA_PROXY_BASE_URL=http://localhost:8080")
  
  & flutter @flutterArgs
}
finally {
  if ($null -ne $proxyProcess -and -not $proxyProcess.HasExited) {
    Write-Host "`n🛑 Encerrando proxy..." -ForegroundColor Yellow
    Stop-Process -Id $proxyProcess.Id -Force -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 500
  }

  Pop-Location
}