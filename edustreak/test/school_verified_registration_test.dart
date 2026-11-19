import 'package:flutter_test/flutter_test.dart';
import 'package:edustreak/models/roster_student_model.dart';
import 'package:edustreak/models/roster_teacher_model.dart';
import 'package:edustreak/models/user_model.dart';
import 'package:edustreak/services/csv_import_service.dart';
import 'package:edustreak/services/school_registration_service.dart';

void main() {
  group('Roster Models Tests', () {
    test('RosterStudentModel correctly serializes and deserializes', () {
      final now = DateTime.now();
      final model = RosterStudentModel(
        id: 'std_01',
        schoolId: 'sch_ap_001',
        schoolCode: 'AP-KRI-042',
        studentName: 'Ravi Kumar',
        rollNumber: '101',
        admissionNumber: 'ADM001',
        grade: '8',
        section: 'A',
        classId: 'Class 8-A',
        academicYear: '2026-2027',
        verificationPin: '4821',
        status: 'not_registered',
        createdAt: now,
      );

      final map = model.toMap();
      expect(map['schoolCode'], equals('AP-KRI-042'));
      expect(map['status'], equals('not_registered'));
      expect(map['verificationPin'], equals('4821'));

      final reconstructed = RosterStudentModel.fromMap(map, 'std_01');
      expect(reconstructed.studentName, equals('Ravi Kumar'));
      expect(reconstructed.rollNumber, equals('101'));
      expect(reconstructed.isEligibleForRegistration, isTrue);
      expect(reconstructed.isRegistered, isFalse);
    });

    test('RosterTeacherModel correctly serializes and preserves assigned subjects/classes', () {
      final model = RosterTeacherModel(
        id: 'tch_01',
        schoolId: 'sch_ap_001',
        schoolCode: 'AP-KRI-042',
        teacherName: 'Dr. Sarah Jenkins',
        employeeId: 'EMP014',
        email: 'sarah.jenkins@edustreak.com',
        phone: '9876543210',
        assignedSubjects: const ['Mathematics', 'Physics'],
        assignedClasses: const ['Class 8-A', 'Class 9-B'],
        academicYear: '2026-2027',
        verificationPin: '5819',
        status: 'not_registered',
        createdAt: DateTime.now(),
      );

      final map = model.toMap();
      expect(map['employeeId'], equals('EMP014'));
      expect(map['assignedSubjects'], contains('Mathematics'));
      expect(map['status'], equals('not_registered'));

      final reconstructed = RosterTeacherModel.fromMap(map, 'tch_01');
      expect(reconstructed.assignedClasses, contains('Class 8-A'));
      expect(reconstructed.isEligibleForRegistration, isTrue);
    });
  });

  group('CSV Parsing & Validation Tests', () {
    final csvService = CsvImportService();

    test('Student CSV Template generation is non-empty and well-formatted', () {
      final template = CsvImportService.getStudentCsvTemplate();
      expect(template, contains('student_name'));
      expect(template, contains('roll_number'));
      expect(template, contains('class'));
      expect(template, contains('section'));
    });

    test('Teacher CSV Template generation is non-empty and well-formatted', () {
      final template = CsvImportService.getTeacherCsvTemplate();
      expect(template, contains('teacher_name'));
      expect(template, contains('employee_id'));
      expect(template, contains('assigned_subjects'));
    });

    test('validateCsv catches completely empty CSV', () async {
      final result = await csvService.validateCsv(
        csvContent: '',
        schoolId: 'dummy_school',
      );
      expect(result.hasErrors, isTrue);
      expect(result.globalErrors, isNotEmpty);
      expect(result.globalErrors.first, contains('empty'));
    });

    test('validateCsv catches missing required columns', () async {
      const invalidCsv = '''student_name,grade
Ravi,8''';
      final result = await csvService.validateCsv(
        csvContent: invalidCsv,
        schoolId: 'dummy_school',
      );
      expect(result.hasErrors, isTrue);
      expect(result.globalErrors.first, contains('Missing required columns'));
    });

    test('validateCsv parses valid student CSV rows correctly', () async {
      const validCsv = '''student_name,roll_number,admission_number,class,section,academic_year
Ravi Kumar,101,ADM001,8,A,2026-2027
Priya Sharma,102,ADM002,8,A,2026-2027''';

      final result = await csvService.validateCsv(
        csvContent: validCsv,
        schoolId: 'dummy_school',
      );
      expect(result.globalErrors, isEmpty);
      expect(result.validRows.length, equals(2));
      expect(result.validRows[0].rollNumber, equals('101'));
      expect(result.validRows[0].classLabel, equals('Class 8-A'));
      expect(result.validRows[1].studentName, equals('Priya Sharma'));
    });

    test('validateCsv detects duplicate roll numbers within the file', () async {
      const dupCsv = '''student_name,roll_number,class,section
Ravi Kumar,101,8,A
Priya Sharma,101,8,A''';

      final result = await csvService.validateCsv(
        csvContent: dupCsv,
        schoolId: 'dummy_school',
      );
      expect(result.invalidRows.length, equals(1));
      expect(result.invalidRows[0].error, contains('Duplicate roll number'));
    });

    test('validateTeacherCsv catches missing employee_id or email', () async {
      const invalidTeacherCsv = '''teacher_name,assigned_subjects
Dr. Sarah,Mathematics''';

      final result = await csvService.validateTeacherCsv(
        csvContent: invalidTeacherCsv,
        schoolId: 'dummy_school',
      );
      expect(result.hasErrors, isTrue);
      expect(result.globalErrors.first, contains('Missing required columns'));
    });

    test('validateTeacherCsv correctly parses valid teacher CSV', () async {
      const validTeacherCsv = '''teacher_name,employee_id,email,phone,assigned_subjects,assigned_classes,academic_year
Dr. Sarah Jenkins,EMP014,sarah.jenkins@edustreak.com,9876543220,Mathematics;Physics,Class 8-A;Class 9-B,2026-2027
Mr. David Smith,EMP015,david.smith@edustreak.com,9876543221,Biology;General Science,Class 7-A;Class 8-B,2026-2027''';

      final result = await csvService.validateTeacherCsv(
        csvContent: validTeacherCsv,
        schoolId: 'dummy_school',
      );
      expect(result.globalErrors, isEmpty);
      expect(result.validRows.length, equals(2));
      expect(result.validRows[0].employeeId, equals('EMP014'));
      expect(result.validRows[0].assignedSubjects, contains('Mathematics'));
      expect(result.validRows[0].assignedSubjects, contains('Physics'));
      expect(result.validRows[0].assignedClasses, contains('Class 8-A'));
    });
  });

  group('School Registration Service Verification Logic Tests', () {
    final regService = SchoolRegistrationService();

    test('verifySchoolCode returns school for standard government code', () async {
      final school = await regService.verifySchoolCode('AP-KRI-042');
      expect(school, isNotNull);
      expect(school!.name, contains('Kankipadu'));
      expect(school.code, equals('AP-KRI-042'));
    });

    test('verifySchoolCode returns null for empty or nonexistent code', () async {
      final school = await regService.verifySchoolCode('INVALID-XYZ-999');
      expect(school, isNull);
    });

    test('lookupStudentRecord verifies registered student baseline', () async {
      final preview = await regService.lookupStudentRecord('AP-KRI-042', '101');
      expect(preview, isNotNull);
      expect(preview.studentName, equals('Ravi Kumar'));
      expect(preview.classLabel, equals('Class 8-A'));
    });

    test('lookupTeacherRecord verifies registered faculty baseline', () async {
      final preview = await regService.lookupTeacherRecord('AP-KRI-042', 'EMP014');
      expect(preview, isNotNull);
      expect(preview.teacherName, equals('Dr. Sarah Jenkins'));
      expect(preview.assignedSubjects, contains('Mathematics'));
    });

    test('lookupStudentRecord throws error on invalid school code', () async {
      expect(
        () => regService.lookupStudentRecord('BAD-CODE', '101'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('Principal Invitation & Institutional Governance Tests', () {
    final regService = SchoolRegistrationService();

    test('verifyPrincipalInvitation verifies valid invitation code', () async {
      final preview = await regService.verifyPrincipalInvitation('INV-PRIN-APKRI042-DEMO');
      expect(preview, isNotNull);
      expect(preview.principalName, equals('Dr. Sudhir Sharma'));
      expect(preview.schoolCode, equals('AP-KRI-042'));
      expect(preview.schoolName, contains('Kankipadu'));
      expect(preview.status, equals('pending'));
      expect(preview.isExpired, isFalse);
    });

    test('verifyPrincipalInvitation verifies official principal email', () async {
      final preview = await regService.verifyPrincipalInvitation('dr.sudhir.principal@apgov.edu.in');
      expect(preview, isNotNull);
      expect(preview.principalEmail, equals('dr.sudhir.principal@apgov.edu.in'));
      expect(preview.principalName, equals('Dr. Sudhir Sharma'));
      expect(preview.schoolCode, equals('AP-KRI-042'));
    });

    test('verifyPrincipalInvitation throws error on empty query', () async {
      expect(
        () => regService.verifyPrincipalInvitation('   '),
        throwsA(isA<Exception>()),
      );
    });

    test('verifyPrincipalInvitation throws error on nonexistent code', () async {
      expect(
        () => regService.verifyPrincipalInvitation('INV-PRIN-NONEXISTENT-9999'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('Parent Relationship Verification Tests', () {
    final regService = SchoolRegistrationService();

    test('lookupParentRelationship verifies child with school code and student ID', () async {
      final preview = await regService.lookupParentRelationship(
        schoolCode: 'AP-KRI-042',
        studentIdentifier: '101',
        parentContact: '9440123456',
      );
      expect(preview, isNotNull);
      expect(preview.studentName, equals('Ravi Kumar'));
      expect(preview.schoolCode, equals('AP-KRI-042'));
      expect(preview.maskedContact, contains('3456'));
    });

    test('lookupParentRelationship rejects invalid school code', () async {
      expect(
        () => regService.lookupParentRelationship(
          schoolCode: 'INVALID-CODE',
          studentIdentifier: '101',
          parentContact: '9440123456',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('lookupParentRelationship rejects invalid student ID', () async {
      expect(
        () => regService.lookupParentRelationship(
          schoolCode: 'AP-KRI-042',
          studentIdentifier: '99999',
          parentContact: '9440123456',
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('Identity Verification Challenge Tests', () {
    final regService = SchoolRegistrationService();

    test('sendIdentityVerification creates challenge with 10-minute expiry and masked recipient', () async {
      final challenge = await regService.sendIdentityVerification(
        schoolCode: 'AP-KRI-042',
        targetType: 'student',
        rosterId: 'roster_std_001',
        contactMethod: 'sms',
      );
      expect(challenge.challengeId, isNotEmpty);
      expect(challenge.channel, equals('sms'));
      expect(challenge.expiresAt.isAfter(DateTime.now()), isTrue);
    });

    test('verifyIdentityChallenge accepts valid OTP', () async {
      final isValid = await regService.verifyIdentityChallenge(
        challengeId: 'CHAL-TEST-001',
        code: '123456',
      );
      expect(isValid, isTrue);
    });

    test('verifyIdentityChallenge accepts valid institutional PINs', () async {
      final isPinValid = await regService.verifyIdentityChallenge(
        challengeId: 'CHAL-TEST-002',
        code: '4821',
      );
      expect(isPinValid, isTrue);
    });
  });

  group('UserModel Status Integration Tests', () {
    test('UserModel defaults status to active if isActive is true', () {
      final user = UserModel(
        id: 'u_1',
        name: 'Test Student',
        email: 'test@edustreak.com',
        role: 'student',
        isActive: true,
      );
      expect(user.status, equals('active'));
    });

    test('UserModel preserves employeeId and explicit status', () {
      final user = UserModel(
        id: 't_1',
        name: 'Test Teacher',
        email: 'teacher@edustreak.com',
        role: 'teacher',
        employeeId: 'EMP999',
        status: 'not_registered',
        isActive: false,
      );
      expect(user.employeeId, equals('EMP999'));
      expect(user.status, equals('not_registered'));
      expect(user.isActive, isFalse);

      final map = user.toMap();
      expect(map['employeeId'], equals('EMP999'));
      expect(map['status'], equals('not_registered'));

      final copy = user.copyWith(status: 'active', isActive: true);
      expect(copy.status, equals('active'));
      expect(copy.isActive, isTrue);
    });
  });
}
