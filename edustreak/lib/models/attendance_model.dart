import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for individual attendance record
/// Stored at: users/{studentId}/attendanceRecords/{YYYY-MM-DD}
class AttendanceRecord {
  final String date; // YYYY-MM-DD format
  final bool present; // true = present, false = absent
  final String markedBy; // teacher ID
  final DateTime timestamp; // server timestamp

  AttendanceRecord({
    required this.date,
    required this.present,
    required this.markedBy,
    required this.timestamp,
  });

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    // Handle timestamp - it might be a Timestamp, null, or not exist yet
    DateTime timestampValue;
    if (map['timestamp'] == null) {
      // If timestamp is null (server timestamp not set yet), use current time
      timestampValue = DateTime.now();
    } else if (map['timestamp'] is Timestamp) {
      timestampValue = (map['timestamp'] as Timestamp).toDate();
    } else if (map['timestamp'] is DateTime) {
      timestampValue = map['timestamp'] as DateTime;
    } else {
      // Fallback to current time if unknown format
      timestampValue = DateTime.now();
    }

    return AttendanceRecord(
      date: map['date'] ?? '',
      present: map['present'] ?? false,
      markedBy: map['markedBy'] ?? '',
      timestamp: timestampValue,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'present': present,
      'markedBy': markedBy,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}

/// Model for monthly attendance summary
/// Stored at: attendanceSummary/{classId_YYYY-MM}
class AttendanceSummary {
  final String id; // classId_YYYY-MM
  final String classId;
  final String monthKey; // YYYY-MM
  final int totalWorkingDays;
  final Map<String, int> presentDays; // studentId -> count
  final Map<String, int> absentDays; // studentId -> count
  final DateTime lastUpdated;

  AttendanceSummary({
    required this.id,
    required this.classId,
    required this.monthKey,
    required this.totalWorkingDays,
    required this.presentDays,
    required this.absentDays,
    required this.lastUpdated,
  });

  factory AttendanceSummary.fromMap(Map<String, dynamic> map) {
    return AttendanceSummary(
      id: map['id'] ?? '',
      classId: map['classId'] ?? '',
      monthKey: map['monthKey'] ?? '',
      totalWorkingDays: map['totalWorkingDays'] ?? 0,
      presentDays: Map<String, int>.from(map['presentDays'] ?? {}),
      absentDays: Map<String, int>.from(map['absentDays'] ?? {}),
      lastUpdated: (map['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'classId': classId,
      'monthKey': monthKey,
      'totalWorkingDays': totalWorkingDays,
      'presentDays': presentDays,
      'absentDays': absentDays,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  /// Get attendance percentage for a student
  double getAttendancePercentage(String studentId) {
    if (totalWorkingDays == 0) return 0.0;
    final present = presentDays[studentId] ?? 0;
    return (present / totalWorkingDays) * 100;
  }

  /// Get present days for a student
  int getPresentDays(String studentId) {
    return presentDays[studentId] ?? 0;
  }

  /// Get absent days for a student
  int getAbsentDays(String studentId) {
    return absentDays[studentId] ?? 0;
  }
}

/// Legacy model for backward compatibility (if needed)
/// @deprecated Use AttendanceRecord instead
class AttendanceModel {
  final String id;
  final String classId;
  final String studentId;
  final DateTime date;
  final String status; // present, absent
  final String? markedBy; // teacher ID

  AttendanceModel({
    required this.id,
    required this.classId,
    required this.studentId,
    required this.date,
    required this.status,
    this.markedBy,
  });

  factory AttendanceModel.fromMap(Map<String, dynamic> map) {
    return AttendanceModel(
      id: map['id'] ?? '',
      classId: map['classId'] ?? '',
      studentId: map['studentId'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      status: map['status'] ?? 'absent',
      markedBy: map['markedBy'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'classId': classId,
      'studentId': studentId,
      'date': Timestamp.fromDate(date),
      'status': status,
      'markedBy': markedBy,
    };
  }
}
