@echo off
REM Custom Chrome launcher that removes --no-sandbox flag
REM This script filters out the --no-sandbox flag from Chrome arguments

setlocal enabledelayedexpansion

REM Find Chrome executable
set "CHROME_PATH="
if exist "C:\Program Files\Google\Chrome\Application\chrome.exe" (
    set "CHROME_PATH=C:\Program Files\Google\Chrome\Application\chrome.exe"
) else if exist "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe" (
    set "CHROME_PATH=C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
) else (
    REM Try to find Chrome from registry or PATH
    where chrome.exe >nul 2>&1
    if !errorlevel! equ 0 (
        set "CHROME_PATH=chrome.exe"
    ) else (
        echo Error: Chrome not found
        exit /b 1
    )
)

REM Build arguments without --no-sandbox
set "ARGS="
:parse_args
if "%~1"=="" goto :end_parse
if /i not "%~1"=="--no-sandbox" (
    set "ARGS=!ARGS! %~1"
)
shift
goto :parse_args

:end_parse
REM Launch Chrome with filtered arguments
"%CHROME_PATH%" %ARGS%

