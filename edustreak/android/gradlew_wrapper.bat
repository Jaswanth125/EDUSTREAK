@echo off
REM Wrapper for gradlew.bat to handle paths with parentheses
cd /d "%~dp0"
call gradlew.bat %*

