@echo off
REM Deploy Flutter App to USB-Connected Tablet and Run Backend Server
REM This script will:
REM 1. Check for connected USB devices
REM 2. Get your computer's IP address
REM 3. Start the backend server in a separate window
REM 4. Deploy and run the Flutter app on the tablet

cd /d "%~dp0"

echo ========================================
echo   EduStreak Deployment Script
echo   Deploy to USB Tablet + Backend Server
echo ========================================
echo.

REM Check if PowerShell is available
powershell -Command "& {Get-Host}" >nul 2>&1
if errorlevel 1 (
    echo Error: PowerShell is required to run this script.
    echo Please use deploy_to_tablet.ps1 instead or install PowerShell.
    pause
    exit 1
)

REM Run the PowerShell script
powershell -ExecutionPolicy Bypass -File "%~dp0deploy_to_tablet.ps1"

pause



