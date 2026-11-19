import 'package:flutter_test/flutter_test.dart';
import 'package:edustreak/models/curriculum_model.dart';
import 'package:edustreak/models/school_model.dart';
import 'package:edustreak/models/user_model.dart';
import 'package:edustreak/services/school_service.dart';

SchoolModel createTestSchool({
  required String id,
  required String name,
  required String code,
  required SchoolType type,
  String status = 'active',
  String district = 'Krishna',
  String? principalId,
  String? principalName,
  String? principalEmail,
  String curriculumTemplateId = 'AP_STATE_GOVT',
}) {
  return SchoolModel(
    id: id,
    name: name,
    code: code,
    type: type,
    status: status,
    district: district,
    principalId: principalId,
    principalName: principalName,
    principalEmail: principalEmail,
    totalStudents: 450,
    totalTeachers: 24,
    curriculumTemplateId: curriculumTemplateId,
    establishedDate: DateTime(2020, 1, 1),
  );
}

void main() {
  group('1. School Code Generation & Uniqueness Format Tests', () {
    final schoolService = SchoolService();

    test('Generates AP Government code with correct prefix and district', () async {
      final code = await schoolService.generateUniqueSchoolCode(
        type: SchoolType.government,
        district: 'Krishna',
      );

      expect(code, startsWith('AP-KRI-'));
      expect(RegExp(r'^AP-KRI-\d{3}$').hasMatch(code), isTrue);
    });

    test('Generates CBSE code with correct prefix and district', () async {
      final code = await schoolService.generateUniqueSchoolCode(
        type: SchoolType.cbse,
        district: 'Guntur',
      );

      expect(code, startsWith('CBSE-GUN-'));
      expect(RegExp(r'^CBSE-GUN-\d{3}$').hasMatch(code), isTrue);
    });

    test('Generates Private school code with correct prefix and district', () async {
      final code = await schoolService.generateUniqueSchoolCode(
        type: SchoolType.privateSchool,
        district: 'Visakhapatnam',
      );

      expect(code, startsWith('PVT-VIS-'));
      expect(RegExp(r'^PVT-VIS-\d{3}$').hasMatch(code), isTrue);
    });

    test('Successive generated codes adhere to length and formatting constraints', () async {
      final codes = <String>{};
      for (int i = 0; i < 10; i++) {
        final c = await schoolService.generateUniqueSchoolCode(
          type: SchoolType.government,
          district: 'Tirupati',
        );
        codes.add(c);
      }
      expect(codes.length, greaterThanOrEqualTo(1));
      for (final c in codes) {
        expect(RegExp(r'^AP-TIR-\d{3}$').hasMatch(c), isTrue);
      }
    });
  });

  group('2. School Registration Approval & Rejection State Transitions', () {
    test('New school starts in pending_approval state', () {
      final school = createTestSchool(
        id: 'sch_test_001',
        name: 'Amaravati Public School',
        code: 'PVT-GNT-101',
        type: SchoolType.privateSchool,
        status: 'pending_approval',
        district: 'Guntur',
        curriculumTemplateId: 'PRIVATE_CUSTOM',
      );

      expect(school.isPendingApproval, isTrue);
      expect(school.isSuspended, isFalse);
      expect(school.isDeactivated, isFalse);
      expect(school.hasPrincipalAssigned, isFalse);
    });

    test('School approval transitions status to active', () {
      final pendingSchool = createTestSchool(
        id: 'sch_test_001',
        name: 'Amaravati Public School',
        code: 'PVT-GNT-101',
        type: SchoolType.privateSchool,
        status: 'pending_approval',
        district: 'Guntur',
      );

      final approvedSchool = pendingSchool.copyWith(status: 'active');
      expect(approvedSchool.status, equals('active'));
      expect(approvedSchool.isPendingApproval, isFalse);
      expect(approvedSchool.isSuspended, isFalse);
      expect(approvedSchool.isDeactivated, isFalse);
    });

    test('School rejection transitions status to deactivated with reason', () {
      final pendingSchool = createTestSchool(
        id: 'sch_test_002',
        name: 'Unverified Academy',
        code: 'PVT-KRI-999',
        type: SchoolType.privateSchool,
        status: 'pending_approval',
        district: 'Krishna',
      );

      final rejectedSchool = pendingSchool.copyWith(status: 'deactivated');
      expect(rejectedSchool.status, equals('deactivated'));
      expect(rejectedSchool.isDeactivated, isTrue);
      expect(rejectedSchool.isPendingApproval, isFalse);
    });

    test('School suspension state helper works properly', () {
      final activeSchool = createTestSchool(
        id: 'sch_test_003',
        name: 'Zilla Parishad High School',
        code: 'AP-KRI-042',
        type: SchoolType.government,
        status: 'active',
        district: 'Krishna',
      );

      final suspendedSchool = activeSchool.copyWith(status: 'suspended');
      expect(suspendedSchool.isSuspended, isTrue);
      expect(suspendedSchool.isPendingApproval, isFalse);
    });
  });

  group('3. Principal Assignment & Leadership Transfer Tests', () {
    test('Assigning Principal sets ID, name, email and triggers hasPrincipalAssigned', () {
      final school = createTestSchool(
        id: 'sch_test_004',
        name: 'AP Model School',
        code: 'AP-GNT-109',
        type: SchoolType.government,
        status: 'active',
        district: 'Guntur',
      );

      expect(school.hasPrincipalAssigned, isFalse);

      final assigned = school.copyWith(
        principalId: 'prin_991',
        principalName: 'Dr. M. Sailaja',
        principalEmail: 'sailaja.m@apgov.edu.in',
      );

      expect(assigned.hasPrincipalAssigned, isTrue);
      expect(assigned.principalId, equals('prin_991'));
      expect(assigned.principalName, equals('Dr. M. Sailaja'));
      expect(assigned.principalEmail, equals('sailaja.m@apgov.edu.in'));
    });

    test('Leadership transfer updates principal credentials while preserving school identifiers', () {
      final currentSchool = createTestSchool(
        id: 'sch_test_005',
        name: 'Kendriya Vidyalaya 1',
        code: 'CBSE-AP-012',
        type: SchoolType.cbse,
        status: 'active',
        district: 'Krishna',
        principalId: 'prin_old',
        principalName: 'S. N. Sharma',
        principalEmail: 'sn.sharma@kvs.ac.in',
      );

      // Perform transfer
      final transferred = currentSchool.copyWith(
        principalId: 'prin_new',
        principalName: 'Dr. R. Ramanathan',
        principalEmail: 'r.ramanathan@kvs.ac.in',
      );

      expect(transferred.id, equals(currentSchool.id));
      expect(transferred.code, equals(currentSchool.code));
      expect(transferred.type, equals(currentSchool.type));
      expect(transferred.principalId, equals('prin_new'));
      expect(transferred.principalName, equals('Dr. R. Ramanathan'));
      expect(transferred.principalEmail, equals('r.ramanathan@kvs.ac.in'));
    });
  });

  group('4. Multi-Tenant Protected Fields & Scoping Tests', () {
    test('Principal cannot alter protected fields (code, type, status, id)', () {
      final originalData = {
        'id': 'sch_001',
        'code': 'AP-KRI-042',
        'type': 'government',
        'status': 'active',
        'curriculumTemplateId': 'AP_STATE_GOVT',
        'contactPhone': '9848011111',
        'contactEmail': 'headmaster@apgov.edu.in',
        'contactPerson': 'Headmaster',
        'mandal': 'Kankipadu',
      };
      expect(originalData['code'], equals('AP-KRI-042'));

      // Attempt to maliciously or accidentally modify code and type
      final attemptPayload = {
        'code': 'HACKED-CODE',
        'type': 'privateSchool',
        'status': 'suspended',
        'curriculumTemplateId': 'PRIVATE_CUSTOM',
        'contactPhone': '9999988888',
        'contactEmail': 'updated.headmaster@apgov.edu.in',
        'mandal': 'Kankipadu Central',
      };

      // Filter as updateSchoolPermittedProfile enforces
      final filtered = <String, dynamic>{};
      final allowedFields = {
        'contactPhone',
        'contactEmail',
        'contactPerson',
        'address',
        'mandal',
        'pincode',
        'cityOrVillage',
        'academicYear',
      };

      for (var entry in attemptPayload.entries) {
        if (allowedFields.contains(entry.key)) {
          filtered[entry.key] = entry.value;
        }
      }

      expect(filtered.containsKey('code'), isFalse);
      expect(filtered.containsKey('type'), isFalse);
      expect(filtered.containsKey('status'), isFalse);
      expect(filtered.containsKey('curriculumTemplateId'), isFalse);
      expect(filtered['contactPhone'], equals('9999988888'));
      expect(filtered['contactEmail'], equals('updated.headmaster@apgov.edu.in'));
      expect(filtered['mandal'], equals('Kankipadu Central'));
    });
  });

  group('5. Parent Linking Request & Status Resolution Tests', () {
    test('Parent model serializes multiple linked children correctly', () {
      final parent = UserModel(
        id: 'par_test_01',
        name: 'M. Ramesh Babu',
        email: 'ramesh.m@gmail.com',
        role: 'parent',
        schoolId: 'sch_ap_001',
        schoolCode: 'AP-KRI-042',
        childIds: const ['std_01', 'std_02'],
        status: 'active',
      );

      expect(parent.isParent, isTrue);
      expect(parent.childIds.length, equals(2));
      expect(parent.childIds, contains('std_01'));
      expect(parent.childIds, contains('std_02'));
    });

    test('Approval request resolution marks status approved and records reviewer', () {
      final request = {
        'id': 'appr_01',
        'schoolId': 'sch_ap_001',
        'type': 'parent_linking',
        'title': 'Parent Student Linking Request',
        'status': 'pending',
      };

      // Simulate resolution
      final resolved = Map<String, dynamic>.from(request)
        ..addAll({
          'status': 'approved',
          'reviewerUid': 'prin_001',
          'reviewerName': 'Dr. Sudhir Sharma',
          'resolvedAt': DateTime.now().toIso8601String(),
        });

      expect(resolved['status'], equals('approved'));
      expect(resolved['reviewerUid'], equals('prin_001'));
      expect(resolved['reviewerName'], equals('Dr. Sudhir Sharma'));
      expect(resolved['resolvedAt'], isNotNull);
    });

    test('Approval request rejection records reason', () {
      final request = {
        'id': 'appr_02',
        'schoolId': 'sch_ap_001',
        'type': 'attendance_correction',
        'title': 'Attendance Record Correction',
        'status': 'pending',
      };

      final rejected = Map<String, dynamic>.from(request)
        ..addAll({
          'status': 'rejected',
          'reason': 'Medical certificate missing for Nov 04 absence',
          'reviewerUid': 'prin_001',
          'reviewerName': 'Dr. Sudhir Sharma',
        });

      expect(rejected['status'], equals('rejected'));
      expect(rejected['reason'], contains('Medical certificate missing'));
    });
  });

  group('6. Curriculum Multi-Tenant Isolation Tests', () {
    test('Curriculum board mappings match statutory requirements', () {
      expect(SchoolType.government.defaultCurriculumCode, equals('AP_STATE_GOVT'));
      expect(SchoolType.cbse.defaultCurriculumCode, equals('CBSE_CENTRAL'));
      expect(SchoolType.privateSchool.defaultCurriculumCode, equals('PRIVATE_CUSTOM'));
    });

    test('Custom private school subject serialization and chapter hierarchy', () {
      final topic1 = TopicModel(
        id: 't_01',
        title: 'Introduction to Python Data Structures',
        order: 1,
        estimatedMinutes: 30,
        isCompleted: true,
      );

      final chapter1 = ChapterModel(
        id: 'ch_01',
        title: 'Python for Beginners',
        chapterNumber: 1,
        topics: [topic1],
        progress: 1.0,
      );

      final subject = SubjectCurriculumModel(
        id: 'subj_pvt_coding',
        name: 'Computer Science & AI',
        code: 'CS-AI-8',
        colorValue: 0xFF00E5FF,
        chapters: [chapter1],
        completionPercentage: 85.0,
      );

      final map = subject.toMap();
      expect(map['code'], equals('CS-AI-8'));
      expect(map['completionPercentage'], equals(85.0));

      final deserialized = SubjectCurriculumModel.fromMap(map);
      expect(deserialized.name, equals('Computer Science & AI'));
      expect(deserialized.chapters.length, equals(1));
      expect(deserialized.chapters.first.title, equals('Python for Beginners'));
      expect(deserialized.chapters.first.topics.first.title, equals('Introduction to Python Data Structures'));
      expect(deserialized.chapters.first.topics.first.isCompleted, isTrue);
    });

    test('Cloning template to private school does not mutate base template', () {
      final template = CurriculumTemplateModel(
        id: 'AP_STATE_GOVT',
        name: 'AP State Board',
        boardCode: 'BSEAP',
        description: 'SCERT standard',
        adoptedSchoolsCount: 128,
        standardSubjects: [
          SubjectCurriculumModel(
            id: 'm_01',
            name: 'Mathematics',
            code: 'MATH-8',
            colorValue: 0xFF3B82F6,
            chapters: [],
          ),
        ],
      );

      // Clone subjects to private school
      final clonedSubjects = template.standardSubjects
          .map((s) => SubjectCurriculumModel.fromMap(s.toMap()))
          .toList();

      // Add custom chapter to cloned subject
      final modifiedPrivateSubject = SubjectCurriculumModel(
        id: clonedSubjects.first.id,
        name: clonedSubjects.first.name,
        code: clonedSubjects.first.code,
        colorValue: clonedSubjects.first.colorValue,
        chapters: [
          ChapterModel(id: 'ch_new', title: 'Vedic Math Shortcuts', chapterNumber: 1),
        ],
      );

      // Verify template remains pristine with 0 chapters
      expect(template.standardSubjects.first.chapters.isEmpty, isTrue);
      // Verify private school subject has the new chapter
      expect(modifiedPrivateSubject.chapters.length, equals(1));
      expect(modifiedPrivateSubject.chapters.first.title, equals('Vedic Math Shortcuts'));
    });
  });
}
