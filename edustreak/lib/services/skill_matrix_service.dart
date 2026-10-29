import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/skill_matrix_model.dart';
import '../models/user_model.dart';

class SkillMatrixService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Calculate skill matrix for a student (optimized for fast loading)
  Future<SkillMatrixModel> calculateSkillMatrix(String studentId) async {
    try {
      // Get student data once
      final studentDoc = await _firestore.collection('users').doc(studentId).get();
      if (!studentDoc.exists) {
        throw Exception('Student not found');
      }

      final studentData = studentDoc.data()!;
      final student = UserModel.fromMap(studentData..['id'] = studentId);
      final studentName = student.name;
      final classId = student.classId;

      // Use attendance summary for faster attendance calculation
      final now = DateTime.now();
      final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      
      // Parallel fetch for all data sources
      final futures = <Future>[
        // Attendance from summary (faster)
        classId != null
            ? _firestore
                .collection('attendanceSummary')
                .doc('${classId}_$monthKey')
                .get()
                .then((doc) => doc.data())
            : Future.value(null),
        // Task submissions count only (not all data)
        _firestore
            .collection('taskSubmissions')
            .where('studentId', isEqualTo: studentId)
            .count()
            .get(),
        // Challenges count only
        _firestore
            .collection('challenges')
            .where('assignedTo', arrayContains: studentId)
            .count()
            .get(),
      ];

      final results = await Future.wait(futures);
      final attendanceSummary = results[0] as Map<String, dynamic>?;
      final taskCount = (results[1] as AggregateQuerySnapshot).count ?? 0;
      final challengeCount = (results[2] as AggregateQuerySnapshot).count ?? 0;

      // Calculate skills using cached/optimized data
      final attendance = _calculateAttendanceFast(attendanceSummary, studentId);
      final taskPerformance = await _calculateTaskPerformanceFast(studentId, taskCount);
      final engagement = _calculateEngagementFast(student);
      final participation = _calculateParticipationFast(student);
      final challengeCompletion = await _calculateChallengeCompletionFast(studentId, challengeCount);
      final overallProgress = _calculateOverallProgressFast(student);

      return SkillMatrixModel(
        studentId: studentId,
        studentName: studentName,
        attendance: attendance,
        taskPerformance: taskPerformance,
        engagement: engagement,
        participation: participation,
        challengeCompletion: challengeCompletion,
        overallProgress: overallProgress,
      );
    } catch (e) {
      debugPrint('Error calculating skill matrix: $e');
      // Return default values on error
      final studentDoc = await _firestore.collection('users').doc(studentId).get();
      final studentName = studentDoc.data()?['name'] ?? 'Unknown';
      
      return SkillMatrixModel(
        studentId: studentId,
        studentName: studentName,
        attendance: 0,
        taskPerformance: 0,
        engagement: 0,
        participation: 0,
        challengeCompletion: 0,
        overallProgress: 0,
      );
    }
  }

  /// Fast attendance calculation using summary
  double _calculateAttendanceFast(Map<String, dynamic>? summary, String studentId) {
    if (summary == null) return 0.0;
    final totalDays = summary['totalWorkingDays'] as int? ?? 0;
    if (totalDays == 0) return 0.0;
    final presentDays = (summary['presentDays'] as Map<String, dynamic>?)?[studentId] as int? ?? 0;
    return (presentDays / totalDays) * 100;
  }

  /// Fast task performance - only fetch completed tasks
  Future<double> _calculateTaskPerformanceFast(String studentId, int totalTasks) async {
    if (totalTasks == 0) return 0.0;
    
    try {
      // Only get submitted tasks with marks
      final submittedSnapshot = await _firestore
          .collection('taskSubmissions')
          .where('studentId', isEqualTo: studentId)
          .where('isSubmitted', isEqualTo: true)
          .limit(50) // Limit to recent 50 for performance
          .get();

      if (submittedSnapshot.docs.isEmpty) return 0.0;

      double totalMarks = 0.0;
      double maxMarks = 0.0;
      int completedTasks = submittedSnapshot.docs.length;

      for (final doc in submittedSnapshot.docs) {
        final data = doc.data();
        final marks = (data['marks'] as num?)?.toDouble() ?? 0.0;
        final maxMarksForTask = (data['maxMarks'] as num?)?.toDouble() ?? 100.0;
        totalMarks += marks;
        maxMarks += maxMarksForTask;
      }

      final completionRate = (completedTasks / totalTasks) * 100;
      final averageGrade = maxMarks > 0 ? (totalMarks / maxMarks) * 100 : 0.0;

      return (completionRate * 0.4) + (averageGrade * 0.6);
    } catch (e) {
      debugPrint('Error calculating task performance: $e');
      return 0.0;
    }
  }

  /// Fast engagement (no async needed)
  double _calculateEngagementFast(UserModel student) {
    final xpScore = (student.xp / 10000).clamp(0.0, 1.0) * 50;
    final levelScore = (student.level / 20).clamp(0.0, 1.0) * 50;
    return xpScore + levelScore;
  }

  /// Fast participation (no async needed)
  double _calculateParticipationFast(UserModel student) {
    final streakScore = (student.streakCount / 30).clamp(0.0, 1.0) * 50;
    final badgeCount = student.badges.length;
    final badgeScore = (badgeCount / 10).clamp(0.0, 1.0) * 50;
    return streakScore + badgeScore;
  }

  /// Fast challenge completion
  Future<double> _calculateChallengeCompletionFast(String studentId, int totalChallenges) async {
    if (totalChallenges == 0) return 0.0;
    
    try {
      // Get all assigned challenges and check completion in memory
      final challengesSnapshot = await _firestore
          .collection('challenges')
          .where('assignedTo', arrayContains: studentId)
          .limit(100) // Limit for performance
          .get();

      int completedCount = 0;
      for (final doc in challengesSnapshot.docs) {
        final data = doc.data();
        final completedBy = List<String>.from(data['completedBy'] ?? []);
        if (completedBy.contains(studentId)) {
          completedCount++;
        }
      }

      return (completedCount / totalChallenges) * 100;
    } catch (e) {
      debugPrint('Error calculating challenge completion: $e');
      return 0.0;
    }
  }

  /// Fast overall progress (no async needed)
  double _calculateOverallProgressFast(UserModel student) {
    final xpProgress = (student.xp / 10000).clamp(0.0, 1.0) * 30;
    final levelProgress = (student.level / 20).clamp(0.0, 1.0) * 30;
    final streakProgress = (student.streakCount / 30).clamp(0.0, 1.0) * 20;
    final badgeProgress = (student.badges.length / 10).clamp(0.0, 1.0) * 20;
    return xpProgress + levelProgress + streakProgress + badgeProgress;
  }

}

