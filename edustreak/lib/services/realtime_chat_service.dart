import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import 'in_app_notification_service.dart';

class RealtimeChatService {
  FirebaseFirestore? get _firestoreOrNull {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  FirebaseStorage? get _storageOrNull {
    try {
      return FirebaseStorage.instance;
    } catch (_) {
      return null;
    }
  }

  String buildChatId(String uidA, String uidB) {
    final ids = [uidA, uidB]..sort();
    return ids.join('_');
  }

  String chatType(String roleA, String roleB) {
    final roles = [roleA.toLowerCase(), roleB.toLowerCase()]..sort();
    final joined = roles.join('_');
    switch (joined) {
      case 'parent_teacher':
        return 'parent_teacher';
      case 'student_student':
        return 'student_student';
      case 'student_teacher':
        return 'student_teacher';
      case 'principal_teacher':
        return 'principal_teacher';
      case 'parent_principal':
        return 'parent_principal';
      case 'parent_student':
        return 'parent_student';
      case 'admin_principal':
        return 'admin_principal';
      case 'admin_teacher':
      case 'admin_student':
      case 'admin_parent':
        return 'admin_direct';
      default:
        return 'direct';
    }
  }

  Future<ChatModel> getOrCreateChat({
    required String currentUserId,
    required String currentUserRole,
    String? currentUserName,
    required String otherUserId,
    required String otherUserRole,
    String? otherUserName,
    String? schoolId,
  }) async {
    final firestore = _firestoreOrNull;
    final chatId = buildChatId(currentUserId, otherUserId);
    if (firestore == null) {
      return ChatModel(
        id: chatId,
        participants: [currentUserId, otherUserId]..sort(),
        type: chatType(currentUserRole, otherUserRole),
        lastMessage: '',
        lastUpdated: DateTime.now(),
        participantRoles: {
          currentUserId: currentUserRole,
          otherUserId: otherUserRole,
        },
        participantNames: {
          if (currentUserName != null) currentUserId: currentUserName,
          if (otherUserName != null) otherUserId: otherUserName,
        },
        schoolId: schoolId,
      );
    }

    final chatRef = firestore.collection('chats').doc(chatId);

    return firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(chatRef);

      if (snapshot.exists) {
        final existing = snapshot.data()!;
        final updatedData = <String, dynamic>{};
        final pNames = existing['participantNames'] as Map<dynamic, dynamic>? ?? {};
        if (currentUserName != null && (pNames[currentUserId] == null || pNames[currentUserId] == 'User')) {
          updatedData['participantNames.$currentUserId'] = currentUserName;
        }
        if (otherUserName != null && (pNames[otherUserId] == null || pNames[otherUserId] == 'User')) {
          updatedData['participantNames.$otherUserId'] = otherUserName;
        }
        if (schoolId != null && existing['schoolId'] == null) {
          updatedData['schoolId'] = schoolId;
        }
        if (updatedData.isNotEmpty) {
          transaction.update(chatRef, updatedData);
        }
        return ChatModel.fromMap(existing, snapshot.id);
      }

      final participants = [currentUserId, otherUserId]..sort();
      final chatData = {
        'participants': participants,
        'type': chatType(currentUserRole, otherUserRole),
        'lastMessage': '',
        'lastUpdated': FieldValue.serverTimestamp(),
        'participantRoles': {
          currentUserId: currentUserRole,
          otherUserId: otherUserRole,
        },
        'participantNames': {
          if (currentUserName != null) currentUserId: currentUserName,
          if (otherUserName != null) otherUserId: otherUserName,
        },
        'unreadCounts': {
          currentUserId: 0,
          otherUserId: 0,
        },
        'isPinned': false,
        'isMuted': {
          currentUserId: false,
          otherUserId: false,
        },
        if (schoolId != null) 'schoolId': schoolId,
      };

      transaction.set(chatRef, chatData);
      return ChatModel.fromMap(chatData, chatId);
    });
  }

  // ── User Profile & Presence Caching ───────────────────────────────────────
  static final Map<String, Map<String, dynamic>> _userProfileCache = {};
  static final Map<String, Completer<Map<String, dynamic>?>> _inFlightProfiles = {};

  /// Asynchronously retrieve and cache user profile details from Firestore
  Future<Map<String, dynamic>?> getParticipantProfile(String userId) async {
    if (userId.isEmpty) return null;
    if (_userProfileCache.containsKey(userId)) {
      return _userProfileCache[userId];
    }
    if (_inFlightProfiles.containsKey(userId)) {
      return _inFlightProfiles[userId]!.future;
    }

    final completer = Completer<Map<String, dynamic>?>();
    _inFlightProfiles[userId] = completer;

    try {
      final firestore = _firestoreOrNull;
      if (firestore == null) {
        completer.complete(null);
        _inFlightProfiles.remove(userId);
        return null;
      }
      final doc = await firestore.collection('users').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        _userProfileCache[userId] = data;
        completer.complete(data);
      } else {
        completer.complete(null);
      }
    } catch (_) {
      completer.complete(null);
    } finally {
      _inFlightProfiles.remove(userId);
    }
    return completer.future;
  }

  /// Synchronously resolve participant name from chat record or memory cache,
  /// triggering a background cache fill if missing to prevent generic "User".
  String resolveParticipantNameSync(ChatModel chat, String currentUserId) {
    final otherId = chat.getOtherParticipantId(currentUserId);
    final stored = chat.participantNames[otherId]?.trim();
    if (stored != null && stored.isNotEmpty && stored.toLowerCase() != 'user') {
      return stored;
    }
    final cached = _userProfileCache[otherId]?['name']?.toString().trim();
    if (cached != null && cached.isNotEmpty && cached.toLowerCase() != 'user') {
      return cached;
    }

    // Trigger non-blocking profile resolution in background
    getParticipantProfile(otherId).then((profile) {
      if (profile != null) {
        final realName = profile['name']?.toString().trim();
        if (realName != null && realName.isNotEmpty && realName.toLowerCase() != 'user') {
          // Asynchronously backfill Firestore chat document so future loads have the name
          final firestore = _firestoreOrNull;
          if (firestore != null) {
            firestore.collection('chats').doc(chat.id).update({
              'participantNames.$otherId': realName,
            }).catchError((_) {});
          }
        }
      }
    });

    final role = chat.getOtherParticipantRole(currentUserId);
    if (role.isNotEmpty && role.toLowerCase() != 'contact') {
      return role[0].toUpperCase() + role.substring(1);
    }
    return 'School Member';
  }

  /// Synchronously resolve participant role
  String resolveParticipantRoleSync(ChatModel chat, String currentUserId) {
    final otherId = chat.getOtherParticipantId(currentUserId);
    final stored = chat.participantRoles[otherId]?.trim();
    if (stored != null && stored.isNotEmpty && stored.toLowerCase() != 'contact') {
      return stored;
    }
    final cached = _userProfileCache[otherId]?['role']?.toString().trim();
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }
    return 'Contact';
  }

  /// Check if participant is known to be online right now
  bool isUserOnlineSync(String userId) {
    return _userProfileCache[userId]?['isOnline'] == true;
  }

  /// Stream participant presence and profile info from users collection
  Stream<Map<String, dynamic>?> streamUserPresence(String userId) {
    final firestore = _firestoreOrNull;
    if (firestore == null || userId.isEmpty) {
      return Stream.value(null);
    }
    return firestore.collection('users').doc(userId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      final data = doc.data()!;
      _userProfileCache[userId] = data;
      return {
        'isOnline': data['isOnline'] == true,
        'lastSeen': data['lastSeen'],
        'name': data['name'],
        'role': data['role'],
        'classId': data['classId'],
        'grade': data['grade'],
        'section': data['section'],
        'profileImageUrl': data['profileImageUrl'],
      };
    });
  }

  /// Update the current user's presence in Firestore
  Future<void> updatePresence({
    required String userId,
    required bool isOnline,
  }) async {
    final firestore = _firestoreOrNull;
    if (firestore == null || userId.isEmpty) return;
    try {
      await firestore.collection('users').doc(userId).update({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  Stream<List<ChatModel>> getUserChatsStream(String userId) {
    final firestore = _firestoreOrNull;
    if (firestore == null) {
      return const Stream.empty();
    }
    return firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
          final chats = snapshot.docs
              .map((doc) => ChatModel.fromMap(doc.data(), doc.id))
              .toList();
          chats.sort((a, b) {
            if (a.isPinned != b.isPinned) {
              return a.isPinned ? -1 : 1;
            }
            if (a.lastUpdated == null && b.lastUpdated == null) return 0;
            if (a.lastUpdated == null) return 1;
            if (b.lastUpdated == null) return -1;
            return b.lastUpdated!.compareTo(a.lastUpdated!);
          });
          return chats;
        });
  }

  Stream<ChatModel?> streamChat(String chatId) {
    final firestore = _firestoreOrNull;
    if (firestore == null) {
      return const Stream.empty();
    }
    return firestore
        .collection('chats')
        .doc(chatId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      return ChatModel.fromMap(snapshot.data()!, snapshot.id);
    });
  }

  Future<void> setTypingStatus({
    required String chatId,
    required String userId,
    required bool isTyping,
  }) async {
    final firestore = _firestoreOrNull;
    if (firestore == null) return;
    try {
      await firestore.collection('chats').doc(chatId).update({
        'typingUsers.$userId': isTyping,
      });
    } catch (_) {}
  }

  Stream<int> getTotalUnreadCountStream(String userId) {
    final firestore = _firestoreOrNull;
    if (firestore == null) {
      return Stream.value(0);
    }
    return firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      int count = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final unreadCounts = data['unreadCounts'];
        if (unreadCounts is Map && unreadCounts[userId] is num) {
          count += (unreadCounts[userId] as num).toInt();
        }
      }
      return count;
    });
  }

  Future<String?> uploadChatAttachment({
    required String chatId,
    required String fileName,
    required Uint8List bytes,
    required String contentType,
  }) async {
    final storage = _storageOrNull;
    if (storage == null) return null;
    try {
      final safeName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      final path = 'chat_attachments/$chatId/${DateTime.now().millisecondsSinceEpoch}_$safeName';
      final ref = storage.ref().child(path);
      final metadata = SettableMetadata(
        contentType: contentType,
        customMetadata: {'chatId': chatId},
      );
      final uploadTask = await ref.putData(bytes, metadata);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading chat attachment: $e');
      return null;
    }
  }

  Stream<List<MessageModel>> streamMessages(String chatId) {
    final firestore = _firestoreOrNull;
    if (firestore == null) {
      return const Stream.empty();
    }
    return firestore
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
    String? senderName,
    required String receiverId,
    required String receiverRole,
    String? receiverName,
    required String text,
    String type = 'text',
    String? attachmentUrl,
    String? attachmentName,
    int? attachmentSize,
    String? replyToId,
    String? replyToText,
    String? replyToSender,
    String? schoolId,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty && attachmentUrl == null) return;

    final firestore = _firestoreOrNull;
    if (firestore == null) return;

    final chatId = buildChatId(senderId, receiverId);
    final chatRef = firestore.collection('chats').doc(chatId);
    final messagesRef = chatRef.collection('messages');
    final messageDoc = messagesRef.doc();

    final cType = chatType(senderRole, receiverRole);
    final displaySummary = type == 'image'
        ? '📷 Photo'
        : type == 'file'
            ? '📎 ${attachmentName ?? "File"}'
            : trimmed;

    await firestore.runTransaction((transaction) async {
      final now = FieldValue.serverTimestamp();

      transaction.set(
        messageDoc,
        {
          'id': messageDoc.id,
          'chatId': chatId,
          'senderId': senderId,
          if (senderName != null) 'senderName': senderName,
          'senderRole': senderRole,
          'text': trimmed,
          'timestamp': now,
          'read': false,
          'readBy': [senderId],
          'type': type,
          if (attachmentUrl != null) 'attachmentUrl': attachmentUrl,
          if (attachmentName != null) 'attachmentName': attachmentName,
          if (attachmentSize != null) 'attachmentSize': attachmentSize,
          if (replyToId != null) 'replyToId': replyToId,
          if (replyToText != null) 'replyToText': replyToText,
          if (replyToSender != null) 'replyToSender': replyToSender,
          'reactions': {},
          'isEdited': false,
          'isDeleted': false,
          'deliveryStatus': 'sent',
        },
      );

      transaction.set(
        chatRef,
        {
          'participants': [senderId, receiverId]..sort(),
          'type': cType,
          'lastMessage': displaySummary,
          'lastUpdated': now,
          'lastMessageSenderId': senderId,
          'unreadCounts.$receiverId': FieldValue.increment(1),
          'unreadCounts.$senderId': 0,
          'typingUsers.$senderId': false,
          'participantRoles.$senderId': senderRole,
          'participantRoles.$receiverId': receiverRole,
          if (senderName != null) 'participantNames.$senderId': senderName,
          if (receiverName != null) 'participantNames.$receiverId': receiverName,
          if (schoolId != null) 'schoolId': schoolId,
        },
        SetOptions(merge: true),
      );
    });

    // Dispatch real-time in-app notification to the recipient
    try {
      await InAppNotificationService().sendNotification(
        userId: receiverId,
        title: 'New message from ${senderName ?? "User"}',
        body: displaySummary,
        type: 'message',
        metadata: {
          'chatId': chatId,
          'senderId': senderId,
          'senderName': senderName ?? 'User',
          'senderRole': senderRole,
        },
      );
    } catch (e) {
      debugPrint('Error sending message notification: $e');
    }
  }

  Future<void> markChatAsRead({
    required String currentUserId,
    required String otherUserId,
    String? chatId,
  }) async {
    final firestore = _firestoreOrNull;
    if (firestore == null) return;

    final resolvedChatId = chatId ?? buildChatId(currentUserId, otherUserId);
    final chatRef = firestore.collection('chats').doc(resolvedChatId);

    // Reset unread counter for current user
    try {
      await chatRef.update({'unreadCounts.$currentUserId': 0});
    } catch (_) {
      // Chat may not exist yet or no counter field, ignore
    }

    final unreadSnapshot = await firestore
        .collection('chats')
        .doc(resolvedChatId)
        .collection('messages')
        .where('read', isEqualTo: false)
        .get();

    if (unreadSnapshot.docs.isEmpty) return;

    final batch = firestore.batch();
    for (final doc in unreadSnapshot.docs) {
      final senderId = doc.data()['senderId'];
      if (senderId != currentUserId) {
        batch.update(doc.reference, {
          'read': true,
          'readBy': FieldValue.arrayUnion([currentUserId]),
        });
      }
    }
    await batch.commit();
  }

  Future<void> toggleReaction({
    required String chatId,
    required String messageId,
    required String emoji,
    required String userId,
  }) async {
    final firestore = _firestoreOrNull;
    if (firestore == null) return;

    final messageRef = firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId);

    await firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(messageRef);
      if (!snapshot.exists) return;

      final data = snapshot.data() ?? {};
      final rawReactions = (data['reactions'] as Map<String, dynamic>?) ?? {};
      final reactions = <String, List<String>>{};
      rawReactions.forEach((k, v) {
        if (v is List) {
          reactions[k] = v.map((e) => e.toString()).toList();
        }
      });

      final currentUsers = reactions[emoji] ?? [];
      if (currentUsers.contains(userId)) {
        currentUsers.remove(userId);
        if (currentUsers.isEmpty) {
          reactions.remove(emoji);
        } else {
          reactions[emoji] = currentUsers;
        }
      } else {
        reactions[emoji] = [...currentUsers, userId];
      }

      transaction.update(messageRef, {'reactions': reactions});
    });
  }

  Future<void> editMessage({
    required String chatId,
    required String messageId,
    required String newText,
  }) async {
    final firestore = _firestoreOrNull;
    if (firestore == null) return;

    final trimmed = newText.trim();
    if (trimmed.isEmpty) return;

    final messageRef = firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId);

    await messageRef.update({
      'text': trimmed,
      'isEdited': true,
    });
  }

  Future<void> deleteMessage({
    required String chatId,
    required String messageId,
    bool softDelete = true,
  }) async {
    final firestore = _firestoreOrNull;
    if (firestore == null) return;

    final messageRef = firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId);

    if (softDelete) {
      await messageRef.update({
        'text': 'This message was deleted',
        'isDeleted': true,
        'attachmentUrl': FieldValue.delete(),
        'attachmentName': FieldValue.delete(),
        'attachmentSize': FieldValue.delete(),
      });
    } else {
      await messageRef.delete();
    }
  }

  Future<void> togglePinChat({
    required String chatId,
    required bool currentIsPinned,
  }) async {
    final firestore = _firestoreOrNull;
    if (firestore == null) return;

    final chatRef = firestore.collection('chats').doc(chatId);
    await chatRef.update({'isPinned': !currentIsPinned});
  }

  Future<void> toggleMuteChat({
    required String chatId,
    required String userId,
    required bool currentMuted,
  }) async {
    final firestore = _firestoreOrNull;
    if (firestore == null) return;

    final chatRef = firestore.collection('chats').doc(chatId);
    await chatRef.update({'isMuted.$userId': !currentMuted});
  }

  /// Consolidated role-based contact discovery for Student, Teacher, Parent, Principal, Admin
  Future<List<Map<String, dynamic>>> getAvailableContacts(UserModel currentUser) async {
    final firestore = _firestoreOrNull;
    if (firestore == null) return [];

    final Map<String, Map<String, dynamic>> contactMap = {};

    void addContact(QueryDocumentSnapshot doc, {String fallbackName = 'Member', String fallbackRole = 'member'}) {
      if (doc.id == currentUser.id) return;
      final data = doc.data() as Map<String, dynamic>;
      final rawName = (data['name'] as String?)?.trim() ?? '';
      final role = (data['role'] as String?) ?? fallbackRole;
      final grade = data['grade']?.toString();
      final section = data['section']?.toString();
      final resolvedFallback = (grade != null && grade.isNotEmpty)
          ? '${role[0].toUpperCase()}${role.substring(1)} (Class $grade${section ?? ''})'
          : (role.isNotEmpty ? '${role[0].toUpperCase()}${role.substring(1)}' : fallbackName);

      contactMap[doc.id] = {
        'id': doc.id,
        'name': (rawName.isEmpty || rawName.toLowerCase() == 'user') ? resolvedFallback : rawName,
        'role': role,
        'email': data['email'] ?? '',
        'schoolId': data['schoolId'] ?? '',
        'grade': grade ?? '',
        'section': section ?? '',
        'profileImageUrl': data['profileImageUrl'],
        'assignedSubjects': data['assignedSubjects'] ?? [],
      };
      _userProfileCache[doc.id] = data;
    }

    List<List<String>> chunk(List<String> source, int size) {
      if (source.isEmpty) return [];
      if (source.length <= size) return [List<String>.from(source)];
      final chunks = <List<String>>[];
      for (var i = 0; i < source.length; i += size) {
        chunks.add(source.sublist(i, math.min(i + size, source.length)));
      }
      return chunks;
    }

    Future<void> addAdmins() async {
      try {
        final adminsSnapshot = await firestore
            .collection('users')
            .where('role', isEqualTo: 'admin')
            .get();
        for (final doc in adminsSnapshot.docs) {
          addContact(doc, fallbackName: 'Platform Administrator', fallbackRole: 'admin');
        }
      } catch (_) {}
    }

    try {
      final role = currentUser.role.toLowerCase();

      if (role == 'student') {
        final studentClasses = <String>[
          if (currentUser.classId != null && currentUser.classId!.isNotEmpty) currentUser.classId!,
          ...(currentUser.classIds ?? []),
        ];

        for (final classId in studentClasses) {
          // Assigned teachers with classIds array
          final teachersSnap1 = await firestore
              .collection('users')
              .where('role', isEqualTo: 'teacher')
              .where('classIds', arrayContains: classId)
              .get();
          for (final doc in teachersSnap1.docs) {
            addContact(doc, fallbackName: 'Teacher', fallbackRole: 'teacher');
          }

          // Assigned teachers with singular classId
          final teachersSnap2 = await firestore
              .collection('users')
              .where('role', isEqualTo: 'teacher')
              .where('classId', isEqualTo: classId)
              .get();
          for (final doc in teachersSnap2.docs) {
            addContact(doc, fallbackName: 'Teacher', fallbackRole: 'teacher');
          }

          // Classmates
          final classmatesSnapshot = await firestore
              .collection('users')
              .where('role', isEqualTo: 'student')
              .where('classId', isEqualTo: classId)
              .get();
          for (final doc in classmatesSnapshot.docs) {
            addContact(doc, fallbackName: 'Classmate', fallbackRole: 'student');
          }
        }

        // Linked parent
        final parentsSnapshot = await firestore
            .collection('users')
            .where('role', isEqualTo: 'parent')
            .where('childId', isEqualTo: currentUser.id)
            .get();
        for (final doc in parentsSnapshot.docs) {
          addContact(doc, fallbackName: 'Parent', fallbackRole: 'parent');
        }

        final parentsSnap2 = await firestore
            .collection('users')
            .where('role', isEqualTo: 'parent')
            .where('childIds', arrayContains: currentUser.id)
            .get();
        for (final doc in parentsSnap2.docs) {
          addContact(doc, fallbackName: 'Parent', fallbackRole: 'parent');
        }

        // Principal of school
        if (currentUser.schoolId != null && currentUser.schoolId!.isNotEmpty) {
          final principalSnap = await firestore
              .collection('users')
              .where('role', isEqualTo: 'principal')
              .where('schoolId', isEqualTo: currentUser.schoolId)
              .get();
          for (final doc in principalSnap.docs) {
            addContact(doc, fallbackName: 'Principal', fallbackRole: 'principal');
          }
        }

        await addAdmins();
      } else if (role == 'teacher') {
        final classIds = <String>[
          if (currentUser.classId != null && currentUser.classId!.isNotEmpty) currentUser.classId!,
          ...(currentUser.classIds ?? []),
        ];
        final List<String> studentIds = [];

        if (classIds.isNotEmpty) {
          for (final classChunk in chunk(classIds, 10)) {
            final studentsSnapshot = await firestore
                .collection('users')
                .where('role', isEqualTo: 'student')
                .where('classId', whereIn: classChunk)
                .get();
            for (final doc in studentsSnapshot.docs) {
              addContact(doc, fallbackName: 'Student', fallbackRole: 'student');
              studentIds.add(doc.id);
            }
          }

          for (final studentChunk in chunk(studentIds, 10)) {
            final parentsSnapshot = await firestore
                .collection('users')
                .where('role', isEqualTo: 'parent')
                .where('childId', whereIn: studentChunk)
                .get();
            for (final doc in parentsSnapshot.docs) {
              addContact(doc, fallbackName: 'Parent', fallbackRole: 'parent');
            }
          }
        }

        // Fellow teachers in same school or platform
        if (currentUser.schoolId != null && currentUser.schoolId!.isNotEmpty) {
          final fellowTeachersSnapshot = await firestore
              .collection('users')
              .where('role', isEqualTo: 'teacher')
              .where('schoolId', isEqualTo: currentUser.schoolId)
              .get();
          for (final doc in fellowTeachersSnapshot.docs) {
            addContact(doc, fallbackName: 'Teacher', fallbackRole: 'teacher');
          }

          final principalsSnapshot = await firestore
              .collection('users')
              .where('role', isEqualTo: 'principal')
              .where('schoolId', isEqualTo: currentUser.schoolId)
              .get();
          for (final doc in principalsSnapshot.docs) {
            addContact(doc, fallbackName: 'Principal', fallbackRole: 'principal');
          }
        } else {
          final otherTeachersSnapshot = await firestore
              .collection('users')
              .where('role', isEqualTo: 'teacher')
              .get();
          for (final doc in otherTeachersSnapshot.docs) {
            addContact(doc, fallbackName: 'Teacher', fallbackRole: 'teacher');
          }
        }

        await addAdmins();
      } else if (role == 'principal') {
        if (currentUser.schoolId != null && currentUser.schoolId!.isNotEmpty) {
          final teachersSnapshot = await firestore
              .collection('users')
              .where('role', isEqualTo: 'teacher')
              .where('schoolId', isEqualTo: currentUser.schoolId)
              .get();
          for (final doc in teachersSnapshot.docs) {
            addContact(doc, fallbackName: 'Teacher', fallbackRole: 'teacher');
          }

          final studentsSnapshot = await firestore
              .collection('users')
              .where('role', isEqualTo: 'student')
              .where('schoolId', isEqualTo: currentUser.schoolId)
              .limit(50)
              .get();
          for (final doc in studentsSnapshot.docs) {
            addContact(doc, fallbackName: 'Student', fallbackRole: 'student');
          }

          final parentsSnapshot = await firestore
              .collection('users')
              .where('role', isEqualTo: 'parent')
              .where('schoolId', isEqualTo: currentUser.schoolId)
              .limit(50)
              .get();
          for (final doc in parentsSnapshot.docs) {
            addContact(doc, fallbackName: 'Parent', fallbackRole: 'parent');
          }
        }
        await addAdmins();
      } else if (role == 'parent') {
        final childIds = <String>[
          if (currentUser.childId != null && currentUser.childId!.isNotEmpty) currentUser.childId!,
          ...currentUser.childIds,
        ];

        for (final childChunk in chunk(childIds, 10)) {
          final childrenSnapshot = await firestore
              .collection('users')
              .where(FieldPath.documentId, whereIn: childChunk)
              .get();

          final List<String> childClassIds = [];
          String? childSchoolId;
          for (final childDoc in childrenSnapshot.docs) {
            addContact(childDoc, fallbackName: 'Child / Student', fallbackRole: 'student');
            final childData = childDoc.data();
            final classId = childData['classId'] as String?;
            if (classId != null && classId.isNotEmpty) {
              childClassIds.add(classId);
            }
            if (childSchoolId == null && childData['schoolId'] != null) {
              childSchoolId = childData['schoolId'] as String?;
            }
          }

          for (final classChunk in chunk(childClassIds, 10)) {
            final teachersSnapshot = await firestore
                .collection('users')
                .where('role', isEqualTo: 'teacher')
                .where('classIds', arrayContainsAny: classChunk)
                .get();
            for (final doc in teachersSnapshot.docs) {
              addContact(doc, fallbackName: 'Teacher', fallbackRole: 'teacher');
            }

            final teachersSnap2 = await firestore
                .collection('users')
                .where('role', isEqualTo: 'teacher')
                .where('classId', whereIn: classChunk)
                .get();
            for (final doc in teachersSnap2.docs) {
              addContact(doc, fallbackName: 'Teacher', fallbackRole: 'teacher');
            }
          }

          if (childSchoolId != null && childSchoolId.isNotEmpty) {
            final principalSnap = await firestore
                .collection('users')
                .where('role', isEqualTo: 'principal')
                .where('schoolId', isEqualTo: childSchoolId)
                .get();
            for (final doc in principalSnap.docs) {
              addContact(doc, fallbackName: 'Principal', fallbackRole: 'principal');
            }
          }
        }
        await addAdmins();
      } else if (role == 'admin') {
        final principals = await firestore
            .collection('users')
            .where('role', isEqualTo: 'principal')
            .limit(50)
            .get();
        for (final doc in principals.docs) {
          addContact(doc, fallbackName: 'Principal', fallbackRole: 'principal');
        }
        final teachers = await firestore
            .collection('users')
            .where('role', isEqualTo: 'teacher')
            .limit(50)
            .get();
        for (final doc in teachers.docs) {
          addContact(doc, fallbackName: 'Teacher', fallbackRole: 'teacher');
        }
      }
    } catch (_) {}

    return contactMap.values.toList();
  }
}