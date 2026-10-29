# Flutter Command Helper Script for PowerShell - Using Edge Browser
# Edge browser doesn't show the --no-sandbox warning

param(
    [Parameter(ValueFromRemainingArguments=$true)]
    [string[]]$FlutterArgs
)

$FlutterPath = "C:\src\flutter\bin\flutter.bat"

if (-not (Test-Path $FlutterPath)) {
    Write-Host "Error: Flutter not found at $FlutterPath" -ForegroundColor Red
    Write-Host "Please update the FlutterPath variable in this script." -ForegroundColor Yellow
    exit 1
}

# Change to the Flutter project directory
$ProjectDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ProjectDir

# Replace chrome with edge if specified, or add edge as default
if ($FlutterArgs -contains "-d") {
    $deviceIndex = $FlutterArgs.IndexOf("-d")
    if ($deviceIndex -ge 0 -and $deviceIndex -lt ($FlutterArgs.Length - 1)) {
        if ($FlutterArgs[$deviceIndex + 1] -eq "chrome") {
            $FlutterArgs[$deviceIndex + 1] = "edge"
            Write-Host "Using Edge browser instead of Chrome to avoid --no-sandbox warning" -ForegroundColor Green
        }
    }
} else {
    # Add edge as default device
    $FlutterArgs = $FlutterArgs + "-d", "edge"
    Write-Host "Using Edge browser (no --no-sandbox warning)" -ForegroundColor Green
}

# Run Flutter command using cmd to avoid PowerShell issues
$command = "`"$FlutterPath`" $($FlutterArgs -join ' ')"
Write-Host "Running: flutter $($FlutterArgs -join ' ')" -ForegroundColor Cyan
Write-Host ""

# Use cmd /c to run the command and suppress the DIR warning
$output = cmd /c $command 2>&1 | Where-Object { $_ -notmatch "DIR /B /O:D" -and $_ -notmatch "is not recognized as an internal or external command" }
$output

# Check exit code
if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne $null) {
    exit $LASTEXITCODE
}

