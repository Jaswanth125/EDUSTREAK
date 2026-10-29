# Firebase Cloud Messaging (FCM) Setup Guide

This guide explains how to set up FCM notifications for the real-time chat system in EduStreak.

## Overview

The real-time chat system uses Firebase Firestore for message streaming and FCM for push notifications. When a new message arrives, FCM sends a push notification to the recipient's device.

## Architecture

1. **Firestore Real-time Streams**: Messages are streamed in real-time using Firestore's `.snapshots()` listener
2. **FCM Notifications**: Push notifications are sent when new messages arrive (handled via Cloud Functions)
3. **Offline Support**: Firestore automatically handles offline persistence and sync

## Setup Steps

### 1. Enable FCM in Firebase Console

1. Go to Firebase Console → Your Project → Project Settings
2. Navigate to Cloud Messaging tab
3. Enable Cloud Messaging API
4. Generate and download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)

### 2. Set up Cloud Functions for FCM

Create a Cloud Function to send FCM notifications when new messages are created:

```javascript
// functions/index.js
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.sendMessageNotification = functions.firestore
  .document('chats/{chatId}/messages/{messageId}')
  .onCreate(async (snapshot, context) => {
    const message = snapshot.data();
    const chatId = context.params.chatId;

    // Get chat data
    const chatDoc = await admin.firestore().collection('chats').doc(chatId).get();
    const chatData = chatDoc.data();
    
    if (!chatData) return;

    // Get recipient IDs (exclude sender)
    const participants = chatData.participants || [];
    const recipients = participants.filter(id => id !== message.senderId);

    // Get FCM tokens for recipients
    const tokens = [];
    for (const recipientId of recipients) {
      const userDoc = await admin.firestore().collection('users').doc(recipientId).get();
      const fcmToken = userDoc.data()?.fcmToken;
      if (fcmToken) {
        tokens.push(fcmToken);
      }
    }

    if (tokens.length === 0) return;

    // Prepare notification
    const notification = {
      title: message.senderName || 'New Message',
      body: message.text || '📎 File attached',
      icon: 'default',
      sound: 'default',
    };

    const payload = {
      notification,
      data: {
        chatId,
        senderId: message.senderId,
        messageId: context.params.messageId,
        type: 'message',
      },
      tokens,
    };

    // Send notification
    try {
      const response = await admin.messaging().sendMulticast(payload);
      console.log(`Successfully sent ${response.successCount} notifications`);
      
      // Remove invalid tokens
      const invalidTokens = [];
      response.responses.forEach((resp, idx) => {
        if (!resp.success && resp.error?.code === 'messaging/invalid-registration-token') {
          invalidTokens.push(tokens[idx]);
        }
      });

      if (invalidTokens.length > 0) {
        // Remove invalid tokens from users
        const batch = admin.firestore().batch();
        for (const token of invalidTokens) {
          const userDocs = await admin.firestore()
            .collection('users')
            .where('fcmToken', '==', token)
            .get();
          userDocs.forEach(doc => {
            batch.update(doc.ref, { fcmToken: admin.firestore.FieldValue.delete() });
          });
        }
        await batch.commit();
      }
    } catch (error) {
      console.error('Error sending notification:', error);
    }
  });
```

### 3. Update Flutter App to Request FCM Token

In your Flutter app, request and store FCM tokens:

```dart
// lib/services/fcm_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FCMService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> initialize() async {
    // Request permission
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Get FCM token
      String? token = await _messaging.getToken();
      if (token != null && _auth.currentUser != null) {
        await _saveFCMToken(token);
      }

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        _saveFCMToken(newToken);
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        // Show local notification
        _handleForegroundMessage(message);
      });

      // Handle background messages (must be top-level function)
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    }
  }

  Future<void> _saveFCMToken(String token) async {
    final userId = _auth.currentUser?.uid;
    if (userId != null) {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    // Show local notification using flutter_local_notifications
    // This is handled by your notification service
  }
}

// Top-level function for background messages
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background notification
  print('Handling background message: ${message.messageId}');
}
```

### 4. Initialize FCM in main.dart

```dart
// lib/main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Initialize FCM
  final fcmService = FCMService();
  await fcmService.initialize();
  
  runApp(MyApp());
}
```

### 5. Handle Notification Taps

When a user taps a notification, navigate to the chat screen:

```dart
// In your main app or router
FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
  final chatId = message.data['chatId'];
  if (chatId != null) {
    // Navigate to chat screen
    Navigator.pushNamed(context, '/chat', arguments: chatId);
  }
});
```

## Testing

1. **Test FCM Token Storage**:
   - Log in as a user
   - Check Firestore `users/{userId}` document for `fcmToken` field

2. **Test Notifications**:
   - Send a message from User A to User B
   - User B should receive a push notification
   - Check Cloud Functions logs for notification delivery

3. **Test Offline Support**:
   - Turn off internet on device
   - Send a message
   - Message should be queued locally
   - Turn on internet
   - Message should sync automatically

## Security Considerations

1. **FCM Tokens**: Store FCM tokens securely in Firestore
2. **Token Validation**: Cloud Function removes invalid tokens automatically
3. **Rate Limiting**: Implement rate limiting for notifications to prevent spam
4. **Privacy**: Only send notifications to chat participants

## Troubleshooting

1. **Notifications not received**:
   - Check if FCM token is stored in Firestore
   - Verify Cloud Functions are deployed and running
   - Check device notification permissions

2. **Invalid token errors**:
   - Cloud Function automatically removes invalid tokens
   - User needs to re-authenticate to get new token

3. **Background messages not working**:
   - Ensure `_firebaseMessagingBackgroundHandler` is a top-level function
   - Check Firebase configuration files are correct

## Additional Resources

- [Firebase Cloud Messaging Documentation](https://firebase.google.com/docs/cloud-messaging)
- [Flutter Firebase Messaging Plugin](https://pub.dev/packages/firebase_messaging)
- [Firebase Cloud Functions Documentation](https://firebase.google.com/docs/functions)

