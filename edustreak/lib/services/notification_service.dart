import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color, TargetPlatform;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static bool _initialized = false;

  // Note: iOS notifications are not fully supported on web
  // For web builds, we use Android-only settings

  Future<void> init() async {
    if (_initialized) return;

    // Skip FCM initialization on web (service worker not configured)
    if (kIsWeb) {
      _initialized = true;
      return;
    }

    // Request permissions
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Initialize local notifications (only for mobile platforms)
      if (!kIsWeb) {
        try {
          const AndroidInitializationSettings initializationSettingsAndroid =
              AndroidInitializationSettings('@mipmap/ic_launcher');

          InitializationSettings initializationSettings;
          
          final targetPlatform = defaultTargetPlatform;
          
          if (targetPlatform == TargetPlatform.android) {
            initializationSettings = const InitializationSettings(
              android: initializationSettingsAndroid,
            );
          } else {
            // For iOS or other platforms, use Android-only settings
            // (iOS full support requires mobile build)
            initializationSettings = const InitializationSettings(
              android: initializationSettingsAndroid,
            );
          }

          await _localNotifications.initialize(
            initializationSettings,
            onDidReceiveNotificationResponse: _onNotificationTapped,
          );
        } catch (e) {
          // Platform not available (web), skip initialization
          if (kDebugMode) {
            print('Local notifications not available: $e');
          }
        }
      }

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _showNotification(message);
      });

      // Handle background messages
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleNotificationTap(message);
      });

      // Get FCM token and save to user document
      final token = await getToken();
      if (token != null) {
        await _saveTokenToUser(token);
      }

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _saveTokenToUser(newToken);
      });

      _initialized = true;
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap
    // You can navigate to specific screens based on notification data
  }

  void _handleNotificationTap(RemoteMessage message) {
    // Handle notification tap when app is opened from notification
    final _ = message.data;
    // Navigate based on notification type
  }

  Future<void> _saveTokenToUser(String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': token,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving FCM token: $e');
      }
    }
  }

  Future<void> _showNotification(RemoteMessage message) async {
    if (kIsWeb) return; // Web doesn't support local notifications
    
    try {
      final androidDetails = AndroidNotificationDetails(
        'edustreak_channel',
        'EduStreak Notifications',
        channelDescription: 'Notifications for streaks, badges, and updates',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: const Color(0xFF6366F1),
        enableVibration: true,
        playSound: true,
      );

      // Use Android-only notification details (works on all platforms)
      // iOS-specific details require mobile build
      final details = NotificationDetails(android: androidDetails);

      await _localNotifications.show(
        message.hashCode,
        message.notification?.title ?? 'EduStreak',
        message.notification?.body ?? '',
        details,
        payload: message.data.toString(),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error showing notification: $e');
      }
    }
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb) return; // Web doesn't support local notifications
    
    try {
      const androidDetails = AndroidNotificationDetails(
        'edustreak_channel',
        'EduStreak Notifications',
        channelDescription: 'Notifications for streaks, badges, and updates',
        importance: Importance.high,
        priority: Priority.high,
      );

      // Use Android-only notification details (works on all platforms)
      final details = const NotificationDetails(android: androidDetails);

      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title,
        body,
        details,
        payload: payload,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error showing local notification: $e');
      }
    }
  }

  Future<String?> getToken() async {
    // Skip FCM token on web (service worker not configured)
    if (kIsWeb) {
      return null;
    }
    
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      // Silently handle errors - FCM is not critical for core functionality
      if (kDebugMode) {
        print('Error getting FCM token: $e');
      }
      return null;
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
  }
}

