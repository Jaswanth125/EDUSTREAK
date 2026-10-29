# Flutter Command Setup for PowerShell

## Issue
When running Flutter commands in PowerShell, you may see warnings like:
```
'DIR /B /O:D "..."' is not recognized as an internal or external command
```

This is a known issue with Flutter's batch file when executed from PowerShell. The commands still work, but the warnings are annoying.

## Solutions

### Option 1: Use the Helper Script (Recommended)
Use the `run_flutter.ps1` script to run Flutter commands:

```powershell
.\run_flutter.ps1 devices
.\run_flutter.ps1 run -d chrome
.\run_flutter.ps1 build web
```

**Note:** If you encounter issues with the `-d` flag being interpreted incorrectly, use the `--` separator:
```powershell
.\run_flutter.ps1 -- run -d chrome
```

### Option 2: Use cmd /c Directly
Run Flutter commands through cmd:

```powershell
cmd /c "C:\src\flutter\bin\flutter.bat devices"
cmd /c "C:\src\flutter\bin\flutter.bat run -d chrome"
```

### Option 3: Add to PowerShell Profile
1. Open your PowerShell profile:
   ```powershell
   notepad $PROFILE
   ```

2. Add this function:
   ```powershell
   function flutter {
       param([Parameter(ValueFromRemainingArguments=$true)][string[]]$args)
       $FlutterPath = "C:\src\flutter\bin\flutter.bat"
       $ProjectDir = "C:\EDUSTREAK(4)\EDUSTREAK\edustreak"
       Push-Location $ProjectDir
       try {
           cmd /c "`"$FlutterPath`" $($args -join ' ')" 2>&1 | Where-Object { 
               $_ -notmatch "DIR /B /O:D" -and 
               $_ -notmatch "is not recognized" 
           }
       }
       finally {
           Pop-Location
       }
   }
   ```

3. Reload your profile:
   ```powershell
   . $PROFILE
   ```

4. Now you can use `flutter` directly:
   ```powershell
   flutter devices
   flutter run -d chrome
   ```

## Current Flutter Installation
- Path: `C:\src\flutter\bin\flutter.bat`
- Project: `C:\EDUSTREAK(4)\EDUSTREAK\edustreak`

## Fixing Chrome --no-sandbox Warning

If you see a warning about `--no-sandbox` when running Flutter in Chrome, you have two options:

### Option 1: Use Edge Browser (Recommended - No Warning)
Edge browser doesn't show the `--no-sandbox` warning:

```powershell
# Use the Edge-specific script
.\run_flutter_edge.ps1 run

# Or manually specify Edge
.\run_flutter.ps1 run -d edge
```

### Option 2: Use Chrome with HTML Renderer
The script automatically adds `--web-renderer html` when using Chrome, which may reduce the warning:

```powershell
.\run_flutter.ps1 run -d chrome
```

**Note:** The `--no-sandbox` warning is harmless for development but indicates reduced security. For production builds, this flag is not used.

## Quick Commands

```powershell
# Check devices
.\run_flutter.ps1 devices

# Run on Chrome (may show --no-sandbox warning)
.\run_flutter.ps1 run -d chrome
# If you have issues with -d flag, use:
.\run_flutter.ps1 -- run -d chrome

# Run on Edge (no warning - recommended)
.\run_flutter_edge.ps1 run
# OR
.\run_flutter.ps1 run -d edge

# Run on Windows desktop
.\run_flutter.ps1 run -d windows

# Build for web
.\run_flutter.ps1 build web

# Get dependencies
.\run_flutter.ps1 pub get

# Check Flutter setup
.\run_flutter.ps1 doctor
```

## Troubleshooting

### "Target file 'chrome' not found" Error
If you see this error, it means the `-d` flag is being lost. Try using the `--` separator:
```powershell
.\run_flutter.ps1 -- run -d chrome
```

### Arguments Not Being Passed Correctly
The script now properly handles all Flutter arguments. If you still have issues:
1. Use the `--` separator: `.\run_flutter.ps1 -- [your-flutter-command]`
2. Check that you're in the correct directory
3. Verify Flutter is installed at `C:\src\flutter\bin\flutter.bat`

