import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/chat_model.dart';
import '../models/message_model.dart';

class RealtimeChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _buildChatId(String uidA, String uidB) {
    final ids = [uidA, uidB]..sort();
    return ids.join('_');
  }

  String _chatType(String roleA, String roleB) {
    final roles = [roleA, roleB]..sort();
    final joined = roles.join('_');
    switch (joined) {
      case 'parent_teacher':
        return 'parent_teacher';
      case 'student_student':
        return 'student_student';
      case 'student_teacher':
        return 'student_teacher';
      default:
        return 'direct';
    }
  }

  Future<ChatModel> getOrCreateChat({
    required String currentUserId,
    required String currentUserRole,
    required String otherUserId,
    required String otherUserRole,
  }) async {
    final chatId = _buildChatId(currentUserId, otherUserId);
    final chatRef = _firestore.collection('chats').doc(chatId);

    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(chatRef);

      if (snapshot.exists) {
        return ChatModel.fromMap(snapshot.data()!, snapshot.id);
      }

      final participants = [currentUserId, otherUserId]..sort();
      final chatData = {
        'participants': participants,
        'type': _chatType(currentUserRole, otherUserRole),
        'lastMessage': '',
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      transaction.set(chatRef, chatData);
      return ChatModel.fromMap(chatData, chatId);
    });
  }

  Stream<List<ChatModel>> getUserChatsStream(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
          final chats = snapshot.docs
              .map((doc) => ChatModel.fromMap(doc.data(), doc.id))
              .toList();
          // Sort by lastUpdated in memory (descending - most recent first)
          chats.sort((a, b) {
            if (a.lastUpdated == null && b.lastUpdated == null) return 0;
            if (a.lastUpdated == null) return 1;
            if (b.lastUpdated == null) return -1;
            return b.lastUpdated!.compareTo(a.lastUpdated!);
          });
          return chats;
        });
  }

  Stream<List<MessageModel>> streamMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = {
                ...doc.data(),
                'id': doc.id,
                'chatId': chatId,
              };
              return MessageModel.fromMap(data);
            }).toList());
  }

  Future<void> sendMessage({
    required String senderId,
    required String senderRole,
    required String receiverId,
    required String receiverRole,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final chatId = _buildChatId(senderId, receiverId);
    final chatRef = _firestore.collection('chats').doc(chatId);
    final messagesRef = chatRef.collection('messages');
    final messageDoc = messagesRef.doc();

    final chatType = _chatType(senderRole, receiverRole);

    await _firestore.runTransaction((transaction) async {
      final now = FieldValue.serverTimestamp();

      transaction.set(
        messageDoc,
        {
          'id': messageDoc.id,
          'chatId': chatId,
          'senderId': senderId,
          'text': trimmed,
          'timestamp': now,
          'read': false,
        },
      );

      transaction.set(
        chatRef,
        {
          'participants': [senderId, receiverId]..sort(),
          'type': chatType,
          'lastMessage': trimmed,
          'lastUpdated': now,
        },
        SetOptions(merge: true),
      );
    });
  }

  Future<void> markChatAsRead({
    required String currentUserId,
    required String otherUserId,
  }) async {
    final chatId = _buildChatId(currentUserId, otherUserId);
    final unreadSnapshot = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('read', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (final doc in unreadSnapshot.docs) {
      final senderId = doc.data()['senderId'];
      if (senderId != currentUserId) {
        batch.update(doc.reference, {'read': true});
      }
    }
    await batch.commit();
  }
}