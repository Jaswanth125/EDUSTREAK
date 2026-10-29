# How to Build APK for EduStreak

## Quick Steps to Build APK

### Option 1: Install NDK via Android Studio (Recommended)

1. **Open Android Studio**
2. **Go to Tools → SDK Manager** (or File → Settings → Appearance & Behavior → System Settings → Android SDK)
3. **Click on the "SDK Tools" tab**
4. **Check the box for "NDK (Side by side)"**
5. **Select version 27.0.12077973** (or latest available)
6. **Click "Apply" and wait for installation to complete**

### Option 2: Install NDK via Command Line

If you have SDK command-line tools installed:

```bash
cd C:\Users\dasar\AppData\Local\Android\sdk
sdkmanager "ndk;27.0.12077973"
```

### Build the APK

After NDK is installed, run:

```bash
cd C:\Users\dasar\Downloads\EDUSTREAK
flutter clean
flutter build apk --release
```

The APK will be located at:
```
build/app/outputs/flutter-apk/app-release.apk
```

### Alternative: Build Split APKs (Smaller file size)

```bash
flutter build apk --split-per-abi
```

This creates separate APKs for different CPU architectures:
- `app-armeabi-v7a-release.apk` (32-bit)
- `app-arm64-v8a-release.apk` (64-bit)
- `app-x86_64-release.apk` (x86_64)

### Build Debug APK (Faster, but larger)

If you just need a test APK:

```bash
flutter build apk --debug
```

Debug APK location:
```
build/app/outputs/flutter-apk/app-debug.apk
```

## Troubleshooting

### If NDK installation fails:
1. Make sure you have internet connection
2. Try installing via Android Studio instead
3. Check Android SDK path in `android/local.properties`

### If build still fails:
1. Run `flutter clean`
2. Run `flutter pub get`
3. Check `flutter doctor` for any issues
4. Make sure Java/JDK is properly configured

## Current Status

- ✅ Flutter setup complete
- ✅ Android SDK configured
- ⚠️ NDK not installed (required for build)
- ✅ Firebase configured
- ✅ All dependencies installed

