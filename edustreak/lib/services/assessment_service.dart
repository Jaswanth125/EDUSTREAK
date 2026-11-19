import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/assessment_model.dart';
import 'gamification_service.dart';
import 'in_app_notification_service.dart';

class AssessmentService {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  GamificationService get _gamificationService => GamificationService();
  final InAppNotificationService _notificationService = InAppNotificationService();

  CollectionReference get _assessmentsCollection => _firestore.collection('assessments');

  /// Creates a new assessment in Firestore.
  Future<String> createAssessment(AssessmentModel assessment) async {
    try {
      final docRef = _assessmentsCollection.doc();
      final id = assessment.id.isNotEmpty ? assessment.id : docRef.id;
      final assessmentWithId = AssessmentModel(
        id: id,
        schoolId: assessment.schoolId,
        classId: assessment.classId,
        className: assessment.className,
        subject: assessment.subject,
        chapter: assessment.chapter,
        topic: assessment.topic,
        title: assessment.title,
        description: assessment.description,
        type: assessment.type,
        status: assessment.status,
        totalMarks: assessment.totalMarks,
        passingMarks: assessment.passingMarks,
        durationMinutes: assessment.durationMinutes,
        scheduledDate: assessment.scheduledDate,
        dueDate: assessment.dueDate,
        createdAt: DateTime.now(),
        createdBy: assessment.createdBy,
        createdByName: assessment.createdByName,
        questions: assessment.questions,
        assignedTo: assessment.assignedTo,
        submissions: assessment.submissions,
        scores: assessment.scores,
        feedback: assessment.feedback,
        studentAnswers: assessment.studentAnswers,
      );

      await _assessmentsCollection.doc(id).set(assessmentWithId.toMap());

      if (assessment.status == 'published') {
        _notifyStudentsOfAssessment(assessmentWithId);
      }

      return id;
    } catch (e) {
      if (kDebugMode) print('Error creating assessment: $e');
      rethrow;
    }
  }

  /// Updates an existing assessment.
  Future<void> updateAssessment(AssessmentModel assessment) async {
    try {
      await _assessmentsCollection.doc(assessment.id).update(assessment.toMap());
    } catch (e) {
      if (kDebugMode) print('Error updating assessment: $e');
      rethrow;
    }
  }

  /// Changes assessment status to published.
  Future<void> publishAssessment(String assessmentId) async {
    try {
      await _assessmentsCollection.doc(assessmentId).update({
        'status': 'published',
        'publishedAt': FieldValue.serverTimestamp(),
      });

      final doc = await _assessmentsCollection.doc(assessmentId).get();
      if (doc.exists) {
        final assessment = AssessmentModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        _notifyStudentsOfAssessment(assessment);
      }
    } catch (e) {
      if (kDebugMode) print('Error publishing assessment: $e');
      rethrow;
    }
  }

  /// Deletes an assessment.
  Future<void> deleteAssessment(String assessmentId) async {
    try {
      await _assessmentsCollection.doc(assessmentId).delete();
    } catch (e) {
      if (kDebugMode) print('Error deleting assessment: $e');
      rethrow;
    }
  }

  /// Submits an assessment attempt by a student with auto-grading for objective questions.
  Future<Map<String, dynamic>> submitStudentAssessment({
    required String assessmentId,
    required String studentId,
    required Map<String, dynamic> answers, // { questionId: selectedOptionOrText }
    String studentName = 'Student',
  }) async {
    try {
      final docRef = _assessmentsCollection.doc(assessmentId);
      final doc = await docRef.get();
      if (!doc.exists) throw Exception('Assessment not found');

      final assessment = AssessmentModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);

      // Auto-grade objective questions (MCQs)
      double autoGradedMarks = 0.0;
      int objectiveQuestionsCount = 0;
      int correctObjectiveCount = 0;
      bool hasDescriptive = false;
      final Map<String, bool> questionCorrectness = {};

      for (final q in assessment.questions) {
        final studentAns = answers[q.id]?.toString().trim() ?? '';
        final correctAns = q.correctAnswer.trim();

        if (q.type == 'mcq' || q.options.isNotEmpty) {
          objectiveQuestionsCount++;
          bool isMatch = false;
          if (studentAns.isNotEmpty) {
            if (studentAns.toLowerCase() == correctAns.toLowerCase()) {
              isMatch = true;
            } else if (q.options.containsKey(studentAns) &&
                q.options[studentAns]!.toLowerCase() == correctAns.toLowerCase()) {
              isMatch = true;
            } else if (q.options.entries.any((e) =>
                e.key.toLowerCase() == correctAns.toLowerCase() &&
                e.value.toLowerCase() == studentAns.toLowerCase())) {
              isMatch = true;
            }
          }
          questionCorrectness[q.id] = isMatch;
          if (isMatch) {
            autoGradedMarks += q.marks;
            correctObjectiveCount++;
          }
        } else {
          hasDescriptive = true;
        }
      }

      final isAllObjective = !hasDescriptive && objectiveQuestionsCount > 0;
      final finalStatus = isAllObjective ? 'evaluated' : 'submitted';

      // Update assessment document in Firestore
      await docRef.update({
        'submissions.$studentId': finalStatus,
        'scores.$studentId': autoGradedMarks,
        'studentAnswers.$studentId': answers,
      });

      // Award XP idempotently (50 XP completion + bonus for performance)
      final xpEarned = 50 + (autoGradedMarks * 2).toInt();
      await _gamificationService.addXP(
        studentId,
        xpEarned,
        reason: 'Assessment: ${assessment.title}',
      );

      // Record Skill Evidence for Assessment Performance (formal test evidence)
      try {
        final schoolId = assessment.schoolId.isNotEmpty ? assessment.schoolId : 'school_demo';
        final normalizedScore = assessment.totalMarks > 0
            ? ((autoGradedMarks / assessment.totalMarks) * 100.0).clamp(0.0, 100.0)
            : 70.0;

        final evidenceRef = _firestore.collection('schools').doc(schoolId).collection('skill_evidence');

        // Evidence for Conceptual Understanding
        await evidenceRef.doc('exam_${assessment.id}_${studentId}_concepts').set({
          'id': 'exam_${assessment.id}_${studentId}_concepts',
          'studentId': studentId,
          'schoolId': schoolId,
          'skillId': 'conceptual_understanding',
          'dimensionName': 'Conceptual Understanding',
          'source': 'exam',
          'sourceTitle': assessment.title,
          'rawScore': autoGradedMarks,
          'maxScore': assessment.totalMarks.toDouble(),
          'normalizedScore': normalizedScore,
          'weight': 1.5, // High weight for formal exams
          'subject': assessment.subject,
          'topic': assessment.topic.isNotEmpty ? assessment.topic : assessment.chapter,
          'evaluatorId': assessment.createdBy,
          'evaluatorName': assessment.createdByName,
          'timestamp': FieldValue.serverTimestamp(),
          'periodKey': 'current',
        });

        // Evidence for Problem Solving (if Math or Science)
        if (assessment.subject.toLowerCase().contains('math') ||
            assessment.subject.toLowerCase().contains('science')) {
          await evidenceRef.doc('exam_${assessment.id}_${studentId}_problem').set({
            'id': 'exam_${assessment.id}_${studentId}_problem',
            'studentId': studentId,
            'schoolId': schoolId,
            'skillId': 'problem_solving',
            'dimensionName': 'Problem Solving',
            'source': 'exam',
            'sourceTitle': assessment.title,
            'rawScore': autoGradedMarks,
            'maxScore': assessment.totalMarks.toDouble(),
            'normalizedScore': normalizedScore,
            'weight': 1.5,
            'subject': assessment.subject,
            'topic': assessment.topic.isNotEmpty ? assessment.topic : assessment.chapter,
            'timestamp': FieldValue.serverTimestamp(),
            'periodKey': 'current',
          });
        }
      } catch (e) {
        debugPrint('Note: Error recording assessment skill evidence: $e');
      }

      // Notify Teacher of submission
      if (assessment.createdBy.isNotEmpty) {
        _notificationService.sendNotification(
          userId: assessment.createdBy,
          schoolId: assessment.schoolId,
          title: '📥 Assessment Submission: $studentName',
          body: '$studentName submitted "${assessment.title}". Auto-score: ${autoGradedMarks.toStringAsFixed(0)}/${assessment.totalMarks}',
          type: 'assessment_submission',
          metadata: {
            'assessmentId': assessment.id,
            'studentId': studentId,
          },
        );
      }

      // Notify Student of confirmation
      _notificationService.sendNotification(
        userId: studentId,
        schoolId: assessment.schoolId,
        title: '✅ Assessment Submitted: ${assessment.title}',
        body: isAllObjective
            ? 'Your score: ${autoGradedMarks.toStringAsFixed(0)}/${assessment.totalMarks} (+${xpEarned} XP awarded)'
            : 'Submitted successfully. Awaiting teacher evaluation for descriptive questions.',
        type: 'assessment_submitted',
        metadata: {
          'assessmentId': assessment.id,
          'score': autoGradedMarks,
        },
      );

      return {
        'score': autoGradedMarks,
        'totalMarks': assessment.totalMarks,
        'isAllObjective': isAllObjective,
        'correctCount': correctObjectiveCount,
        'objectiveCount': objectiveQuestionsCount,
        'questionCorrectness': questionCorrectness,
        'xpEarned': xpEarned,
      };
    } catch (e) {
      if (kDebugMode) print('Error submitting student assessment: $e');
      rethrow;
    }
  }

  /// Grades a student's submission.
  Future<void> gradeStudentSubmission({
    required String assessmentId,
    required String studentId,
    required double score,
    required String feedback,
    int xpPoints = 50,
  }) async {
    try {
      final docRef = _assessmentsCollection.doc(assessmentId);
      final snap = await docRef.get();
      final assessment = snap.exists ? AssessmentModel.fromMap(snap.data() as Map<String, dynamic>, snap.id) : null;

      await docRef.update({
        'submissions.$studentId': 'evaluated',
        'scores.$studentId': score,
        'feedback.$studentId': feedback,
      });

      // Award XP to the student upon successful evaluation
      await _gamificationService.addXP(
        studentId,
        xpPoints,
        reason: 'Assessment Graded: Score $score',
      );

      // Record formal assessment evidence for Skill Matrix
      if (assessment != null) {
        try {
          final schoolId = assessment.schoolId.isNotEmpty ? assessment.schoolId : 'school_demo';
          final normalizedScore = assessment.totalMarks > 0
              ? ((score / assessment.totalMarks) * 100.0).clamp(0.0, 100.0)
              : 75.0;

          final evidenceRef = _firestore.collection('schools').doc(schoolId).collection('skill_evidence');
          await evidenceRef.doc('exam_${assessment.id}_${studentId}_graded').set({
            'id': 'exam_${assessment.id}_${studentId}_graded',
            'studentId': studentId,
            'schoolId': schoolId,
            'skillId': 'conceptual_understanding',
            'dimensionName': 'Conceptual Understanding',
            'source': 'exam',
            'sourceTitle': assessment.title,
            'rawScore': score,
            'maxScore': assessment.totalMarks.toDouble(),
            'normalizedScore': normalizedScore,
            'weight': 1.6,
            'subject': assessment.subject,
            'topic': assessment.topic.isNotEmpty ? assessment.topic : assessment.chapter,
            'evaluatorId': assessment.createdBy,
            'evaluatorName': assessment.createdByName,
            'feedback': feedback,
            'timestamp': FieldValue.serverTimestamp(),
            'periodKey': 'current',
          });
        } catch (_) {}

        // Notify student of published grade
        _notificationService.sendNotification(
          userId: studentId,
          schoolId: assessment.schoolId,
          title: '🎉 Assessment Graded: ${assessment.title}',
          body: 'Score: ${score.toStringAsFixed(0)}/${assessment.totalMarks} • Feedback: ${feedback.isNotEmpty ? feedback : "Well done!"}',
          type: 'assessment_graded',
          metadata: {
            'assessmentId': assessment.id,
            'score': score,
            'feedback': feedback,
          },
        );
      }
    } catch (e) {
      if (kDebugMode) print('Error grading submission: $e');
      rethrow;
    }
  }

  /// Broadcast notifications to enrolled students when an assessment is published.
  Future<void> _notifyStudentsOfAssessment(AssessmentModel assessment) async {
    try {
      final studentsSnap = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'student')
          .where('classId', isEqualTo: assessment.classId)
          .get();

      for (final doc in studentsSnap.docs) {
        _notificationService.sendNotification(
          userId: doc.id,
          schoolId: assessment.schoolId,
          title: '📝 New Assessment: ${assessment.title}',
          body: '${assessment.subject} • ${assessment.totalMarks} Marks • Duration: ${assessment.durationMinutes} mins',
          type: 'assessment_published',
          metadata: {
            'assessmentId': assessment.id,
            'subject': assessment.subject,
            'classId': assessment.classId,
          },
        );
      }
    } catch (_) {}
  }

  /// Stream of assessments for a given teacher and optional class filter.
  Stream<List<AssessmentModel>> getAssessmentsStream({
    required String teacherId,
    String? classId,
  }) {
    try {
      Query query = _assessmentsCollection;

      if (teacherId.isNotEmpty) {
        query = query.where('createdBy', isEqualTo: teacherId);
      }

      if (classId != null && classId.isNotEmpty && classId != 'All') {
        query = query.where('classId', isEqualTo: classId);
      }

      return query.snapshots().map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return AssessmentModel.fromMap(data, doc.id);
        }).toList();
      }).handleError((_) => <AssessmentModel>[]);
    } catch (_) {
      return Stream.value(<AssessmentModel>[]);
    }
  }

  /// Stream of assessments for a given student (filtered by student's class).
  Stream<List<AssessmentModel>> getAssessmentsForStudent({
    required String studentId,
    String? classId,
  }) {
    try {
      Query query = _assessmentsCollection;

      if (classId != null && classId.isNotEmpty && classId != 'All') {
        query = query.where('classId', isEqualTo: classId);
      }

      return query.snapshots().map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return AssessmentModel.fromMap(data, doc.id);
        }).where((a) => a.status == 'published' || a.status == 'closed').toList();
      }).handleError((_) => <AssessmentModel>[]);
    } catch (_) {
      return Stream.value(<AssessmentModel>[]);
    }
  }
}
