# Firestore Security Rules Setup

## Issue
You're getting `permission-denied` error when trying to upload badges because Firestore security rules don't allow writes to `store/badges`.

## Solution

### Option 1: Update Rules in Firebase Console (Recommended)

1. **Go to Firebase Console**
   - Visit: https://console.firebase.google.com
   - Select your project: `edustreak-21475`

2. **Navigate to Firestore Database**
   - Click on "Firestore Database" in the left menu
   - Click on the "Rules" tab

3. **Copy and Paste the Rules**
   - Open `firestore.rules` file in this project
   - Copy all the content
   - Paste it into the Firebase Console Rules editor
   - Click "Publish"

### Option 2: Deploy Rules via Firebase CLI

If you have Firebase CLI installed:

```bash
firebase deploy --only firestore:rules
```

## What the Rules Allow

✅ **Store/Badges Collection:**
- **Read**: Any authenticated user can read badges
- **Write/Create/Update/Delete**: Only admins can modify badges

✅ **Users Collection:**
- Users can read/update their own data
- Only admins can create/delete users

✅ **Other Collections:**
- Tasks, Messages, Challenges follow role-based access
- Students can read tasks assigned to them
- Teachers can create/update tasks
- Admins have full access

## Testing

After updating rules:
1. Make sure you're logged in as **ADMIN**
2. Try uploading badges again
3. Should work without permission errors!

## Important Notes

- Rules take effect immediately after publishing
- Make sure your user account has `role: 'admin'` in Firestore
- Check: `users/{yourUserId}` document should have `role: 'admin'`

