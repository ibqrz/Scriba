param(
  [int]$WebPort = 1623
)

$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
Push-Location $projectRoot

$proxyProcess = $null

try {
  $proxyProcess = Start-Process -FilePath "dart" -ArgumentList "run", "tool/api_proxy_server.dart" -PassThru

  flutter run -d chrome --web-port $WebPort --dart-define=SCRIBA_PROXY_BASE_URL=http://localhost:8080
}
finally {
  if ($null -ne $proxyProcess -and -not $proxyProcess.HasExited) {
    Stop-Process -Id $proxyProcess.Id -Force
  }

  Pop-Location
}
