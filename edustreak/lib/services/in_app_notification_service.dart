import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/in_app_notification_model.dart';

/// Real-time in-app notification manager with Firestore synchronization.
class InAppNotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _collection() {
    return _firestore.collection('in_app_notifications');
  }

  /// Send an in-app notification to a user
  Future<void> sendNotification({
    required String userId,
    String? schoolId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final docRef = _collection().doc();
      final notification = InAppNotificationModel(
        id: docRef.id,
        userId: userId,
        schoolId: schoolId,
        title: title,
        body: body,
        type: type,
        isRead: false,
        createdAt: DateTime.now(),
        metadata: metadata,
      );
      await docRef.set(notification.toMap());
    } catch (e) {
      debugPrint('Error sending in-app notification: $e');
    }
  }

  /// Real-time stream of notifications for a specific user
  Stream<List<InAppNotificationModel>> streamNotifications(String userId) {
    return _collection()
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => InAppNotificationModel.fromMap(doc.data(), id: doc.id))
          .toList();
      // Sort in-memory to prevent requiring custom composite indexes
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Real-time unread count stream
  Stream<int> getUnreadCountStream(String userId) {
    return _collection()
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _collection().doc(notificationId).update({'isRead': true});
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read for a user
  Future<void> markAllAsRead(String userId) async {
    try {
      final unreadDocs = await _collection()
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in unreadDocs.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }
}
