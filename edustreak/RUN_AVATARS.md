# How to Run and Test the Avatar System

## Prerequisites

1. ✅ Flutter SDK installed and in PATH
2. ✅ Firebase project configured
3. ✅ Firestore rules deployed (updated rules allow avatar initialization)
4. ✅ Assets file exists: `assets/store_avatars.json`

## Step 1: Navigate to Project Directory

```bash
cd P:\EDUSTREAK\EDUSTREAK
```

## Step 2: Get Dependencies

```bash
flutter pub get
```

## Step 3: Verify Assets

Make sure `pubspec.yaml` includes:
```yaml
assets:
  - assets/store_badges.json
  - assets/store_avatars.json
```

## Step 4: Deploy Firestore Rules (IMPORTANT)

**Before running the app, you MUST deploy the updated Firestore rules:**

1. Go to Firebase Console → Firestore Database → Rules
2. Copy the contents from `firestore.rules`
3. Paste and Deploy

**OR** use Firebase CLI:
```bash
firebase deploy --only firestore:rules
```

The updated rules allow any authenticated user to create avatars (one-time initialization).

## Step 5: Run the App

```bash
# For Android
flutter run

# For a specific device
flutter devices
flutter run -d <device-id>

# For Android emulator
flutter run -d emulator
```

## Step 6: Test Avatar System

1. **Login as a Student**
   - Use your student credentials to log in

2. **Navigate to Store**
   - From the student dashboard, tap on the "Store" card
   - You should see two tabs: "Avatars" and "Badges"

3. **Initialize Avatars (First Time Only)**
   - If no avatars exist, you'll see an "Initialize Avatars" button
   - Tap the button to upload 30 avatars to Firestore
   - Wait for the success message

4. **View Avatars**
   - After initialization, you'll see a grid of 30 avatars
   - Each avatar shows:
     - Emoji icon
     - Name
     - Description
     - Category
     - Price in points

5. **Redeem an Avatar**
   - Tap on an avatar you can afford (check your points)
   - Confirm the redemption
   - Points will be deducted
   - Avatar will be added to your redeemed avatars

6. **Set as Profile Avatar**
   - After redeeming, tap "Set as Avatar" button
   - The avatar will become your profile avatar
   - You'll see a blue border around the active avatar

## Troubleshooting

### Error: "Permission denied"
- **Solution**: Make sure Firestore rules are deployed
- Check that you're logged in as an authenticated user
- Verify the rules in `firestore.rules` allow avatar creation

### Error: "Avatar data file not found"
- **Solution**: 
  - Verify `assets/store_avatars.json` exists
  - Run `flutter pub get`
  - Rebuild the app: `flutter clean && flutter pub get && flutter run`

### Error: "Avatars already exist"
- This means avatars were already initialized
- Only admins can modify avatars after initialization
- You can still redeem and use avatars

### Avatars not showing after initialization
- Refresh the store screen
- Check Firestore console to verify avatars were uploaded
- Check network connection

### Flutter not found
- Make sure Flutter SDK is installed
- Add Flutter to your PATH
- Restart your terminal/IDE

## Expected Behavior

✅ Store screen shows "Avatars" tab with face icon
✅ "Initialize Avatars" button appears when no avatars exist
✅ After initialization, 30 avatars appear in a grid
✅ Each avatar shows icon, name, description, category, and price
✅ Redeemed avatars show green border
✅ Active avatar shows blue border
✅ Points are deducted when redeeming
✅ Can set redeemed avatars as profile avatar

## Files Modified

- ✅ `firestore.rules` - Updated to allow avatar initialization
- ✅ `lib/services/avatar_service.dart` - Avatar service with initialization
- ✅ `lib/screens/student/store_screen.dart` - Store screen with avatar tab
- ✅ `lib/models/user_model.dart` - Added `redeemedAvatars` field
- ✅ `lib/services/store_service.dart` - Added avatar methods
- ✅ `assets/store_avatars.json` - 30 motivational avatars
- ✅ `pubspec.yaml` - Added avatar assets

## Next Steps

1. Deploy Firestore rules
2. Run the app
3. Initialize avatars
4. Test redemption
5. Enjoy your new avatar system! 🎉

