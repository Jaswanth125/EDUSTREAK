# Build APK Script for EduStreak
# This script builds the APK while handling path issues with parentheses

Write-Host "Building EduStreak APK..." -ForegroundColor Cyan
Write-Host ""

$projectDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$androidDir = Join-Path $projectDir "android"
$flutterPath = "C:\src\flutter\bin\flutter.bat"

# Set environment variables
$env:ANDROID_HOME = "C:\Users\jaswa\AppData\Local\Android\sdk"
$env:FLUTTER_ROOT = "C:\src\flutter"

# Change to project directory
Set-Location $projectDir

Write-Host "Step 1: Cleaning build..." -ForegroundColor Yellow
cmd /c "`"$flutterPath`" clean" 2>&1 | Where-Object { $_ -notmatch "DIR /B /O:D" } | Out-Null

Write-Host "Step 2: Getting dependencies..." -ForegroundColor Yellow
cmd /c "`"$flutterPath`" pub get" 2>&1 | Where-Object { $_ -notmatch "DIR /B /O:D" } | Out-Null

Write-Host "Step 3: Building APK (this may take several minutes)..." -ForegroundColor Yellow
Write-Host ""

# Try building with Flutter first
$buildResult = cmd /c "`"$flutterPath`" build apk --release" 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "Flutter build failed. Trying direct Gradle build..." -ForegroundColor Yellow
    
    # Try direct Gradle build
    Set-Location $androidDir
    $gradleResult = cmd /c "gradlew.bat assembleRelease --no-daemon" 2>&1
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Build failed!" -ForegroundColor Red
        Write-Host $gradleResult
        exit 1
    }
}

# Find the APK file
$apkPath = Join-Path $projectDir "build\app\outputs\flutter-apk\app-release.apk"

if (Test-Path $apkPath) {
    $apkInfo = Get-Item $apkPath
    $sizeMB = [math]::Round($apkInfo.Length / 1MB, 2)
    
    Write-Host ""
    Write-Host "✓ APK built successfully!" -ForegroundColor Green
    Write-Host "Location: $apkPath" -ForegroundColor Cyan
    Write-Host "Size: $sizeMB MB" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "You can now transfer this APK to your Android device and install it." -ForegroundColor Yellow
} else {
    Write-Host "APK file not found at expected location: $apkPath" -ForegroundColor Red
    Write-Host "Checking for APK files..." -ForegroundColor Yellow
    
    $apkFiles = Get-ChildItem -Path (Join-Path $projectDir "build\app\outputs") -Filter "*.apk" -Recurse -ErrorAction SilentlyContinue
    if ($apkFiles) {
        Write-Host "Found APK files:" -ForegroundColor Green
        foreach ($apk in $apkFiles) {
            Write-Host "  - $($apk.FullName)" -ForegroundColor Cyan
        }
    } else {
        Write-Host "No APK files found. Build may have failed." -ForegroundColor Red
    }
}

