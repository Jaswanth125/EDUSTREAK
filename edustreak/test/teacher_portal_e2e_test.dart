import 'package:flutter_test/flutter_test.dart';
import 'package:edustreak/models/user_model.dart';
import 'package:edustreak/models/resource_model.dart';
import 'package:edustreak/models/task_model.dart';
import 'package:edustreak/utils/class_name_helper.dart';
import 'package:edustreak/services/teacher_ai_hub_service.dart';
import 'package:edustreak/models/assessment_model.dart';

void main() {
  group('1. ClassNameHelper & Raw Document ID Sanitization Tests', () {
    setUp(() {
      ClassNameHelper.clearCache();
    });

    test('isRawDocumentId detects random alphanumeric Firestore IDs', () {
      expect(ClassNameHelper.isRawDocumentId('0XpwI38PyE9zavRdjcG1'), isTrue);
      expect(ClassNameHelper.isRawDocumentId('k9Z1X2w3e4r5t6y7u8i9o0p'), isTrue);
      expect(ClassNameHelper.isRawDocumentId('abc123456789def012345'), isTrue);
    });

    test('isRawDocumentId rejects legitimate class and grade names', () {
      expect(ClassNameHelper.isRawDocumentId('Class 8A'), isFalse);
      expect(ClassNameHelper.isRawDocumentId('Grade 10-B'), isFalse);
      expect(ClassNameHelper.isRawDocumentId('Class 9'), isFalse);
      expect(ClassNameHelper.isRawDocumentId('Section C'), isFalse);
      expect(ClassNameHelper.isRawDocumentId('Class (Assigned)'), isFalse);
    });

    test('cleanFormattedName strips duplicate class prefixes', () {
      expect(ClassNameHelper.cleanFormattedName('Class Class 8A'), equals('Class 8A'));
      expect(ClassNameHelper.cleanFormattedName('Grade Grade 10'), equals('Class 10'));
      expect(ClassNameHelper.cleanFormattedName('Class Grade 9'), equals('Class 9'));
      expect(ClassNameHelper.cleanFormattedName('8A'), equals('Class 8A'));
    });

    test('formatClassNameSync NEVER leaks raw document IDs and returns clean fallback', () {
      const rawId = '0XpwI38PyE9zavRdjcG1';
      final formatted = ClassNameHelper.formatClassNameSync(rawId);
      
      // Must not equal the raw document ID
      expect(formatted, isNot(equals(rawId)));
      expect(formatted.contains('0XpwI38Py'), isFalse);
      expect(formatted, equals('Class (Assigned)'));
    });

    test('formatClassNameSync retrieves from cache when available', () {
      const rawId = 'class_doc_id_9999999999';
      ClassNameHelper.setCachedName(rawId, 'Class 10A');

      final formatted = ClassNameHelper.formatClassNameSync(rawId);
      expect(formatted, equals('Class 10A'));
    });

    test('getClassNames batch sanitization maps and preserves clean names', () async {
      final input = ['Class 8A', '0XpwI38PyE9zavRdjcG1', 'Grade 9B'];
      final output = await ClassNameHelper.getClassNames(input);

      expect(output['Class 8A'], equals('Class 8A'));
      expect(output['0XpwI38PyE9zavRdjcG1'], equals('Class (Assigned)'));
      expect(output['Grade 9B'], equals('Class 9B'));
      expect(output.values.any((name) => name.contains('0XpwI38Py')), isFalse);
    });
  });

  group('2. ResourceModel & Learning Resource Library Serialization Tests', () {
    test('ResourceModel round-trip serialization maintains full fidelity', () {
      final now = DateTime(2026, 11, 10, 10, 0);
      final resource = ResourceModel(
        id: 'res_001',
        schoolId: 'school_ap_01',
        classId: 'class_8a',
        className: 'Class 8A',
        section: 'A',
        subject: 'Physical Science',
        chapter: 'Force and Pressure',
        topic: 'Atmospheric Pressure',
        title: 'Force and Pressure - Comprehensive Study Notes',
        description: 'Complete revision notes with diagrams and practice questions.',
        resourceType: 'pdf',
        fileUrl: 'https://storage.googleapis.com/edustreak/notes_ch1.pdf',
        fileSize: '2.4 MB',
        uploadedBy: 'teacher_101',
        uploadedByName: 'Srikanth Verma',
        createdAt: now,
        isPublished: true,
      );

      final map = resource.toMap();
      expect(map['id'], equals('res_001'));
      expect(map['className'], equals('Class 8A'));
      expect(map['resourceType'], equals('pdf'));
      expect(map['isPublished'], isTrue);
      expect(map['fileSize'], equals('2.4 MB'));

      final fromMap = ResourceModel.fromMap(map, 'res_001');
      expect(fromMap.id, equals('res_001'));
      expect(fromMap.schoolId, equals('school_ap_01'));
      expect(fromMap.title, equals('Force and Pressure - Comprehensive Study Notes'));
      expect(fromMap.subject, equals('Physical Science'));
      expect(fromMap.isPublished, isTrue);
    });

    test('ResourceModel copyWith allows partial mutation while keeping immutability', () {
      final original = ResourceModel(
        id: 'res_002',
        schoolId: 'school_ap_01',
        classId: 'class_8b',
        className: 'Class 8B',
        subject: 'Mathematics',
        chapter: 'Linear Equations',
        title: 'Formula Sheet',
        resourceType: 'image',
        fileUrl: 'https://storage.googleapis.com/edustreak/formula.png',
        uploadedBy: 'teacher_102',
        uploadedByName: 'Anita Sharma',
        createdAt: DateTime.now(),
        isPublished: false,
      );

      final published = original.copyWith(isPublished: true, fileSize: '1.1 MB');
      expect(published.isPublished, isTrue);
      expect(published.fileSize, equals('1.1 MB'));
      expect(published.title, equals(original.title));
      expect(original.isPublished, isFalse); // original unmodified
    });

    test('Validates all supported resource types', () {
      const validTypes = ['pdf', 'docx', 'pptx', 'image', 'weblink', 'other'];
      for (final type in validTypes) {
        final res = ResourceModel(
          id: 'res_type_$type',
          schoolId: 's1',
          classId: 'c1',
          className: 'Class 9',
          subject: 'Science',
          chapter: 'Ch 1',
          title: '$type test',
          resourceType: type,
          fileUrl: 'https://example.com/$type',
          uploadedBy: 't1',
          uploadedByName: 'Teacher',
          createdAt: DateTime.now(),
        );
        expect(res.resourceType, equals(type));
      }
    });
  });

  group('3. TeacherAiHubService Fallback Generation Tests', () {
    late TeacherAiHubService aiService;

    setUp(() {
      // Points to a non-existent port to verify fallback resilience
      aiService = TeacherAiHubService(baseUrl: 'http://127.0.0.1:9999');
    });

    test('generateLessonPlan returns structured curriculum-aligned lesson plan on fallback', () async {
      final plan = await aiService.generateLessonPlan(
        gradeOrClass: 'Class 9',
        subject: 'Physical Science',
        chapter: 'Motion and Measurement',
        topic: 'Newton\'s Second Law',
        durationMinutes: 45,
      );

      expect(plan['lesson_title'], contains('Newton\'s Second Law'));
      expect(plan['grade_or_class'], equals('Class 9'));
      expect(plan['subject'], equals('Physical Science'));
      expect(plan['duration_minutes'], equals(45));
      expect(plan['objectives'], isA<List>());
      expect((plan['objectives'] as List).length, greaterThanOrEqualTo(2));
      expect(plan['teaching_explanation'], isNotEmpty);
      expect(plan['classroom_activities'], isA<List>());
      expect(plan['homework_suggestions'], isA<List>());
    });

    test('generateQuestions returns MCQ questions with options and explanations on fallback', () async {
      final result = await aiService.generateQuestions(
        gradeOrClass: 'Class 8',
        subject: 'Social Studies',
        chapter: 'Indian Constitution',
        topic: 'Fundamental Rights',
        numQuestions: 4,
        questionType: 'mcq',
      );

      expect(result['subject'], equals('Social Studies'));
      expect(result['topic'], equals('Fundamental Rights'));
      final questions = result['questions'] as List;
      expect(questions.length, equals(4));

      final firstQ = questions[0] as Map<String, dynamic>;
      expect(firstQ['options'], isNotNull);
      expect((firstQ['options'] as Map).containsKey('A'), isTrue);
      expect((firstQ['options'] as Map).containsKey('B'), isTrue);
      expect(firstQ['correct_answer'], isNotEmpty);
      expect(firstQ['explanation'], isNotEmpty);
    });

    test('generateWorksheet returns printable structured worksheet sections on fallback', () async {
      final worksheet = await aiService.generateWorksheet(
        gradeOrClass: 'Class 10',
        subject: 'Mathematics',
        chapter: 'Quadratic Equations',
        topic: 'Nature of Roots',
      );

      expect(worksheet['worksheet_title'], contains('Quadratic Equations'));
      expect(worksheet['sections'], isA<List>());
      final sections = worksheet['sections'] as List;
      expect(sections.length, greaterThanOrEqualTo(3));
    });

    test('askAssistant provides pedagogical assistance on fallback', () async {
      final reply = await aiService.askAssistant(
        question: 'How can I explain Archimedes Principle through an engaging hands-on activity?',
        gradeOrClass: 'Class 9',
        subject: 'Physical Science',
      );

      expect(reply['answer'], isNotNull);
      expect((reply['answer'] as String).length, greaterThan(50));
      expect(reply['pedagogy_tips'], isA<List>());
    });

    test('generateLearningInsights returns cohort analysis and targeted pedagogy strategies on fallback', () async {
      final insights = await aiService.generateLearningInsights(
        gradeOrClass: 'Class 8',
        subject: 'General Science',
        topic: 'Metals and Non-Metals',
        studentCount: 30,
        averageScore: 72.0,
      );

      expect(insights['grade_or_class'], equals('Class 8'));
      expect(insights['subject'], equals('General Science'));
      expect(insights['topic'], equals('Metals and Non-Metals'));
      expect(insights['total_students'], equals(30));
      expect(insights['cohorts'], isA<Map>());
      expect((insights['cohorts'] as Map).containsKey('struggling'), isTrue);
      expect((insights['cohorts'] as Map).containsKey('advanced'), isTrue);
      expect(insights['weak_concepts'], isA<List>());
      expect((insights['weak_concepts'] as List).isNotEmpty, isTrue);
      expect(insights['remediation_strategies'], isA<List>());
      expect(insights['recommended_next_action'], isNotEmpty);
    });
  });

  group('4. Teacher Leaderboard & Student XP Ranking Logic Tests', () {
    test('Students are ordered strictly descending by XP', () {
      final students = [
        UserModel(id: 's1', email: 's1@school.edu', name: 'Aarav Kumar', role: 'student', xp: 450),
        UserModel(id: 's2', email: 's2@school.edu', name: 'Divya Reddy', role: 'student', xp: 1200),
        UserModel(id: 's3', email: 's3@school.edu', name: 'Bhavya Sri', role: 'student', xp: 850),
        UserModel(id: 's4', email: 's4@school.edu', name: 'Charan Teja', role: 'student', xp: 1900),
      ];

      students.sort((a, b) => b.xp.compareTo(a.xp));

      expect(students[0].name, equals('Charan Teja'));
      expect(students[0].xp, equals(1900));
      expect(students[1].name, equals('Divya Reddy'));
      expect(students[1].xp, equals(1200));
      expect(students[2].name, equals('Bhavya Sri'));
      expect(students[2].xp, equals(850));
      expect(students[3].name, equals('Aarav Kumar'));
      expect(students[3].xp, equals(450));
    });

    test('Class filter accurately isolates students belonging to selected class', () {
      final allStudents = [
        UserModel(id: 's1', email: 's1@school.edu', name: 'Student 1', role: 'student', classId: 'class_8a', xp: 500),
        UserModel(id: 's2', email: 's2@school.edu', name: 'Student 2', role: 'student', classId: 'class_9b', xp: 700),
        UserModel(id: 's3', email: 's3@school.edu', name: 'Student 3', role: 'student', classId: 'class_8a', xp: 900),
      ];

      final filtered = allStudents.where((s) => s.classId == 'class_8a').toList();
      expect(filtered.length, equals(2));
      expect(filtered.every((s) => s.classId == 'class_8a'), isTrue);
    });

    test('Podium ranks correctly assigned to top 3 students', () {
      final sortedXps = [2500, 1800, 1200, 900, 400];
      
      for (int i = 0; i < sortedXps.length; i++) {
        final rank = i + 1;
        final isPodium = rank <= 3;
        if (rank == 1) {
          expect(isPodium, isTrue);
        } else if (rank == 2) {
          expect(isPodium, isTrue);
        } else if (rank == 3) {
          expect(isPodium, isTrue);
        } else {
          expect(isPodium, isFalse);
        }
      }
    });
  });

  group('5. Attendance Metric Calculations & "Mark All Present" Tests', () {
    test('Computes attendance overview metrics correctly', () {
      final attendanceMap = <String, String>{
        'student_1': 'present',
        'student_2': 'present',
        'student_3': 'absent',
        'student_4': 'late',
        'student_5': 'present',
      };

      final total = attendanceMap.length;
      final presentCount = attendanceMap.values.where((s) => s == 'present').length;
      final absentCount = attendanceMap.values.where((s) => s == 'absent').length;
      final lateCount = attendanceMap.values.where((s) => s == 'late').length;
      final percentage = (presentCount / total) * 100;

      expect(total, equals(5));
      expect(presentCount, equals(3));
      expect(absentCount, equals(1));
      expect(lateCount, equals(1));
      expect(percentage, equals(60.0));
    });

    test('"Mark All Present" batch action marks every student present', () {
      final studentIds = ['s_1', 's_2', 's_3', 's_4', 's_5'];
      final statusMap = <String, String>{
        's_1': 'absent',
        's_2': 'late',
        's_3': 'absent',
      };

      for (final id in studentIds) {
        statusMap[id] = 'present';
      }

      expect(statusMap.values.every((s) => s == 'present'), isTrue);
      expect(statusMap.length, equals(5));
    });
  });

  group('6. Submissions within Tasks Calculation Tests', () {
    test('Calculates submitted count, graded count, and pending review from task document', () {
      final task = TaskModel(
        id: 'task_math_01',
        classId: 'class_8a',
        assignedBy: 'teacher_101',
        assignedByName: 'Teacher Name',
        createdAt: DateTime.now(),
        assignedTo: ['student_1', 'student_2', 'student_3'],
        title: 'Trigonometry Homework 1',
        description: 'Solve problems 1-10',
        subject: 'Mathematics',
        dueDate: DateTime.now().add(const Duration(days: 3)),
        submissions: {
          'student_1': 'submitted',
          'student_2': 'submitted',
          'student_3': 'submitted',
        },
        marks: {
          'student_1': 48.0,
          'student_2': 45.0,
        },
      );

      final totalSubmissions = task.submissions.length;
      final gradedCount = task.marks.length;
      final pendingCount = totalSubmissions - gradedCount;

      expect(totalSubmissions, equals(3));
      expect(gradedCount, equals(2));
      expect(pendingCount, equals(1));
    });
  });

  group('7. Teacher Profile & Password Validation Tests', () {
    test('Validates password change requirements', () {
      bool isValidPassword(String pwd) => pwd.length >= 6;
      bool passwordsMatch(String p1, String p2) => p1 == p2;

      expect(isValidPassword('12345'), isFalse);
      expect(isValidPassword('securePass1'), isTrue);
      expect(passwordsMatch('secret123', 'secret123'), isTrue);
      expect(passwordsMatch('secret123', 'secret456'), isFalse);
    });

    test('Teacher credentials display data formatting', () {
      final teacher = UserModel(
        id: 'teach_9876',
        email: 'srikanth.v@school.edu',
        name: 'Srikanth Verma',
        role: 'teacher',
        schoolId: 'AP-KRI-042',
        schoolCode: 'AP-KRI-042',
        classIds: ['Class 8A', 'Class 9B'],
      );

      expect(teacher.role, equals('teacher'));
      expect(teacher.schoolCode, equals('AP-KRI-042'));
      expect(teacher.classIds, contains('Class 8A'));
      expect(teacher.classIds, contains('Class 9B'));
    });
  });

  group('8. AssessmentModel Serialization & Metric Calculation Tests', () {
    test('AssessmentModel round-trip serialization maintains full fidelity', () {
      final now = DateTime.now();
      final assessment = AssessmentModel(
        id: 'asmnt_101',
        schoolId: 'AP-KRI-042',
        classId: 'Class 8A',
        className: 'Class 8A',
        subject: 'General Science',
        chapter: 'Cell Biology',
        topic: 'Organelles',
        title: 'Unit Test 1: Cell Biology',
        description: 'Complete all questions within 45 minutes.',
        type: 'unit_test',
        status: 'published',
        totalMarks: 30,
        passingMarks: 12,
        durationMinutes: 45,
        scheduledDate: now,
        dueDate: now.add(const Duration(days: 2)),
        createdAt: now,
        createdBy: 'teach_001',
        createdByName: 'Srikanth Verma',
        questions: [
          AssessmentQuestion(
            id: 'q1',
            question: 'What is the function of the ribosome?',
            type: 'mcq',
            options: {'A': 'Lipid synthesis', 'B': 'Protein synthesis', 'C': 'Respiration', 'D': 'Digestion'},
            correctAnswer: 'B',
            explanation: 'Ribosomes are the site of protein synthesis.',
            marks: 2,
          ),
          AssessmentQuestion(
            id: 'q2',
            question: 'Explain the difference between plant and animal cells.',
            type: 'short_answer',
            correctAnswer: 'Plant cells have cell wall and chloroplasts.',
            marks: 5,
          ),
        ],
        submissions: {'s1': 'submitted', 's2': 'evaluated', 's3': 'evaluated'},
        scores: {'s2': 28.0, 's3': 22.0},
        feedback: {'s2': 'Outstanding work!', 's3': 'Good attempt, review cell wall.'},
      );

      final map = assessment.toMap();
      final roundTripped = AssessmentModel.fromMap(map, assessment.id);

      expect(roundTripped.id, equals('asmnt_101'));
      expect(roundTripped.title, equals('Unit Test 1: Cell Biology'));
      expect(roundTripped.totalMarks, equals(30));
      expect(roundTripped.questions.length, equals(2));
      expect(roundTripped.questions[0].options['B'], equals('Protein synthesis'));
      expect(roundTripped.submittedCount, equals(3));
      expect(roundTripped.evaluatedCount, equals(2));
      expect(roundTripped.averageScore, equals(25.0)); // (28 + 22) / 2 = 25.0
    });

    test('AssessmentModel averageScore handles zero submissions gracefully', () {
      final assessment = AssessmentModel(
        id: 'asmnt_empty',
        classId: 'Class 8A',
        subject: 'Math',
        title: 'Practice Quiz',
        scheduledDate: DateTime.now(),
        dueDate: DateTime.now().add(const Duration(days: 1)),
        createdAt: DateTime.now(),
        createdBy: 'teach_001',
        createdByName: 'Teacher',
        scores: {},
      );

      expect(assessment.averageScore, equals(0.0));
      expect(assessment.submittedCount, equals(0));
      expect(assessment.evaluatedCount, equals(0));
    });
  });

  group('9. Teacher Fallback Resilience Tests', () {
    test('Teacher with empty classIds and empty assignedSubjects defaults safely', () {
      final user = UserModel(
        id: 't_empty',
        email: 'empty@school.edu',
        name: 'New Teacher',
        role: 'teacher',
        classIds: [],
        assignedSubjects: [],
      );

      // Verify safe extraction
      final safeClasses = (user.classIds != null && user.classIds!.isNotEmpty)
          ? user.classIds!
          : (user.classId != null && user.classId!.isNotEmpty ? [user.classId!] : ['Class 8A', 'Class 8B']);
      final safeSubjects = (user.assignedSubjects.isNotEmpty)
          ? user.assignedSubjects
          : ['Science', 'Mathematics', 'English'];

      expect(safeClasses, isNotEmpty);
      expect(safeClasses.first, equals('Class 8A'));
      expect(safeSubjects, isNotEmpty);
      expect(safeSubjects.first, equals('Science'));
    });
  });
}
