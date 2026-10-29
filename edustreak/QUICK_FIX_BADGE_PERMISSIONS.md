# Quick Fix: Badge Upload Permission Error

## The Problem
You're getting `[cloud_firestore/permission-denied]` when trying to upload badges.

## Solution: Update Firestore Rules

The rules file has been updated to allow admins to write to `store/badges`. You need to deploy these rules to Firebase.

### Step 1: Copy Updated Rules

The file `firebase_rules.txt` has been updated with badge permissions. Copy its entire contents.

### Step 2: Deploy to Firebase Console

1. **Go to Firebase Console**: https://console.firebase.google.com/
2. **Select your project**: `edustreak-21475`
3. **Open Firestore Database** → Click **Rules** tab
4. **Copy all content** from `firebase_rules.txt` in your project
5. **Paste** into the Firebase Console rules editor
6. **Click Publish** button

### Step 3: Verify Admin Role

Make sure you're logged in as an admin:
1. Go to Firebase Console → Firestore Database
2. Navigate to `users` collection
3. Find your user document (by your user ID)
4. Check that the `role` field is set to `'admin'`

If it's not:
- Click on the user document
- Edit the `role` field
- Set it to `'admin'`
- Save

### Step 4: Retry Upload

1. **Refresh your Flutter app** (hot reload or restart)
2. **Make sure you're logged in as admin**
3. **Go to Admin Dashboard**
4. **Click badge icon**
5. **Click "Upload Badges to Firestore"**
6. Should work now! ✅

## What Changed

Added specific rules for `store/badges`:
- ✅ **Read**: Any authenticated user can read badges
- ✅ **Write/Create/Update/Delete**: Only admins can modify badges
- ✅ **Subcollection**: `store/badges/items/{badgeId}` has same permissions

## Alternative: Temporary Test Mode (Development Only)

If you want to test quickly, you can temporarily use these rules (⚠️ **NOT for production**):

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

⚠️ **WARNING**: This allows any authenticated user to read/write everything. Only use for testing!

After testing, switch back to the proper rules from `firebase_rules.txt`.

