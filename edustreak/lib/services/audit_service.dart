import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuditRecord {
  final String id;
  final String adminUid;
  final String adminEmail;
  final String action;
  final String entityType;
  final String entityId;
  final String? schoolId;
  final String? schoolCode;
  final Map<String, dynamic>? previousValues;
  final Map<String, dynamic>? newValues;
  final String? reason;
  final DateTime timestamp;
  final String status;

  const AuditRecord({
    required this.id,
    required this.adminUid,
    required this.adminEmail,
    required this.action,
    required this.entityType,
    required this.entityId,
    this.schoolId,
    this.schoolCode,
    this.previousValues,
    this.newValues,
    this.reason,
    required this.timestamp,
    this.status = 'SUCCESS',
  });

  String get targetType => entityType;
  String get targetId => entityId;
  String get adminId => adminUid;
  Map<String, dynamic> get details => newValues ?? previousValues ?? {};
  String get formattedTime {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    return '$h:$m • ${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'adminUid': adminUid,
        'adminEmail': adminEmail,
        'action': action,
        'entityType': entityType,
        'entityId': entityId,
        'schoolId': schoolId,
        'schoolCode': schoolCode,
        'previousValues': previousValues,
        'newValues': newValues,
        'reason': reason,
        'timestamp': Timestamp.fromDate(timestamp),
        'status': status,
      };

  factory AuditRecord.fromMap(Map<String, dynamic> map, String docId) {
    DateTime ts = DateTime.now();
    if (map['timestamp'] is Timestamp) {
      ts = (map['timestamp'] as Timestamp).toDate();
    } else if (map['timestamp'] is String) {
      ts = DateTime.tryParse(map['timestamp']) ?? DateTime.now();
    }

    return AuditRecord(
      id: docId,
      adminUid: map['adminUid'] ?? map['adminId'] ?? '',
      adminEmail: map['adminEmail'] ?? 'admin@edustreak.com',
      action: map['action'] ?? '',
      entityType: map['entityType'] ?? map['targetType'] ?? '',
      entityId: map['entityId'] ?? map['targetId'] ?? '',
      schoolId: map['schoolId'],
      schoolCode: map['schoolCode'],
      previousValues: map['previousValues'] as Map<String, dynamic>?,
      newValues: (map['newValues'] ?? map['details']) as Map<String, dynamic>?,
      reason: map['reason'],
      timestamp: ts,
      status: map['status'] ?? 'SUCCESS',
    );
  }
}

class AuditService {
  static final AuditService _instance = AuditService._internal();
  factory AuditService() => _instance;
  AuditService._internal();

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _auditRef =>
      _firestore.collection('platform').doc('audit_trail').collection('audit_logs');

  /// Record an administrative action to the immutable audit trail
  Future<void> logAction({
    String? adminUid,
    String? adminEmail,
    required String action,
    String? entityType,
    String? entityId,
    String? targetType,
    String? targetId,
    Map<String, dynamic>? details,
    String? schoolId,
    String? schoolCode,
    Map<String, dynamic>? previousValues,
    Map<String, dynamic>? newValues,
    String? reason,
    String status = 'SUCCESS',
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final resolvedAdminUid = adminUid ?? user?.uid ?? 'central_admin';
      final resolvedAdminEmail = adminEmail ?? user?.email ?? 'admin@edustreak.com';
      final resolvedEntityType = entityType ?? targetType ?? 'system';
      final resolvedEntityId = entityId ?? targetId ?? 'platform';
      final resolvedNewValues = newValues ?? details;

      final docRef = _auditRef.doc();
      final record = AuditRecord(
        id: docRef.id,
        adminUid: resolvedAdminUid,
        adminEmail: resolvedAdminEmail,
        action: action,
        entityType: resolvedEntityType,
        entityId: resolvedEntityId,
        schoolId: schoolId,
        schoolCode: schoolCode,
        previousValues: previousValues,
        newValues: resolvedNewValues,
        reason: reason,
        timestamp: DateTime.now(),
        status: status,
      );

      await docRef.set(record.toMap());
    } catch (e) {
      debugPrint('Warning: Audit logging failed: $e');
    }
  }

  /// Stream recent audit logs with pagination limit
  Stream<List<AuditRecord>> getRecentAuditLogsStream({int limit = 50}) {
    return _auditRef
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AuditRecord.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Stream audit logs for a specific school
  Stream<List<AuditRecord>> getSchoolAuditLogsStream(String schoolId) {
    return _auditRef
        .where('schoolId', isEqualTo: schoolId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AuditRecord.fromMap(doc.data(), doc.id))
            .toList());
  }
}
