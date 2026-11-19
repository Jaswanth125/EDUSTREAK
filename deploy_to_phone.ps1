# deploy_to_phone.ps1
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
$apk = "c:\Users\jaswa\EDUSTREAK\edustreak\build\app\outputs\flutter-apk\app-debug.apk"

Write-Host "Checking for connected Android device..." -ForegroundColor Cyan
$devices = & $adb devices | Where-Object { $_ -match "\bdevice\b" }

if (-not $devices) {
    Write-Host "No authorized device detected yet." -ForegroundColor Yellow
    Write-Host "Waiting for device to be connected with USB Debugging enabled..." -ForegroundColor Yellow
    
    $timeout = 60
    $elapsed = 0
    while (-not $devices -and $elapsed -lt $timeout) {
        Start-Sleep -Seconds 2
        $elapsed += 2
        $devices = & $adb devices | Where-Object { $_ -match "\bdevice\b" }
    }
}

if ($devices) {
    Write-Host "Device detected: $devices" -ForegroundColor Green
    
    Write-Host "Setting up port forwarding (phone localhost:8000 -> PC localhost:8000)..." -ForegroundColor Cyan
    & $adb reverse tcp:8000 tcp:8000
    
    Write-Host "Installing APK ($apk)..." -ForegroundColor Cyan
    & $adb install -r $apk
    
    Write-Host "Launching EduStreak on device..." -ForegroundColor Green
    & $adb shell monkey -p com.example.edustreak -c android.intent.category.LAUNCHER 1
    
    Write-Host "EduStreak deployed and launched successfully!" -ForegroundColor Green
} else {
    Write-Host "Device connection timed out. Please follow the instructions to enable USB Debugging." -ForegroundColor Red
}
