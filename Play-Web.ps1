$ErrorActionPreference = 'Stop'
$projectDir = $PSScriptRoot
$serverScript = Join-Path $projectDir 'tools\serve.cjs'
$running = $false
try { $response = Invoke-WebRequest -Uri 'http://127.0.0.1:8787/web/index.html' -UseBasicParsing -TimeoutSec 2; $running = $response.Content.Contains('game.js') } catch {}
if (-not $running) {
    Start-Process -FilePath 'node' -ArgumentList @('"' + $serverScript + '"') -WorkingDirectory $projectDir -WindowStyle Hidden
    Start-Sleep -Milliseconds 700
}
Start-Process 'http://127.0.0.1:8787'
