import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'audit_service.dart';

class PlatformAnnouncement {
  final String id;
  final String title;
  final String message;
  final String targetAudience; // ALL, STUDENTS, TEACHERS, PARENTS
  final String? targetSchoolId;
  final String priority; // NORMAL, URGENT
  final DateTime createdAt;
  final bool isActive;

  const PlatformAnnouncement({
    required this.id,
    required this.title,
    required this.message,
    required this.targetAudience,
    this.targetSchoolId,
    required this.priority,
    required this.createdAt,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'message': message,
    'targetAudience': targetAudience,
    'targetSchoolId': targetSchoolId,
    'priority': priority,
    'createdAt': Timestamp.fromDate(createdAt),
    'isActive': isActive,
  };

  factory PlatformAnnouncement.fromMap(Map<String, dynamic> map, String docId) {
    return PlatformAnnouncement(
      id: docId,
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      targetAudience: map['targetAudience'] ?? 'ALL',
      targetSchoolId: map['targetSchoolId'],
      priority: map['priority'] ?? 'NORMAL',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: map['isActive'] ?? true,
    );
  }
}

class PlatformSettingsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuditService _auditService = AuditService();

  DocumentReference<Map<String, dynamic>> get _settingsDoc =>
      _firestore.collection('platform').doc('settings');

  CollectionReference<Map<String, dynamic>> get _announcementsRef =>
      _firestore.collection('platform').doc('announcements').collection('broadcasts');

  /// Stream of platform settings
  Stream<Map<String, dynamic>> getSettingsStream() {
    return _settingsDoc.snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) {
        return {
          'xpPerDailyStreak': 50,
          'xpPerQuizCompletion': 100,
          'streakGracePeriodHours': 24,
          'maintenanceMode': false,
          'registrationOpen': true,
          'fastApiBackendUrl': 'http://127.0.0.1:8000',
        };
      }
      return snap.data()!;
    });
  }

  /// Update platform configuration settings
  Future<void> updateSettings(Map<String, dynamic> newSettings) async {
    await _settingsDoc.set(newSettings, SetOptions(merge: true));

    await _auditService.logAction(
      action: 'PLATFORM_SETTINGS_UPDATED',
      targetType: 'platform',
      targetId: 'settings',
      details: newSettings,
    );
  }

  /// Stream of broadcast announcements
  Stream<List<PlatformAnnouncement>> getAnnouncementsStream() {
    return _announcementsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => PlatformAnnouncement.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Create and broadcast an announcement
  Future<void> broadcastAnnouncement({
    required String title,
    required String message,
    required String targetAudience,
    String? targetSchoolId,
    String priority = 'NORMAL',
  }) async {
    final docRef = _announcementsRef.doc();
    final announcement = PlatformAnnouncement(
      id: docRef.id,
      title: title.trim(),
      message: message.trim(),
      targetAudience: targetAudience,
      targetSchoolId: targetSchoolId,
      priority: priority,
      createdAt: DateTime.now(),
      isActive: true,
    );

    await docRef.set(announcement.toMap());

    await _auditService.logAction(
      action: 'ANNOUNCEMENT_BROADCAST',
      targetType: 'platform',
      targetId: docRef.id,
      details: {
        'title': title,
        'targetAudience': targetAudience,
        'priority': priority,
      },
    );
  }

  /// Delete an announcement
  Future<void> deleteAnnouncement(String announcementId) async {
    await _announcementsRef.doc(announcementId).delete();

    await _auditService.logAction(
      action: 'ANNOUNCEMENT_DELETED',
      targetType: 'platform',
      targetId: announcementId,
      details: {},
    );
  }

  /// Query FastAPI backend AI health status
  Future<Map<String, dynamic>> checkFastApiHealth({String baseUrl = 'http://127.0.0.1:8000'}) async {
    final startTime = DateTime.now();
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/status/'))
          .timeout(const Duration(seconds: 4));

      final latencyMs = DateTime.now().difference(startTime).inMilliseconds;

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return {
          'status': 'online',
          'statusCode': response.statusCode,
          'latencyMs': latencyMs,
          'details': body,
        };
      } else {
        return {
          'status': 'degraded',
          'statusCode': response.statusCode,
          'latencyMs': latencyMs,
          'error': 'HTTP ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'status': 'offline',
        'latencyMs': DateTime.now().difference(startTime).inMilliseconds,
        'error': e.toString(),
      };
    }
  }
}
