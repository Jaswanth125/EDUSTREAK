# Flutter Command Helper Script for PowerShell
# This script helps run Flutter commands without the DIR command warnings
# Usage: .\run_flutter.ps1 run -d chrome
#        .\run_flutter.ps1 -- run -d chrome  (if you have issues with -d being interpreted)

param(
    [Parameter(ValueFromRemainingArguments=$true)]
    [string[]]$FlutterArgs
)

# If no arguments provided, show usage
if ($FlutterArgs.Count -eq 0) {
    Write-Host "Usage: .\run_flutter.ps1 [flutter-arguments]" -ForegroundColor Yellow
    Write-Host "Example: .\run_flutter.ps1 run -d chrome" -ForegroundColor Yellow
    Write-Host "Example: .\run_flutter.ps1 -- run -d chrome  (if -d causes issues)" -ForegroundColor Yellow
    exit 1
}

# Remove '--' if it's the first argument (used to separate script args from Flutter args)
if ($FlutterArgs[0] -eq "--") {
    $FlutterArgs = $FlutterArgs[1..($FlutterArgs.Length - 1)]
}

$FlutterPath = "C:\src\flutter\bin\flutter.bat"

if (-not (Test-Path $FlutterPath)) {
    Write-Host "Error: Flutter not found at $FlutterPath" -ForegroundColor Red
    Write-Host "Please update the FlutterPath variable in this script." -ForegroundColor Yellow
    exit 1
}

# Change to the Flutter project directory
$ProjectDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ProjectDir

# Debug: Show received arguments
# Write-Host "Received arguments: $($FlutterArgs -join ', ')" -ForegroundColor Yellow

# Use custom browser launcher to remove --no-sandbox flag
$deviceIndex = -1
for ($i = 0; $i -lt $FlutterArgs.Length; $i++) {
    if ($FlutterArgs[$i] -eq "-d" -or $FlutterArgs[$i] -eq "--device") {
        $deviceIndex = $i
        break
    }
}

if ($deviceIndex -ge 0 -and $deviceIndex -lt ($FlutterArgs.Length - 1)) {
    $deviceName = $FlutterArgs[$deviceIndex + 1]
    if ($deviceName -eq "chrome" -or $deviceName -eq "edge") {
        # Use custom launcher to remove --no-sandbox flag
        $launcherPath = Join-Path $ProjectDir "edge_launcher.bat"
        if (Test-Path $launcherPath) {
            $env:CHROME_EXECUTABLE = $launcherPath
            if ($deviceName -eq "chrome") {
                $FlutterArgs[$deviceIndex + 1] = "edge"
                Write-Host "Using Edge with custom launcher to remove --no-sandbox warning" -ForegroundColor Green
            } else {
                Write-Host "Using custom Edge launcher to remove --no-sandbox warning" -ForegroundColor Green
            }
        } else {
            # Fallback: switch Chrome to Edge
            if ($deviceName -eq "chrome") {
                $FlutterArgs[$deviceIndex + 1] = "edge"
                Write-Host "Switched to Edge browser" -ForegroundColor Yellow
            }
        }
    }
}

# Build command with proper argument escaping
$argList = @()
foreach ($arg in $FlutterArgs) {
    # Quote arguments that contain spaces or special characters
    if ($arg -match '\s' -or $arg -match '[()]') {
        $argList += "`"$arg`""
    } else {
        $argList += $arg
    }
}

$command = "`"$FlutterPath`" $($argList -join ' ')"
Write-Host "Running: flutter $($FlutterArgs -join ' ')" -ForegroundColor Cyan
Write-Host ""

# Use cmd /c to run the command and suppress the DIR warning
$output = cmd /c $command 2>&1 | Where-Object { $_ -notmatch "DIR /B /O:D" -and $_ -notmatch "is not recognized as an internal or external command" }
$output

# Check exit code
if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne $null) {
    exit $LASTEXITCODE
}

