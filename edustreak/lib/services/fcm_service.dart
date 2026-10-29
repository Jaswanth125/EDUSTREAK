import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Firebase Cloud Messaging Service
/// Handles FCM token management and notification reception
class FCMService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Initialize FCM service
  Future<void> initialize() async {
    // Skip FCM initialization on web (service worker not configured)
    if (kIsWeb) {
      debugPrint('FCM: Skipping initialization on web platform');
      return;
    }

    try {
      // Request notification permissions
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
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
          _handleForegroundMessage(message);
        });

        // Handle notification taps (when app is in background)
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          _handleNotificationTap(message);
        });

        // Check if app was opened from a notification (when app was terminated)
        RemoteMessage? initialMessage = await _messaging.getInitialMessage();
        if (initialMessage != null) {
          _handleNotificationTap(initialMessage);
        }
      }
    } catch (e) {
      // Silently handle errors - FCM is not critical for core functionality
      debugPrint('Error initializing FCM: $e');
    }
  }

  /// Save FCM token to Firestore
  Future<void> _saveFCMToken(String token) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        await _firestore.collection('users').doc(userId).update({
          'fcmToken': token,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        });
        debugPrint('FCM token saved for user: $userId');
      }
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground message received: ${message.messageId}');
    // Show local notification using flutter_local_notifications
    // This is handled by NotificationService
  }

  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('Notification tapped: ${message.messageId}');
    final chatId = message.data['chatId'];
    if (chatId != null) {
      // Navigate to chat screen
      // This will be handled by the app's navigation system
      // You can use a global navigator key or event bus
    }
  }

  /// Delete FCM token (on logout)
  Future<void> deleteToken() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        await _firestore.collection('users').doc(userId).update({
          'fcmToken': FieldValue.delete(),
        });
        await _messaging.deleteToken();
        debugPrint('FCM token deleted for user: $userId');
      }
    } catch (e) {
      debugPrint('Error deleting FCM token: $e');
    }
  }
}

/// Top-level function for handling background messages
/// Must be a top-level function (not a class method)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling background message: ${message.messageId}');
  // Handle background notification here
  // You can show a local notification or update UI state
}

