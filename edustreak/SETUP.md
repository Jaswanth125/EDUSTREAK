# EduStreak Setup Guide

## Prerequisites

1. **Flutter SDK** (>=3.0.0)
   - Install from [flutter.dev](https://flutter.dev/docs/get-started/install)
   - Verify: `flutter doctor`

2. **Firebase Project**
   - Create a project at [Firebase Console](https://console.firebase.google.com/)
   - Enable the following services:
     - Authentication (Email/Password)
     - Cloud Firestore
     - Firebase Storage
     - Firebase Cloud Messaging (FCM)
     - Firebase Analytics

3. **Android Studio / Xcode** (for mobile development)

## Firebase Setup

### 1. Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add Project"
3. Enter project name: "EduStreak"
4. Follow the setup wizard

### 2. Enable Authentication

1. In Firebase Console, go to **Authentication** > **Sign-in method**
2. Enable **Email/Password** provider
3. Save

### 3. Create Firestore Database

1. Go to **Firestore Database** > **Create Database**
2. Start in **production mode** (we'll add rules later)
3. Choose a location
4. Create

### 4. Add Security Rules

1. Go to **Firestore Database** > **Rules**
2. Copy the contents from `firebase_rules.txt`
3. Paste and **Publish**

### 5. Enable Firebase Storage

1. Go to **Storage** > **Get Started**
2. Start in **production mode**
3. Choose a location
4. Create

### 6. Enable Firebase Cloud Messaging

1. Go to **Cloud Messaging** in Firebase Console
2. FCM is automatically enabled

### 7. Download Configuration Files

#### Android:
1. Click the gear icon next to Project Overview
2. Select **Project settings**
3. Scroll to "Your apps"
4. Click **Add app** > **Android**
5. Enter package name: `com.edustreak.app` (or your package name)
6. Download `google-services.json`
7. Place it in `android/app/`

#### iOS:
1. In Project settings, click **Add app** > **iOS**
2. Enter bundle ID: `com.edustreak.app` (or your bundle ID)
3. Download `GoogleService-Info.plist`
4. Place it in `ios/Runner/` (via Xcode)

## Flutter Setup

### 1. Install Dependencies

```bash
cd edustreak
flutter pub get
```

### 2. Firebase CLI Setup

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Firebase in your project
firebase init
```

Select:
- Firestore
- Functions
- Storage (optional)

### 3. Configure Firebase for Flutter

```bash
# Install Firebase CLI tools
dart pub global activate flutterfire_cli

# Configure Firebase
flutterfire configure
```

Follow the prompts to select your Firebase project.

## Cloud Functions Setup

### 1. Navigate to Functions Directory

```bash
cd cloud_functions
```

### 2. Install Dependencies

```bash
npm install
```

### 3. Deploy Functions

```bash
firebase deploy --only functions
```

## Running the App

### Android

```bash
flutter run
```

### iOS

```bash
flutter run
```

### Web

```bash
flutter run -d chrome
```

## Testing

### Create Test Users

1. Use the sign-up screen to create test users:
   - Student account
   - Teacher account
   - Parent account (link to student via `childId`)
   - Admin account

### Test Flow

1. **Student**: Login → View streak → Check tasks → View leaderboard
2. **Teacher**: Login → Mark attendance → Assign task → View students
3. **Parent**: Login → View child progress → Chat with teacher
4. **Admin**: Login → View analytics → Manage users → Manage classes

## Troubleshooting

### Firebase Connection Issues

- Verify `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) are in correct locations
- Check Firebase project configuration
- Verify internet connection

### Build Errors

```bash
flutter clean
flutter pub get
flutter run
```

### Firestore Rules Errors

- Verify rules are published in Firebase Console
- Check rule syntax in `firebase_rules.txt`

### Cloud Functions Not Working

- Check Firebase Functions logs: `firebase functions:log`
- Verify functions are deployed: `firebase functions:list`
- Check Node.js version (should be 18+)

## Production Deployment

### Android

1. Generate signed APK/AAB:
```bash
flutter build appbundle
```

2. Upload to Google Play Console

### iOS

1. Build for release:
```bash
flutter build ios --release
```

2. Archive and upload via Xcode

### Web

1. Build for web:
```bash
flutter build web
```

2. Deploy to Firebase Hosting or your preferred hosting

## Additional Configuration

### FCM Notifications

1. For Android: Add FCM server key to Firebase Console
2. For iOS: Upload APNs certificate to Firebase Console

### Analytics

Firebase Analytics is automatically enabled. View analytics in Firebase Console.

## Support

For issues or questions:
1. Check Firebase Console for error logs
2. Review Flutter logs: `flutter logs`
3. Check Cloud Functions logs: `firebase functions:log`

