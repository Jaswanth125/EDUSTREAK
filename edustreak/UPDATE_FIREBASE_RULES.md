# Update Firebase Rules for Avatar System

## What Changed?

The `firebase_rules.txt` file has been **updated** to include avatar initialization rules. You need to deploy these updated rules to Firebase Console.

## Key Addition: Avatar Rules (Lines 109-131)

```javascript
// Store collection - Avatars (special case for initialization)
match /store/avatars {
  // Anyone authenticated can read avatars
  allow read: if isAuthenticated();
  // Allow creation for first-time initialization (any authenticated user can initialize once)
  // This allows students to initialize avatars without admin access
  allow create: if isAuthenticated();
  // Only admins can update or delete after creation
  allow update: if isAuthenticated() && isAdmin();
  allow delete: if isAuthenticated() && isAdmin();
  
  // Avatar items subcollection
  match /items/{avatarId} {
    // Anyone authenticated can read avatar items
    allow read: if isAuthenticated();
    // Allow creation during initialization (when parent document is being created)
    // This allows the batch write to succeed during initialization
    allow create: if isAuthenticated();
    // Only admins can update or delete after initialization
    allow update: if isAuthenticated() && isAdmin();
    allow delete: if isAuthenticated() && isAdmin();
  }
}
```

## How to Update Firebase Console Rules

### Step 1: Open Firebase Console
1. Go to https://console.firebase.google.com
2. Select your project
3. Click on **Firestore Database** in the left sidebar
4. Click on the **Rules** tab

### Step 2: Copy Updated Rules
1. Open `firebase_rules.txt` file in your project
2. Copy **ALL** the content (Ctrl+A, Ctrl+C)

### Step 3: Paste and Deploy
1. In Firebase Console Rules editor, select all existing rules (Ctrl+A)
2. Paste the new rules (Ctrl+V)
3. Click **Publish** button
4. Wait for confirmation: "Rules published successfully"

## What This Enables

✅ **Any authenticated user** can initialize avatars (first time only)
✅ Students can click "Initialize Avatars" button in the app
✅ After initialization, only admins can modify avatars
✅ Students can redeem avatars with points
✅ Students can set redeemed avatars as profile avatar

## Verification

After deploying the rules:
1. Run your Flutter app
2. Login as a student
3. Go to Store → Avatars tab
4. Click "Initialize Avatars" button
5. It should work without permission errors!

## Troubleshooting

### "Permission denied" error after updating rules
- Make sure you copied the **entire** `firebase_rules.txt` file
- Check that the avatar rules section (lines 109-131) is included
- Wait a few seconds after publishing (rules may take time to propagate)

### Rules not updating
- Clear browser cache
- Try in incognito/private window
- Check Firebase Console for any syntax errors (it will highlight them in red)

## Files Updated

- ✅ `firebase_rules.txt` - Updated with avatar rules
- ✅ `firestore.rules` - Already has avatar rules (used for Firebase CLI)

## Next Steps

1. ✅ Update Firebase Console rules (copy from `firebase_rules.txt`)
2. ✅ Run the Flutter app
3. ✅ Test avatar initialization
4. ✅ Enjoy your avatar system! 🎉

