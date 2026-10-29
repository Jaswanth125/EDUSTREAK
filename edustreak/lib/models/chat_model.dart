import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String id;
  final List<String> participants;
  final String type; // student_teacher, student_student, parent_teacher
  final String lastMessage;
  final DateTime? lastUpdated;

  ChatModel({
    required this.id,
    required this.participants,
    required this.type,
    required this.lastMessage,
    required this.lastUpdated,
  });

  factory ChatModel.fromMap(Map<String, dynamic> map, String id) {
    return ChatModel(
      id: id,
      participants: List<String>.from(map['participants'] ?? []),
      type: map['type'] ?? 'direct',
      lastMessage: map['lastMessage'] ?? '',
      lastUpdated: map['lastUpdated'] is Timestamp
          ? (map['lastUpdated'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'type': type,
      'lastMessage': lastMessage,
      'lastUpdated':
          lastUpdated != null ? Timestamp.fromDate(lastUpdated!) : null,
    };
  }

  String getOtherParticipantId(String currentUserId) {
    return participants.firstWhere((id) => id != currentUserId,
        orElse: () => currentUserId);
  }
}

