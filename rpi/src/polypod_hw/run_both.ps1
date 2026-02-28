# run_both.ps1 — Launch both Polypod windows in separate processes (development)
# Run from the polypod_hw directory.

Write-Host "Starting Polypod top window..." -ForegroundColor Cyan
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$PSScriptRoot'; flutter run --dart-define=POLYPOD_WINDOW=top"

# Small delay so the IPC server has time to start before the client connects.
Start-Sleep -Seconds 3

Write-Host "Starting Polypod bottom window..." -ForegroundColor Green
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$PSScriptRoot'; flutter run --dart-define=POLYPOD_WINDOW=bottom"

Write-Host "Both windows launched." -ForegroundColor Yellow
