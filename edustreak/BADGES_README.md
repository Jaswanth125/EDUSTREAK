# Store Badges System

## Overview
This file contains 70 badges ready for upload to Firestore under `store/badges`.

## Badge Categories Distribution

- **Attendance**: 5 badges (300-1200 points)
- **Learning Streaks**: 6 badges (150-2000 points)
- **Assignments**: 5 badges (250-1000 points)
- **Quiz**: 6 badges (100-1200 points)
- **Motivation**: 6 badges (100-700 points)
- **AI Learning**: 7 badges (200-1500 points)
- **Community**: 6 badges (300-1000 points)
- **Special Achievements**: 12 badges (200-2000 points)
- **Additional Mixed**: 17 badges (various categories)

**Total: 70 badges**

## Price Range
- Minimum: 100 points
- Maximum: 2000 points
- Average: ~650 points

## Upload Instructions

### Option 1: Using Firebase Console
1. Go to Firebase Console → Firestore Database
2. Create collection: `store`
3. Create document: `badges`
4. Add field: `badges` (type: array)
5. Copy the JSON array from `store_badges.json` and paste it

### Option 2: Using Firebase Admin SDK (Node.js)
```bash
npm install firebase-admin
node upload_badges_to_firestore.js
```

### Option 3: Using Flutter/Dart
```dart
// In your Flutter app
final badges = jsonDecode(await rootBundle.loadString('assets/store_badges.json'));
final batch = FirebaseFirestore.instance.batch();
final badgesRef = FirebaseFirestore.instance.collection('store').doc('badges');

for (var badge in badges) {
  batch.set(
    badgesRef.collection('items').doc(badge['badgeId']),
    badge,
  );
}
await batch.commit();
```

## Badge Structure
Each badge contains:
- `badgeId`: Unique identifier (lowercase with underscores)
- `name`: Display name
- `description`: Friendly description
- `category`: One of 8 categories
- `price`: Points cost (100-2000)
- `iconUrl`: Placeholder icon URL

## Integration with Flutter App

### Fetching Badges
```dart
final badgesSnapshot = await FirebaseFirestore.instance
    .collection('store')
    .doc('badges')
    .get();

final badges = badgesSnapshot.data()?['badges'] as List;
```

### Redeeming Badge
```dart
// Check user points
final userDoc = await FirebaseFirestore.instance
    .collection('users')
    .doc(userId)
    .get();
final userPoints = userDoc.data()?['points'] ?? 0;

if (userPoints >= badge['price']) {
  // Deduct points
  await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .update({
    'points': FieldValue.increment(-badge['price']),
    'badges.${badge['badgeId']}': true,
  });
}
```

## Notes
- All icon URLs are placeholders. Replace with actual icon URLs or use local assets.
- Badge prices are balanced across difficulty levels.
- Categories are evenly distributed for diverse achievements.

