@echo off
REM Custom Edge launcher that removes --no-sandbox flag
REM This script filters out the --no-sandbox flag from Edge arguments

setlocal enabledelayedexpansion

REM Find Edge executable
set "EDGE_PATH="
if exist "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe" (
    set "EDGE_PATH=C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
) else if exist "C:\Program Files\Microsoft\Edge\Application\msedge.exe" (
    set "EDGE_PATH=C:\Program Files\Microsoft\Edge\Application\msedge.exe"
) else (
    REM Try to find Edge from PATH
    where msedge.exe >nul 2>&1
    if !errorlevel! equ 0 (
        set "EDGE_PATH=msedge.exe"
    ) else (
        echo Error: Edge not found
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
REM Launch Edge with filtered arguments
"%EDGE_PATH%" %ARGS%

