$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$venvPython = Join-Path $root ".venv\Scripts\python.exe"
$python = if (Test-Path $venvPython) { $venvPython } else { "python" }
$godotCandidates = @(
    (Join-Path $root "Godot_v4.5.1-stable_win64_console.exe"),
    (Join-Path $root "Godot_v4.5.1-stable_win64.exe")
)
$godot = $godotCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $godot) {
    throw "Godot executable not found in project root."
}

Write-Host "Importing Godot assets..."
& $godot --headless --editor --quit --path $root
if ($LASTEXITCODE -ne 0) {
    throw "Godot asset import failed."
}

$envFile = Join-Path $root ".env"
if (-not (Test-Path $envFile)) {
    $exampleEnv = Join-Path $root ".env.example"
    if (Test-Path $exampleEnv) {
        Copy-Item $exampleEnv $envFile
    }
}

Write-Host "Starting shell-and-market service..."
$service = Start-Process -FilePath $python -ArgumentList "-m uvicorn services.app:app --host 127.0.0.1 --port 8765" -WorkingDirectory $root -PassThru

$serviceReady = $false
for ($attempt = 0; $attempt -lt 20; $attempt++) {
    Start-Sleep -Milliseconds 500
    try {
        $health = Invoke-WebRequest -UseBasicParsing -Uri "http://127.0.0.1:8765/health" -TimeoutSec 3
        if ($health.StatusCode -eq 200) {
            $serviceReady = $true
            break
        }
    }
    catch {
    }
}

if (-not $serviceReady) {
    if ($service -and -not $service.HasExited) {
        Stop-Process -Id $service.Id -Force
    }
    throw "Backend service did not become ready on 127.0.0.1:8765."
}

Write-Host "Launching Godot..."
try {
    & $godot --path $root
}
finally {
    if ($service -and !$service.HasExited) {
        Stop-Process -Id $service.Id -Force
    }
}
