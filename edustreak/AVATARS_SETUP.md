# Avatar System Setup Guide

## Overview
The avatar system allows students to redeem motivational avatars with points, similar to the badge system. Avatars are stored in Firestore and can be initialized directly from the app.

## Initial Setup

### Option 1: Initialize from App (Recommended - No Firestore Access Needed)

1. **Open the Store Screen** in the student app
2. **Click "Initialize Avatars"** button (shown when no avatars exist)
3. The app will automatically upload 30 avatars from the JSON file to Firestore
4. Once initialized, students can start redeeming avatars with points

**Note:** This only works once. After initialization, only admins can modify avatars.

### Option 2: Initialize via Firebase Console (If you have admin access)

1. Go to Firebase Console → Firestore Database
2. Navigate to `store` collection
3. Create a document with ID: `avatars`
4. Add field: `avatars` (type: array)
5. Copy the JSON array from `assets/store_avatars.json` and paste it
6. Add fields: `totalCount` (number), `version` (string: "1.0")

### Option 3: Using Firebase Admin SDK

```javascript
// upload_avatars_to_firestore.js
const admin = require('firebase-admin');
const avatars = require('./store_avatars.json');

admin.initializeApp({
  credential: admin.credential.cert(require('./service-account-key.json'))
});

const db = admin.firestore();

async function uploadAvatars() {
  const avatarsRef = db.collection('store').doc('avatars');
  
  // Upload as array
  await avatarsRef.set({
    avatars: avatars,
    totalCount: avatars.length,
    lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
    version: '1.0',
  });
  
  // Also upload as individual documents
  const batch = db.batch();
  const itemsRef = avatarsRef.collection('items');
  
  avatars.forEach(avatar => {
    const avatarRef = itemsRef.doc(avatar.avatarId);
    batch.set(avatarRef, {
      ...avatar,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });
  
  await batch.commit();
  console.log(`✅ Uploaded ${avatars.length} avatars!`);
}

uploadAvatars();
```

## Firestore Security Rules

The Firestore rules have been updated to allow:
- **Any authenticated user** to create the `store/avatars` document (first-time initialization only)
- **Any authenticated user** to read avatars
- **Only admins** to update or delete avatars after creation

Rules are in `firestore.rules`:
```javascript
match /store/avatars {
  allow read: if isAuthenticated();
  allow create: if isAuthenticated(); // Allows first-time initialization
  allow update: if isAdmin();
  allow delete: if isAdmin();
  
  match /items/{avatarId} {
    allow read: if isAuthenticated();
    allow create: if isAuthenticated(); // During initialization
    allow update: if isAdmin();
    allow delete: if isAdmin();
  }
}
```

## Avatar Structure

Each avatar contains:
- `avatarId`: Unique identifier
- `name`: Display name
- `description`: Motivational description
- `category`: Category (Motivation, Achievement, Streaks, etc.)
- `price`: Points cost (200-1200)
- `icon`: Emoji icon
- `iconUrl`: Placeholder icon URL

## How It Works

1. **Redeeming Avatars**: Students can redeem avatars with points (same process as badges)
2. **Setting Avatar**: After redemption, students can set the avatar as their profile avatar
3. **Points Deduction**: Points are deducted when an avatar is redeemed
4. **Tracking**: Redeemed avatars are stored in the user's `redeemedAvatars` field

## Troubleshooting

### "Permission denied" Error
- Make sure you're logged in as an authenticated user
- Check Firestore rules are deployed
- If avatars already exist, only admins can modify them

### "Avatar data file not found" Error
- Make sure `assets/store_avatars.json` exists
- Check `pubspec.yaml` includes the assets file
- Run `flutter pub get` and rebuild the app

### Avatars not showing after initialization
- Refresh the store screen
- Check Firestore console to verify avatars were uploaded
- Check network connection

## Features

- ✅ 30 motivational avatars
- ✅ Categories: Motivation, Achievement, Streaks, Personal Growth, Skills, Adventure, Inspiration
- ✅ Price range: 200-1200 points
- ✅ Real-time updates
- ✅ Set as profile avatar
- ✅ Same process as badges (no storage needed)

