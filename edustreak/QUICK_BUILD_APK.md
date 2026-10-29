# Quick APK Build Solution

## The Problem
Your project path `C:\EDUSTREAK(4)\EDUSTREAK\edustreak` contains parentheses `(4)`, which causes Flutter's build system to fail when Gradle tries to call Flutter.

## EASIEST SOLUTION - Use Android Studio (5 minutes)

1. **Open Android Studio**
2. **File → Open**
3. Navigate to and select: `C:\EDUSTREAK(4)\EDUSTREAK\edustreak\android`
4. Wait for Gradle sync (first time may take a few minutes)
5. **Build → Build Bundle(s) / APK(s) → Build APK(s)**
6. Wait for build to complete (5-10 minutes)
7. When done, click **"locate"** in the notification, or find the APK at:
   ```
   C:\EDUSTREAK(4)\EDUSTREAK\edustreak\build\app\outputs\flutter-apk\app-release.apk
   ```

**That's it!** Android Studio handles the path issues automatically.

## Alternative: Move Project (10 minutes)

If you prefer command line:

1. **Create new folder without parentheses:**
   ```powershell
   New-Item -ItemType Directory -Path "C:\EDUSTREAK" -Force
   ```

2. **Copy project:**
   ```powershell
   Copy-Item -Path "C:\EDUSTREAK(4)\EDUSTREAK\edustreak\*" -Destination "C:\EDUSTREAK\edustreak" -Recurse -Force
   ```

3. **Build APK:**
   ```powershell
   cd C:\EDUSTREAK\edustreak
   flutter build apk --release
   ```

4. **APK will be at:**
   ```
   C:\EDUSTREAK\edustreak\build\app\outputs\flutter-apk\app-release.apk
   ```

## After Building

Transfer the APK to your phone and install it:
- USB cable + File Explorer
- Google Drive / Dropbox
- Email to yourself
- ADB: `adb install app-release.apk`

Enable "Install from unknown sources" in your phone's security settings first!

