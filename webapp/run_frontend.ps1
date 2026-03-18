$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$frontendDir = Join-Path $scriptDir 'frontend'

Set-Location $frontendDir
npm run dev -- --host 127.0.0.1 --port 5173
