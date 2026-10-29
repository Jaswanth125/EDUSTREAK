# Deploy Firebase Security Rules

The permission error you're seeing is because the Firestore security rules need to be deployed to Firebase.

## Quick Fix

You need to deploy the updated `firebase_rules.txt` file to Firebase. Here's how:

### Option 1: Using Firebase Console (Easiest)

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **edustreak-21475**
3. Click on **Firestore Database** in the left menu
4. Click on the **Rules** tab
5. Copy the contents of `firebase_rules.txt` from your project
6. Paste it into the rules editor
7. Click **Publish**

### Option 2: Using Firebase CLI

If you have Firebase CLI installed:

```bash
firebase deploy --only firestore:rules
```

Or if you need to specify the project:

```bash
firebase deploy --only firestore:rules --project edustreak-21475
```

## After Deploying Rules

1. **Refresh your app** (or restart it)
2. **Try initializing sample data again** from the Admin Dashboard
3. The permission error should be resolved

## Important Notes

- The rules allow **admin users** to write to the `store` collection
- Make sure you're logged in as an **admin user** when initializing sample data
- The admin user must have their `role` field set to `'admin'` in their user document in Firestore

## Verify Admin Role

To verify your user has admin role:

1. Go to Firebase Console → Firestore Database
2. Navigate to `users` collection
3. Find your user document (by your user ID)
4. Check that the `role` field is set to `'admin'`

If it's not set, you can manually set it:
- Click on the user document
- Edit the `role` field
- Set it to `'admin'`
- Save

Then try initializing sample data again.

