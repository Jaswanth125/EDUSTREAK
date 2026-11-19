import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/school_model.dart';
import '../models/user_model.dart';
import '../models/curriculum_model.dart';
import '../models/roster_student_model.dart';
import '../models/roster_teacher_model.dart';
import '../models/resource_model.dart';
import '../models/assessment_model.dart';
import '../models/task_model.dart';
import '../models/xp_transaction_model.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';

/// Pilot Setup & Seeding Service for Real Andhra Pradesh School Environment
/// School: Sri Venkateswara Vidya Mandir (Machilipatnam, Krishna District)
/// Fully persistent, strictly Telugu named, compliant with existing Firestore schemas.
class ApSchoolPilotService {
  final FirebaseFirestore _firestore;

  ApSchoolPilotService([FirebaseFirestore? firestore])
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ─── CANONICAL PILOT CONSTANTS ─────────────────────────────────────────────
  static const String schoolId = 'sch_ap_svvm_001';
  static const String schoolCode = 'AP-KRI-SVVM';
  static const String schoolName = 'Sri Venkateswara Vidya Mandir';
  static const String academicYear = '2026-2027';
  static const String district = 'Krishna';
  static const String primaryClassId = 'cls_8';
  static const String primaryClassFormatted = 'Class 8A';
  static const String primarySectionId = 'sec_8_a';

  // Principal
  static const String principalUid = 'usr_prin_svvm_001';
  static const String principalName = 'K. Srinivas Rao';
  static const String principalEmail = 'principal.svvm@edustreak.ap.gov.in';

  // ─── 12 TELUGU CLASS 8A STUDENTS CONFIGURATION ─────────────────────────────
  static final List<Map<String, dynamic>> pilotStudents = [
    {
      'uid': 'usr_std_svvm_801',
      'rosterId': 'rst_std_svvm_801',
      'name': 'P. Sai Charan',
      'rollNumber': '801',
      'admissionNumber': 'ADM-2026-801',
      'email': 'p.saicharan.801@svvm.edustreak.ap.gov.in',
      'parentUid': 'usr_prt_svvm_001',
      'parentName': 'K. Ramesh',
      'parentEmail': 'k.ramesh.801@gmail.com',
      'parentPhone': '+91 98480 80101',
      'verificationPin': '8011',
      'targetLevel': 9,
      'streak': 24,
      'xp': 9250,
      'badges': ['streak_master', 'attendance_hero', 'homework_hero', 'perfectionist'],
    },
    {
      'uid': 'usr_std_svvm_802',
      'rosterId': 'rst_std_svvm_802',
      'name': 'M. Harshitha',
      'rollNumber': '802',
      'admissionNumber': 'ADM-2026-802',
      'email': 'm.harshitha.802@svvm.edustreak.ap.gov.in',
      'parentUid': 'usr_prt_svvm_002',
      'parentName': 'P. Anitha',
      'parentEmail': 'p.anitha.802@gmail.com',
      'parentPhone': '+91 98480 80202',
      'verificationPin': '8022',
      'targetLevel': 7,
      'streak': 15,
      'xp': 5800,
      'badges': ['consistency_star', 'homework_hero', 'assignment_ace'],
    },
    {
      'uid': 'usr_std_svvm_803',
      'rosterId': 'rst_std_svvm_803',
      'name': 'K. Venkatesh',
      'rollNumber': '803',
      'admissionNumber': 'ADM-2026-803',
      'email': 'k.venkatesh.803@svvm.edustreak.ap.gov.in',
      'parentUid': 'usr_prt_svvm_003',
      'parentName': 'M. Srinivas',
      'parentEmail': 'm.srinivas.803@gmail.com',
      'parentPhone': '+91 98480 80303',
      'verificationPin': '8033',
      'targetLevel': 5,
      'streak': 8,
      'xp': 3150,
      'badges': ['bronze_warrior', 'assignment_ace'],
    },
    {
      'uid': 'usr_std_svvm_804',
      'rosterId': 'rst_std_svvm_804',
      'name': 'N. Sravani',
      'rollNumber': '804',
      'admissionNumber': 'ADM-2026-804',
      'email': 'n.sravani.804@svvm.edustreak.ap.gov.in',
      'parentUid': 'usr_prt_svvm_004',
      'parentName': 'N. Sujatha',
      'parentEmail': 'n.sujatha.804@gmail.com',
      'parentPhone': '+91 98480 80404',
      'verificationPin': '8044',
      'targetLevel': 3,
      'streak': 4,
      'xp': 1300,
      'badges': ['consistency_star'],
    },
    {
      'uid': 'usr_std_svvm_805',
      'rosterId': 'rst_std_svvm_805',
      'name': 'B. Akhil',
      'rollNumber': '805',
      'admissionNumber': 'ADM-2026-805',
      'email': 'b.akhil.805@svvm.edustreak.ap.gov.in',
      'parentUid': 'usr_prt_svvm_005',
      'parentName': 'G. Ramakrishna',
      'parentEmail': 'g.ramakrishna.805@gmail.com',
      'parentPhone': '+91 98480 80505',
      'verificationPin': '8055',
      'targetLevel': 7,
      'streak': 18,
      'xp': 5950,
      'badges': ['consistency_king', 'homework_hero', 'attendance_hero'],
    },
    {
      'uid': 'usr_std_svvm_806',
      'rosterId': 'rst_std_svvm_806',
      'name': 'D. Lahari',
      'rollNumber': '806',
      'admissionNumber': 'ADM-2026-806',
      'email': 'd.lahari.806@svvm.edustreak.ap.gov.in',
      'parentUid': 'usr_prt_svvm_006',
      'parentName': 'P. Padma',
      'parentEmail': 'p.padma.806@gmail.com',
      'parentPhone': '+91 98480 80606',
      'verificationPin': '8066',
      'targetLevel': 4,
      'streak': 6,
      'xp': 2150,
      'badges': ['assignment_ace'],
    },
    {
      'uid': 'usr_std_svvm_807',
      'rosterId': 'rst_std_svvm_807',
      'name': 'G. Manikanta',
      'rollNumber': '807',
      'admissionNumber': 'ADM-2026-807',
      'email': 'g.manikanta.807@svvm.edustreak.ap.gov.in',
      'parentUid': 'usr_prt_svvm_007',
      'parentName': 'N. Ravi Kumar',
      'parentEmail': 'n.ravikumar.807@gmail.com',
      'parentPhone': '+91 98480 80707',
      'verificationPin': '8077',
      'targetLevel': 9,
      'streak': 30,
      'xp': 9600,
      'badges': ['streak_master', 'perfect_attendance', 'top_performer', 'homework_hero'],
    },
    {
      'uid': 'usr_std_svvm_808',
      'rosterId': 'rst_std_svvm_808',
      'name': 'S. Bhavya',
      'rollNumber': '808',
      'admissionNumber': 'ADM-2026-808',
      'email': 's.bhavya.808@svvm.edustreak.ap.gov.in',
      'parentUid': 'usr_prt_svvm_008',
      'parentName': 'K. Lakshmi',
      'parentEmail': 'k.lakshmi.808@gmail.com',
      'parentPhone': '+91 98480 80808',
      'verificationPin': '8088',
      'targetLevel': 6,
      'streak': 12,
      'xp': 4350,
      'badges': ['bronze_warrior', 'consistency_king'],
    },
    {
      'uid': 'usr_std_svvm_809',
      'rosterId': 'rst_std_svvm_809',
      'name': 'T. Rohit Kumar',
      'rollNumber': '809',
      'admissionNumber': 'ADM-2026-809',
      'email': 't.rohitkumar.809@svvm.edustreak.ap.gov.in',
      'parentUid': 'usr_prt_svvm_009',
      'parentName': 'V. Suresh',
      'parentEmail': 'v.suresh.809@gmail.com',
      'parentPhone': '+91 98480 80909',
      'verificationPin': '8099',
      'targetLevel': 2,
      'streak': 2,
      'xp': 650,
      'badges': <String>[],
    },
    {
      'uid': 'usr_std_svvm_810',
      'rosterId': 'rst_std_svvm_810',
      'name': 'Y. Sirisha',
      'rollNumber': '810',
      'admissionNumber': 'ADM-2026-810',
      'email': 'y.sirisha.810@svvm.edustreak.ap.gov.in',
      'parentUid': 'usr_prt_svvm_010',
      'parentName': 'M. Radha',
      'parentEmail': 'm.radha.810@gmail.com',
      'parentPhone': '+91 98480 81010',
      'verificationPin': '8100',
      'targetLevel': 8,
      'streak': 21,
      'xp': 7450,
      'badges': ['streak_master', 'top_performer', 'homework_hero'],
    },
    {
      'uid': 'usr_std_svvm_811',
      'rosterId': 'rst_std_svvm_811',
      'name': 'V. Tejaswini',
      'rollNumber': '811',
      'admissionNumber': 'ADM-2026-811',
      'email': 'v.tejaswini.811@svvm.edustreak.ap.gov.in',
      'parentUid': 'usr_prt_svvm_011',
      'parentName': 'P. Mohan Rao',
      'parentEmail': 'p.mohanrao.811@gmail.com',
      'parentPhone': '+91 98480 81111',
      'verificationPin': '8111',
      'targetLevel': 5,
      'streak': 10,
      'xp': 3250,
      'badges': ['bronze_warrior', 'early_bird', 'assignment_ace'],
    },
    {
      'uid': 'usr_std_svvm_812',
      'rosterId': 'rst_std_svvm_812',
      'name': 'A. Charan Teja',
      'rollNumber': '812',
      'admissionNumber': 'ADM-2026-812',
      'email': 'a.charanteja.812@svvm.edustreak.ap.gov.in',
      'parentUid': 'usr_prt_svvm_012',
      'parentName': 'G. Kavitha',
      'parentEmail': 'g.kavitha.812@gmail.com',
      'parentPhone': '+91 98480 81212',
      'verificationPin': '8122',
      'targetLevel': 3,
      'streak': 5,
      'xp': 1400,
      'badges': ['consistency_star'],
    },
  ];

  // ─── 5 TELUGU CLASS 8A TEACHERS CONFIGURATION ──────────────────────────────
  static final List<Map<String, dynamic>> pilotTeachers = [
    {
      'uid': 'usr_tch_svvm_001',
      'rosterId': 'rst_tch_svvm_001',
      'name': 'K. Srinivas',
      'subject': 'Mathematics',
      'employeeId': 'EMP-SVVM-MATH',
      'email': 'k.srinivas.math@svvm.edustreak.ap.gov.in',
      'phone': '+91 94401 11001',
      'pin': '7001',
    },
    {
      'uid': 'usr_tch_svvm_002',
      'rosterId': 'rst_tch_svvm_002',
      'name': 'P. Lakshmi Devi',
      'subject': 'Telugu',
      'employeeId': 'EMP-SVVM-TEL',
      'email': 'p.lakshmidevi.tel@svvm.edustreak.ap.gov.in',
      'phone': '+91 94401 11002',
      'pin': '7002',
    },
    {
      'uid': 'usr_tch_svvm_003',
      'rosterId': 'rst_tch_svvm_003',
      'name': 'M. Suresh Babu',
      'subject': 'Science',
      'employeeId': 'EMP-SVVM-SCI',
      'email': 'm.sureshbabu.sci@svvm.edustreak.ap.gov.in',
      'phone': '+91 94401 11003',
      'pin': '7003',
    },
    {
      'uid': 'usr_tch_svvm_004',
      'rosterId': 'rst_tch_svvm_004',
      'name': 'N. Padmavathi',
      'subject': 'English',
      'employeeId': 'EMP-SVVM-ENG',
      'email': 'n.padmavathi.eng@svvm.edustreak.ap.gov.in',
      'phone': '+91 94401 11004',
      'pin': '7004',
    },
    {
      'uid': 'usr_tch_svvm_005',
      'rosterId': 'rst_tch_svvm_005',
      'name': 'G. Venkata Ramana',
      'subject': 'Social Studies',
      'employeeId': 'EMP-SVVM-SOC',
      'email': 'g.venkataramana.soc@svvm.edustreak.ap.gov.in',
      'phone': '+91 94401 11005',
      'pin': '7005',
    },
  ];

  // ─── 6 AP SCERT TEXTBOOKS & LEARNING MATERIALS ─────────────────────────────
  static final List<Map<String, dynamic>> pilotResources = [
    {
      'id': 'res_svvm_tel_01',
      'subject': 'Telugu',
      'chapter': 'అమృతం - పద్యాలు & గద్యాలు',
      'topic': 'వేమన శతక పద్యాలు మరియు ఆధునిక కథలు',
      'title': 'AP SCERT 8వ తరగతి తెలుగు వాచకం (అమృతం)',
      'description': 'ఆంధ్రప్రదేశ్ ప్రభుత్వం ప్రచురించిన 8వ తరగతి ప్రామాణిక తెలుగు పాఠ్యపుస్తకం.',
      'resourceType': 'pdf',
      'fileUrl': 'https://scert.ap.gov.in/textbooks/class8/telugu_reader.pdf',
      'fileSize': '8.4 MB',
      'uploadedBy': 'usr_tch_svvm_002',
      'uploadedByName': 'P. Lakshmi Devi',
    },
    {
      'id': 'res_svvm_eng_01',
      'subject': 'English',
      'chapter': 'Honeydew & Grammar',
      'topic': 'Comprehension, Tenses & Active Passive Voice',
      'title': 'AP SCERT Class 8 English Reader & Practice Manual',
      'description': 'Official AP SCERT Reader Honeydew with Andhra Pradesh supplementary grammar syllabus.',
      'resourceType': 'pdf',
      'fileUrl': 'https://scert.ap.gov.in/textbooks/class8/english_honeydew.pdf',
      'fileSize': '6.2 MB',
      'uploadedBy': 'usr_tch_svvm_004',
      'uploadedByName': 'N. Padmavathi',
    },
    {
      'id': 'res_svvm_mat_01',
      'subject': 'Mathematics',
      'chapter': 'అకరణీయ సంఖ్యలు & రేఖీయ సమీకరణాలు',
      'topic': 'Rational Numbers and Linear Equations in One Variable',
      'title': 'AP SCERT 8వ తరగతి గణిత శాస్త్రం (తెలుగు మాధ్యమం)',
      'description': 'ఆంధ్రప్రదేశ్ రాష్ట్ర విద్యా పరిశోధన మరియు శిక్షణ మండలి 8వ తరగతి గణిత పాఠ్యపుస్తకం.',
      'resourceType': 'pdf',
      'fileUrl': 'https://scert.ap.gov.in/textbooks/class8/mathematics_telugu_medium.pdf',
      'fileSize': '11.5 MB',
      'uploadedBy': 'usr_tch_svvm_001',
      'uploadedByName': 'K. Srinivas',
    },
    {
      'id': 'res_svvm_sci_01',
      'subject': 'General Science',
      'chapter': 'పంటల ఉత్పత్తి & కణ నిర్మాణం',
      'topic': 'Crop Production and Cell Structure & Functions',
      'title': 'AP SCERT 8వ తరగతి సాధారణ విజ్ఞానశాస్త్రం',
      'description': 'భౌతిక, రసాయన మరియు జీవ శాస్త్ర భావనలతో కూడిన సమగ్ర సైన్స్ పాఠ్యపుస్తకం.',
      'resourceType': 'pdf',
      'fileUrl': 'https://scert.ap.gov.in/textbooks/class8/general_science_telugu.pdf',
      'fileSize': '14.1 MB',
      'uploadedBy': 'usr_tch_svvm_003',
      'uploadedByName': 'M. Suresh Babu',
    },
    {
      'id': 'res_svvm_soc_01',
      'subject': 'Social Studies',
      'chapter': 'భారత రాజ్యాంగం & భూగోళం',
      'topic': 'Our Constitution, Resources and Indian Heritage',
      'title': 'AP SCERT 8వ తరగతి సాంఘిక శాస్త్రం',
      'description': 'భారతదేశ చరిత్ర, భూగోళ శాస్త్రం మరియు పౌరనీతి పాఠ్యపుస్తకం.',
      'resourceType': 'pdf',
      'fileUrl': 'https://scert.ap.gov.in/textbooks/class8/social_studies_telugu.pdf',
      'fileSize': '9.8 MB',
      'uploadedBy': 'usr_tch_svvm_005',
      'uploadedByName': 'G. Venkata Ramana',
    },
    {
      'id': 'res_svvm_hin_01',
      'subject': 'Hindi',
      'chapter': 'ద్వితీయ భాష హిందీ - సుగంధ్',
      'topic': 'హిందీ వ్యాకరణం మరియు కవితలు',
      'title': 'AP SCERT 8వ తరగతి హిందీ సుగంధ్ (ద్వితీయ భాష)',
      'description': 'ఆంధ్రప్రదేశ్ రాష్ట్ర పాఠశాలల ద్వితీయ భాష హిందీ పాఠ్యపుస్తకం.',
      'resourceType': 'pdf',
      'fileUrl': 'https://scert.ap.gov.in/textbooks/class8/hindi_sugandh.pdf',
      'fileSize': '5.6 MB',
      'uploadedBy': 'usr_tch_svvm_004',
      'uploadedByName': 'N. Padmavathi',
    },
  ];

  // ─── MASTER SEEDING FUNCTION ───────────────────────────────────────────────
  Future<Map<String, dynamic>> seedApSchoolPilot() async {
    final results = <String, dynamic>{
      'schoolId': schoolId,
      'schoolCode': schoolCode,
      'principalUid': principalUid,
      'studentsCount': 0,
      'teachersCount': 0,
      'parentsCount': 0,
      'classesCount': 0,
      'resourcesCount': 0,
      'assessmentsCount': 0,
      'tasksCount': 0,
      'attendanceCount': 0,
      'xpTransactionsCount': 0,
      'chatsCount': 0,
    };

    try {
      if (kDebugMode) print('🚀 Starting AP School Pilot Seeding: $schoolName ($schoolCode)');

      // 1. Seed School Record
      await _seedSchool();

      // 2. Seed Academic Structure (Classes 6-10 with Section A)
      final classesCount = await _seedAcademicClasses();
      results['classesCount'] = classesCount;

      // 3. Seed Principal Account & Invitation
      await _seedPrincipal();

      // 4. Seed 5 Telugu Teachers
      final teachersCount = await _seedTeachers();
      results['teachersCount'] = teachersCount;

      // 5. Seed 12 Telugu Students (Roster + Active User Accounts + XP Ledger)
      final studentStats = await _seedStudents();
      results['studentsCount'] = studentStats['studentsCount'];
      results['xpTransactionsCount'] = studentStats['xpTransactionsCount'];

      // 6. Seed 12 Parents & Link to Students
      final parentsCount = await _seedParents();
      results['parentsCount'] = parentsCount;

      // 7. Seed Textbooks & Learning Materials
      final resourcesCount = await _seedLearningResources();
      results['resourcesCount'] = resourcesCount;

      // 8. Seed Subject Assessments (Created, Published, Submitted, Graded)
      final assessmentsCount = await _seedAssessments();
      results['assessmentsCount'] = assessmentsCount;

      // 9. Seed Homework Tasks (Assigned, Submitted, Evaluated)
      final tasksCount = await _seedHomeworkTasks();
      results['tasksCount'] = tasksCount;

      // 10. Seed Attendance Records for Working Days
      final attendanceCount = await _seedAttendanceRecords();
      results['attendanceCount'] = attendanceCount;

      // 11. Seed In-App Telugu Conversations
      final chatsCount = await _seedTeluguMessaging();
      results['chatsCount'] = chatsCount;

      if (kDebugMode) print('✅ AP School Pilot Seeding successfully completed!');
      return results;
    } catch (e, stack) {
      if (kDebugMode) {
        print('❌ Error in AP School Pilot Seeding: $e');
        print(stack);
      }
      rethrow;
    }
  }

  // ─── 1. SCHOOL RECORD ───────────────────────────────────────────────────────
  Future<void> _seedSchool() async {
    final school = SchoolModel(
      id: schoolId,
      name: schoolName,
      code: schoolCode,
      type: SchoolType.government,
      status: 'active',
      address: 'Opposite Collectorate Complex, Machilipatnam',
      mandal: 'Machilipatnam Urban',
      district: district,
      state: 'Andhra Pradesh',
      pincode: '521001',
      contactPerson: 'K. Srinivas Rao (Headmaster / Principal)',
      contactPhone: '+91 94401 98765',
      contactEmail: principalEmail,
      affiliationNumber: 'AP-BSEAP-SCERT-2026-KRI',
      academicYear: academicYear,
      supportedClasses: const [
        'Class 6',
        'Class 7',
        'Class 8',
        'Class 9',
        'Class 10',
      ],
      totalStudents: 12,
      totalTeachers: 5,
      curriculumTemplateId: 'AP_STATE_GOVT',
      establishedDate: DateTime(1978, 6, 15),
      principalId: principalUid,
      principalName: principalName,
      principalEmail: principalEmail,
      updatedAt: DateTime.now(),
    );

    await _firestore.collection('schools').doc(schoolId).set(school.toMap());
  }

  // ─── 2. ACADEMIC STRUCTURE ──────────────────────────────────────────────────
  Future<int> _seedAcademicClasses() async {
    final batch = _firestore.batch();

    final classes = [
      GradeClassModel(
        id: 'cls_6',
        gradeNumber: 6,
        gradeName: 'Class 6',
        sections: const [
          SectionModel(id: 'sec_6_a', name: 'A', classId: 'cls_6', totalStudents: 30),
        ],
      ),
      GradeClassModel(
        id: 'cls_7',
        gradeNumber: 7,
        gradeName: 'Class 7',
        sections: const [
          SectionModel(id: 'sec_7_a', name: 'A', classId: 'cls_7', totalStudents: 32),
        ],
      ),
      GradeClassModel(
        id: primaryClassId, // 'cls_8'
        gradeNumber: 8,
        gradeName: 'Class 8',
        sections: const [
          SectionModel(
            id: primarySectionId, // 'sec_8_a'
            name: 'A',
            classId: primaryClassId,
            totalStudents: 12,
          ),
        ],
      ),
      GradeClassModel(
        id: 'cls_9',
        gradeNumber: 9,
        gradeName: 'Class 9',
        sections: const [
          SectionModel(id: 'sec_9_a', name: 'A', classId: 'cls_9', totalStudents: 28),
        ],
      ),
      GradeClassModel(
        id: 'cls_10',
        gradeNumber: 10,
        gradeName: 'Class 10',
        sections: const [
          SectionModel(id: 'sec_10_a', name: 'A', classId: 'cls_10', totalStudents: 35),
        ],
      ),
    ];

    for (var c in classes) {
      final docRef = _firestore
          .collection('schools')
          .doc(schoolId)
          .collection('classes')
          .doc(c.id);
      batch.set(docRef, c.toMap());
    }

    // Also populate root 'classes' collection for multi-portal backward compatibility
    final rootClassRef1 = _firestore.collection('classes').doc(primaryClassId);
    batch.set(rootClassRef1, {
      'id': primaryClassId,
      'name': primaryClassFormatted,
      'code': '8A',
      'grade': '8',
      'section': 'A',
      'schoolId': schoolId,
      'schoolCode': schoolCode,
      'createdAt': Timestamp.now(),
    });

    final rootClassRef2 = _firestore.collection('classes').doc('cls_8_sec_8_a');
    batch.set(rootClassRef2, {
      'id': 'cls_8_sec_8_a',
      'name': primaryClassFormatted,
      'code': '8A',
      'grade': '8',
      'section': 'A',
      'schoolId': schoolId,
      'schoolCode': schoolCode,
      'createdAt': Timestamp.now(),
    });

    await batch.commit();
    return classes.length;
  }

  // ─── 3. PRINCIPAL ACCOUNT ───────────────────────────────────────────────────
  Future<void> _seedPrincipal() async {
    final batch = _firestore.batch();

    // User record
    final principalModel = UserModel(
      id: principalUid,
      name: principalName,
      email: principalEmail,
      role: 'principal',
      schoolId: schoolId,
      schoolCode: schoolCode,
      academicYear: academicYear,
      status: 'active',
      isActive: true,
      lastLogin: DateTime.now(),
      lastLoginDate: DateTime.now(),
    );

    final userRef = _firestore.collection('users').doc(principalUid);
    final userMap = principalModel.toMap()..['invitationCode'] = 'INV-PRIN-APKRI-SVVM';
    batch.set(userRef, userMap);

    // Invitation record
    final invRef = _firestore.collection('invitations').doc('INV-PRIN-APKRI-SVVM');
    batch.set(invRef, {
      'invitationCode': 'INV-PRIN-APKRI-SVVM',
      'principalUid': principalUid,
      'principalName': principalName,
      'principalEmail': principalEmail,
      'schoolId': schoolId,
      'schoolCode': schoolCode,
      'role': 'principal',
      'status': 'accepted',
      'createdAt': Timestamp.now(),
      'acceptedAt': Timestamp.now(),
      'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
    });

    await batch.commit();
  }

  // ─── 4. 5 TELUGU TEACHERS ───────────────────────────────────────────────────
  Future<int> _seedTeachers() async {
    final batch = _firestore.batch();

    for (final teacher in pilotTeachers) {
      final uid = teacher['uid'] as String;
      final rosterId = teacher['rosterId'] as String;
      final name = teacher['name'] as String;
      final subject = teacher['subject'] as String;
      final empId = teacher['employeeId'] as String;
      final email = teacher['email'] as String;
      final phone = teacher['phone'] as String;
      final pin = teacher['pin'] as String;

      // 1. Roster Teacher Record
      final rosterTeacher = RosterTeacherModel(
        id: rosterId,
        schoolId: schoolId,
        schoolCode: schoolCode,
        teacherName: name,
        employeeId: empId,
        email: email,
        phone: phone,
        assignedSubjects: [subject],
        assignedClasses: [primaryClassFormatted],
        academicYear: academicYear,
        verificationPin: pin,
        status: 'active',
        claimedByUid: uid,
        claimedAt: DateTime.now().subtract(const Duration(days: 30)),
        createdAt: DateTime.now().subtract(const Duration(days: 45)),
      );

      final rRef = _firestore.collection('roster_teachers').doc(rosterId);
      batch.set(rRef, rosterTeacher.toMap());

      // 2. Active User Account
      final userModel = UserModel(
        id: uid,
        name: name,
        email: email,
        role: 'teacher',
        schoolId: schoolId,
        schoolCode: schoolCode,
        employeeId: empId,
        classIds: [primaryClassId, 'cls_8_sec_8_a'],
        assignedSubjects: [subject],
        status: 'active',
        isActive: true,
        lastLogin: DateTime.now(),
        lastLoginDate: DateTime.now(),
      );

      final uRef = _firestore.collection('users').doc(uid);
      batch.set(uRef, userModel.toMap());
    }

    await batch.commit();
    return pilotTeachers.length;
  }

  // ─── 5. 12 TELUGU STUDENTS + XP AUDIT LEDGER ───────────────────────────────
  Future<Map<String, int>> _seedStudents() async {
    int studentsCount = 0;
    int xpTxCount = 0;

    for (final s in pilotStudents) {
      final uid = s['uid'] as String;
      final rosterId = s['rosterId'] as String;
      final name = s['name'] as String;
      final roll = s['rollNumber'] as String;
      final adm = s['admissionNumber'] as String;
      final email = s['email'] as String;
      final parentName = s['parentName'] as String;
      final parentPhone = s['parentPhone'] as String;
      final parentEmail = s['parentEmail'] as String;
      final pin = s['verificationPin'] as String;
      final targetLevel = s['targetLevel'] as int;
      final streak = s['streak'] as int;
      final xp = s['xp'] as int;
      final badges = List<String>.from(s['badges'] as List);

      // 1. Roster Student Record
      final rosterStudent = RosterStudentModel(
        id: rosterId,
        schoolId: schoolId,
        schoolCode: schoolCode,
        studentName: name,
        rollNumber: roll,
        admissionNumber: adm,
        grade: '8',
        section: 'A',
        classId: primaryClassId,
        academicYear: academicYear,
        email: email,
        parentName: parentName,
        parentPhone: parentPhone,
        parentEmail: parentEmail,
        verificationPin: pin,
        status: 'active',
        claimedByUid: uid,
        claimedAt: DateTime.now().subtract(Duration(days: streak + 5)),
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
      );

      await _firestore.collection('roster_students').doc(rosterId).set(rosterStudent.toMap());

      // 2. Student User Document
      final studentUser = UserModel(
        id: uid,
        name: name,
        email: email,
        role: 'student',
        schoolId: schoolId,
        schoolCode: schoolCode,
        rollNumber: roll,
        admissionNumber: adm,
        classId: primaryClassId,
        grade: '8',
        section: 'A',
        academicYear: academicYear,
        streak: streak,
        streakCount: streak,
        highestStreak: streak + 2,
        xp: xp,
        spendablePoints: xp,
        level: targetLevel,
        badges: badges,
        status: 'active',
        isActive: true,
        lastLogin: DateTime.now(),
        lastLoginDate: DateTime.now(),
      );

      await _firestore.collection('users').doc(uid).set(studentUser.toMap());
      studentsCount++;

      // 3. Legitimate Immutable XP Transactions matching the total lifetime XP
      final txBatch = _firestore.batch();

      // Divide the student's XP into 3 realistic chronological transactions
      final part1 = (xp * 0.4).round();
      final part2 = (xp * 0.35).round();
      final part3 = xp - part1 - part2;

      final tx1 = XpTransactionModel(
        id: 'tx_${uid}_01',
        userId: uid,
        schoolId: schoolId,
        amount: part1,
        type: 'earn',
        reason: 'AP SCERT Semester 1 Milestone Completion & Perfect Attendance',
        balanceAfter: part1,
        timestamp: DateTime.now().subtract(const Duration(days: 20)),
      );

      final tx2 = XpTransactionModel(
        id: 'tx_${uid}_02',
        userId: uid,
        schoolId: schoolId,
        amount: part2,
        type: 'earn',
        reason: 'Mathematics & Science Worksheets Evaluation',
        balanceAfter: part1 + part2,
        timestamp: DateTime.now().subtract(const Duration(days: 10)),
      );

      final tx3 = XpTransactionModel(
        id: 'tx_${uid}_03',
        userId: uid,
        schoolId: schoolId,
        amount: part3,
        type: 'earn',
        reason: 'Telugu & English Reading Quizzes and Daily Streak Bonus',
        balanceAfter: xp,
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
      );

      txBatch.set(_firestore.collection('xp_transactions').doc(tx1.id), tx1.toMap());
      txBatch.set(_firestore.collection('xp_transactions').doc(tx2.id), tx2.toMap());
      txBatch.set(_firestore.collection('xp_transactions').doc(tx3.id), tx3.toMap());

      await txBatch.commit();
      xpTxCount += 3;
    }

    return {
      'studentsCount': studentsCount,
      'xpTransactionsCount': xpTxCount,
    };
  }

  // ─── 6. 12 TELUGU PARENTS LINKED TO STUDENTS ────────────────────────────────
  Future<int> _seedParents() async {
    final batch = _firestore.batch();

    for (final s in pilotStudents) {
      final parentUid = s['parentUid'] as String;
      final parentName = s['parentName'] as String;
      final parentEmail = s['parentEmail'] as String;
      final studentUid = s['uid'] as String;

      final parentUser = UserModel(
        id: parentUid,
        name: parentName,
        email: parentEmail,
        role: 'parent',
        schoolId: schoolId,
        schoolCode: schoolCode,
        childId: studentUid,
        childIds: [studentUid],
        status: 'active',
        isActive: true,
        lastLogin: DateTime.now(),
        lastLoginDate: DateTime.now(),
      );

      final pRef = _firestore.collection('users').doc(parentUid);
      batch.set(pRef, parentUser.toMap());
    }

    await batch.commit();
    return pilotStudents.length;
  }

  // ─── 7. 6 AP SCERT TEXTBOOKS & LEARNING MATERIALS ───────────────────────────
  Future<int> _seedLearningResources() async {
    final batch = _firestore.batch();

    for (final res in pilotResources) {
      final model = ResourceModel(
        id: res['id'] as String,
        schoolId: schoolId,
        classId: primaryClassId,
        className: primaryClassFormatted,
        section: 'A',
        subject: res['subject'] as String,
        chapter: res['chapter'] as String,
        topic: res['topic'] as String,
        title: res['title'] as String,
        description: res['description'] as String,
        resourceType: res['resourceType'] as String,
        fileUrl: res['fileUrl'] as String,
        fileSize: res['fileSize'] as String,
        uploadedBy: res['uploadedBy'] as String,
        uploadedByName: res['uploadedByName'] as String,
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        isPublished: true,
      );

      final docRef = _firestore.collection('learning_resources').doc(model.id);
      batch.set(docRef, model.toMap()..['id'] = model.id);
    }

    await batch.commit();
    return pilotResources.length;
  }

  // ─── 8. SUBJECT ASSESSMENTS & GRADING ────────────────────────────────────────
  Future<int> _seedAssessments() async {
    final allStudentIds = pilotStudents.map((s) => s['uid'] as String).toList();
    final batch = _firestore.batch();

    // Telugu Assessment
    final teluguQuestions = [
      AssessmentQuestion(
        id: 'q1',
        question: 'వేమన శతకంలో ప్రధానంగా ఏ ఛందస్సు ఉపయోగించబడింది?',
        type: 'mcq',
        options: {
          'A': 'ఉత్పలమాల',
          'B': 'ఆటవెలది',
          'C': 'తేటగీతి',
          'D': 'చంపకమాల',
        },
        correctAnswer: 'B',
        explanation: 'వేమన శతక పద్యాలన్నీ ఆటవెలది ఛందస్సులో రచించబడ్డాయి.',
        marks: 10,
      ),
      AssessmentQuestion(
        id: 'q2',
        question: 'సంధిని నిర్వచించి, సవర్ణదీర్ఘ సంధికి రెండు ఉదాహరణలు రాయండి.',
        type: 'short_answer',
        correctAnswer: 'పూర్వ పర స్వరంబులకు పరస్వరంబేకాదేశంబగుట సంధి. ఉదా: దేవా+ఆలయము=దేవాలయము.',
        explanation: 'సవర్ణాచ్ఛులు పరమైనపుడు దీర్ఘం ఏకాదేశమగును.',
        marks: 15,
      ),
      AssessmentQuestion(
        id: 'q3',
        question: 'అతిథి మర్యాద ప్రాముఖ్యతను గురించి మీ సొంత మాటల్లో రాయండి.',
        type: 'long_answer',
        correctAnswer: 'ఆతిథ్యం భారతీయ సంస్కృతిలో విశిష్ట స్థానం కలిగి ఉన్నది.',
        marks: 25,
      ),
    ];

    final teluguSubmissions = <String, String>{};
    final teluguScores = <String, double>{};
    final teluguFeedback = <String, String>{};

    for (var i = 0; i < allStudentIds.length; i++) {
      final sId = allStudentIds[i];
      teluguSubmissions[sId] = 'evaluated';
      // Vary marks realistically: top students get 46-50, others 35-45
      final score = (48.0 - (i % 6) * 2.5);
      teluguScores[sId] = score;
      teluguFeedback[sId] = score >= 45
          ? 'అద్భుతమైన వ్యాకరణ జ్ఞానం మరియు పద్య పరిజ్ఞానం!'
          : 'చక్కగా రాశారు. పద్య భావాలపై మరింత దృష్టి పెట్టండి.';
    }

    final teluguAssessment = AssessmentModel(
      id: 'asm_svvm_tel_01',
      schoolId: schoolId,
      classId: primaryClassId,
      className: primaryClassFormatted,
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
      questions: teluguQuestions,
      assignedTo: allStudentIds,
      submissions: teluguSubmissions,
      scores: teluguScores,
      feedback: teluguFeedback,
    );

    // Mathematics Assessment
    final mathQuestions = [
      AssessmentQuestion(
        id: 'mq1',
        question: 'What is the additive inverse of -7/19?',
        type: 'mcq',
        options: {
          'A': '19/7',
          'B': '7/19',
          'C': '-19/7',
          'D': '0',
        },
        correctAnswer: 'B',
        explanation: 'Additive inverse of a/b is -a/b.',
        marks: 10,
      ),
      AssessmentQuestion(
        id: 'mq2',
        question: 'Solve the linear equation: 5x - 7 = 2x + 8',
        type: 'short_answer',
        correctAnswer: 'x = 5',
        explanation: '5x - 2x = 8 + 7 => 3x = 15 => x = 5',
        marks: 15,
      ),
      AssessmentQuestion(
        id: 'mq3',
        question: 'State and verify associative property of rational numbers under addition with examples.',
        type: 'long_answer',
        correctAnswer: 'a + (b + c) = (a + b) + c',
        marks: 25,
      ),
    ];

    final mathSubmissions = <String, String>{};
    final mathScores = <String, double>{};
    final mathFeedback = <String, String>{};

    for (var i = 0; i < allStudentIds.length; i++) {
      final sId = allStudentIds[i];
      mathSubmissions[sId] = 'evaluated';
      final score = (49.0 - (i % 5) * 3.0);
      mathScores[sId] = score;
      mathFeedback[sId] = score >= 45
          ? 'అన్ని సమస్యలు అద్భుతంగా సాధించారు! గొప్ప ప్రతిభ.'
          : 'సమస్యల సాధన విధానం బాగుంది. సూత్రాలను జాగ్రత్తగా గమనించండి.';
    }

    final mathAssessment = AssessmentModel(
      id: 'asm_svvm_mat_01',
      schoolId: schoolId,
      classId: primaryClassId,
      className: primaryClassFormatted,
      subject: 'Mathematics',
      chapter: 'Chapter 1: Rational Numbers',
      topic: 'Rational numbers operations and linear equations',
      title: 'Class 8A Mathematics Unit Test - Rational Numbers',
      description: 'Official AP Board SCERT Class 8 Mathematics diagnostic test.',
      type: 'unit_test',
      status: 'published',
      totalMarks: 50,
      passingMarks: 20,
      durationMinutes: 45,
      scheduledDate: DateTime.now().subtract(const Duration(days: 4)),
      dueDate: DateTime.now().add(const Duration(days: 6)),
      createdAt: DateTime.now().subtract(const Duration(days: 8)),
      createdBy: 'usr_tch_svvm_001',
      createdByName: 'K. Srinivas',
      questions: mathQuestions,
      assignedTo: allStudentIds,
      submissions: mathSubmissions,
      scores: mathScores,
      feedback: mathFeedback,
    );

    batch.set(_firestore.collection('assessments').doc(teluguAssessment.id), teluguAssessment.toMap());
    batch.set(_firestore.collection('assessments').doc(mathAssessment.id), mathAssessment.toMap());

    await batch.commit();
    return 2;
  }

  // ─── 9. HOMEWORK TASKS & EVALUATION ─────────────────────────────────────────
  Future<int> _seedHomeworkTasks() async {
    final allStudentIds = pilotStudents.map((s) => s['uid'] as String).toList();
    final batch = _firestore.batch();

    final mathSubmissions = <String, String>{};
    final mathTexts = <String, String>{};
    final mathMarks = <String, double>{};
    final mathPoints = <String, int>{};
    final mathFeedback = <String, String>{};

    for (final sId in allStudentIds) {
      mathSubmissions[sId] = 'graded';
      mathTexts[sId] = 'సమస్యలు 1 నుండి 10 వరకు సాధించబడ్డాయి: 1) x = 5, 2) y = 12/7, 3) LHS = RHS.';
      mathMarks[sId] = 95.0;
      mathPoints[sId] = 10;
      mathFeedback[sId] = 'అన్ని లెక్కలు దశలవారీగా సరిగ్గా సాధించారు. చాలా మంచి ప్రదర్శన!';
    }

    final mathTask = TaskModel(
      id: 'tsk_svvm_mat_01',
      classId: primaryClassId,
      title: 'గణిత అభ్యాసం: అధ్యాయం 1 - అకరణీయ సంఖ్యల సమస్యలు 1-10',
      description: 'పాఠ్యపుస్తకం పేజీ 18 లోని అభ్యాసం 1.2 లో 1 నుండి 10 వరకు లెక్కలు పూర్తి చేయండి.',
      subject: 'Mathematics',
      assignedBy: 'usr_tch_svvm_001',
      assignedByName: 'K. Srinivas',
      dueDate: DateTime.now().add(const Duration(days: 3)),
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      assignedTo: allStudentIds,
      submissions: mathSubmissions,
      submissionTexts: mathTexts,
      marks: mathMarks,
      pointsAwarded: mathPoints,
      feedback: mathFeedback,
      maxMarks: 100,
      xpReward: 50,
    );

    final teluguSubmissions = <String, String>{};
    final teluguTexts = <String, String>{};
    final teluguMarks = <String, double>{};
    final teluguPoints = <String, int>{};
    final teluguFeedback = <String, String>{};

    for (final sId in allStudentIds) {
      teluguSubmissions[sId] = 'graded';
      teluguTexts[sId] = 'వేమన శతకంలో "ఉప్పు కప్పురంబు" మరియు "మేడిపండు చూడు" పద్యాలు వాటి భావాలు పూర్తి చేశాను.';
      teluguMarks[sId] = 92.0;
      teluguPoints[sId] = 10;
      teluguFeedback[sId] = 'అక్షర దోషాలు లేకుండా అందమైన చేతిరాతతో రాశారు. శభాష్!';
    }

    final teluguTask = TaskModel(
      id: 'tsk_svvm_tel_01',
      classId: primaryClassId,
      title: 'తెలుగు ప్రాజెక్ట్: వేమన శతక పద్యాలు - భావాలు రాయడం',
      description: 'ఏవైనా 5 వేమన శతక పద్యాలను వాటి భావాలతో రాసి సమర్పించండి.',
      subject: 'Telugu',
      assignedBy: 'usr_tch_svvm_002',
      assignedByName: 'P. Lakshmi Devi',
      dueDate: DateTime.now().add(const Duration(days: 4)),
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      assignedTo: allStudentIds,
      submissions: teluguSubmissions,
      submissionTexts: teluguTexts,
      marks: teluguMarks,
      pointsAwarded: teluguPoints,
      feedback: teluguFeedback,
      maxMarks: 100,
      xpReward: 60,
    );

    batch.set(_firestore.collection('tasks').doc(mathTask.id), mathTask.toMap());
    batch.set(_firestore.collection('tasks').doc(teluguTask.id), teluguTask.toMap());

    await batch.commit();
    return 2;
  }

  // ─── 10. ATTENDANCE RECORDS ────────────────────────────────────────────────
  Future<int> _seedAttendanceRecords() async {
    int totalAttendanceRecords = 0;
    final now = DateTime.now();

    // Generate attendance for the last 10 working days
    final workingDays = <String>[];
    for (int i = 1; i <= 14; i++) {
      final date = now.subtract(Duration(days: i));
      // Exclude Sundays
      if (date.weekday != DateTime.sunday) {
        final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        workingDays.add(dateKey);
        if (workingDays.length >= 10) break;
      }
    }

    final presentMap = <String, int>{};

    for (final s in pilotStudents) {
      final uid = s['uid'] as String;
      final streak = s['streak'] as int;
      int studentPresents = 0;

      final batch = _firestore.batch();
      for (int dayIdx = 0; dayIdx < workingDays.length; dayIdx++) {
        final dateKey = workingDays[dayIdx];
        // High streak students present all days; low streak students absent occasionally
        final isPresent = streak > 10 ? true : (dayIdx % 4 != 0);
        if (isPresent) studentPresents++;

        final docRef = _firestore
            .collection('users')
            .doc(uid)
            .collection('attendanceRecords')
            .doc(dateKey);

        batch.set(docRef, {
          'date': dateKey,
          'present': isPresent,
          'markedBy': 'usr_tch_svvm_001',
          'markedByName': 'K. Srinivas',
          'schoolId': schoolId,
          'classId': primaryClassId,
          'timestamp': Timestamp.now(),
        });
        totalAttendanceRecords++;
      }

      await batch.commit();
      presentMap[uid] = studentPresents;
    }

    // Save summary document for fast portal dashboard lookup
    final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    await _firestore.collection('attendanceSummary').doc('${primaryClassId}_$monthKey').set({
      'classId': primaryClassId,
      'month': monthKey,
      'schoolId': schoolId,
      'totalWorkingDays': workingDays.length,
      'presentDays': presentMap,
      'lastUpdated': Timestamp.now(),
    });

    return totalAttendanceRecords;
  }

  // ─── 11. REALISTIC IN-APP TELUGU MESSAGING ─────────────────────────────────
  Future<int> _seedTeluguMessaging() async {
    final chats = [
      // Chat 1: Teacher K. Srinivas & Student P. Sai Charan
      {
        'id': 'usr_std_svvm_801_usr_tch_svvm_001',
        'participants': ['usr_std_svvm_801', 'usr_tch_svvm_001'],
        'type': 'student_teacher',
        'messages': [
          {
            'senderId': 'usr_tch_svvm_001',
            'text': 'రేపు గణిత తరగతిలో అకరణీయ సంఖ్యల ప్రత్యేక పరీక్ష ఉంటుంది. అందరూ పాఠాలను చదివి రావాలి.',
            'timeOffset': 24,
          },
          {
            'senderId': 'usr_std_svvm_801',
            'text': 'నమస్కారం సార్! నేను అధ్యాయం 1 మరియు 2 అభ్యాసాలన్నీ పునశ్చరణ చేశాను. ఖచ్చితంగా మంచి మార్కులు సాధిస్తాను.',
            'timeOffset': 20,
          },
          {
            'senderId': 'usr_tch_svvm_001',
            'text': 'చాలా సంతోషం సాయి చరణ్. సందేహాలుంటే తరగతిలో అడగండి.',
            'timeOffset': 15,
          },
        ],
      },
      // Chat 2: Teacher P. Lakshmi Devi & Parent K. Ramesh
      {
        'id': 'usr_prt_svvm_001_usr_tch_svvm_002',
        'participants': ['usr_prt_svvm_001', 'usr_tch_svvm_002'],
        'type': 'parent_teacher',
        'messages': [
          {
            'senderId': 'usr_tch_svvm_002',
            'text': 'నమస్కారం రమేష్ గారు, సాయి చరణ్ తెలుగు పద్య పఠనంలో ప్రథమ స్థానంలో నిలిచాడు. అభినందనలు!',
            'timeOffset': 48,
          },
          {
            'senderId': 'usr_prt_svvm_001',
            'text': 'చాలా ధన్యవాదాలు మేడమ్! మీ మార్గదర్శకత్వంలో అతను చాలా శ్రద్ధగా చదువుతున్నాడు.',
            'timeOffset': 40,
          },
        ],
      },
      // Chat 3: Principal K. Srinivas Rao & Teacher M. Suresh Babu
      {
        'id': 'usr_prin_svvm_001_usr_tch_svvm_003',
        'participants': ['usr_prin_svvm_001', 'usr_tch_svvm_003'],
        'type': 'direct',
        'messages': [
          {
            'senderId': 'usr_prin_svvm_001',
            'text': 'సురేష్ బాబు గారు, 8వ తరగతి సైన్స్ ప్రయోగశాల ప్రాజెక్ట్‌ల ఏర్పాట్లు పూర్తయ్యాయా?',
            'timeOffset': 30,
          },
          {
            'senderId': 'usr_tch_svvm_003',
            'text': 'నమస్కారం హెడ్మాస్టర్ సార్! విద్యార్థులందరూ మోడల్స్ మరియు చార్టులు సిద్ధం చేశారు.',
            'timeOffset': 10,
          },
        ],
      },
    ];

    for (final c in chats) {
      final chatId = c['id'] as String;
      final participants = List<String>.from(c['participants'] as List);
      final type = c['type'] as String;
      final messagesList = c['messages'] as List<Map<String, dynamic>>;

      final lastMsg = messagesList.last['text'] as String;
      final chatModel = ChatModel(
        id: chatId,
        participants: participants,
        type: type,
        lastMessage: lastMsg,
        lastUpdated: DateTime.now().subtract(Duration(hours: messagesList.last['timeOffset'] as int)),
      );

      await _firestore.collection('chats').doc(chatId).set(chatModel.toMap());

      for (var idx = 0; idx < messagesList.length; idx++) {
        final m = messagesList[idx];
        final msgId = 'msg_${chatId}_$idx';
        final msgModel = MessageModel(
          id: msgId,
          chatId: chatId,
          senderId: m['senderId'] as String,
          text: m['text'] as String,
          timestamp: DateTime.now().subtract(Duration(hours: m['timeOffset'] as int)),
          read: true,
        );

        await _firestore
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .doc(msgId)
            .set(msgModel.toMap()..['id'] = msgId);
      }
    }

    return chats.length;
  }

  // ─── SAFE REVERSIBLE ROLLBACK ──────────────────────────────────────────────
  /// Safely deletes only documents created for this pilot school without affecting other data
  Future<void> revertApSchoolPilot() async {
    if (kDebugMode) print('🧹 Reverting AP School Pilot data for: $schoolId ($schoolCode)');

    // 1. Delete Attendance records and user documents
    for (final s in pilotStudents) {
      final uid = s['uid'] as String;
      final attSnap = await _firestore.collection('users').doc(uid).collection('attendanceRecords').get();
      for (var d in attSnap.docs) {
        await d.reference.delete();
      }
      await _firestore.collection('users').doc(uid).delete();
      await _firestore.collection('roster_students').doc(s['rosterId'] as String).delete();
    }

    // 2. Delete Parents
    for (final s in pilotStudents) {
      await _firestore.collection('users').doc(s['parentUid'] as String).delete();
    }

    // 3. Delete Teachers
    for (final t in pilotTeachers) {
      await _firestore.collection('users').doc(t['uid'] as String).delete();
      await _firestore.collection('roster_teachers').doc(t['rosterId'] as String).delete();
    }

    // 4. Delete Principal
    await _firestore.collection('users').doc(principalUid).delete();
    await _firestore.collection('invitations').doc('INV-PRIN-APKRI-SVVM').delete();

    // 5. Delete Classes subcollection & School
    final classesSnap = await _firestore.collection('schools').doc(schoolId).collection('classes').get();
    for (var d in classesSnap.docs) {
      await d.reference.delete();
    }
    await _firestore.collection('schools').doc(schoolId).delete();
    await _firestore.collection('classes').doc(primaryClassId).delete();
    await _firestore.collection('classes').doc('cls_8_sec_8_a').delete();

    // 6. Delete Resources
    for (final r in pilotResources) {
      await _firestore.collection('learning_resources').doc(r['id'] as String).delete();
    }

    // 7. Delete Assessments & Tasks
    await _firestore.collection('assessments').doc('asm_svvm_tel_01').delete();
    await _firestore.collection('assessments').doc('asm_svvm_mat_01').delete();
    await _firestore.collection('tasks').doc('tsk_svvm_mat_01').delete();
    await _firestore.collection('tasks').doc('tsk_svvm_tel_01').delete();

    if (kDebugMode) print('✅ Pilot rollback completed.');
  }
}
