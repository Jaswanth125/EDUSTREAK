# 🚀 EduStreak - Quick Start Guide

## Setup Steps

### 1. Firebase Console Setup

1. **Enable Authentication**:
   - Go to Firebase Console → Authentication → Sign-in method
   - Enable "Email/Password"

2. **Create Firestore Database**:
   - Go to Firebase Console → Firestore Database
   - Click "Create database"
   - Start in test mode (or use rules from `firebase_rules.txt`)

3. **Publish Security Rules**:
   - Go to Firebase Console → Firestore Database → Rules
   - Copy rules from `firebase_rules.txt` and publish

4. **Enable Storage** (for file uploads):
   - Go to Firebase Console → Storage
   - Get started
   - Copy rules from `firebase_storage_rules.txt` and publish

### 2. Run the App

```bash
cd C:\Users\dasar\Downloads\EDUSTREAK
flutter pub get
flutter run -d chrome
```

### 3. Initialize Sample Data

**Option A: Via Admin Dashboard** (Recommended)
1. Sign up as admin (or use existing admin account)
2. Go to Admin Dashboard
3. Click the refresh icon (🔄) in the top right
4. Click "Initialize" to create sample data

**Option B: Create Admin Manually**
1. Sign up with email/password
2. In Firebase Console → Firestore → users collection
3. Find your user document
4. Set `role: "admin"`
5. Reload the app

### 4. Test Accounts (After Seed Data)

- **Admin**: admin@edustreak.com / admin123
- **Teacher**: teacher1@edustreak.com / teacher123
- **Student**: student1@edustreak.com / student123
- **Parent**: parent1@edustreak.com / parent123

## 🎯 Testing Features

### As Student:
1. ✅ View streak and XP
2. ✅ Complete tasks (upload proof)
3. ✅ View grades and feedback
4. ✅ Purchase avatars from store
5. ✅ Earn badges
6. ✅ Chat with teachers

### As Teacher:
1. ✅ Mark attendance
2. ✅ Assign tasks
3. ✅ Grade assignments
4. ✅ Chat with students/parents

### As Parent:
1. ✅ View child's progress
2. ✅ View child's grades
3. ✅ Chat with teacher

## 🔧 Troubleshooting

### App won't compile:
- Run `flutter clean && flutter pub get`
- Check Firebase configuration in `firebase_options.dart`

### Authentication errors:
- Verify Email/Password is enabled in Firebase Console
- Check Firebase project ID matches

### Firestore errors:
- Verify security rules are published
- Check Firestore database is created

### File upload errors:
- Verify Storage is enabled
- Check Storage rules are published

## 📝 Notes

- All data is **dynamic** and **real-time**
- No hardcoding - everything from Firebase
- Seed data creates example users/tasks for testing
- Store items are auto-initialized on first access

## 🎉 Ready to Use!

The app is fully functional with all requested features:
- ✅ Dynamic website
- ✅ Task submission with proof
- ✅ Grading system
- ✅ Points store
- ✅ Enhanced badges
- ✅ Real-time messaging
- ✅ Seed data
- ✅ All features real-time

**Enjoy testing EduStreak!** 🚀

