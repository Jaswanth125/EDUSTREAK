# Building APK for EduStreak

## Current Issue

The project path contains parentheses (`C:\EDUSTREAK(4)\EDUSTREAK\edustreak`), which causes issues when Flutter tries to call Gradle. This is a known limitation with Flutter's build system on Windows.

## Solutions

### Option 1: Build Using Android Studio (Recommended)

1. **Open Android Studio**
2. **Open the project:**
   - File → Open
   - Navigate to: `C:\EDUSTREAK(4)\EDUSTREAK\edustreak\android`
   - Click OK

3. **Wait for Gradle sync to complete**

4. **Build the APK:**
   - Build → Build Bundle(s) / APK(s) → Build APK(s)
   - Wait for the build to complete

5. **Locate the APK:**
   - After build completes, click "locate" in the notification
   - Or navigate to: `C:\EDUSTREAK(4)\EDUSTREAK\edustreak\build\app\outputs\flutter-apk\app-release.apk`

### Option 2: Move Project to Path Without Parentheses

1. **Move the project to a new location:**
   ```powershell
   # Create new directory without parentheses
   New-Item -ItemType Directory -Path "C:\EDUSTREAK\edustreak" -Force
   
   # Copy project (or move if you prefer)
   Copy-Item -Path "C:\EDUSTREAK(4)\EDUSTREAK\edustreak\*" -Destination "C:\EDUSTREAK\edustreak" -Recurse
   ```

2. **Build from new location:**
   ```powershell
   cd C:\EDUSTREAK\edustreak
   flutter build apk --release
   ```

### Option 3: Use Command Line with Workaround

Try building directly with Gradle (may still have issues):

```powershell
cd "C:\EDUSTREAK(4)\EDUSTREAK\edustreak\android"
.\gradlew.bat assembleRelease
```

**Note:** This may still fail when Gradle tries to call Flutter.

## APK Location

After successful build, the APK will be located at:
```
C:\EDUSTREAK(4)\EDUSTREAK\edustreak\build\app\outputs\flutter-apk\app-release.apk
```

## Installing on Your Phone

1. **Transfer the APK to your phone:**
   - Use USB cable
   - Use cloud storage (Google Drive, Dropbox, etc.)
   - Use email
   - Use ADB: `adb install app-release.apk`

2. **Enable installation from unknown sources:**
   - Go to Settings → Security
   - Enable "Install from unknown sources" or "Allow installation of apps from unknown sources"

3. **Install the APK:**
   - Open the APK file on your phone
   - Tap "Install"
   - Wait for installation to complete

## Troubleshooting

### Build Fails with "cannot find file specified"
- This is due to the path with parentheses
- Use Option 1 (Android Studio) or Option 2 (move project)

### Gradle Sync Fails
- Make sure Android SDK is properly installed
- Check that `ANDROID_HOME` environment variable is set
- Run `flutter doctor` to check setup

### APK Not Found
- Check `build\app\outputs\flutter-apk\` directory
- Look for `app-release.apk` or `app-debug.apk`

