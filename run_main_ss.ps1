$projectDir = (Get-ChildItem -Path $PSScriptRoot -Directory | Where-Object { $_.Name -like 'MATLAB*' } | Select-Object -First 1 -ExpandProperty FullName)
$runtimeRoot = "C:\Program Files\MATLAB\MATLAB Runtime\R2022b"

if (-not (Test-Path $projectDir)) {
    throw "Project directory not found: $projectDir"
}

if (-not (Test-Path $runtimeRoot)) {
    throw "MATLAB Runtime R2022b not found: $runtimeRoot"
}

$env:PATH = "$runtimeRoot\runtime\win64;$runtimeRoot\bin\win64;$runtimeRoot\extern\bin\win64;$env:PATH"
Set-Location $projectDir

py -3.10 -c "import python_Main_SS; pkg = python_Main_SS.initialize(); pkg.python_Main_SS(nargout=0)"
