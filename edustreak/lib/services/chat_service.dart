import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/chat_message.dart';
import '../models/user_model.dart';
import '../utils/chat_id_generator.dart';

class ChatService {
  final _db = FirebaseFirestore.instance;

  String _chatId(String a, String b) => buildChatId(a, b);

  Future<void> sendMessage({
    required UserModel currentUser,
    required String receiverId,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final chatId = _chatId(currentUser.id, receiverId);
    final chatDoc = _db.collection('messages').doc(chatId);

    // Get existing document to preserve unreadCount for other users
    final existingDoc = await chatDoc.get();
    final existingData = existingDoc.data();
    final existingUnreadCount = existingData?['unreadCount'] as Map<String, dynamic>? ?? <String, dynamic>{};

    // Update unread counts
    final updatedUnreadCount = Map<String, dynamic>.from(existingUnreadCount);
    updatedUnreadCount[currentUser.id] = 0; // Sender has 0 unread
    // Increment receiver's unread count
    final currentReceiverUnread = (updatedUnreadCount[receiverId] ?? 0) as int;
    updatedUnreadCount[receiverId] = currentReceiverUnread + 1;

    // Update metadata document
    await chatDoc.set({
      'participants': [currentUser.id, receiverId],
      'lastMessage': trimmed,
      'lastTimestamp': FieldValue.serverTimestamp(),
      'unreadCount': updatedUnreadCount,
    }, SetOptions(merge: true));

    // Add message to chat subcollection
    await chatDoc.collection('chat').add({
      'from': currentUser.id,
      'to': receiverId,
      'text': trimmed,
      'timestamp': FieldValue.serverTimestamp(),
      'readBy': [currentUser.id],
    });
  }

  Stream<List<ChatMessage>> streamMessages({
    required String currentUid,
    required String otherUid,
  }) {
    final chatId = _chatId(currentUid, otherUid);
    return _db
        .collection('messages')
        .doc(chatId)
        .collection('chat')
        .orderBy('timestamp')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(ChatMessage.fromDoc).toList(),
        );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamInbox(String uid) {
    // Query without orderBy to avoid requiring a composite index
    // Sorting is done client-side in the inbox screen
    return _db
        .collection('messages')
        .where('participants', arrayContains: uid)
        .snapshots();
  }

  Future<void> markMessagesAsRead({
    required String currentUid,
    required String otherUid,
  }) async {
    final chatId = _chatId(currentUid, otherUid);
    final chatDoc = _db.collection('messages').doc(chatId);

    await chatDoc.set({
      'unreadCount': {currentUid: 0},
    }, SetOptions(merge: true));

    final recentMessages = await chatDoc
        .collection('chat')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .get();

    final batch = _db.batch();
    for (final doc in recentMessages.docs) {
      final readBy = List<String>.from(doc['readBy'] ?? const []);
      if (!readBy.contains(currentUid)) {
        batch.update(doc.reference, {
          'readBy': FieldValue.arrayUnion([currentUid]),
        });
      }
    }

    if (recentMessages.docs.isNotEmpty) {
      await batch.commit();
    }
  }
}

