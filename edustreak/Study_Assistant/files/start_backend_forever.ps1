# Auto-restarting Backend Server Script
$ErrorActionPreference = "Continue"
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptPath

Write-Host "========================================" -ForegroundColor Green
Write-Host "  Study Assistant Backend Server" -ForegroundColor Green
Write-Host "  Auto-Restart Enabled" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Server URL: http://10.0.57.34:8000" -ForegroundColor Cyan
Write-Host "Press Ctrl+C to stop" -ForegroundColor Yellow
Write-Host ""

$restartCount = 0
$maxRestarts = 1000

while ($true) {
    try {
        $restartCount++
        Write-Host "[$restartCount] Starting backend server..." -ForegroundColor Green
        
        & ".\venv\Scripts\python.exe" -m uvicorn backend.main:app --host 0.0.0.0 --port 8000
        
        # If we get here, the server stopped
        Write-Host "[$restartCount] Server stopped. Restarting in 5 seconds..." -ForegroundColor Yellow
        Start-Sleep -Seconds 5
        
        if ($restartCount -ge $maxRestarts) {
            Write-Host "Maximum restart attempts reached. Exiting." -ForegroundColor Red
            break
        }
    }
    catch {
        Write-Host "[$restartCount] Error occurred: $_" -ForegroundColor Red
        Write-Host "Restarting in 5 seconds..." -ForegroundColor Yellow
        Start-Sleep -Seconds 5
    }
}

Write-Host "Backend server stopped." -ForegroundColor Red
pause

