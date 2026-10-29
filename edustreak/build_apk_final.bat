@echo off
REM Build APK script that handles path with parentheses
cd /d "%~dp0"
set ANDROID_HOME=C:\Users\jaswa\AppData\Local\Android\sdk
set FLUTTER_ROOT=C:\src\flutter

echo Building EduStreak APK...
echo.

echo Step 1: Cleaning...
call "C:\src\flutter\bin\flutter.bat" clean >nul 2>&1

echo Step 2: Getting dependencies...
call "C:\src\flutter\bin\flutter.bat" pub get >nul 2>&1

echo Step 3: Building APK (this may take 5-10 minutes)...
echo.

cd android
call gradlew.bat assembleRelease --no-daemon

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ✓ APK built successfully!
    echo.
    cd ..
    if exist "build\app\outputs\flutter-apk\app-release.apk" (
        for %%F in ("build\app\outputs\flutter-apk\app-release.apk") do (
            echo Location: %%~fF
            echo Size: %%~zF bytes
        )
        echo.
        echo APK is ready! You can find it in:
        echo build\app\outputs\flutter-apk\app-release.apk
    ) else (
        echo APK file not found. Checking for any APK files...
        dir /s /b build\app\outputs\*.apk 2>nul
    )
) else (
    echo.
    echo Build failed. Please check the error messages above.
    echo.
    echo Alternative: Use Android Studio to build the APK
    echo 1. Open Android Studio
    echo 2. Open: %~dp0android
    echo 3. Build -^> Build Bundle(s) / APK(s) -^> Build APK(s)
)

pause

