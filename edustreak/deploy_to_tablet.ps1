# Deploy Flutter App to USB-Connected Tablet and Run Backend Server
# This script will:
# 1. Check for connected USB devices
# 2. Get your computer's IP address
# 3. Start the backend server in a separate window
# 4. Deploy and run the Flutter app on the tablet

$ErrorActionPreference = "Continue"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  EduStreak Deployment Script" -ForegroundColor Cyan
Write-Host "  Deploy to USB Tablet + Backend Server" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Get script directory
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$flutterProjectDir = $scriptPath
$backendDir = Join-Path $scriptPath "Study_Assistant\files"

# Check if backend directory exists
if (-not (Test-Path $backendDir)) {
    Write-Host "Error: Backend directory not found at: $backendDir" -ForegroundColor Red
    Write-Host "Please ensure the backend is located at: Study_Assistant\files\" -ForegroundColor Yellow
    pause
    exit 1
}

# Check if Flutter is installed
# First, try to find Flutter in PATH
$flutterPath = $null
try {
    $flutterCheck = Get-Command flutter -ErrorAction Stop
    $flutterPath = "flutter"
    Write-Host "Flutter found in PATH" -ForegroundColor Green
} catch {
    # Flutter not in PATH, try common locations
    $possiblePaths = @(
        "C:\src\flutter\bin\flutter.bat",
        "$env:LOCALAPPDATA\flutter\bin\flutter.bat",
        "$env:USERPROFILE\flutter\bin\flutter.bat",
        "C:\flutter\bin\flutter.bat"
    )
    
    $found = $false
    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            $flutterPath = $path
            $found = $true
            break
        }
    }
    
    if (-not $found) {
        Write-Host "Error: Flutter not found!" -ForegroundColor Red
        Write-Host "Please install Flutter or add it to your PATH." -ForegroundColor Yellow
        Write-Host "Common locations:" -ForegroundColor Yellow
        Write-Host "  - C:\src\flutter\bin\flutter.bat" -ForegroundColor Yellow
        Write-Host "  - $env:LOCALAPPDATA\flutter\bin\flutter.bat" -ForegroundColor Yellow
        pause
        exit 1
    }
}

Write-Host "Flutter found at: $flutterPath" -ForegroundColor Green
Write-Host ""

# Step 1: Check for connected devices
Write-Host "Step 1: Checking for connected devices..." -ForegroundColor Yellow
Write-Host "Waiting for devices to be detected (this may take a few seconds)..." -ForegroundColor Yellow
Set-Location $flutterProjectDir

# Wait a bit for devices to be detected
Start-Sleep -Seconds 2

# Try with device timeout to give more time for detection
$devicesOutput = & $flutterPath devices --device-timeout 10 2>&1

# Improved device pattern matching
$devices = @()
$devicesOutput | ForEach-Object {
    $line = $_.ToString()
    # Match patterns like: "ABC123XYZ    • device" or "emulator-5554  • device"
    if ($line -match "^([^\s]+)\s+.*?\(device\)") {
        $deviceId = $matches[1]
        $deviceName = $line -replace "^$deviceId\s+", "" -replace "\s+\(device\).*", ""
        if ($deviceId -and $deviceId -notmatch "^\s*$") {
            $devices += [PSCustomObject]@{
                Id = $deviceId
                Name = $deviceName
            }
        }
    }
}

if ($devices.Count -eq 0) {
    Write-Host "No devices found!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please ensure:" -ForegroundColor Yellow
    Write-Host "  1. Your tablet is connected via USB" -ForegroundColor Yellow
    Write-Host "  2. USB debugging is enabled on your tablet" -ForegroundColor Yellow
    Write-Host "  3. You've authorized the computer on your tablet" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Available devices:" -ForegroundColor Yellow
    $devicesOutput | Write-Host
    pause
    exit 1
}

Write-Host "Found $($devices.Count) device(s):" -ForegroundColor Green
foreach ($device in $devices) {
    Write-Host "  - $($device.Id): $($device.Name)" -ForegroundColor Cyan
}

# Select device (if multiple, use first one)
$selectedDevice = $devices[0]
if ($devices.Count -gt 1) {
    Write-Host ""
    Write-Host "Multiple devices found. Using first device: $($selectedDevice.Id)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Selected device: $($selectedDevice.Id) - $($selectedDevice.Name)" -ForegroundColor Green
Write-Host ""

# Step 2: Get computer's IP address
Write-Host "Step 2: Getting computer's IP address..." -ForegroundColor Yellow

$ipAddress = $null
$networkAdapters = Get-NetIPAddress -AddressFamily IPv4 | Where-Object {
    $_.IPAddress -notlike "127.*" -and 
    $_.IPAddress -notlike "169.254.*" -and
    $_.PrefixOrigin -eq "Dhcp" -or $_.PrefixOrigin -eq "Manual"
} | Sort-Object -Property InterfaceIndex

if ($networkAdapters.Count -gt 0) {
    $ipAddress = $networkAdapters[0].IPAddress
    Write-Host "Found IP address: $ipAddress" -ForegroundColor Green
} else {
    Write-Host "Warning: Could not determine IP address automatically." -ForegroundColor Yellow
    Write-Host "Using default: 10.97.72.248" -ForegroundColor Yellow
    $ipAddress = "10.97.72.248"
}

$backendUrl = "http://$ipAddress:8000"
Write-Host "Backend URL: $backendUrl" -ForegroundColor Cyan
Write-Host ""

# Step 3: Start backend server in a separate window
Write-Host "Step 3: Starting backend server..." -ForegroundColor Yellow

$backendScript = @"
@echo off
title EduStreak Backend Server
cd /d "$backendDir"
echo ========================================
echo   Study Assistant Backend Server
echo ========================================
echo.
echo Server URL: $backendUrl
echo.
echo This window must stay open!
echo Press Ctrl+C to stop the server
echo.
echo ========================================
echo.

call venv\Scripts\activate.bat
if errorlevel 1 (
    echo Error: Failed to activate virtual environment
    echo Make sure venv exists in: $backendDir
    pause
    exit 1
)

python -m uvicorn backend.main:app --host 0.0.0.0 --port 8000
pause
"@

$backendBatFile = Join-Path $env:TEMP "edustreak_backend_$(Get-Date -Format 'yyyyMMdd_HHmmss').bat"
$backendScript | Out-File -FilePath $backendBatFile -Encoding ASCII

Write-Host "Starting backend server in a new window..." -ForegroundColor Green
Start-Process cmd.exe -ArgumentList "/c", "`"$backendBatFile`""

# Wait a bit for the server to start
Write-Host "Waiting 3 seconds for backend server to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 3
Write-Host ""

# Step 4: Deploy and run Flutter app
Write-Host "Step 4: Deploying Flutter app to tablet..." -ForegroundColor Yellow
Write-Host "Device: $($selectedDevice.Id) - $($selectedDevice.Name)" -ForegroundColor Cyan
Write-Host "Backend URL: $backendUrl" -ForegroundColor Cyan
Write-Host ""

Set-Location $flutterProjectDir

# Run Flutter app with backend URL override
Write-Host "Running: flutter run -d $($selectedDevice.Id) --dart-define=STUDY_ASSISTANT_URL=$backendUrl" -ForegroundColor Cyan
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Flutter App Starting..." -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Note: The backend server is running in a separate window." -ForegroundColor Yellow
Write-Host "Keep both windows open while testing." -ForegroundColor Yellow
Write-Host ""

& $flutterPath run -d $selectedDevice.Id --dart-define=STUDY_ASSISTANT_URL=$backendUrl

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Deployment Complete" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Backend server is still running in the other window." -ForegroundColor Yellow
Write-Host "To stop it, close that window or press Ctrl+C in it." -ForegroundColor Yellow
Write-Host ""

