import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../utils/debug_utils.dart';

/// Real-time chat service using Firestore streams
/// No external messaging API - pure Firebase Firestore real-time streaming
class RealtimeChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Generate chat ID deterministically
  /// Uses sorted user IDs to ensure same chat ID for same two users
  String _generateChatId(String userId1, String userId2) {
    // Sort IDs to ensure deterministic chat ID
    final sortedIds = [userId1, userId2]..sort();
    return 'chat_${sortedIds[0]}_${sortedIds[1]}';
  }

  /// Determine chat type based on roles
  String _determineChatType(String role1, String role2) {
    final roles = [role1, role2]..sort();
    final rolePair = '${roles[0]}_${roles[1]}';
    
    // Map role combinations to chat types
    switch (rolePair) {
      case 'admin_admin':
        return 'admin_admin';
      case 'admin_parent':
        return 'admin_parent';
      case 'admin_student':
        return 'admin_student';
      case 'admin_teacher':
        return 'admin_teacher';
      case 'parent_parent':
        return 'parent_parent';
      case 'parent_student':
        return 'parent_student';
      case 'parent_teacher':
        return 'teacher_parent';
      case 'student_student':
        return 'student_student';
      case 'student_teacher':
        return 'teacher_student';
      case 'teacher_teacher':
        return 'teacher_teacher';
      default:
        return 'general';
    }
  }

  /// Get or create a chat between two users
  /// Supports all role combinations
  Future<ChatModel> getOrCreateChat({
    required String currentUserId,
    required String currentUserRole,
    required String otherUserId,
    required String otherUserRole,
  }) async {
    try {
      // Generate deterministic chat ID
      final chatId = _generateChatId(currentUserId, otherUserId);
      
      // Determine chat type
      final chatType = _determineChatType(currentUserRole, otherUserRole);

      // Check if chat exists
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();

      if (chatDoc.exists) {
        return ChatModel.fromMap(chatDoc.data()!, chatId);
      }

      // Create new chat
      // Sort participants to ensure consistent order
      final participants = [currentUserId, otherUserId]..sort();
      
      final chatData = {
        'participants': participants,
        'chatType': chatType,
        'lastMessage': '',
        'lastTimestamp': null,
        'createdAt': Timestamp.now(),
        'typing': {},
        'lastSeen': {},
        'unreadCount': {
          currentUserId: 0,
          otherUserId: 0,
        },
      };

      await _firestore.collection('chats').doc(chatId).set(chatData);

      return ChatModel.fromMap(chatData, chatId);
    } catch (e) {
      throw Exception('Failed to get or create chat: $e');
    }
  }

  /// Stream chats for a user (real-time updates)
  Stream<List<ChatModel>> getUserChatsStream(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      // Sort in memory to avoid requiring Firestore composite index
      final chats = snapshot.docs.map((doc) {
        return ChatModel.fromMap(doc.data(), doc.id);
      }).toList();
      
      // Sort by lastTimestamp descending (most recent first)
      // Use epoch (1970-01-01) as default for chats without timestamp
      final epoch = DateTime.fromMillisecondsSinceEpoch(0);
      chats.sort((a, b) {
        final aTime = a.lastTimestamp ?? epoch;
        final bTime = b.lastTimestamp ?? epoch;
        return bTime.compareTo(aTime); // Descending order
      });
      
      // Limit to 50 most recent chats
      if (chats.length > 50) {
        return chats.sublist(0, 50);
      }
      return chats;
    });
  }

  /// Stream messages for a chat (real-time updates)
  /// Automatically updates when new messages arrive
  Stream<List<MessageModel>> getMessagesStream(String chatId, {int limit = 50}) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MessageModel.fromMap(
                doc.data() as Map<String, dynamic>..['id'] = doc.id,
              ))
          .toList()
          .reversed
          .toList(); // Reverse to show oldest first
    });
  }

  /// Send a message (real-time)
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String text,
    String? fileUrl,
    String? fileName,
    String? fileType,
    String? taskId,
  }) async {
    try {
      final batch = _firestore.batch();

      // Create message
      final messageRef = _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc();

      final message = MessageModel(
        id: messageRef.id,
        chatId: chatId,
        senderId: senderId,
        senderName: senderName,
        text: text,
        timestamp: DateTime.now(),
        fileUrl: fileUrl,
        fileName: fileName,
        fileType: fileType,
        taskId: taskId,
        status: 'sent',
      );

      batch.set(messageRef, message.toMap());

      // Update chat metadata
      final chatRef = _firestore.collection('chats').doc(chatId);
      final previewText = fileUrl != null 
          ? (fileName ?? '📎 File attached')
          : text;
      
      final chatDoc = await chatRef.get();
      final chatData = chatDoc.data()!;
      final unreadCount = Map<String, int>.from(chatData['unreadCount'] ?? {});
      
      // Increment unread count for all participants except sender
      final participants = List<String>.from(chatData['participants'] ?? []);
      for (var participantId in participants) {
        if (participantId != senderId) {
          unreadCount[participantId] = (unreadCount[participantId] ?? 0) + 1;
        }
      }

      batch.update(chatRef, {
        'lastMessage': previewText.length > 100 
            ? '${previewText.substring(0, 100)}...' 
            : previewText,
        'lastTimestamp': Timestamp.fromDate(message.timestamp),
        'unreadCount': unreadCount,
      });

      // Commit batch write
      await batch.commit();

      // Update message status to delivered (async)
      _updateMessageStatus(chatId, messageRef.id, 'delivered');

      // Send FCM notification to other participants
      await _sendMessageNotification(
        chatId: chatId,
        senderName: senderName,
        messageText: previewText,
        senderId: senderId,
      );
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  /// Update message status (sent -> delivered -> read)
  Future<void> _updateMessageStatus(
    String chatId,
    String messageId,
    String status,
  ) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({'status': status});
    } catch (e) {
      // Error updating message status - non-critical, continue silently
      safeErrorPrint('Error updating message status', e);
    }
  }

  /// Mark message as read
  Future<void> markMessageAsRead({
    required String chatId,
    required String messageId,
    required String userId,
  }) async {
    try {
      final batch = _firestore.batch();

      // Update message readBy
      final messageRef = _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId);

      final messageDoc = await messageRef.get();
      if (messageDoc.exists) {
        final readBy = Map<String, dynamic>.from(
          messageDoc.data()!['readBy'] ?? {},
        );
        readBy[userId] = Timestamp.now();

        batch.update(messageRef, {
          'readBy': readBy,
          'status': 'read',
        });
      }

      // Reset unread count for this user
      final chatRef = _firestore.collection('chats').doc(chatId);
      final chatDoc = await chatRef.get();
      if (chatDoc.exists) {
        final unreadCount = Map<String, int>.from(
          chatDoc.data()!['unreadCount'] ?? {},
        );
        unreadCount[userId] = 0;

        batch.update(chatRef, {'unreadCount': unreadCount});
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to mark message as read: $e');
    }
  }

  /// Mark all messages in chat as read
  Future<void> markChatAsRead({
    required String chatId,
    required String userId,
  }) async {
    try {
      // Get all unread messages
      final messagesSnapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('senderId', isNotEqualTo: userId)
          .get();

      final batch = _firestore.batch();
      final now = Timestamp.now();

      for (var doc in messagesSnapshot.docs) {
        final data = doc.data();
        final readBy = Map<String, dynamic>.from(data['readBy'] ?? {});
        
        if (!readBy.containsKey(userId)) {
          readBy[userId] = now;
          batch.update(doc.reference, {
            'readBy': readBy,
            'status': 'read',
          });
        }
      }

      // Reset unread count
      final chatRef = _firestore.collection('chats').doc(chatId);
      batch.update(chatRef, {
        'unreadCount.$userId': 0,
      });

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to mark chat as read: $e');
    }
  }

  /// Set typing indicator
  Future<void> setTyping({
    required String chatId,
    required String userId,
    required bool isTyping,
  }) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'typing.$userId': isTyping,
      });
    } catch (e) {
      // Error setting typing indicator - non-critical, continue silently
      safeErrorPrint('Error setting typing indicator', e);
    }
  }

  /// Get typing indicator stream
  Stream<Map<String, bool>> getTypingStream(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return {};
      final data = snapshot.data()!;
      return Map<String, bool>.from(data['typing'] ?? {});
    });
  }

  /// Upload file for chat - DISABLED (Firebase Storage not available)
  /// File uploads are disabled. Only text messages are supported.
  Future<String> uploadFileFromPath(
    String filePath,
    String fileName,
    String fileType,
  ) async {
    throw UnsupportedError('File uploads are disabled. Firebase Storage is not configured. Only text messages are supported.');
  }

  /// Upload file from bytes - DISABLED (Firebase Storage not available)
  /// File uploads are disabled. Only text messages are supported.
  Future<String> uploadFileFromBytes(
    Uint8List bytes,
    String fileName,
    String fileType,
  ) async {
    throw UnsupportedError('File uploads are disabled. Firebase Storage is not configured. Only text messages are supported.');
  }

  /// Send FCM notification for new message
  Future<void> _sendMessageNotification({
    required String chatId,
    required String senderName,
    required String messageText,
    required String senderId,
  }) async {
    try {
      // Get chat data
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      if (!chatDoc.exists) return;

      final participants = List<String>.from(chatDoc.data()!['participants'] ?? []);
      final recipients = participants.where((id) => id != senderId).toList();

      // Get FCM tokens for recipients
      for (var recipientId in recipients) {
        final userDoc = await _firestore.collection('users').doc(recipientId).get();
        if (!userDoc.exists) continue;

        final fcmToken = userDoc.data()?['fcmToken'];
        if (fcmToken == null || fcmToken.isEmpty) continue;

        // Send notification via FCM
        // Note: In production, you'd use Cloud Functions for this
        // For now, this is a placeholder - implement FCM in Cloud Functions
        await _sendFCMNotification(
          token: fcmToken,
          title: senderName,
          body: messageText,
          data: {
            'chatId': chatId,
            'senderId': senderId,
            'type': 'message',
          },
        );
      }
    } catch (e) {
      // Error sending notification - non-critical, continue silently
      safeErrorPrint('Error sending notification', e);
      // Don't throw - notifications are not critical
    }
  }

  /// Send FCM notification (placeholder - implement with Cloud Functions)
  Future<void> _sendFCMNotification({
    required String token,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    // TODO: Implement FCM notification sending
    // This should be done via Cloud Functions for security
    // For now, this is a placeholder
    debugPrint('FCM Notification: $title - $body to $token');
  }

  /// Delete chat (admin only)
  Future<void> deleteChat(String chatId) async {
    try {
      // Delete all messages
      final messagesSnapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .get();

      final batch = _firestore.batch();
      for (var doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete chat document
      batch.delete(_firestore.collection('chats').doc(chatId));

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete chat: $e');
    }
  }

  /// Get chat participants info
  Future<Map<String, Map<String, dynamic>>> getChatParticipants(String chatId) async {
    try {
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      if (!chatDoc.exists) return {};

      final participants = List<String>.from(chatDoc.data()!['participants'] ?? []);
      final participantsData = <String, Map<String, dynamic>>{};

      for (var participantId in participants) {
        final userDoc = await _firestore.collection('users').doc(participantId).get();
        if (userDoc.exists) {
          participantsData[participantId] = userDoc.data()!;
        }
      }

      return participantsData;
    } catch (e) {
      throw Exception('Failed to get chat participants: $e');
    }
  }
}

