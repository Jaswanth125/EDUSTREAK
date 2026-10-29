# 🔥 Firebase Setup Checklist

## ✅ Pre-Configuration Steps

### 1. Firebase Console Setup
Go to [Firebase Console](https://console.firebase.google.com/) and select your project `edustreak-f6fd8`

#### Authentication
- [ ] Go to **Authentication** → **Sign-in method**
- [ ] Click on **Email/Password**
- [ ] Toggle **Enable** → **Save**

#### Firestore Database
- [ ] Go to **Firestore Database**
- [ ] Click **Create Database**
- [ ] Choose **Start in production mode** (we'll add rules later)
- [ ] Select a **location** (choose closest to your users)
- [ ] Click **Enable**

#### Firebase Storage (OPTIONAL - Skip for now)
- [ ] ⏭️ **SKIPPING** - Storage is optional
- [ ] Can be enabled later if needed for profile images/attachments
- [ ] App works perfectly without Storage

#### Cloud Messaging (FCM)
- [ ] FCM is automatically enabled
- [ ] No additional setup needed

### 2. Firestore Security Rules
- [ ] Go to **Firestore Database** → **Rules** tab
- [ ] Copy contents from `firebase_rules.txt` in your project
- [ ] Paste into the rules editor
- [ ] Click **Publish**

### 3. Firebase CLI Authentication
Open a terminal and run:
```bash
firebase login
```
- [ ] Sign in with your Google account
- [ ] Grant permissions when prompted
- [ ] Verify: Run `firebase projects:list` to see your project

## 🔧 FlutterFire Configuration

After Firebase CLI authentication, run:

```bash
cd C:\Users\dasar\Downloads\EDUSTREAK
dart pub global run flutterfire_cli:flutterfire configure --project=edustreak-21475
```

### What to expect:
1. It will prompt you to select platforms:
   - ✅ Android
   - ✅ iOS (if developing for iOS)
   - ✅ Web (if developing for web)
   - Select the platforms you need

2. It will generate:
   - `lib/firebase_options.dart` ✅ (Already updated main.dart to use this)
   - Platform-specific config files

## 📱 Platform-Specific Setup

### Android
- [ ] Verify `android/app/google-services.json` exists
- [ ] If missing, download from Firebase Console:
  - Project Settings → Your apps → Android app
  - Download `google-services.json`
  - Place in `android/app/` directory

### iOS
- [ ] Verify `ios/Runner/GoogleService-Info.plist` exists
- [ ] If missing, download from Firebase Console:
  - Project Settings → Your apps → iOS app
  - Download `GoogleService-Info.plist`
  - Add to Xcode project in `ios/Runner/`

## 🧪 Testing

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Run the App
```bash
flutter run
```

### 3. Test Authentication
- [ ] Create a test account via sign-up screen
- [ ] Verify user appears in Firebase Console → Authentication
- [ ] Verify user document created in Firestore → users collection

## 🐛 Troubleshooting

### If FlutterFire configure fails:
1. Make sure `firebase login` completed successfully
2. Verify project ID: `edustreak-f6fd8`
3. Check internet connection
4. Try running: `firebase projects:list` to verify access

### If app crashes on startup:
1. Verify `firebase_options.dart` exists in `lib/` directory
2. Check `main.dart` imports `firebase_options.dart`
3. Verify platform-specific config files are in place
4. Run `flutter clean` then `flutter pub get`

### If Firestore rules error:
1. Verify rules are published in Firebase Console
2. Check rule syntax matches `firebase_rules.txt`
3. Ensure user is authenticated before accessing Firestore

## ✅ Final Checklist

- [ ] Firebase CLI authenticated
- [ ] FlutterFire configure completed
- [ ] `firebase_options.dart` generated
- [ ] `main.dart` updated to use Firebase options
- [ ] Firestore rules published
- [ ] Authentication enabled (Email/Password)
- [ ] Firestore database created
- [ ] Firebase Storage (skipped - optional)
- [ ] Platform config files in place (Android/iOS)
- [ ] App runs without errors
- [ ] Can create user account
- [ ] User appears in Firestore

## 📚 Next Steps

1. **Deploy Cloud Functions** (optional):
   ```bash
   cd cloud_functions
   npm install
   firebase deploy --only functions
   ```

2. **Test All Features**:
   - Student sign-up and login
   - Teacher attendance marking
   - Parent chat with teacher
   - Admin analytics

3. **Production Deployment**:
   - Review security rules
   - Set up proper error handling
   - Configure production Firebase project
   - Build release APK/AAB

