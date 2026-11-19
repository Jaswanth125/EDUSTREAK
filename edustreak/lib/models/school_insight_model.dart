import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single AI-generated or algorithmically detected operational insight
/// for a verified school, complete with empirical findings, hypothesis separation,
/// and interactive lifecycle tracking.
class SchoolInsightModel {
  final String id;
  final String schoolId;
  final String category; // academic, attendance, teacher_activity, homework, curriculum, growth
  final String severity; // critical, high, moderate, informational
  final String title;
  final String finding; // Verified factual statement derived from actual records
  final String interpretation; // AI hypothesis explaining possible factors
  final String recommendedAction; // Actionable suggestion
  final Map<String, dynamic> supportingMetrics; // e.g. {'classAvg': 64.2, 'dropPct': 14.5}
  final String observationPeriod;
  final String affectedEntity; // e.g. "Class 10-A • Science"
  final int affectedCount;
  final String confidenceLevel; // e.g. "High (94%)"
  final DateTime timestamp;
  final DateTime? freshnessTimestamp;
  final bool isReviewed;
  final String? assignedTo; // UID of faculty or staff assigned
  final String? assignedToName;
  final String? actionTaken; // Documentation of steps taken by school leadership
  final String status; // open, in_progress, resolved

  SchoolInsightModel({
    required this.id,
    required this.schoolId,
    required this.category,
    required this.severity,
    required this.title,
    required this.finding,
    required this.interpretation,
    required this.recommendedAction,
    this.supportingMetrics = const {},
    required this.observationPeriod,
    required this.affectedEntity,
    this.affectedCount = 0,
    this.confidenceLevel = 'High (90%)',
    required this.timestamp,
    this.freshnessTimestamp,
    this.isReviewed = false,
    this.assignedTo,
    this.assignedToName,
    this.actionTaken,
    this.status = 'open',
  });

  factory SchoolInsightModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return SchoolInsightModel(
      id: docId.isNotEmpty ? docId : (map['id'] ?? ''),
      schoolId: map['schoolId'] ?? '',
      category: map['category'] ?? 'academic',
      severity: map['severity'] ?? 'informational',
      title: map['title'] ?? '',
      finding: map['finding'] ?? map['description'] ?? '',
      interpretation: map['interpretation'] ?? '',
      recommendedAction: map['recommendedAction'] ?? map['suggestedAction'] ?? '',
      supportingMetrics: Map<String, dynamic>.from(map['supportingMetrics'] ?? {}),
      observationPeriod: map['observationPeriod'] ?? 'Current Term',
      affectedEntity: map['affectedEntity'] ?? map['impactedClass'] ?? 'School-wide',
      affectedCount: (map['affectedCount'] as num?)?.toInt() ?? 0,
      confidenceLevel: map['confidenceLevel'] ?? 'High (90%)',
      timestamp: parseDate(map['timestamp']),
      freshnessTimestamp: map['freshnessTimestamp'] != null ? parseDate(map['freshnessTimestamp']) : null,
      isReviewed: map['isReviewed'] ?? false,
      assignedTo: map['assignedTo'],
      assignedToName: map['assignedToName'],
      actionTaken: map['actionTaken'],
      status: map['status'] ?? 'open',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'schoolId': schoolId,
      'category': category,
      'severity': severity,
      'title': title,
      'finding': finding,
      'interpretation': interpretation,
      'recommendedAction': recommendedAction,
      'supportingMetrics': supportingMetrics,
      'observationPeriod': observationPeriod,
      'affectedEntity': affectedEntity,
      'affectedCount': affectedCount,
      'confidenceLevel': confidenceLevel,
      'timestamp': Timestamp.fromDate(timestamp),
      'freshnessTimestamp': freshnessTimestamp != null ? Timestamp.fromDate(freshnessTimestamp!) : null,
      'isReviewed': isReviewed,
      'assignedTo': assignedTo,
      'assignedToName': assignedToName,
      'actionTaken': actionTaken,
      'status': status,
    };
  }

  SchoolInsightModel copyWith({
    String? id,
    String? schoolId,
    String? category,
    String? severity,
    String? title,
    String? finding,
    String? interpretation,
    String? recommendedAction,
    Map<String, dynamic>? supportingMetrics,
    String? observationPeriod,
    String? affectedEntity,
    int? affectedCount,
    String? confidenceLevel,
    DateTime? timestamp,
    DateTime? freshnessTimestamp,
    bool? isReviewed,
    String? assignedTo,
    String? assignedToName,
    String? actionTaken,
    String? status,
  }) {
    return SchoolInsightModel(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      category: category ?? this.category,
      severity: severity ?? this.severity,
      title: title ?? this.title,
      finding: finding ?? this.finding,
      interpretation: interpretation ?? this.interpretation,
      recommendedAction: recommendedAction ?? this.recommendedAction,
      supportingMetrics: supportingMetrics ?? this.supportingMetrics,
      observationPeriod: observationPeriod ?? this.observationPeriod,
      affectedEntity: affectedEntity ?? this.affectedEntity,
      affectedCount: affectedCount ?? this.affectedCount,
      confidenceLevel: confidenceLevel ?? this.confidenceLevel,
      timestamp: timestamp ?? this.timestamp,
      freshnessTimestamp: freshnessTimestamp ?? this.freshnessTimestamp,
      isReviewed: isReviewed ?? this.isReviewed,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedToName: assignedToName ?? this.assignedToName,
      actionTaken: actionTaken ?? this.actionTaken,
      status: status ?? this.status,
    );
  }
}

/// Verified statistical metrics aggregated across the school's actual database
class SchoolAnalyticsMetrics {
  final double overallAttendance;
  final double overallAcademicAverage;
  final double homeworkCompletionRate;
  final int pendingGradingCount;
  final int chronicAbsentCount;
  final int totalStudents;
  final int totalTeachers;
  final int totalClasses;
  final Map<String, double> classAverages;
  final Map<String, double> subjectAverages;
  final Map<String, double> classAttendance;
  final DateTime lastCalculated;

  const SchoolAnalyticsMetrics({
    this.overallAttendance = 0.0,
    this.overallAcademicAverage = 0.0,
    this.homeworkCompletionRate = 0.0,
    this.pendingGradingCount = 0,
    this.chronicAbsentCount = 0,
    this.totalStudents = 0,
    this.totalTeachers = 0,
    this.totalClasses = 0,
    this.classAverages = const {},
    this.subjectAverages = const {},
    this.classAttendance = const {},
    required this.lastCalculated,
  });

  /// Overall composite School Health Index (0-100)
  int get healthScore {
    if (totalStudents == 0 && totalClasses == 0) return 85;
    // Weighted formula: Attendance (35%), Academics (40%), Homework Completion (25%)
    final score = (overallAttendance * 0.35) +
        (overallAcademicAverage * 0.40) +
        (homeworkCompletionRate * 0.25);
    return score.round().clamp(10, 100);
  }

  Map<String, dynamic> toSummaryMap() {
    return {
      'overallAttendance': overallAttendance,
      'overallAcademicAverage': overallAcademicAverage,
      'homeworkCompletionRate': homeworkCompletionRate,
      'pendingGradingCount': pendingGradingCount,
      'chronicAbsentCount': chronicAbsentCount,
      'totalStudents': totalStudents,
      'totalTeachers': totalTeachers,
      'totalClasses': totalClasses,
      'classAverages': classAverages,
      'subjectAverages': subjectAverages,
      'classAttendance': classAttendance,
      'healthScore': healthScore,
      'lastCalculated': lastCalculated.toIso8601String(),
    };
  }
}
