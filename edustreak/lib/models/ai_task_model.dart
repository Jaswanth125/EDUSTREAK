import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents an AI-generated personalized task or quiz question.
/// Stored in Firestore at: schools/{schoolId}/ai_generated_tasks/{taskId}
class AiTaskModel {
  final String id;
  final String schoolId;
  final String studentId;
  final String studentName;
  final String classId;
  final String subject;
  final String topic;
  final String difficulty; // 'easy', 'medium', 'hard'
  final String question;
  final List<String> options;
  final String correctAnswer;
  final String explanation;
  final String status; // 'pending_review', 'approved', 'rejected'
  final DateTime createdAt;
  final String? reviewedBy;
  final String? reviewedByName;
  final DateTime? reviewedAt;
  final String? rejectionReason;
  final List<String> completedBy;
  final Map<String, dynamic> studentAnswers; // studentId -> {selectedAnswer, isCorrect, timestamp}

  AiTaskModel({
    required this.id,
    this.schoolId = 'default_school',
    required this.studentId,
    this.studentName = '',
    required this.classId,
    required this.subject,
    required this.topic,
    this.difficulty = 'medium',
    required this.question,
    required this.options,
    required this.correctAnswer,
    this.explanation = '',
    this.status = 'pending_review',
    required this.createdAt,
    this.reviewedBy,
    this.reviewedByName,
    this.reviewedAt,
    this.rejectionReason,
    this.completedBy = const [],
    this.studentAnswers = const {},
  });

  bool get isPending => status == 'pending_review';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  AiTaskModel copyWith({
    String? id,
    String? schoolId,
    String? studentId,
    String? studentName,
    String? classId,
    String? subject,
    String? topic,
    String? difficulty,
    String? question,
    List<String>? options,
    String? correctAnswer,
    String? explanation,
    String? status,
    DateTime? createdAt,
    String? reviewedBy,
    String? reviewedByName,
    DateTime? reviewedAt,
    String? rejectionReason,
    List<String>? completedBy,
    Map<String, dynamic>? studentAnswers,
  }) {
    return AiTaskModel(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      classId: classId ?? this.classId,
      subject: subject ?? this.subject,
      topic: topic ?? this.topic,
      difficulty: difficulty ?? this.difficulty,
      question: question ?? this.question,
      options: options ?? this.options,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      explanation: explanation ?? this.explanation,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedByName: reviewedByName ?? this.reviewedByName,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      completedBy: completedBy ?? this.completedBy,
      studentAnswers: studentAnswers ?? this.studentAnswers,
    );
  }

  factory AiTaskModel.fromMap(Map<String, dynamic> map, {String? id}) {
    DateTime createdAtDate;
    if (map['createdAt'] is Timestamp) {
      createdAtDate = (map['createdAt'] as Timestamp).toDate();
    } else if (map['createdAt'] is String) {
      createdAtDate = DateTime.tryParse(map['createdAt']) ?? DateTime.now();
    } else {
      createdAtDate = DateTime.now();
    }

    DateTime? reviewedAtDate;
    if (map['reviewedAt'] is Timestamp) {
      reviewedAtDate = (map['reviewedAt'] as Timestamp).toDate();
    } else if (map['reviewedAt'] is String) {
      reviewedAtDate = DateTime.tryParse(map['reviewedAt']);
    }

    return AiTaskModel(
      id: id ?? map['id'] ?? '',
      schoolId: map['schoolId'] ?? 'default_school',
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      classId: map['classId'] ?? '',
      subject: map['subject'] ?? 'General',
      topic: map['topic'] ?? 'Practice',
      difficulty: map['difficulty'] ?? 'medium',
      question: map['question'] ?? '',
      options: (map['options'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      correctAnswer: map['correctAnswer'] ?? '',
      explanation: map['explanation'] ?? '',
      status: map['status'] ?? 'pending_review',
      createdAt: createdAtDate,
      reviewedBy: map['reviewedBy'],
      reviewedByName: map['reviewedByName'],
      reviewedAt: reviewedAtDate,
      rejectionReason: map['rejectionReason'],
      completedBy: (map['completedBy'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      studentAnswers: Map<String, dynamic>.from(map['studentAnswers'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'schoolId': schoolId,
      'studentId': studentId,
      'studentName': studentName,
      'classId': classId,
      'subject': subject,
      'topic': topic,
      'difficulty': difficulty,
      'question': question,
      'options': options,
      'correctAnswer': correctAnswer,
      'explanation': explanation,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'reviewedBy': reviewedBy,
      'reviewedByName': reviewedByName,
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'rejectionReason': rejectionReason,
      'completedBy': completedBy,
      'studentAnswers': studentAnswers,
    };
  }
}
