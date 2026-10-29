# Check Tablet USB Connection and USB Debugging Status
$ErrorActionPreference = "Continue"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Tablet Connection Checker" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Find ADB
$adbPath = $null
$androidHome = $env:ANDROID_HOME
if (-not $androidHome) {
    $androidHome = "$env:LOCALAPPDATA\Android\sdk"
}

$possibleAdbPaths = @(
    "$androidHome\platform-tools\adb.exe",
    "C:\Users\$env:USERNAME\AppData\Local\Android\sdk\platform-tools\adb.exe",
    "C:\Android\sdk\platform-tools\adb.exe"
)

foreach ($path in $possibleAdbPaths) {
    if (Test-Path $path) {
        $adbPath = $path
        break
    }
}

if (-not $adbPath) {
    Write-Host "Error: ADB not found!" -ForegroundColor Red
    Write-Host "Please install Android SDK Platform Tools." -ForegroundColor Yellow
    pause
    exit 1
}

Write-Host "ADB found at: $adbPath" -ForegroundColor Green
Write-Host ""

# Check for devices
Write-Host "Checking for connected devices..." -ForegroundColor Yellow
$adbOutput = & $adbPath devices 2>&1

Write-Host ""
Write-Host "ADB Output:" -ForegroundColor Cyan
Write-Host $adbOutput
Write-Host ""

$devices = $adbOutput | Select-String -Pattern "device$" | Where-Object { $_.Line -notmatch "List of devices" }

if ($devices.Count -eq 0) {
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "  No devices detected!" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please follow these steps:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "1. Enable Developer Options on your tablet:" -ForegroundColor Cyan
    Write-Host "   - Go to Settings > About Tablet" -ForegroundColor White
    Write-Host "   - Tap 'Build Number' 7 times" -ForegroundColor White
    Write-Host "   - Go back to Settings > Developer Options" -ForegroundColor White
    Write-Host ""
    Write-Host "2. Enable USB Debugging:" -ForegroundColor Cyan
    Write-Host "   - In Developer Options, enable 'USB Debugging'" -ForegroundColor White
    Write-Host "   - Also enable 'Stay Awake' (optional but helpful)" -ForegroundColor White
    Write-Host ""
    Write-Host "3. Connect your tablet via USB:" -ForegroundColor Cyan
    Write-Host "   - Use a data cable (not just charging cable)" -ForegroundColor White
    Write-Host "   - When prompted on tablet, select 'File Transfer' or 'MTP' mode" -ForegroundColor White
    Write-Host ""
    Write-Host "4. Authorize the computer:" -ForegroundColor Cyan
    Write-Host "   - When you connect, your tablet will show 'Allow USB Debugging?'" -ForegroundColor White
    Write-Host "   - Check 'Always allow from this computer' and tap 'OK'" -ForegroundColor White
    Write-Host ""
    Write-Host "5. Run this script again to verify connection" -ForegroundColor Cyan
    Write-Host ""
} else {
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "  Device(s) Found!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    foreach ($device in $devices) {
        $deviceId = ($device.Line -split "\s+")[0]
        Write-Host "Device ID: $deviceId" -ForegroundColor Green
    }
    Write-Host ""
    Write-Host "Your tablet is ready! You can now run deploy_to_tablet.ps1" -ForegroundColor Green
    Write-Host ""
}

Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")



