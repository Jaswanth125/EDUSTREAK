// Firebase Admin SDK script to upload badges to Firestore
// Run with: node upload_badges_to_firestore.js

const admin = require('firebase-admin');
const badges = require('./store_badges.json');

// Initialize Firebase Admin (you'll need to set up your service account)
// admin.initializeApp({
//   credential: admin.credential.cert(require('./path-to-service-account.json'))
// });

const db = admin.firestore();

async function uploadBadges() {
  const batch = db.batch();
  const badgesRef = db.collection('store').doc('badges');
  
  // Set all badges as a subcollection or as a map
  badges.forEach((badge, index) => {
    const badgeRef = badgesRef.collection('items').doc(badge.badgeId);
    batch.set(badgeRef, {
      ...badge,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });
  
  await batch.commit();
  console.log(`✅ Successfully uploaded ${badges.length} badges to Firestore!`);
}

// Alternative: Upload as a single document with badges array
async function uploadBadgesAsArray() {
  const badgesRef = db.collection('store').doc('badges');
  await badgesRef.set({
    badges: badges,
    totalCount: badges.length,
    lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
  });
  console.log(`✅ Successfully uploaded ${badges.length} badges as array!`);
}

// Run the upload
uploadBadgesAsArray().catch(console.error);

