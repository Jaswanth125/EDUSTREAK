import 'package:cloud_firestore/cloud_firestore.dart';

class AssessmentQuestion {
  final String id;
  final String question;
  final String type; // 'mcq', 'short_answer', 'long_answer'
  final Map<String, String> options; // e.g. {'A': '...', 'B': '...'}
  final String correctAnswer;
  final String explanation;
  final int marks;

  AssessmentQuestion({
    required this.id,
    required this.question,
    this.type = 'mcq',
    this.options = const {},
    required this.correctAnswer,
    this.explanation = '',
    this.marks = 2,
  });

  factory AssessmentQuestion.fromMap(Map<String, dynamic> map) {
    return AssessmentQuestion(
      id: map['id']?.toString() ?? '',
      question: map['question'] ?? '',
      type: map['type'] ?? 'mcq',
      options: Map<String, String>.from(map['options'] ?? {}),
      correctAnswer: map['correctAnswer'] ?? map['correct_answer'] ?? '',
      explanation: map['explanation'] ?? '',
      marks: (map['marks'] as num?)?.toInt() ?? 2,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question': question,
      'type': type,
      'options': options,
      'correctAnswer': correctAnswer,
      'explanation': explanation,
      'marks': marks,
    };
  }
}

class AssessmentModel {
  final String id;
  final String schoolId;
  final String classId;
  final String className;
  final String subject;
  final String chapter;
  final String topic;
  final String title;
  final String description;
  final String type; // 'quiz', 'unit_test', 'practice_test', 'chapter_test', 'mid_term', 'terminal'
  final String status; // 'draft', 'published', 'closed'
  final int totalMarks;
  final int passingMarks;
  final int durationMinutes;
  final DateTime scheduledDate;
  final DateTime dueDate;
  final DateTime createdAt;
  final String createdBy; // teacher id
  final String createdByName;
  final List<AssessmentQuestion> questions;
  final List<String> assignedTo; // student IDs
  final Map<String, String> submissions; // studentId -> 'submitted', 'evaluated'
  final Map<String, double> scores; // studentId -> double score
  final Map<String, String> feedback; // studentId -> feedback text
  final Map<String, Map<String, dynamic>> studentAnswers; // studentId -> { questionId: answer }

  AssessmentModel({
    required this.id,
    this.schoolId = '',
    required this.classId,
    this.className = '',
    required this.subject,
    this.chapter = '',
    this.topic = '',
    required this.title,
    this.description = '',
    this.type = 'quiz',
    this.status = 'published',
    this.totalMarks = 25,
    this.passingMarks = 10,
    this.durationMinutes = 45,
    required this.scheduledDate,
    required this.dueDate,
    required this.createdAt,
    required this.createdBy,
    required this.createdByName,
    this.questions = const [],
    this.assignedTo = const [],
    this.submissions = const {},
    this.scores = const {},
    this.feedback = const {},
    this.studentAnswers = const {},
  });

  factory AssessmentModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    DateTime parseDate(dynamic val, DateTime fallback) {
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      return fallback;
    }

    final questionsRaw = (map['questions'] as List?) ?? [];
    final parsedQuestions = questionsRaw
        .map((q) => AssessmentQuestion.fromMap(Map<String, dynamic>.from(q as Map)))
        .toList();

    return AssessmentModel(
      id: docId ?? (map['id'] ?? ''),
      schoolId: map['schoolId'] ?? '',
      classId: map['classId'] ?? '',
      className: map['className'] ?? '',
      subject: map['subject'] ?? '',
      chapter: map['chapter'] ?? '',
      topic: map['topic'] ?? '',
      title: map['title'] ?? 'Assessment',
      description: map['description'] ?? '',
      type: map['type'] ?? 'quiz',
      status: map['status'] ?? 'published',
      totalMarks: (map['totalMarks'] as num?)?.toInt() ?? 25,
      passingMarks: (map['passingMarks'] as num?)?.toInt() ?? 10,
      durationMinutes: (map['durationMinutes'] as num?)?.toInt() ?? 45,
      scheduledDate: parseDate(map['scheduledDate'], DateTime.now()),
      dueDate: parseDate(map['dueDate'], DateTime.now().add(const Duration(days: 3))),
      createdAt: parseDate(map['createdAt'], DateTime.now()),
      createdBy: map['createdBy'] ?? '',
      createdByName: map['createdByName'] ?? '',
      questions: parsedQuestions,
      assignedTo: List<String>.from(map['assignedTo'] ?? []),
      submissions: Map<String, String>.from(map['submissions'] ?? {}),
      scores: (map['scores'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, (v as num).toDouble()),
          ) ??
          {},
      feedback: Map<String, String>.from(map['feedback'] ?? {}),
      studentAnswers: (map['studentAnswers'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, Map<String, dynamic>.from(v as Map)),
          ) ??
          {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'schoolId': schoolId,
      'classId': classId,
      'className': className,
      'subject': subject,
      'chapter': chapter,
      'topic': topic,
      'title': title,
      'description': description,
      'type': type,
      'status': status,
      'totalMarks': totalMarks,
      'passingMarks': passingMarks,
      'durationMinutes': durationMinutes,
      'scheduledDate': Timestamp.fromDate(scheduledDate),
      'dueDate': Timestamp.fromDate(dueDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'createdByName': createdByName,
      'questions': questions.map((q) => q.toMap()).toList(),
      'assignedTo': assignedTo,
      'submissions': submissions,
      'scores': scores,
      'feedback': feedback,
      'studentAnswers': studentAnswers,
    };
  }

  int get submittedCount => submissions.length;
  int get evaluatedCount => scores.length;

  double get averageScore {
    if (scores.isEmpty) return 0.0;
    final total = scores.values.fold(0.0, (acc, s) => acc + s);
    return total / scores.length;
  }
}
