$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$backendDir = Join-Path $scriptDir 'backend'

Set-Location $backendDir
py -3.10 -m uvicorn app.main:app --app-dir $backendDir --host 127.0.0.1 --port 8000
