import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/ai_task_model.dart';
import 'gamification_service.dart';

class AiGenerationResult {
  final bool success;
  final String message;
  final AiTaskModel? task;
  final bool isCached;

  const AiGenerationResult({
    required this.success,
    required this.message,
    this.task,
    this.isCached = false,
  });
}

class AiTaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GamificationService _gamificationService = GamificationService();

  // Reference helper for tenant-scoped collection
  CollectionReference<Map<String, dynamic>> _aiTasksRef(String schoolId) {
    return _firestore
        .collection('schools')
        .doc(schoolId)
        .collection('ai_generated_tasks');
  }

  /// 1. Analyze student's weak subjects/topics from their last N tasks
  Future<Map<String, dynamic>> detectWeakTopic(String studentId) async {
    try {
      final tasksSnapshot = await _firestore
          .collection('tasks')
          .where('assignedTo', arrayContains: studentId)
          .limit(20)
          .get();

      if (tasksSnapshot.docs.isEmpty) {
        return {
          'subject': 'Mathematics',
          'topic': 'Fundamentals & Problem Solving',
          'reason': 'Initial diagnostic practice',
          'needsPractice': true,
        };
      }

      final Map<String, List<double>> subjectScores = {};
      final Map<String, int> skippedCounts = {};

      for (var doc in tasksSnapshot.docs) {
        final data = doc.data();
        final title = data['title']?.toString() ?? 'General';

        // ✅ Priority 1: Use the explicit subject field (added to TaskModel).
        // ✅ Priority 2: Fall back to title-string matching for legacy tasks.
        String subject = _inferSubject(
          explicitSubject: data['subject']?.toString(),
          title: title,
        );

        final maxMarks = (data['maxMarks'] as num?)?.toDouble() ?? 100.0;
        final marksMap = data['marks'] as Map<String, dynamic>?;
        final studentMark = marksMap?[studentId] as num?;

        if (studentMark != null && maxMarks > 0) {
          final scorePct = (studentMark.toDouble() / maxMarks) * 100;
          subjectScores.putIfAbsent(subject, () => []).add(scorePct);
        } else {
          final submissions = data['submissions'] as Map<String, dynamic>?;
          final subStatus = submissions?[studentId]?.toString();
          if (subStatus == null || subStatus == 'not_submitted') {
            skippedCounts[subject] = (skippedCounts[subject] ?? 0) + 1;
          }
        }
      }

      // Rule: Identify subject with average score < 70% or highest skipped count
      String? weakestSubject;
      double lowestAverage = 100.0;

      subjectScores.forEach((subj, scores) {
        final avg = scores.reduce((a, b) => a + b) / scores.length;
        if (avg < 70.0 && avg < lowestAverage) {
          lowestAverage = avg;
          weakestSubject = subj;
        }
      });

      // If no score < 70%, check most skipped
      if (weakestSubject == null && skippedCounts.isNotEmpty) {
        var sortedSkipped = skippedCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        weakestSubject = sortedSkipped.first.key;
      }

      final finalSubject = weakestSubject ?? 'Mathematics';
      return {
        'subject': finalSubject,
        'topic': '$finalSubject Problem Solving & Core Concepts',
        'averageScore': lowestAverage < 100 ? lowestAverage.round() : null,
        'reason': lowestAverage < 70
            ? 'Recent average score was below 70%'
            : 'Targeted reinforcement practice',
        'needsPractice': true,
      };
    } catch (e) {
      debugPrint('Error detecting weak topic: $e');
      return {
        'subject': 'Mathematics',
        'topic': 'Core Concepts',
        'reason': 'Curriculum reinforcement',
        'needsPractice': true,
      };
    }
  }

  /// Returns a canonical subject name by:
  /// 1. Using [explicitSubject] if it is non-null and non-empty (new tasks).
  /// 2. Falling back to keyword-matching on [title] (legacy tasks).
  String _inferSubject({String? explicitSubject, required String title}) {
    if (explicitSubject != null && explicitSubject.trim().isNotEmpty) {
      return explicitSubject.trim();
    }
    final t = title.toLowerCase();
    if (t.contains('math') ||
        t.contains('algebra') ||
        t.contains('geometry') ||
        t.contains('calculus')) {
      return 'Mathematics';
    } else if (t.contains('science') ||
        t.contains('physic') ||
        t.contains('chem') ||
        t.contains('bio')) {
      return 'Science';
    } else if (t.contains('eng') ||
        t.contains('grammar') ||
        t.contains('essay')) {
      return 'English';
    } else if (t.contains('hist') ||
        t.contains('geog') ||
        t.contains('social')) {
      return 'Social Studies';
    }
    return 'General Studies';
  }


  /// 2. Cost-Control Topic Caching
  /// Check if an approved task for this topic/subject already exists in the school
  Future<AiTaskModel?> findCachedApprovedTask({
    required String schoolId,
    required String subject,
    required String topic,
    required String studentId,
  }) async {
    try {
      final query = await _aiTasksRef(schoolId)
          .where('subject', isEqualTo: subject)
          .where('status', isEqualTo: 'approved')
          .limit(10)
          .get();

      for (var doc in query.docs) {
        final task = AiTaskModel.fromMap(doc.data(), id: doc.id);
        // If this student hasn't completed it yet, we can reuse it immediately!
        if (!task.completedBy.contains(studentId)) {
          return task;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Cache check error (non-fatal): $e');
      return null;
    }
  }

  /// 3. Main Generation Method:
  /// Diagnoses weak area, checks cache for cost control, calls LLM if needed,
  /// saves to `schools/{schoolId}/ai_generated_tasks/{taskId}` in `pending_review` state.
  Future<AiGenerationResult> generatePersonalizedTaskForStudent({
    required String studentId,
    required String studentName,
    required String classId,
    String schoolId = 'default_school',
    String? preferredSubject,
    String? preferredTopic,
  }) async {
    try {
      // 1. Weak topic detection
      String subject = preferredSubject ?? '';
      String topic = preferredTopic ?? '';
      String reason = 'Curriculum practice';

      if (subject.isEmpty || topic.isEmpty) {
        final diagnosis = await detectWeakTopic(studentId);
        subject = diagnosis['subject'] ?? 'Mathematics';
        topic = diagnosis['topic'] ?? 'Core Concepts';
        reason = diagnosis['reason'] ?? 'Targeted reinforcement';
      }

      // 2. Cost Control: Check cache for reusable approved tasks
      final cachedTask = await findCachedApprovedTask(
        schoolId: schoolId,
        subject: subject,
        topic: topic,
        studentId: studentId,
      );

      if (cachedTask != null) {
        return AiGenerationResult(
          success: true,
          message: 'Found an approved practice task for $subject: $topic',
          task: cachedTask,
          isCached: true,
        );
      }

      // 3. Call LLM API (Gemini or OpenAI compatible)
      final rawAiResponse = await _callLlmApi(
        subject: subject,
        topic: topic,
        studentName: studentName,
        reason: reason,
      );

      if (rawAiResponse == null) {
        return const AiGenerationResult(
          success: false,
          message: "Couldn't generate right now, try later.",
        );
      }

      // 4. Parse LLM JSON output
      final parsed = _parseAiTaskJson(rawAiResponse, subject, topic);
      if (parsed == null) {
        return const AiGenerationResult(
          success: false,
          message: "Couldn't generate right now, try later.",
        );
      }

      // 5. Store in Firestore under schools/{schoolId}/ai_generated_tasks
      final taskId = _aiTasksRef(schoolId).doc().id;
      final newTask = AiTaskModel(
        id: taskId,
        schoolId: schoolId,
        studentId: studentId,
        studentName: studentName,
        classId: classId,
        subject: parsed['subject'] ?? subject,
        topic: parsed['topic'] ?? topic,
        difficulty: parsed['difficulty'] ?? 'medium',
        question: parsed['question'] ?? '',
        options: List<String>.from(parsed['options'] ?? []),
        correctAnswer: parsed['correctAnswer'] ?? '',
        explanation: parsed['explanation'] ?? '',
        status: 'pending_review', // Strict Trust & Safety: Pending teacher approval
        createdAt: DateTime.now(),
      );

      await _aiTasksRef(schoolId).doc(taskId).set(newTask.toMap());

      return AiGenerationResult(
        success: true,
        message: 'Personalized practice task generated! Pending teacher review.',
        task: newTask,
        isCached: false,
      );
    } catch (e) {
      debugPrint('AI Task generation error: $e');
      return const AiGenerationResult(
        success: false,
        message: "Couldn't generate right now, try later.",
      );
    }
  }

  /// Calls Google Gemini or OpenAI compatible endpoint using flutter_dotenv
  Future<String?> _callLlmApi({
    required String subject,
    required String topic,
    required String studentName,
    required String reason,
  }) async {
    final geminiKey = dotenv.env['GEMINI_API_KEY'];
    final openAiKey = dotenv.env['OPENAI_API_KEY'];

    final prompt = '''
You are an expert adaptive education tutor for high school students.
Create a high-quality, engaging multiple-choice practice question targeted at the student's weak area.

Student context:
- Name: $studentName
- Focus Subject: $subject
- Topic: $topic
- Reason: $reason

Requirements:
1. Provide exactly one multiple choice question with 4 clear, plausible options (labeled A, B, C, D or just plain text choices).
2. Specify the single exact correct answer.
3. Include a concise, supportive 1-2 sentence explanation of why the answer is correct.
4. Output ONLY valid, raw JSON with NO markdown code fences and NO extra surrounding text.

JSON Schema:
{
  "subject": "$subject",
  "topic": "$topic",
  "difficulty": "medium",
  "question": "Clear and pedagogical question string",
  "options": ["Option 1", "Option 2", "Option 3", "Option 4"],
  "correctAnswer": "Exact matching string of correct option",
  "explanation": "Clear explanation of the solution"
}
''';

    // 1. Try Gemini API if key is available
    if (geminiKey != null && geminiKey.trim().isNotEmpty) {
      try {
        final model = dotenv.env['LLM_MODEL'] ?? 'gemini-1.5-flash';
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$geminiKey',
        );

        final response = await http
            .post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'contents': [
                  {
                    'parts': [
                      {'text': prompt}
                    ]
                  }
                ],
                'generationConfig': {
                  'responseMimeType': 'application/json',
                  'temperature': 0.7,
                },
              }),
            )
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
          if (text != null && text.toString().trim().isNotEmpty) {
            return text.toString();
          }
        } else {
          debugPrint('Gemini API returned status ${response.statusCode}: ${response.body}');
        }
      } catch (e) {
        debugPrint('Gemini API call failed: $e');
      }
    }

    // 2. Try OpenAI API if key is available
    if (openAiKey != null && openAiKey.trim().isNotEmpty) {
      try {
        final baseUrl = dotenv.env['OPENAI_BASE_URL'] ?? 'https://api.openai.com/v1';
        final url = Uri.parse('$baseUrl/chat/completions');

        final response = await http
            .post(
              url,
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $openAiKey',
              },
              body: jsonEncode({
                'model': 'gpt-4o-mini',
                'messages': [
                  {'role': 'system', 'content': 'You are an educational assistant that outputs JSON only.'},
                  {'role': 'user', 'content': prompt},
                ],
                'response_format': {'type': 'json_object'},
                'temperature': 0.7,
              }),
            )
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final text = data['choices']?[0]?['message']?['content'];
          if (text != null && text.toString().trim().isNotEmpty) {
            return text.toString();
          }
        }
      } catch (e) {
        debugPrint('OpenAI API call failed: $e');
      }
    }

    // 3. Fallback Adaptive Generator (Graceful offline/test fallback)
    // Ensures the app works smoothly in local testing even before user configures an API key
    debugPrint('Using built-in adaptive curriculum fallback (no API key configured or offline)');
    return _generateFallbackCurriculumQuiz(subject, topic);
  }

  /// Parses JSON from AI response, stripping any accidental markdown fences
  Map<String, dynamic>? _parseAiTaskJson(String rawText, String defaultSubject, String defaultTopic) {
    try {
      String cleanText = rawText.trim();
      if (cleanText.startsWith('```json')) {
        cleanText = cleanText.substring(7);
      } else if (cleanText.startsWith('```')) {
        cleanText = cleanText.substring(3);
      }
      if (cleanText.endsWith('```')) {
        cleanText = cleanText.substring(0, cleanText.length - 3);
      }
      cleanText = cleanText.trim();

      final decoded = jsonDecode(cleanText);
      if (decoded is Map<String, dynamic>) {
        // Validation of required fields
        if (decoded['question'] != null &&
            decoded['options'] is List &&
            (decoded['options'] as List).isNotEmpty &&
            decoded['correctAnswer'] != null) {
          return decoded;
        }
      }
      return null;
    } catch (e) {
      debugPrint('JSON parsing error from AI response: $e\nRaw: $rawText');
      return null;
    }
  }

  /// Fallback curated adaptive question bank for offline/development use
  String _generateFallbackCurriculumQuiz(String subject, String topic) {
    if (subject.toLowerCase().contains('math')) {
      return jsonEncode({
        'subject': 'Mathematics',
        'topic': topic,
        'difficulty': 'medium',
        'question': 'Solve for x in the linear equation: 3x - 7 = 14.',
        'options': ['x = 5', 'x = 7', 'x = 9', 'x = 3'],
        'correctAnswer': 'x = 7',
        'explanation': 'Add 7 to both sides: 3x = 21. Then divide both sides by 3: x = 7.',
      });
    } else if (subject.toLowerCase().contains('science')) {
      return jsonEncode({
        'subject': 'Science',
        'topic': topic,
        'difficulty': 'medium',
        'question': 'Which cellular organelle is responsible for generating most of the cell’s supply of adenosine triphosphate (ATP)?',
        'options': ['Ribosome', 'Mitochondria', 'Endoplasmic Reticulum', 'Golgi Apparatus'],
        'correctAnswer': 'Mitochondria',
        'explanation': 'Mitochondria are often referred to as the powerhouses of the cell because they produce ATP through cellular respiration.',
      });
    } else {
      return jsonEncode({
        'subject': subject,
        'topic': topic,
        'difficulty': 'medium',
        'question': 'Which of the following represents an effective strategy for conceptual mastery and retention?',
        'options': ['Active recall with spaced repetition', 'Passive re-reading of notes', 'Cramming the night before', 'Highlighting entire pages'],
        'correctAnswer': 'Active recall with spaced repetition',
        'explanation': 'Cognitive science demonstrates that actively testing memory combined with spaced intervals dramatically improves long-term retention.',
      });
    }
  }

  // --- Teacher Review & Moderation Methods ---

  /// Stream of pending AI-generated tasks for a specific class
  Stream<List<AiTaskModel>> getPendingTasksForClass(String schoolId, String classId) {
    return _aiTasksRef(schoolId)
        .where('classId', isEqualTo: classId)
        .where('status', isEqualTo: 'pending_review')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AiTaskModel.fromMap(doc.data(), id: doc.id))
            .toList());
  }

  /// Stream of all pending AI tasks across the school for teachers
  Stream<List<AiTaskModel>> getAllPendingTasks(String schoolId) {
    return _aiTasksRef(schoolId)
        .where('status', isEqualTo: 'pending_review')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AiTaskModel.fromMap(doc.data(), id: doc.id))
            .toList());
  }

  /// Teacher action: Approve task
  Future<void> approveTask({
    required String schoolId,
    required String taskId,
    required String teacherId,
    required String teacherName,
  }) async {
    await _aiTasksRef(schoolId).doc(taskId).update({
      'status': 'approved',
      'reviewedBy': teacherId,
      'reviewedByName': teacherName,
      'reviewedAt': Timestamp.now(),
    });
  }

  /// Teacher action: Reject task
  Future<void> rejectTask({
    required String schoolId,
    required String taskId,
    required String teacherId,
    String? reason,
  }) async {
    await _aiTasksRef(schoolId).doc(taskId).update({
      'status': 'rejected',
      'reviewedBy': teacherId,
      'reviewedAt': Timestamp.now(),
      'rejectionReason': reason ?? 'Declined by teacher',
    });
  }

  /// Teacher action: Edit and Approve task
  Future<void> editAndApproveTask({
    required String schoolId,
    required String taskId,
    required String teacherId,
    required String teacherName,
    required String question,
    required List<String> options,
    required String correctAnswer,
    String? explanation,
  }) async {
    await _aiTasksRef(schoolId).doc(taskId).update({
      'status': 'approved',
      'question': question,
      'options': options,
      'correctAnswer': correctAnswer,
      if (explanation != null) 'explanation': explanation,
      'reviewedBy': teacherId,
      'reviewedByName': teacherName,
      'reviewedAt': Timestamp.now(),
    });
  }

  // --- Student Practice & Gamification Methods ---

  /// Stream of approved AI tasks available for a student
  Stream<List<AiTaskModel>> getApprovedPracticeTasks({
    required String schoolId,
    required String studentId,
    required String classId,
  }) {
    // Return approved tasks assigned to this student or class
    return _aiTasksRef(schoolId)
        .where('status', isEqualTo: 'approved')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AiTaskModel.fromMap(doc.data(), id: doc.id))
          .where((t) => t.studentId == studentId || t.classId == classId)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  /// Student submits an answer to an AI practice question
  Future<Map<String, dynamic>> submitStudentAnswer({
    required String schoolId,
    required String taskId,
    required String studentId,
    required String selectedOption,
  }) async {
    try {
      final docRef = _aiTasksRef(schoolId).doc(taskId);
      final doc = await docRef.get();

      if (!doc.exists) {
        return {'success': false, 'message': 'Task not found'};
      }

      final task = AiTaskModel.fromMap(doc.data()!, id: doc.id);
      final isCorrect = selectedOption.trim() == task.correctAnswer.trim();

      // Check if already completed by this student
      final alreadyCompleted = task.completedBy.contains(studentId);

      // Record answer
      final updatedCompleted = List<String>.from(task.completedBy);
      if (!alreadyCompleted) {
        updatedCompleted.add(studentId);
      }

      final updatedAnswers = Map<String, dynamic>.from(task.studentAnswers);
      updatedAnswers[studentId] = {
        'selectedOption': selectedOption,
        'isCorrect': isCorrect,
        'submittedAt': Timestamp.now(),
      };

      await docRef.update({
        'completedBy': updatedCompleted,
        'studentAnswers': updatedAnswers,
      });

      // Gamification: Award 15 XP if correct and not previously solved
      int xpEarned = 0;
      if (isCorrect && !alreadyCompleted) {
        xpEarned = 15;
        await _gamificationService.addXP(studentId, xpEarned);
      }

      return {
        'success': true,
        'isCorrect': isCorrect,
        'correctAnswer': task.correctAnswer,
        'explanation': task.explanation,
        'xpEarned': xpEarned,
      };
    } catch (e) {
      debugPrint('Error submitting student answer: $e');
      return {
        'success': false,
        'message': 'Failed to submit answer. Please try again.',
      };
    }
  }
}
