import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  final String id;
  final String classId;
  final String title;
  final String description;

  /// Subject this task belongs to (e.g. 'Mathematics', 'Science', 'English').
  /// Used by AI weak-topic detection to identify struggling areas accurately
  /// instead of guessing from the task title.
  final String subject;

  final String assignedBy; // teacher ID
  final String assignedByName; // teacher name
  final DateTime dueDate;
  final DateTime createdAt;
  final List<String> assignedTo; // student IDs
  final Map<String, String> submissions; // studentId -> submission status

  /// @deprecated Use [submissionTexts] for student work. Kept for backward compat only.
  final Map<String, String> proofUrls;

  final Map<String, String> submissionTexts; // studentId -> submission text
  final Map<String, double> marks; // studentId -> marks/grades
  final Map<String, String> feedback; // studentId -> teacher feedback
  final Map<String, int> pointsAwarded; // studentId -> points awarded for grade
  final int maxMarks; // Maximum marks for this assignment
  final int xpReward;

  TaskModel({
    required this.id,
    required this.classId,
    required this.title,
    required this.description,
    this.subject = '',
    required this.assignedBy,
    required this.assignedByName,
    required this.dueDate,
    required this.createdAt,
    required this.assignedTo,
    this.submissions = const {},
    this.proofUrls = const {},
    this.submissionTexts = const {},
    this.marks = const {},
    this.feedback = const {},
    this.pointsAwarded = const {},
    this.maxMarks = 100,
    this.xpReward = 50,
  });

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    // Null-safe dueDate — fall back to tomorrow so the app never crashes on
    // malformed or legacy Firestore documents missing this field.
    DateTime _parseDueDate() {
      try {
        if (map['dueDate'] is Timestamp) {
          return (map['dueDate'] as Timestamp).toDate();
        }
        if (map['dueDate'] is DateTime) return map['dueDate'] as DateTime;
      } catch (_) {}
      return DateTime.now().add(const Duration(days: 1));
    }

    DateTime _parseCreatedAt() {
      try {
        if (map['createdAt'] is Timestamp) {
          return (map['createdAt'] as Timestamp).toDate();
        }
        if (map['createdAt'] is DateTime) return map['createdAt'] as DateTime;
      } catch (_) {}
      return DateTime.now();
    }

    return TaskModel(
      id: map['id'] ?? '',
      classId: map['classId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      subject: map['subject'] ?? '',
      assignedBy: map['assignedBy'] ?? '',
      assignedByName: map['assignedByName'] ?? '',
      dueDate: _parseDueDate(),
      createdAt: _parseCreatedAt(),
      assignedTo: List<String>.from(map['assignedTo'] ?? []),
      submissions: Map<String, String>.from(map['submissions'] ?? {}),
      proofUrls: Map<String, String>.from(map['proofUrls'] ?? {}),
      submissionTexts: Map<String, String>.from(map['submissionTexts'] ?? {}),
      marks: (map['marks'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, (v as num).toDouble())) ??
          {},
      feedback: Map<String, String>.from(map['feedback'] ?? {}),
      pointsAwarded: (map['pointsAwarded'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, (v as num).toInt())) ??
          {},
      maxMarks: map['maxMarks'] ?? 100,
      xpReward: map['xpReward'] ?? 50,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'classId': classId,
      'title': title,
      'description': description,
      'subject': subject,
      'assignedBy': assignedBy,
      'assignedByName': assignedByName,
      'dueDate': Timestamp.fromDate(dueDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'assignedTo': assignedTo,
      'submissions': submissions,
      'proofUrls': proofUrls,
      'submissionTexts': submissionTexts,
      'marks': marks,
      'feedback': feedback,
      'pointsAwarded': pointsAwarded,
      'maxMarks': maxMarks,
      'xpReward': xpReward,
    };
  }
}

