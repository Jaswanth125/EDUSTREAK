import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String id;
  final List<String> participants;
  final String type; // student_teacher, student_student, parent_teacher, principal_teacher, direct
  final String lastMessage;
  final DateTime? lastUpdated;
  final Map<String, String> participantRoles;
  final Map<String, String> participantNames;
  final String? schoolId;
  final Map<String, int> unreadCounts;
  final bool isPinned;
  final Map<String, bool> isMuted;
  final String? lastMessageSenderId;
  final Map<String, bool> typingUsers;

  ChatModel({
    required this.id,
    required this.participants,
    required this.type,
    required this.lastMessage,
    required this.lastUpdated,
    this.participantRoles = const {},
    this.participantNames = const {},
    this.schoolId,
    this.unreadCounts = const {},
    this.isPinned = false,
    this.isMuted = const {},
    this.lastMessageSenderId,
    this.typingUsers = const {},
  });

  factory ChatModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return null;
    }

    Map<String, String> parseStringMap(dynamic val) {
      if (val is Map) {
        return val.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''));
      }
      return {};
    }

    Map<String, int> parseIntMap(dynamic val) {
      if (val is Map) {
        return val.map((k, v) => MapEntry(k.toString(), (v is num) ? v.toInt() : 0));
      }
      return {};
    }

    Map<String, bool> parseBoolMap(dynamic val) {
      if (val is Map) {
        return val.map((k, v) => MapEntry(k.toString(), v == true));
      }
      return {};
    }

    return ChatModel(
      id: id,
      participants: List<String>.from(map['participants'] ?? []),
      type: map['type'] ?? 'direct',
      lastMessage: map['lastMessage'] ?? '',
      lastUpdated: parseDate(map['lastUpdated']),
      participantRoles: parseStringMap(map['participantRoles']),
      participantNames: parseStringMap(map['participantNames']),
      schoolId: map['schoolId']?.toString(),
      unreadCounts: parseIntMap(map['unreadCounts']),
      isPinned: map['isPinned'] == true,
      isMuted: parseBoolMap(map['isMuted']),
      lastMessageSenderId: map['lastMessageSenderId']?.toString(),
      typingUsers: parseBoolMap(map['typingUsers']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'type': type,
      'lastMessage': lastMessage,
      'lastUpdated': lastUpdated != null ? Timestamp.fromDate(lastUpdated!) : null,
      'participantRoles': participantRoles,
      'participantNames': participantNames,
      'schoolId': schoolId,
      'unreadCounts': unreadCounts,
      'isPinned': isPinned,
      'isMuted': isMuted,
      'lastMessageSenderId': lastMessageSenderId,
      'typingUsers': typingUsers,
    };
  }

  bool isUserTyping(String userId) {
    return typingUsers[userId] == true;
  }

  String getOtherParticipantId(String currentUserId) {
    return participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => currentUserId,
    );
  }

  String getOtherParticipantName(String currentUserId, {String fallback = 'User'}) {
    final otherId = getOtherParticipantId(currentUserId);
    final name = participantNames[otherId];
    if (name != null && name.trim().isNotEmpty) return name;
    return fallback;
  }

  String getOtherParticipantRole(String currentUserId, {String fallback = 'Contact'}) {
    final otherId = getOtherParticipantId(currentUserId);
    final role = participantRoles[otherId];
    if (role != null && role.trim().isNotEmpty) return role;
    return fallback;
  }

  int getUnreadCount(String currentUserId) {
    return unreadCounts[currentUserId] ?? 0;
  }

  bool isMutedFor(String currentUserId) {
    return isMuted[currentUserId] == true;
  }
}

