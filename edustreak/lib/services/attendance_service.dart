import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/attendance_model.dart';
import 'attendance_summary_service.dart';
import 'gamification_service.dart';

class AttendanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AttendanceSummaryService _summaryService = AttendanceSummaryService();

  /// Check if attendance is already marked for a date and class
  Future<bool> isAttendanceMarked(String classId, String dateKey) async {
    try {
      // Get all students in the class
      final studentsSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'student')
          .where('classId', isEqualTo: classId)
          .limit(1)
          .get();

      if (studentsSnapshot.docs.isEmpty) return false;

      final studentId = studentsSnapshot.docs.first.id;
      final attendanceDoc = await _firestore
          .collection('users')
          .doc(studentId)
          .collection('attendanceRecords')
          .doc(dateKey)
          .get();

      return attendanceDoc.exists;
    } catch (e) {
      debugPrint('Error checking attendance: $e');
      return false;
    }
  }

  /// Mark attendance for all students in a class for a specific date
  /// This is a batch operation that marks all students at once
  /// Returns true if successful, false if already marked
  Future<bool> markClassAttendance({
    required String classId,
    required String dateKey, // YYYY-MM-DD
    required Map<String, bool> studentAttendance, // studentId -> present (true/false)
    required String markedBy, // teacher ID
  }) async {
    try {
      // Check if attendance is already marked for this date and class
      final isMarked = await isAttendanceMarked(classId, dateKey);
      if (isMarked) {
        throw Exception('Attendance already marked for this date. Cannot mark twice.');
      }

      // Use batch write for atomic operation
      final batch = _firestore.batch();
      final date = DateTime.parse(dateKey);

      // Mark attendance for each student
      for (final entry in studentAttendance.entries) {
        final studentId = entry.key;
        final present = entry.value;

        final attendanceRef = _firestore
            .collection('users')
            .doc(studentId)
            .collection('attendanceRecords')
            .doc(dateKey);

        batch.set(attendanceRef, {
          'date': dateKey,
          'present': present,
          'markedBy': markedBy,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      // Commit batch
      await batch.commit();

      // Update attendance summary for the month
      await _summaryService.updateMonthlySummary(
        classId: classId,
        date: date,
        studentAttendance: studentAttendance,
      );

      // Trigger badge checks for all students (check monthly attendance)
      final gamificationService = GamificationService();
      for (final studentId in studentAttendance.keys) {
        try {
          await gamificationService.checkAttendanceBadges(studentId, date);
        } catch (e) {
          debugPrint('Error checking badges for student $studentId: $e');
          // Continue with other students even if one fails
        }
      }

      return true;
    } catch (e) {
      debugPrint('Error marking class attendance: $e');
      rethrow;
    }
  }

  /// Get attendance record for a student on a specific date
  Future<AttendanceRecord?> getStudentAttendanceRecord(
    String studentId,
    String dateKey, // YYYY-MM-DD
  ) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(studentId)
          .collection('attendanceRecords')
          .doc(dateKey)
          .get();

      if (!doc.exists) return null;

      final data = doc.data();
      if (data == null) return null;

      // Validate required fields
      if (data['date'] == null || data['present'] == null) {
        debugPrint('Invalid attendance record data: missing required fields');
        return null;
      }

      try {
        return AttendanceRecord.fromMap(data);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Error parsing attendance record: ${e.toString()}');
          debugPrint('Record data: ${data?.toString() ?? 'null'}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting attendance record for $studentId on $dateKey: ${e.toString()}');
      }
      // Don't throw - return null to allow other records to load
      return null;
    }
  }

  /// Get all attendance records for a student in a date range
  Future<Map<String, AttendanceRecord>> getStudentAttendanceRange(
    String studentId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final attendanceMap = <String, AttendanceRecord>{};
      
      // Generate date keys for the range
      var currentDate = DateTime(startDate.year, startDate.month, startDate.day);
      final end = DateTime(endDate.year, endDate.month, endDate.day);

      int errorCount = 0;
      const maxErrors = 5; // Limit error logging

      while (currentDate.isBefore(end) || currentDate.isAtSameMomentAs(end)) {
        final dateKey = _formatDateKey(currentDate);
        
        try {
          final record = await getStudentAttendanceRecord(studentId, dateKey);
          if (record != null) {
            attendanceMap[dateKey] = record;
          }
        } catch (e) {
          errorCount++;
          if (errorCount <= maxErrors && kDebugMode) {
            debugPrint('Error loading attendance for $dateKey: ${e.toString()}');
          }
          // Continue loading other dates even if one fails
        }
        
        currentDate = currentDate.add(const Duration(days: 1));
      }

      if (errorCount > maxErrors) {
        debugPrint('... and ${errorCount - maxErrors} more errors loading attendance');
      }

      return attendanceMap;
    } catch (e) {
      debugPrint('Error getting attendance range: $e');
      return {};
    }
  }

  /// Get attendance records for all students in a class for a specific date
  Future<Map<String, AttendanceRecord>> getClassAttendanceForDate(
    String classId,
    String dateKey, // YYYY-MM-DD
  ) async {
    try {
      final attendanceMap = <String, AttendanceRecord>{};

      // Get all students in the class
      final studentsSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'student')
          .where('classId', isEqualTo: classId)
          .get();

      // Get attendance for each student
      for (final studentDoc in studentsSnapshot.docs) {
        final studentId = studentDoc.id;
        try {
          final record = await getStudentAttendanceRecord(studentId, dateKey);
          if (record != null) {
            attendanceMap[studentId] = record;
          }
        } catch (e) {
          debugPrint('Error loading attendance for student $studentId on $dateKey: $e');
          // Continue with other students even if one fails
        }
      }

      return attendanceMap;
    } catch (e) {
      debugPrint('Error getting class attendance for $classId on $dateKey: $e');
      return {};
    }
  }

  /// Get monthly attendance statistics for a student
  Future<Map<String, dynamic>> getStudentMonthlyStats(
    String studentId,
    DateTime month, // Any date in the target month
  ) async {
    try {
      final year = month.year;
      final monthNum = month.month;
      final startDate = DateTime(year, monthNum, 1);
      final endDate = DateTime(year, monthNum + 1, 0); // Last day of month

      final attendanceRecords = await getStudentAttendanceRange(
        studentId,
        startDate,
        endDate,
      );

      int presentDays = 0;
      int absentDays = 0;

      for (final record in attendanceRecords.values) {
        if (record.present) {
          presentDays++;
        } else {
          absentDays++;
        }
      }

      final totalDays = presentDays + absentDays;
      final percentage = totalDays > 0 ? (presentDays / totalDays) * 100 : 0.0;

      return {
        'totalDays': totalDays,
        'presentDays': presentDays,
        'absentDays': absentDays,
        'percentage': percentage,
        'records': attendanceRecords,
      };
    } catch (e) {
      debugPrint('Error getting monthly stats: $e');
      return {
        'totalDays': 0,
        'presentDays': 0,
        'absentDays': 0,
        'percentage': 0.0,
        'records': <String, AttendanceRecord>{},
      };
    }
  }

  /// Format DateTime to YYYY-MM-DD string
  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Get date key from DateTime
  static String getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
