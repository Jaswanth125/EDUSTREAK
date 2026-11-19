import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/school_model.dart';
import 'school_service.dart';
import 'audit_service.dart';

class PrincipalService {
  final FirebaseFirestore? _customFirestore;
  FirebaseFirestore? get _firestoreOrNull {
    if (_customFirestore != null) return _customFirestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  FirebaseFirestore get _firestore => _firestoreOrNull ?? FirebaseFirestore.instance;
  bool get _isFirebaseAvailable => _firestoreOrNull != null;
  final SchoolService _schoolService;
  final AuditService _auditService = AuditService();

  PrincipalService({FirebaseFirestore? firestore})
      : _customFirestore = firestore,
        _schoolService = SchoolService(firestore: firestore);

  CollectionReference<Map<String, dynamic>> _announcementsRef(String schoolId) =>
      _firestore.collection('schools').doc(schoolId).collection('announcements');

  /// Fetches school profile for the given schoolId with reliable fallback
  Future<SchoolModel> getSchoolDetails(String schoolId) async {
    try {
      final school = await _schoolService.getSchool(schoolId);
      if (school != null) return school;
    } catch (e) {
      debugPrint('Error getting school details: $e');
    }

    return SchoolModel(
      id: schoolId.isNotEmpty ? schoolId : 'school_default',
      name: schoolId.isNotEmpty ? 'School ($schoolId)' : 'EduStreak Institution',
      code: schoolId.isNotEmpty ? schoolId.toUpperCase() : 'SCH-001',
      type: SchoolType.government,
      status: 'active',
      district: 'District',
      academicYear: '2026-2027',
      supportedClasses: const ['Class 6', 'Class 7', 'Class 8', 'Class 9', 'Class 10'],
      totalStudents: 0,
      totalTeachers: 0,
      curriculumTemplateId: 'AP_STATE_GOVT',
      establishedDate: DateTime.now(),
    );
  }

  /// Aggregated real-time metrics for Principal Dashboard directly from database records
  Future<Map<String, dynamic>> getSchoolMetrics(String schoolId) async {
    int totalStudents = 0;
    int totalTeachers = 0;
    int totalClasses = 0;
    int totalParents = 0;
    int activeStudents = 0;
    double attendanceToday = 0.0;
    double academicPassRate = 0.0;
    String averageGrade = 'N/A';
    int totalAssignmentsThisWeek = 0;
    int pendingGradingCount = 0;

    try {
      final studentsSnap = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'student')
          .where('schoolId', isEqualTo: schoolId)
          .get();

      totalStudents = studentsSnap.docs.length;
      activeStudents = studentsSnap.docs.where((d) => (d.data()['isActive'] ?? true) == true).length;

      final teachersSnap = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'teacher')
          .where('schoolId', isEqualTo: schoolId)
          .get();

      totalTeachers = teachersSnap.docs.length;

      final parentsSnap = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'parent')
          .where('schoolId', isEqualTo: schoolId)
          .get();

      totalParents = parentsSnap.docs.length;

      final classesSnap = await _firestore
          .collection('schools')
          .doc(schoolId)
          .collection('classes')
          .get();
      if (classesSnap.docs.isNotEmpty) {
        totalClasses = classesSnap.docs.length;
      } else {
        final distinctClasses = studentsSnap.docs
            .map((d) => (d.data()['grade'] ?? d.data()['classId'])?.toString())
            .where((c) => c != null && c.isNotEmpty)
            .toSet();
        totalClasses = distinctClasses.length;
      }

      final tasksSnap = await _firestore
          .collection('tasks')
          .where('schoolId', isEqualTo: schoolId)
          .get();
      totalAssignmentsThisWeek = tasksSnap.docs.length;

      for (final doc in tasksSnap.docs) {
        final data = doc.data();
        final submissions = (data['submissions'] as Map<String, dynamic>?) ?? {};
        final marks = (data['marks'] as Map<String, dynamic>?) ?? {};
        pendingGradingCount += submissions.keys.where((sId) => marks[sId] == null).length;
      }

      if (totalStudents > 0) {
        int presentCount = 0;
        final todayStr = DateTime.now().toIso8601String().substring(0, 10);
        final attSnap = await _firestore
            .collection('attendance')
            .where('schoolId', isEqualTo: schoolId)
            .where('date', isEqualTo: todayStr)
            .get();
        if (attSnap.docs.isNotEmpty) {
          int markedTotal = 0;
          for (final doc in attSnap.docs) {
            final records = (doc.data()['records'] as Map<String, dynamic>?) ?? {};
            for (final status in records.values) {
              markedTotal++;
              if (status == 'present' || status == true) presentCount++;
            }
          }
          if (markedTotal > 0) {
            attendanceToday = double.parse(((presentCount / markedTotal) * 100).toStringAsFixed(1));
          }
        }
      }
    } catch (e) {
      debugPrint('Metrics query note: $e');
    }

    return {
      'totalStudents': totalStudents,
      'totalTeachers': totalTeachers,
      'totalClasses': totalClasses,
      'totalParents': totalParents,
      'activeStudents': activeStudents,
      'attendanceToday': attendanceToday,
      'academicPassRate': academicPassRate,
      'averageGrade': averageGrade,
      'totalAssignmentsThisWeek': totalAssignmentsThisWeek,
      'pendingGradingCount': pendingGradingCount,
    };
  }

  /// Stream of students for the assigned school with search & filter
  Stream<List<UserModel>> getStudentsStream(
    String schoolId, {
    String? classFilter,
    String? searchQuery,
    String? statusFilter,
  }) {
    final fs = _firestoreOrNull;
    if (fs == null) {
      return Stream.value(<UserModel>[]);
    }

    try {
      Query<Map<String, dynamic>> query = fs
          .collection('users')
          .where('role', isEqualTo: 'student')
          .where('schoolId', isEqualTo: schoolId);

      return query.snapshots().map((snapshot) {
        final list = snapshot.docs
            .map((d) => UserModel.fromMap(Map<String, dynamic>.from(d.data())..['id'] = d.id))
            .toList();
        return _filterStudentsList(list, classFilter, searchQuery, statusFilter);
      }).handleError((e) {
        debugPrint('Students stream error: $e');
        return <UserModel>[];
      });
    } catch (e) {
      debugPrint('Firestore students query error: $e');
      return Stream.value(<UserModel>[]);
    }
  }

  List<UserModel> _filterStudentsList(
    List<UserModel> list,
    String? classFilter,
    String? searchQuery,
    String? statusFilter,
  ) {
    var result = List<UserModel>.from(list);
    if (classFilter != null && classFilter.isNotEmpty && classFilter != 'All Classes') {
      result = result.where((s) =>
          s.grade == classFilter ||
          s.classId == classFilter ||
          'Class ${s.grade}-${s.section}' == classFilter ||
          'Class ${s.grade}' == classFilter).toList();
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      result = result.where((s) =>
          s.name.toLowerCase().contains(q) ||
          (s.rollNumber ?? '').toLowerCase().contains(q) ||
          s.email.toLowerCase().contains(q)).toList();
    }

    if (statusFilter != null && statusFilter != 'All') {
      if (statusFilter == 'At-Risk') {
        result = result.where((s) => s.streakCount < 3 || s.xp < 250).toList();
      } else if (statusFilter == 'Top Performers') {
        result = result.where((s) => s.streakCount >= 7 || s.xp >= 400).toList();
      } else if (statusFilter == 'Active') {
        result = result.where((s) => s.status == 'active' || (s.isActive && s.status != 'not_registered')).toList();
      } else if (statusFilter == 'Not Registered') {
        result = result.where((s) => s.status == 'not_registered' || !s.isActive).toList();
      } else if (statusFilter == 'Suspended') {
        result = result.where((s) => s.status == 'suspended' || s.status == 'deactivated').toList();
      }
    }

    return result;
  }

  /// Stream of faculty / teachers assigned to this school
  Stream<List<UserModel>> getTeachersStream(String schoolId, {String? searchQuery, String? statusFilter}) {
    final fs = _firestoreOrNull;
    if (fs == null) {
      return Stream.value(<UserModel>[]);
    }

    try {
      Query<Map<String, dynamic>> query = fs
          .collection('users')
          .where('role', isEqualTo: 'teacher')
          .where('schoolId', isEqualTo: schoolId);

      return query.snapshots().map((snapshot) {
        final list = snapshot.docs
            .map((d) => UserModel.fromMap(Map<String, dynamic>.from(d.data())..['id'] = d.id))
            .toList();
        return _filterTeachersList(list, searchQuery, statusFilter);
      }).handleError((e) {
        debugPrint('Teachers stream error: $e');
        return <UserModel>[];
      });
    } catch (e) {
      debugPrint('Firestore teachers query error: $e');
      return Stream.value(<UserModel>[]);
    }
  }

  List<UserModel> _filterTeachersList(
    List<UserModel> list,
    String? searchQuery,
    String? statusFilter,
  ) {
    var result = List<UserModel>.from(list);
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      result = result.where((t) =>
          t.name.toLowerCase().contains(q) ||
          t.email.toLowerCase().contains(q) ||
          t.assignedSubjects.any((sub) => sub.toLowerCase().contains(q))).toList();
    }

    if (statusFilter != null && statusFilter != 'All') {
      if (statusFilter == 'Active') {
        result = result.where((t) => t.status == 'active' || (t.isActive && t.status != 'not_registered')).toList();
      } else if (statusFilter == 'Not Registered') {
        result = result.where((t) => t.status == 'not_registered' || !t.isActive).toList();
      } else if (statusFilter == 'Suspended') {
        result = result.where((t) => t.status == 'suspended' || t.status == 'deactivated').toList();
      }
    }

    return result;
  }

  /// Today's attendance summary & class status
  Map<String, dynamic> getTodayAttendanceSummary(String schoolId) {
    return {
      'totalEnrolled': 0,
      'presentCount': 0,
      'absentCount': 0,
      'lateCount': 0,
      'overallPercentage': 0.0,
      'teacherPresentCount': 0,
      'teacherTotalCount': 0,
      'teacherPercentage': 0.0,
      'classAttendance': <Map<String, dynamic>>[],
      'lowAttendanceAlerts': <Map<String, dynamic>>[],
    };
  }

  /// At-risk students requiring Principal attention / intervention
  List<Map<String, dynamic>> getAtRiskStudents(String schoolId) {
    return <Map<String, dynamic>>[];
  }

  /// AI-powered school insights
  List<Map<String, dynamic>> getAISchoolInsights(String schoolId) {
    return <Map<String, dynamic>>[];
  }

  /// Curriculum syllabus completion tracker
  List<Map<String, dynamic>> getCurriculumProgress(String schoolId) {
    return <Map<String, dynamic>>[];
  }

  /// Examinations & Results comparison
  List<Map<String, dynamic>> getExaminations(String schoolId) {
    return <Map<String, dynamic>>[];
  }

  /// School Announcements Stream
  Stream<List<Map<String, dynamic>>> getSchoolAnnouncementsStream(String schoolId) {
    if (!_isFirebaseAvailable) {
      return Stream.value(<Map<String, dynamic>>[]);
    }
    try {
      final ref = _announcementsRef(schoolId);
      return ref
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          return snapshot.docs.map((d) => d.data()..['id'] = d.id).toList();
        }
        return <Map<String, dynamic>>[];
      }).handleError((e) {
        debugPrint('Announcements stream error: $e');
        return <Map<String, dynamic>>[];
      });
    } catch (e) {
      debugPrint('Firestore announcements error: $e');
      return Stream.value(<Map<String, dynamic>>[]);
    }
  }

  /// Publish new announcement for the school
  Future<void> createSchoolAnnouncement({
    required String schoolId,
    required String title,
    required String content,
    required String targetAudience, // 'All', 'Teachers', 'Students', 'Parents'
    required String priority, // 'normal', 'important', 'urgent'
    required String authorName,
    required String authorId,
  }) async {
    final docRef = _announcementsRef(schoolId).doc();
    final data = {
      'id': docRef.id,
      'schoolId': schoolId,
      'title': title,
      'content': content,
      'targetAudience': targetAudience,
      'priority': priority,
      'authorName': authorName,
      'authorId': authorId,
      'createdAt': FieldValue.serverTimestamp(),
      'timestamp': DateTime.now().toIso8601String(),
    };

    await docRef.set(data);

    await _auditService.logAction(
      adminUid: authorId,
      adminEmail: authorName,
      action: 'PRINCIPAL_ANNOUNCEMENT_POSTED',
      entityType: 'announcement',
      entityId: docRef.id,
      reason: 'School Announcement: $title ($targetAudience)',
    );
  }

  /// Stream of linked parents for the school
  Stream<List<UserModel>> getLinkedParentsStream(String schoolId, {String? searchQuery}) {
    final fs = _firestoreOrNull;
    if (fs == null) {
      return Stream.value(<UserModel>[]);
    }

    try {
      Query<Map<String, dynamic>> query = fs
          .collection('users')
          .where('role', isEqualTo: 'parent')
          .where('schoolId', isEqualTo: schoolId);

      return query.snapshots().map((snapshot) {
        var list = snapshot.docs
            .map((d) => UserModel.fromMap(Map<String, dynamic>.from(d.data())..['id'] = d.id))
            .toList();

        if (searchQuery != null && searchQuery.trim().isNotEmpty) {
          final q = searchQuery.trim().toLowerCase();
          list = list.where((p) =>
              p.name.toLowerCase().contains(q) ||
              p.email.toLowerCase().contains(q)).toList();
        }

        return list;
      }).handleError((e) {
        debugPrint('Parents stream error: $e');
        return <UserModel>[];
      });
    } catch (e) {
      debugPrint('Firestore parents query error: $e');
      return Stream.value(<UserModel>[]);
    }
  }

  /// Stream of administrative approvals for the school
  Stream<List<Map<String, dynamic>>> getPendingApprovalsStream(String schoolId) {
    final fs = _firestoreOrNull;
    if (fs == null) {
      return Stream.value(<Map<String, dynamic>>[]);
    }

    try {
      return fs
          .collection('schools')
          .doc(schoolId)
          .collection('pending_approvals')
          .snapshots()
          .map((snapshot) {
            final list = snapshot.docs.map((d) {
              final data = Map<String, dynamic>.from(d.data());
              data['id'] = d.id;
              return data;
            }).toList();

            // Sort in memory by requestedAt descending
            list.sort((a, b) {
              final aDate = a['requestedAt']?.toString() ?? '';
              final bDate = b['requestedAt']?.toString() ?? '';
              return bDate.compareTo(aDate);
            });

            return list;
          }).handleError((e) {
            debugPrint('Pending approvals stream error: $e');
            return <Map<String, dynamic>>[];
          });
    } catch (e) {
      debugPrint('Firestore pending approvals error: $e');
      return Stream.value(<Map<String, dynamic>>[]);
    }
  }

  /// Resolve an administrative approval request (Approve or Reject)
  Future<void> resolveApprovalRequest({
    required String schoolId,
    required String requestId,
    required bool approved,
    String? reason,
    required String reviewerUid,
    required String reviewerName,
  }) async {
    final status = approved ? 'approved' : 'rejected';
    final nowIso = DateTime.now().toIso8601String();
    final reviewNote = reason ?? (approved ? 'Authorized by Principal' : 'Rejected by Principal');

    final fs = _firestoreOrNull;
    if (fs != null) {
      try {
        final docRef = fs
            .collection('schools')
            .doc(schoolId)
            .collection('pending_approvals')
            .doc(requestId);

        final existingDoc = await docRef.get();
        if (existingDoc.exists) {
          final currentData = existingDoc.data() ?? {};
          final updatePayload = {
            ...currentData,
            'status': status,
            'reviewedByUid': reviewerUid,
            'reviewedByName': reviewerName,
            'reviewedAt': nowIso,
            'reviewReason': reviewNote,
          };
          await docRef.set(updatePayload, SetOptions(merge: true));
        } else {
          await docRef.set({
            'id': requestId,
            'schoolId': schoolId,
            'status': status,
            'reviewedByUid': reviewerUid,
            'reviewedByName': reviewerName,
            'reviewedAt': nowIso,
            'reviewReason': reviewNote,
            'requestedAt': nowIso,
          }, SetOptions(merge: true));
        }
      } catch (e) {
        debugPrint('Firestore approval sync note: $e');
      }
    }

    // Log to audit trail
    try {
      await _auditService.logAction(
        action: approved ? 'APPROVAL_REQUEST_APPROVED' : 'APPROVAL_REQUEST_REJECTED',
        targetType: 'approval_request',
        targetId: requestId,
        schoolId: schoolId,
        reason: reason,
        details: {
          'status': status,
          'reviewerUid': reviewerUid,
          'reviewerName': reviewerName,
          'reviewedAt': nowIso,
        },
      );
    } catch (e) {
      debugPrint('Audit logging note: $e');
    }
  }

  /// Updates school operational information while enforcing strict read-only lock
  /// on protected fields (School Code, ownership, category, platform IDs)
  Future<void> updateSchoolPermittedProfile(
    String schoolId,
    Map<String, dynamic> permittedFields,
  ) async {
    // Strip forbidden/protected keys
    final safeMap = Map<String, dynamic>.from(permittedFields);
    safeMap.remove('id');
    safeMap.remove('code');
    safeMap.remove('type');
    safeMap.remove('curriculumTemplateId');
    safeMap.remove('status');
    safeMap.remove('isActive');
    safeMap.remove('establishedDate');

    safeMap['updatedAt'] = DateTime.now().toIso8601String();

    await _firestore.collection('schools').doc(schoolId).update(safeMap);

    await _auditService.logAction(
      action: 'SCHOOL_PROFILE_UPDATED_BY_PRINCIPAL',
      targetType: 'school',
      targetId: schoolId,
      schoolId: schoolId,
      details: safeMap,
    );
  }
}
