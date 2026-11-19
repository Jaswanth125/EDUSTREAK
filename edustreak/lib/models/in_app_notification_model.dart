import 'package:cloud_firestore/cloud_firestore.dart';

/// In-app notification for students, teachers, parents and staff.
class InAppNotificationModel {
  final String id;
  final String userId;
  final String? schoolId;
  final String title;
  final String body;
  final String type; // 'homework', 'grade', 'badge', 'level_up', 'xp', 'attendance', 'general'
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  const InAppNotificationModel({
    required this.id,
    required this.userId,
    this.schoolId,
    required this.title,
    required this.body,
    required this.type,
    this.isRead = false,
    required this.createdAt,
    this.metadata,
  });

  factory InAppNotificationModel.fromMap(Map<String, dynamic> map, {String id = ''}) {
    DateTime parsedTime = DateTime.now();
    if (map['createdAt'] != null) {
      if (map['createdAt'] is Timestamp) {
        parsedTime = (map['createdAt'] as Timestamp).toDate();
      } else if (map['createdAt'] is DateTime) {
        parsedTime = map['createdAt'] as DateTime;
      } else if (map['createdAt'] is String) {
        parsedTime = DateTime.tryParse(map['createdAt']) ?? DateTime.now();
      }
    }

    return InAppNotificationModel(
      id: id.isNotEmpty ? id : (map['id'] ?? ''),
      userId: map['userId'] ?? '',
      schoolId: map['schoolId'],
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      type: map['type'] ?? 'general',
      isRead: map['isRead'] ?? false,
      createdAt: parsedTime,
      metadata: map['metadata'] != null ? Map<String, dynamic>.from(map['metadata']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'schoolId': schoolId,
      'title': title,
      'body': body,
      'type': type,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
      'metadata': metadata,
    };
  }

  InAppNotificationModel copyWith({bool? isRead}) {
    return InAppNotificationModel(
      id: id,
      userId: userId,
      schoolId: schoolId,
      title: title,
      body: body,
      type: type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      metadata: metadata,
    );
  }
}
