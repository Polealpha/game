$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$python = "python"
$godot = Join-Path $root "Godot_v4.5.1-stable_win64_console.exe"

Write-Host "Starting shell-and-market service..."
$service = Start-Process -FilePath $python -ArgumentList "-m uvicorn services.app:app --host 127.0.0.1 --port 8765 --reload" -WorkingDirectory $root -PassThru
Start-Sleep -Seconds 2

Write-Host "Launching Godot..."
try {
    & $godot --path $root
}
finally {
    if ($service -and !$service.HasExited) {
        Stop-Process -Id $service.Id -Force
    }
}
