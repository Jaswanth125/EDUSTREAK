import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/attendance_model.dart';

class AttendanceSummaryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Format DateTime to YYYY-MM-DD string
  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Update monthly attendance summary for a class
  /// Called automatically when attendance is marked
  Future<void> updateMonthlySummary({
    required String classId,
    required DateTime date,
    required Map<String, bool> studentAttendance, // studentId -> present
  }) async {
    try {
      final year = date.year;
      final month = date.month;
      final monthKey = '${year}-${month.toString().padLeft(2, '0')}';
      final summaryId = '${classId}_$monthKey';

      // Get or create summary document
      final summaryRef = _firestore
          .collection('attendanceSummary')
          .doc(summaryId);

      final summaryDoc = await summaryRef.get();

      if (summaryDoc.exists) {
        // Update existing summary
        final currentData = summaryDoc.data()!;
        final presentDays = Map<String, int>.from(currentData['presentDays'] ?? {});
        final absentDays = Map<String, int>.from(currentData['absentDays'] ?? {});
        int totalWorkingDays = currentData['totalWorkingDays'] ?? 0;

        // Check if this date was already counted
        final dateKey = _formatDateKey(date);
        final existingDates = List<String>.from(currentData['markedDates'] ?? []);
        
        if (!existingDates.contains(dateKey)) {
          // New date - update counts
          totalWorkingDays++;
          existingDates.add(dateKey);

          for (final entry in studentAttendance.entries) {
            final studentId = entry.key;
            final present = entry.value;

            if (present) {
              presentDays[studentId] = (presentDays[studentId] ?? 0) + 1;
            } else {
              absentDays[studentId] = (absentDays[studentId] ?? 0) + 1;
            }
          }

          await summaryRef.update({
            'totalWorkingDays': totalWorkingDays,
            'presentDays': presentDays,
            'absentDays': absentDays,
            'markedDates': existingDates,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        }
      } else {
        // Create new summary
        final presentDays = <String, int>{};
        final absentDays = <String, int>{};
        final dateKey = _formatDateKey(date);

        for (final entry in studentAttendance.entries) {
          final studentId = entry.key;
          final present = entry.value;

          if (present) {
            presentDays[studentId] = 1;
            absentDays[studentId] = 0;
          } else {
            presentDays[studentId] = 0;
            absentDays[studentId] = 1;
          }
        }

        await summaryRef.set({
          'id': summaryId,
          'classId': classId,
          'monthKey': monthKey,
          'totalWorkingDays': 1,
          'presentDays': presentDays,
          'absentDays': absentDays,
          'markedDates': [dateKey],
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      throw Exception('Failed to update attendance summary: $e');
    }
  }

  /// Get monthly attendance summary for a class
  Future<AttendanceSummary?> getMonthlySummary(
    String classId,
    DateTime month, // Any date in the target month
  ) async {
    try {
      final year = month.year;
      final monthNum = month.month;
      final monthKey = '${year}-${monthNum.toString().padLeft(2, '0')}';
      final summaryId = '${classId}_$monthKey';

      final doc = await _firestore
          .collection('attendanceSummary')
          .doc(summaryId)
          .get();

      if (!doc.exists) return null;

      return AttendanceSummary.fromMap(doc.data()!);
    } catch (e) {
      return null;
    }
  }

  /// Get monthly attendance summary for a student
  Future<Map<String, dynamic>> getStudentMonthlySummary(
    String studentId,
    String classId,
    DateTime month,
  ) async {
    try {
      final summary = await getMonthlySummary(classId, month);
      if (summary == null) {
        return {
          'totalWorkingDays': 0,
          'presentDays': 0,
          'absentDays': 0,
          'percentage': 0.0,
        };
      }

      final presentDays = summary.getPresentDays(studentId);
      final absentDays = summary.getAbsentDays(studentId);
      final totalDays = summary.totalWorkingDays;
      final percentage = totalDays > 0 ? (presentDays / totalDays) * 100 : 0.0;

      return {
        'totalWorkingDays': totalDays,
        'presentDays': presentDays,
        'absentDays': absentDays,
        'percentage': percentage,
      };
    } catch (e) {
      return {
        'totalWorkingDays': 0,
        'presentDays': 0,
        'absentDays': 0,
        'percentage': 0.0,
      };
    }
  }
}

