@echo off
title Study Assistant Backend Server
color 0A
echo ========================================
echo   Study Assistant Backend Server
echo   Auto-Restart Enabled
echo ========================================
echo.
echo Server URL: http://10.0.57.34:8000
echo Press Ctrl+C to stop
echo.

:restart
cd /d "%~dp0"
echo [%date% %time%] Starting backend server...
call venv\Scripts\activate.bat
python -m uvicorn backend.main:app --host 0.0.0.0 --port 8000
echo.
echo [%date% %time%] Server stopped. Restarting in 5 seconds...
timeout /t 5 /nobreak >nul
goto restart
