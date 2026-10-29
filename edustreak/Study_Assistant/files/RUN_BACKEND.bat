@echo off
cd /d "%~dp0"
echo ========================================
echo   Study Assistant Backend Server
echo ========================================
echo.
echo Starting server on http://0.0.0.0:8000
echo Phone URL: http://10.0.57.34:8000
echo.
echo This window must stay open!
echo Press Ctrl+C to stop the server
echo.
echo ========================================
echo.

call venv\Scripts\activate.bat
python -m uvicorn backend.main:app --host 0.0.0.0 --port 8000

pause

