$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$backendScript = Join-Path $scriptDir 'run_backend.ps1'
$frontendScript = Join-Path $scriptDir 'run_frontend.ps1'

Start-Process powershell -ArgumentList @('-ExecutionPolicy', 'Bypass', '-File', $backendScript)
Start-Sleep -Seconds 2
Start-Process powershell -ArgumentList @('-ExecutionPolicy', 'Bypass', '-File', $frontendScript)
Start-Sleep -Seconds 3
Start-Process 'http://127.0.0.1:5173'
