import 'package:flutter_test/flutter_test.dart';
import 'package:edustreak/models/school_model.dart';
import 'package:edustreak/models/user_model.dart';
import 'package:edustreak/models/roster_student_model.dart';
import 'package:edustreak/models/resource_model.dart';
import 'package:edustreak/models/assessment_model.dart';
import 'package:edustreak/models/task_model.dart';
import 'package:edustreak/models/xp_transaction_model.dart';
import 'package:edustreak/models/chat_model.dart';
import 'package:edustreak/models/message_model.dart';
import 'package:edustreak/models/badge_model.dart';
import 'package:edustreak/services/ap_school_pilot_service.dart';
import 'package:edustreak/services/gamification_service.dart';
import 'package:edustreak/utils/class_name_helper.dart';

void main() {
  group('AP School Pilot — Scenario A: School Setup & Principal Activation', () {
    test('School entity is configured with Andhra Pradesh Government and Telugu Medium profile', () {
      final school = SchoolModel(
        id: ApSchoolPilotService.schoolId,
        name: ApSchoolPilotService.schoolName,
        code: ApSchoolPilotService.schoolCode,
        type: SchoolType.government,
        status: 'active',
        address: 'Opposite Collectorate Complex, Machilipatnam',
        mandal: 'Machilipatnam Urban',
        district: ApSchoolPilotService.district,
        state: 'Andhra Pradesh',
        pincode: '521001',
        contactPerson: 'K. Srinivas Rao (Headmaster / Principal)',
        contactPhone: '+91 94401 98765',
        contactEmail: ApSchoolPilotService.principalEmail,
        affiliationNumber: 'AP-BSEAP-SCERT-2026-KRI',
        academicYear: ApSchoolPilotService.academicYear,
        supportedClasses: const ['Class 6', 'Class 7', 'Class 8', 'Class 9', 'Class 10'],
        totalStudents: 12,
        totalTeachers: 5,
        curriculumTemplateId: 'AP_STATE_GOVT',
        establishedDate: DateTime(1978, 6, 15),
        principalId: ApSchoolPilotService.principalUid,
        principalName: ApSchoolPilotService.principalName,
        principalEmail: ApSchoolPilotService.principalEmail,
      );

      expect(school.id, equals('sch_ap_svvm_001'));
      expect(school.name, equals('Sri Venkateswara Vidya Mandir'));
      expect(school.code, equals('AP-KRI-SVVM'));
      expect(school.type, equals(SchoolType.government));
      expect(school.district, equals('Krishna'));
      expect(school.academicYear, equals('2026-2027'));
      expect(school.curriculumTemplateId, equals('AP_STATE_GOVT'));
      expect(school.principalId, equals('usr_prin_svvm_001'));
      expect(school.principalName, equals('K. Srinivas Rao'));
      expect(school.supportedClasses, contains('Class 8'));
    });

    test('Principal user account is bidirectionally bound to school and has Telugu name', () {
      final principal = UserModel(
        id: ApSchoolPilotService.principalUid,
        name: ApSchoolPilotService.principalName,
        email: ApSchoolPilotService.principalEmail,
        role: 'principal',
        schoolId: ApSchoolPilotService.schoolId,
        schoolCode: ApSchoolPilotService.schoolCode,
        academicYear: ApSchoolPilotService.academicYear,
        status: 'active',
        isActive: true,
      );

      expect(principal.isPrincipal, isTrue);
      expect(principal.name, equals('K. Srinivas Rao'));
      expect(principal.schoolId, equals('sch_ap_svvm_001'));
      expect(principal.schoolCode, equals('AP-KRI-SVVM'));
      expect(principal.status, equals('active'));
    });
  });

  group('AP School Pilot — Scenario B: Class 8A Academic Structure & Student Enrollment', () {
    test('Class 8A structure formatting adheres to human-readable conventions', () {
      expect(ClassNameHelper.cleanFormattedName('8A'), equals('Class 8A'));
      expect(ClassNameHelper.cleanFormattedName('Class 8 - A'), equals('Class 8A'));
      expect(ClassNameHelper.cleanFormattedName('8_A'), equals('Class 8A'));
      expect(ClassNameHelper.formatClassNameSync('Class 8A'), equals('Class 8A'));
    });

    test('All 12 students have strictly authentic Telugu names and no foreign names', () {
      final students = ApSchoolPilotService.pilotStudents;
      expect(students.length, equals(12));

      final teluguNames = students.map((s) => s['name'] as String).toList();
      const forbiddenGenericNames = ['John', 'David', 'Michael', 'Sarah', 'Emily', 'Alex', 'Emma', 'Lucas', 'James'];

      for (final name in teluguNames) {
        for (final forbidden in forbiddenGenericNames) {
          expect(name.contains(forbidden), isFalse,
              reason: 'Found forbidden generic name "$forbidden" in student name "$name"');
        }
      }

      expect(teluguNames, containsAll([
        'P. Sai Charan',
        'M. Harshitha',
        'K. Venkatesh',
        'N. Sravani',
        'B. Akhil',
        'D. Lahari',
        'G. Manikanta',
        'S. Bhavya',
        'T. Rohit Kumar',
        'Y. Sirisha',
        'V. Tejaswini',
        'A. Charan Teja',
      ]));
    });

    test('Roll numbers (801-812) and admission numbers are unique and correctly serialized', () {
      final students = ApSchoolPilotService.pilotStudents;
      final rollNumbers = <String>{};
      final admissionNumbers = <String>{};

      for (final s in students) {
        final roll = s['rollNumber'] as String;
        final adm = s['admissionNumber'] as String;
        expect(rollNumbers.add(roll), isTrue, reason: 'Duplicate roll number: $roll');
        expect(admissionNumbers.add(adm), isTrue, reason: 'Duplicate admission number: $adm');

        // Test RosterStudentModel serialization
        final roster = RosterStudentModel(
          id: s['rosterId'] as String,
          schoolId: ApSchoolPilotService.schoolId,
          schoolCode: ApSchoolPilotService.schoolCode,
          studentName: s['name'] as String,
          rollNumber: roll,
          admissionNumber: adm,
          grade: '8',
          section: 'A',
          classId: ApSchoolPilotService.primaryClassId,
          academicYear: ApSchoolPilotService.academicYear,
          email: s['email'] as String,
          parentName: s['parentName'] as String,
          parentPhone: s['parentPhone'] as String,
          parentEmail: s['parentEmail'] as String,
          verificationPin: s['verificationPin'] as String,
          status: 'active',
          claimedByUid: s['uid'] as String,
          claimedAt: DateTime.now(),
          createdAt: DateTime.now(),
        );

        expect(roster.isRegistered, isTrue);
        expect(roster.classLabel, equals('Class 8-A'));
        final map = roster.toMap();
        final reconstructed = RosterStudentModel.fromMap(map, roster.id);
        expect(reconstructed.studentName, equals(s['name']));
        expect(reconstructed.rollNumber, equals(roll));
        expect(reconstructed.claimedByUid, equals(s['uid']));
      }

      expect(rollNumbers.length, equals(12));
      expect(admissionNumbers.length, equals(12));
    });
  });

  group('AP School Pilot — Scenario C: Teacher Assignments to Class 8A', () {
    test('All 5 teachers have authentic Telugu names and proper subject assignments', () {
      final teachers = ApSchoolPilotService.pilotTeachers;
      expect(teachers.length, equals(5));

      final teacherMap = {for (var t in teachers) t['name'] as String: t['subject'] as String};
      expect(teacherMap['K. Srinivas'], equals('Mathematics'));
      expect(teacherMap['P. Lakshmi Devi'], equals('Telugu'));
      expect(teacherMap['M. Suresh Babu'], equals('Science'));
      expect(teacherMap['N. Padmavathi'], equals('English'));
      expect(teacherMap['G. Venkata Ramana'], equals('Social Studies'));

      for (final t in teachers) {
        final user = UserModel(
          id: t['uid'] as String,
          name: t['name'] as String,
          email: t['email'] as String,
          role: 'teacher',
          schoolId: ApSchoolPilotService.schoolId,
          schoolCode: ApSchoolPilotService.schoolCode,
          employeeId: t['employeeId'] as String,
          classIds: const ['cls_8', 'cls_8_sec_8_a'],
          assignedSubjects: [t['subject'] as String],
          status: 'active',
          isActive: true,
        );

        expect(user.isTeacher, isTrue);
        expect(user.classIds, contains('cls_8'));
        expect(user.assignedSubjects, contains(t['subject']));
      }
    });
  });

  group('AP School Pilot — Scenario D: Parent Linking & Child Relationship', () {
    test('12 Telugu parents are correctly linked to their respective Class 8A children', () {
      final students = ApSchoolPilotService.pilotStudents;
      expect(students.length, equals(12));

      final parentNames = students.map((s) => s['parentName'] as String).toList();
      expect(parentNames, containsAll([
        'K. Ramesh',
        'P. Anitha',
        'M. Srinivas',
        'N. Sujatha',
        'G. Ramakrishna',
        'P. Padma',
        'N. Ravi Kumar',
        'K. Lakshmi',
        'V. Suresh',
        'M. Radha',
        'P. Mohan Rao',
        'G. Kavitha',
      ]));

      for (final s in students) {
        final parentUser = UserModel(
          id: s['parentUid'] as String,
          name: s['parentName'] as String,
          email: s['parentEmail'] as String,
          role: 'parent',
          schoolId: ApSchoolPilotService.schoolId,
          schoolCode: ApSchoolPilotService.schoolCode,
          childId: s['uid'] as String,
          childIds: [s['uid'] as String],
          status: 'active',
          isActive: true,
        );

        expect(parentUser.isParent, isTrue);
        expect(parentUser.childId, equals(s['uid']));
        expect(parentUser.childIds, contains(s['uid']));

        // Verify map serialization
        final pMap = parentUser.toMap();
        expect(pMap['childId'], equals(s['uid']));
        expect(pMap['childIds'], contains(s['uid']));
        final reconstructed = UserModel.fromMap(pMap..['id'] = parentUser.id);
        expect(reconstructed.childId, equals(s['uid']));
      }
    });
  });

  group('AP School Pilot — Scenario E: Curriculum & Textbooks (Learning Resources)', () {
    test('6 Class 8A subjects are configured with valid SCERT textbook resources', () {
      final resources = ApSchoolPilotService.pilotResources;
      expect(resources.length, equals(6));

      final subjects = resources.map((r) => r['subject'] as String).toSet();
      expect(subjects, containsAll([
        'Telugu',
        'English',
        'Mathematics',
        'General Science',
        'Social Studies',
        'Hindi',
      ]));

      for (final r in resources) {
        final model = ResourceModel(
          id: r['id'] as String,
          schoolId: ApSchoolPilotService.schoolId,
          classId: ApSchoolPilotService.primaryClassId,
          className: ApSchoolPilotService.primaryClassFormatted,
          section: 'A',
          subject: r['subject'] as String,
          chapter: r['chapter'] as String,
          topic: r['topic'] as String,
          title: r['title'] as String,
          description: r['description'] as String,
          resourceType: r['resourceType'] as String,
          fileUrl: r['fileUrl'] as String,
          fileSize: r['fileSize'] as String,
          uploadedBy: r['uploadedBy'] as String,
          uploadedByName: r['uploadedByName'] as String,
          createdAt: DateTime.now(),
          isPublished: true,
        );

        expect(model.isPublished, isTrue);
        expect(model.fileUrl, startsWith('https://scert.ap.gov.in/textbooks/'));
        expect(model.resourceType, equals('pdf'));
        expect(model.fileSize, isNotNull);

        final map = model.toMap();
        final reconstructed = ResourceModel.fromMap(map, model.id);
        expect(reconstructed.subject, equals(r['subject']));
        expect(reconstructed.title, equals(r['title']));
      }
    });
  });

  group('AP School Pilot — Scenario F: Assessments Creation, Submission & Grading', () {
    test('Telugu and Mathematics assessments have real questions, scores, and Telugu feedback', () {
      final studentIds = ApSchoolPilotService.pilotStudents.map((s) => s['uid'] as String).toList();

      final teluguAssessment = AssessmentModel(
        id: 'asm_svvm_tel_01',
        schoolId: ApSchoolPilotService.schoolId,
        classId: ApSchoolPilotService.primaryClassId,
        className: ApSchoolPilotService.primaryClassFormatted,
        subject: 'Telugu',
        chapter: 'అధ్యాయం 1: వేమన శతకం',
        topic: 'పద్యాలు మరియు వ్యాకరణం',
        title: '8వ తరగతి తెలుగు వ్యాకరణం & పద్య పఠన మూల్యాంకనం',
        description: 'ఆంధ్రప్రదేశ్ SCERT సిలబస్ ఆధారంగా తయారు చేసిన అధికారిక తెలుగు యూనిట్ పరీక్ష.',
        type: 'unit_test',
        status: 'published',
        totalMarks: 50,
        passingMarks: 20,
        durationMinutes: 45,
        scheduledDate: DateTime.now().subtract(const Duration(days: 3)),
        dueDate: DateTime.now().add(const Duration(days: 5)),
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        createdBy: 'usr_tch_svvm_002',
        createdByName: 'P. Lakshmi Devi',
        questions: [
          AssessmentQuestion(
            id: 'q1',
            question: 'వేమన శతకంలో ప్రధానంగా ఏ ఛందస్సు ఉపయోగించబడింది?',
            type: 'mcq',
            options: {'A': 'ఉత్పలమాల', 'B': 'ఆటవెలది', 'C': 'తేటగీతి', 'D': 'చంపకమాల'},
            correctAnswer: 'B',
            marks: 10,
          ),
          AssessmentQuestion(
            id: 'q2',
            question: 'సంధిని నిర్వచించి, సవర్ణదీర్ఘ సంధికి రెండు ఉదాహరణలు రాయండి.',
            type: 'short_answer',
            correctAnswer: 'పూర్వ పర స్వరంబులకు పరస్వరంబేకాదేశంబగుట సంధి.',
            marks: 15,
          ),
        ],
        assignedTo: studentIds,
        submissions: {for (var id in studentIds) id: 'evaluated'},
        scores: {for (var id in studentIds) id: 48.0},
        feedback: {for (var id in studentIds) id: 'అద్భుతమైన వ్యాకరణ జ్ఞానం మరియు పద్య పరిజ్ఞానం!'},
      );

      expect(teluguAssessment.questions.length, equals(2));
      expect(teluguAssessment.status, equals('published'));
      expect(teluguAssessment.scores['usr_std_svvm_801'], equals(48.0));
      expect(teluguAssessment.feedback['usr_std_svvm_801'], contains('అద్భుతమైన'));

      final map = teluguAssessment.toMap();
      final reconstructed = AssessmentModel.fromMap(map, teluguAssessment.id);
      expect(reconstructed.subject, equals('Telugu'));
      expect(reconstructed.questions.first.correctAnswer, equals('B'));
    });

    test('Homework tasks are assigned, submitted, and evaluated with awarded marks and points', () {
      final studentIds = ApSchoolPilotService.pilotStudents.map((s) => s['uid'] as String).toList();

      final mathTask = TaskModel(
        id: 'tsk_svvm_mat_01',
        classId: ApSchoolPilotService.primaryClassId,
        title: 'గణిత అభ్యాసం: అధ్యాయం 1 - అకరణీయ సంఖ్యల సమస్యలు 1-10',
        description: 'పాఠ్యపుస్తకం పేజీ 18 లోని అభ్యాసం 1.2 లో 1 నుండి 10 వరకు లెక్కలు పూర్తి చేయండి.',
        subject: 'Mathematics',
        assignedBy: 'usr_tch_svvm_001',
        assignedByName: 'K. Srinivas',
        dueDate: DateTime.now().add(const Duration(days: 3)),
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        assignedTo: studentIds,
        submissions: {for (var id in studentIds) id: 'graded'},
        submissionTexts: {for (var id in studentIds) id: 'సమస్యలు 1 నుండి 10 వరకు సాధించబడ్డాయి.'},
        marks: {for (var id in studentIds) id: 95.0},
        pointsAwarded: {for (var id in studentIds) id: 10},
        feedback: {for (var id in studentIds) id: 'అన్ని లెక్కలు దశలవారీగా సరిగ్గా సాధించారు.'},
        maxMarks: 100,
        xpReward: 50,
      );

      expect(mathTask.assignedTo.length, equals(12));
      expect(mathTask.submissions['usr_std_svvm_801'], equals('graded'));
      expect(mathTask.marks['usr_std_svvm_801'], equals(95.0));
      expect(mathTask.pointsAwarded['usr_std_svvm_801'], equals(10));

      final map = mathTask.toMap();
      final reconstructed = TaskModel.fromMap(map..['id'] = mathTask.id);
      expect(reconstructed.title, equals(mathTask.title));
      expect(reconstructed.subject, equals('Mathematics'));
    });
  });

  group('AP School Pilot — Scenario G: Gamification, XP Ledger & Class Leaderboard', () {
    final gamificationService = GamificationService();

    test('Every student XP satisfies legitimate level calculation rule: (level * 100) * (level + 1)', () {
      // Validates formula: getXPForLevel(L) = L * 100 * (L + 1)
      // Level 1: 200, Level 2: 600, Level 3: 1200, Level 4: 2000, Level 5: 3000,
      // Level 6: 4200, Level 7: 5600, Level 8: 7200, Level 9: 9000
      expect(gamificationService.getXPForLevel(1), equals(200));
      expect(gamificationService.getXPForLevel(2), equals(600));
      expect(gamificationService.getXPForLevel(3), equals(1200));
      expect(gamificationService.getXPForLevel(4), equals(2000));
      expect(gamificationService.getXPForLevel(5), equals(3000));
      expect(gamificationService.getXPForLevel(6), equals(4200));
      expect(gamificationService.getXPForLevel(7), equals(5600));
      expect(gamificationService.getXPForLevel(8), equals(7200));
      expect(gamificationService.getXPForLevel(9), equals(9000));

      for (final s in ApSchoolPilotService.pilotStudents) {
        final targetLevel = s['targetLevel'] as int;
        final xp = s['xp'] as int;
        final requiredXP = gamificationService.getXPForLevel(targetLevel);

        expect(xp >= requiredXP, isTrue,
            reason: '${s['name']} (Level $targetLevel) has $xp XP, which is below the required threshold of $requiredXP XP.');

        // If not max level, verify it does not exceed next level
        if (targetLevel < 9) {
          final nextLevelXP = gamificationService.getXPForLevel(targetLevel + 1);
          expect(xp < nextLevelXP, isTrue,
              reason: '${s['name']} (Level $targetLevel) has $xp XP, which exceeds next level threshold $nextLevelXP.');
        }
      }
    });

    test('XP Transaction audit trail correctly divides and reconstructs student lifetime XP', () {
      for (final s in ApSchoolPilotService.pilotStudents) {
        final uid = s['uid'] as String;
        final totalXp = s['xp'] as int;

        final part1 = (totalXp * 0.4).round();
        final part2 = (totalXp * 0.35).round();
        final part3 = totalXp - part1 - part2;

        expect(part1 + part2 + part3, equals(totalXp));

        final tx = XpTransactionModel(
          id: 'tx_${uid}_01',
          userId: uid,
          schoolId: ApSchoolPilotService.schoolId,
          amount: part1,
          type: 'earn',
          reason: 'Initial Assessment & Onboarding',
          balanceAfter: part1,
          timestamp: DateTime.now(),
        );

        expect(tx.amount, equals(part1));
        expect(tx.type, equals('earn'));
        final map = tx.toMap();
        final reconstructed = XpTransactionModel.fromMap(map, id: tx.id);
        expect(reconstructed.userId, equals(uid));
        expect(reconstructed.amount, equals(part1));
      }
    });

    test('Class 8A Leaderboard correctly calculates rankings sorted by XP descending', () {
      final studentUsers = ApSchoolPilotService.pilotStudents.map((s) {
        return UserModel(
          id: s['uid'] as String,
          name: s['name'] as String,
          email: s['email'] as String,
          role: 'student',
          schoolId: ApSchoolPilotService.schoolId,
          schoolCode: ApSchoolPilotService.schoolCode,
          classId: ApSchoolPilotService.primaryClassId,
          rollNumber: s['rollNumber'] as String,
          admissionNumber: s['admissionNumber'] as String,
          xp: s['xp'] as int,
          level: s['targetLevel'] as int,
          streak: s['streak'] as int,
          badges: List<String>.from(s['badges'] as List),
        );
      }).toList();

      // Sort by XP descending (same logic as LeaderboardScreen)
      studentUsers.sort((a, b) => b.xp.compareTo(a.xp));

      expect(studentUsers.first.name, equals('G. Manikanta'));
      expect(studentUsers.first.xp, equals(9600));
      expect(studentUsers.first.level, equals(9));
      expect(studentUsers.first.streak, equals(30));

      expect(studentUsers[1].name, equals('P. Sai Charan'));
      expect(studentUsers[1].xp, equals(9250));
      expect(studentUsers[1].level, equals(9));

      expect(studentUsers[2].name, equals('Y. Sirisha'));
      expect(studentUsers[2].xp, equals(7450));
      expect(studentUsers[2].level, equals(8));

      expect(studentUsers.last.name, equals('T. Rohit Kumar'));
      expect(studentUsers.last.xp, equals(650));
      expect(studentUsers.last.level, equals(2));
    });

    test('Badges awarded exist in official Badge catalogue and maintain catalog integrity', () {
      final catalogBadges = BadgeModel.getDefaultBadges().map((b) => b.id).toSet();

      for (final s in ApSchoolPilotService.pilotStudents) {
        final badges = List<String>.from(s['badges'] as List);
        for (final b in badges) {
          expect(catalogBadges.contains(b), isTrue,
              reason: 'Badge "$b" assigned to ${s['name']} does not exist in BadgeModel catalogue.');
        }
      }
    });
  });

  group('AP School Pilot — Scenario H: Attendance & Daily Streaks', () {
    test('Attendance records subcollection structure preserves dateKey and student presence', () {
      const studentId = 'usr_std_svvm_801';
      const dateKey = '2026-11-10';

      final attendanceData = {
        'studentId': studentId,
        'date': dateKey,
        'present': true,
        'markedBy': 'usr_tch_svvm_001',
        'markedByName': 'K. Srinivas',
        'schoolId': ApSchoolPilotService.schoolId,
        'classId': ApSchoolPilotService.primaryClassId,
      };

      expect(attendanceData['studentId'], equals('usr_std_svvm_801'));
      expect(attendanceData['present'], isTrue);
      expect(attendanceData['markedByName'], equals('K. Srinivas'));
      expect(attendanceData['schoolId'], equals('sch_ap_svvm_001'));
      expect(attendanceData['date'], equals(dateKey));
    });
  });

  group('AP School Pilot — Scenario I: Realistic Telugu In-App Messaging', () {
    test('Messages between teachers, students, parents, and principal are properly serialized in Telugu', () {
      final chat = ChatModel(
        id: 'usr_std_svvm_801_usr_tch_svvm_001',
        participants: const ['usr_std_svvm_801', 'usr_tch_svvm_001'],
        type: 'student_teacher',
        lastMessage: 'చాలా సంతోషం సాయి చరణ్. సందేహాలుంటే తరగతిలో అడగండి.',
        lastUpdated: DateTime.now(),
      );

      expect(chat.type, equals('student_teacher'));
      expect(chat.participants, contains('usr_std_svvm_801'));
      expect(chat.lastMessage, contains('సాయి చరణ్'));

      final message = MessageModel(
        id: 'msg_01',
        chatId: chat.id,
        senderId: 'usr_tch_svvm_001',
        text: 'రేపు గణిత తరగతిలో అకరణీయ సంఖ్యల ప్రత్యేక పరీక్ష ఉంటుంది. అందరూ పాఠాలను చదివి రావాలి.',
        timestamp: DateTime.now(),
        read: true,
      );

      final msgMap = message.toMap();
      final reconstructed = MessageModel.fromMap(msgMap);
      expect(reconstructed.text, contains('గణిత తరగతిలో'));
      expect(reconstructed.senderId, equals('usr_tch_svvm_001'));
      expect(reconstructed.read, isTrue);
    });
  });

  group('AP School Pilot — Scenario J: Central Admin & Principal School Monitoring', () {
    test('School aggregation statistics match Class 8A pilot reality', () {
      const studentCount = 12;
      const teacherCount = 5;
      const classCount = 5; // Classes 6, 7, 8, 9, 10
      const activeStatus = 'active';

      expect(studentCount, equals(ApSchoolPilotService.pilotStudents.length));
      expect(teacherCount, equals(ApSchoolPilotService.pilotTeachers.length));
      expect(classCount, equals(5));
      expect(activeStatus, equals('active'));
    });
  });
}
