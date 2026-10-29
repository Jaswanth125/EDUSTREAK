class SkillMatrixModel {
  final String studentId;
  final String studentName;
  final double attendance; // 0-100
  final double taskPerformance; // 0-100
  final double engagement; // 0-100
  final double participation; // 0-100
  final double challengeCompletion; // 0-100
  final double overallProgress; // 0-100

  SkillMatrixModel({
    required this.studentId,
    required this.studentName,
    required this.attendance,
    required this.taskPerformance,
    required this.engagement,
    required this.participation,
    required this.challengeCompletion,
    required this.overallProgress,
  });

  // Get all skill values as a list (for radar chart)
  List<double> get skillValues => [
        attendance,
        taskPerformance,
        engagement,
        participation,
        challengeCompletion,
        overallProgress,
      ];

  // Get skill labels
  static List<String> get skillLabels => [
        'Attendance',
        'Task Performance',
        'Engagement',
        'Participation',
        'Challenges',
        'Overall Progress',
      ];

  // Calculate overall score (average of all skills)
  double get overallScore {
    final sum = attendance +
        taskPerformance +
        engagement +
        participation +
        challengeCompletion +
        overallProgress;
    return sum / 6;
  }
}

