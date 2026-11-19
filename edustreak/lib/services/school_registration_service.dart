import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/school_model.dart';
import '../models/roster_student_model.dart';
import '../models/roster_teacher_model.dart';
import 'audit_service.dart';

class PrincipalInvitationPreview {
  final String invitationCode;
  final String principalEmail;
  final String principalName;
  final String schoolId;
  final String schoolName;
  final String schoolCode;
  final String status; // 'pending', 'accepted', 'expired', 'revoked'
  final DateTime? expiresAt;
  final bool isExpired;

  const PrincipalInvitationPreview({
    required this.invitationCode,
    required this.principalEmail,
    required this.principalName,
    required this.schoolId,
    required this.schoolName,
    required this.schoolCode,
    required this.status,
    this.expiresAt,
    this.isExpired = false,
  });
}

class ParentVerificationPreview {
  final String schoolCode;
  final String schoolName;
  final String studentName;
  final String rollNumber;
  final String admissionNumber;
  final String classLabel;
  final String maskedContact;
  final String rosterId;
  final bool requiresPin;

  const ParentVerificationPreview({
    required this.schoolCode,
    required this.schoolName,
    required this.studentName,
    required this.rollNumber,
    required this.admissionNumber,
    required this.classLabel,
    required this.maskedContact,
    required this.rosterId,
    required this.requiresPin,
  });
}

class IdentityVerificationChallenge {
  final String challengeId;
  final String recipientMasked;
  final String channel; // 'sms' | 'email' | 'pin'
  final DateTime expiresAt;

  const IdentityVerificationChallenge({
    required this.challengeId,
    required this.recipientMasked,
    required this.channel,
    required this.expiresAt,
  });
}

class StudentVerificationPreview {
  final String studentName;
  final String classLabel;
  final String schoolName;
  final String schoolCode;
  final String rollNumber;
  final String admissionNumber;
  final String rosterId;
  final bool requiresPin;

  const StudentVerificationPreview({
    required this.studentName,
    required this.classLabel,
    required this.schoolName,
    required this.schoolCode,
    required this.rollNumber,
    required this.admissionNumber,
    required this.rosterId,
    required this.requiresPin,
  });
}

class TeacherVerificationPreview {
  final String teacherName;
  final String employeeId;
  final String email;
  final List<String> assignedSubjects;
  final List<String> assignedClasses;
  final String schoolName;
  final String schoolCode;
  final String rosterId;

  const TeacherVerificationPreview({
    required this.teacherName,
    required this.employeeId,
    required this.email,
    required this.assignedSubjects,
    required this.assignedClasses,
    required this.schoolName,
    required this.schoolCode,
    required this.rosterId,
  });
}

class SchoolRegistrationService {
  final FirebaseFirestore? _customFirestore;
  FirebaseFirestore get _firestore => _customFirestore ?? FirebaseFirestore.instance;
  final FirebaseAuth? _customAuth;
  FirebaseAuth get _auth => _customAuth ?? FirebaseAuth.instance;
  final AuditService _auditService = AuditService();

  SchoolRegistrationService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _customFirestore = firestore,
        _customAuth = auth;

  /// Verifies a school code and retrieves the official SchoolModel
  Future<SchoolModel?> verifySchoolCode(String schoolCode) async {
    final cleanCode = schoolCode.trim().toUpperCase();
    if (cleanCode.isEmpty) return null;

    try {
      final snap = await _firestore
          .collection('schools')
          .where('code', isEqualTo: cleanCode)
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        final doc = snap.docs.first;
        return SchoolModel.fromMap(doc.data(), doc.id);
      }
    } catch (e) {
      debugPrint('Error verifying school code: $e');
    }

    // Default AP Government baseline school for smooth local experience
    if (cleanCode == 'AP-KRI-042' || cleanCode == 'SCH001') {
      return SchoolModel(
        id: 'sch_ap_001',
        name: 'Z.P. High School, Kankipadu',
        code: cleanCode,
        type: SchoolType.government,
        status: 'active',
        address: 'Main Road, Kankipadu Village',
        mandal: 'Kankipadu',
        district: 'Krishna',
        state: 'Andhra Pradesh',
        pincode: '521151',
        contactPerson: 'Dr. Sudhir Sharma (Principal)',
        contactPhone: '+91 94401 23456',
        contactEmail: 'zphs.kankipadu@apgov.edu.in',
        affiliationNumber: 'AP-SCERT-1984-KRI',
        academicYear: '2026-2027',
        supportedClasses: const ['Class 6', 'Class 7', 'Class 8', 'Class 9', 'Class 10'],
        totalStudents: 620,
        totalTeachers: 28,
        curriculumTemplateId: 'AP_STATE_GOVT',
        establishedDate: DateTime(1984, 6, 12),
      );
    }

    return null;
  }

  /// Looks up and verifies an invitation for a Principal
  Future<PrincipalInvitationPreview> verifyPrincipalInvitation(String codeOrEmail) async {
    final clean = codeOrEmail.trim();
    if (clean.isEmpty) {
      throw Exception('Please enter an invitation code or registered email address.');
    }

    // 1. Check in invitations collection
    try {
      QuerySnapshot<Map<String, dynamic>> snap;
      if (clean.toUpperCase().startsWith('INV-')) {
        snap = await _firestore
            .collection('invitations')
            .where('invitationCode', isEqualTo: clean.toUpperCase())
            .limit(1)
            .get();
      } else {
        snap = await _firestore
            .collection('invitations')
            .where('principalEmail', isEqualTo: clean.toLowerCase())
            .limit(1)
            .get();
      }

      if (snap.docs.isNotEmpty) {
        final data = snap.docs.first.data();
        final status = data['status']?.toString() ?? 'pending';
        final schoolId = data['schoolId']?.toString() ?? '';
        final schoolCode = data['schoolCode']?.toString() ?? '';
        final principalEmail = data['principalEmail']?.toString() ?? clean;
        final principalName = data['principalName']?.toString() ?? 'Principal';
        final inviteCode = data['invitationCode']?.toString() ?? clean;
        final expiresAt = (data['expiresAt'] as Timestamp?)?.toDate();
        final isExpired = expiresAt != null && expiresAt.isBefore(DateTime.now());

        if (status == 'accepted') {
          throw Exception(
            'This invitation has already been accepted. Please sign in with your credentials.',
          );
        }
        if (status == 'revoked') {
          throw Exception('This invitation has been revoked. Please contact Central Administration.');
        }
        if (isExpired) {
          throw Exception(
            'This invitation code has expired. Please contact Central Administration to request a new invitation.',
          );
        }

        // Verify that the associated school is active
        final school = await verifySchoolCode(schoolCode);
        if (school != null && (school.status == 'suspended' || school.status == 'deactivated')) {
          throw Exception('The associated school is currently inactive or suspended.');
        }

        return PrincipalInvitationPreview(
          invitationCode: inviteCode,
          principalEmail: principalEmail,
          principalName: principalName,
          schoolId: schoolId,
          schoolName: school?.name ?? 'Assigned School ($schoolCode)',
          schoolCode: schoolCode,
          status: status,
          expiresAt: expiresAt,
          isExpired: isExpired,
        );
      }
    } catch (e) {
      if (e is Exception &&
          (e.toString().contains('already been accepted') ||
              e.toString().contains('revoked') ||
              e.toString().contains('expired') ||
              e.toString().contains('suspended'))) {
        rethrow;
      }
      debugPrint('Error looking up invitation: $e');
    }

    // 2. Check users collection for pre-provisioned invited principal
    try {
      final userSnap = await _firestore
          .collection('users')
          .where('email', isEqualTo: clean.toLowerCase())
          .where('role', isEqualTo: 'principal')
          .limit(1)
          .get();

      if (userSnap.docs.isNotEmpty) {
        final uDoc = userSnap.docs.first;
        final uData = uDoc.data();
        final schoolCode = uData['schoolCode']?.toString() ?? 'AP-KRI-042';
        final school = await verifySchoolCode(schoolCode);

        if (uData['status'] == 'active' && uData['isActive'] == true) {
          throw Exception('This Principal account is already registered. Please sign in with your credentials.');
        }

        return PrincipalInvitationPreview(
          invitationCode: uData['invitationCode']?.toString() ?? 'INV-PRIN-$schoolCode',
          principalEmail: uData['email']?.toString() ?? clean,
          principalName: uData['name']?.toString() ?? 'Principal',
          schoolId: uData['schoolId']?.toString() ?? school?.id ?? 'sch_ap_001',
          schoolName: school?.name ?? 'Assigned School',
          schoolCode: schoolCode,
          status: 'pending',
          expiresAt: DateTime.now().add(const Duration(days: 7)),
          isExpired: false,
        );
      }
    } catch (e) {
      if (e is Exception && e.toString().contains('already registered')) rethrow;
    }

    // 3. Known demo Principal fallback
    if (clean.toLowerCase() == 'dr.sudhir.principal@apgov.edu.in' ||
        clean.toUpperCase().startsWith('INV-PRIN-APKRI042') ||
        clean.toLowerCase() == 'principal@edustreak.com') {
      final school = await verifySchoolCode('AP-KRI-042');
      return PrincipalInvitationPreview(
        invitationCode: clean.toUpperCase().startsWith('INV-') ? clean.toUpperCase() : 'INV-PRIN-APKRI042-8821',
        principalEmail: clean.contains('@') ? clean.toLowerCase() : 'principal@edustreak.com',
        principalName: 'Dr. Sudhir Sharma',
        schoolId: school?.id ?? 'sch_ap_001',
        schoolName: school?.name ?? 'Z.P. High School, Kankipadu',
        schoolCode: 'AP-KRI-042',
        status: 'pending',
        expiresAt: DateTime.now().add(const Duration(days: 7)),
        isExpired: false,
      );
    }

    throw Exception(
      'Invalid or nonexistent invitation code or email. Please contact your Central Administrator.',
    );
  }

  /// Accepts a Principal invitation, sets credentials, activates account, and associates with the school
  Future<UserModel> acceptPrincipalInvitation({
    required String invitationCode,
    required String password,
  }) async {
    final preview = await verifyPrincipalInvitation(invitationCode);

    if (password.length < 8) {
      throw Exception('Password must be at least 8 characters for administrative accounts.');
    }

    // 1. Create or bind Firebase Auth account
    UserCredential? credential;
    try {
      credential = await _auth.createUserWithEmailAndPassword(
        email: preview.principalEmail,
        password: password,
      );
    } on FirebaseAuthException catch (authErr) {
      if (authErr.code == 'email-already-in-use') {
        try {
          credential = await _auth.signInWithEmailAndPassword(
            email: preview.principalEmail,
            password: password,
          );
        } catch (_) {
          throw Exception(
            'An administrative account with this email already exists. Please sign in or reset your password.',
          );
        }
      } else {
        throw Exception(authErr.message ?? 'Principal account creation failed.');
      }
    }

    final authUser = credential.user;
    if (authUser == null) {
      throw Exception('Failed to establish authenticated Principal session.');
    }

    final authUid = authUser.uid;

    final principalUser = UserModel(
      id: authUid,
      name: preview.principalName,
      email: preview.principalEmail,
      role: 'principal',
      schoolId: preview.schoolId,
      schoolCode: preview.schoolCode,
      status: 'active',
      isActive: true,
      academicYear: '2026-2027',
    );

    // Atomically write user doc, update invitation doc, update school doc
    final batch = _firestore.batch();
    batch.set(_firestore.collection('users').doc(authUid), principalUser.toMap(), SetOptions(merge: true));

    final inviteRef = _firestore.collection('invitations').doc(preview.invitationCode);
    batch.set(
      inviteRef,
      {
        'status': 'accepted',
        'claimedByUid': authUid,
        'acceptedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    if (preview.schoolId.isNotEmpty) {
      final schoolRef = _firestore.collection('schools').doc(preview.schoolId);
      batch.update(schoolRef, {
        'principalId': authUid,
        'principalName': preview.principalName,
        'principalEmail': preview.principalEmail,
        'status': 'active',
        'isActive': true,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    }

    try {
      await batch.commit();
    } catch (e) {
      debugPrint('Firestore batch commit error on principal activation: $e');
    }

    await _auditService.logAction(
      action: 'PRINCIPAL_INVITATION_ACCEPTED',
      targetType: 'user',
      targetId: authUid,
      schoolId: preview.schoolId,
      schoolCode: preview.schoolCode,
      details: {
        'principalName': preview.principalName,
        'principalEmail': preview.principalEmail,
        'invitationCode': preview.invitationCode,
      },
    );

    return principalUser;
  }

  /// Looks up student record and verifies parent relationship using parent contact info
  Future<ParentVerificationPreview> lookupParentRelationship({
    required String schoolCode,
    required String studentIdentifier,
    required String parentContact,
  }) async {
    final cleanCode = schoolCode.trim().toUpperCase();
    final cleanId = studentIdentifier.trim();
    final cleanContact = parentContact.trim();

    if (cleanCode.isEmpty || cleanId.isEmpty || cleanContact.isEmpty) {
      throw Exception('Please provide School Code, Student Identifier, and Parent Phone or Email.');
    }

    final school = await verifySchoolCode(cleanCode);
    if (school == null) {
      throw Exception('Invalid or unregistered School Code ($cleanCode).');
    }
    if (school.status == 'suspended' || school.status == 'deactivated') {
      throw Exception('The school is currently inactive or suspended. Please contact administration.');
    }

    // Look up student in roster_students
    QuerySnapshot<Map<String, dynamic>>? rosterSnap;
    try {
      rosterSnap = await _firestore
          .collection('roster_students')
          .where('schoolCode', isEqualTo: cleanCode)
          .where('rollNumber', isEqualTo: cleanId)
          .limit(1)
          .get();

      if (rosterSnap.docs.isEmpty) {
        rosterSnap = await _firestore
            .collection('roster_students')
            .where('schoolCode', isEqualTo: cleanCode)
            .where('admissionNumber', isEqualTo: cleanId)
            .limit(1)
            .get();
      }
    } catch (_) {
      rosterSnap = null;
    }

    if (rosterSnap != null && rosterSnap.docs.isNotEmpty) {
      final doc = rosterSnap.docs.first;
      final student = RosterStudentModel.fromMap(doc.data(), doc.id);
      final rData = doc.data();

      final registeredPhone = (rData['parentPhone'] ?? '').toString().trim();
      final registeredEmail = (rData['parentEmail'] ?? '').toString().trim().toLowerCase();

      // Check if parentContact matches either registered phone or email
      final normInput = cleanContact.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      final normPhone = registeredPhone.replaceAll(RegExp(r'[^0-9]'), '');
      final normEmail = registeredEmail.replaceAll(RegExp(r'[^a-z0-9]'), '');

      bool contactMatches = false;
      if (normPhone.isNotEmpty && (normInput.endsWith(normPhone) || normPhone.endsWith(normInput))) {
        contactMatches = true;
      } else if (normEmail.isNotEmpty && cleanContact.toLowerCase() == registeredEmail) {
        contactMatches = true;
      }

      // If registered contact exists in CSV and doesn't match input
      if (!contactMatches && registeredPhone.isNotEmpty && registeredEmail.isNotEmpty) {
        throw Exception(
          'The provided contact information does not match school records for student $cleanId. Please verify with your school.',
        );
      }

      String masked = '******${cleanContact.length >= 4 ? cleanContact.substring(cleanContact.length - 4) : cleanContact}';

      return ParentVerificationPreview(
        schoolCode: cleanCode,
        schoolName: school.name,
        studentName: student.studentName,
        rollNumber: student.rollNumber,
        admissionNumber: student.admissionNumber,
        classLabel: student.classLabel,
        maskedContact: masked,
        rosterId: doc.id,
        requiresPin: student.verificationPin.isNotEmpty,
      );
    }

    // Demo student fallback for AP-KRI-042
    if ((cleanCode == 'AP-KRI-042' || cleanCode == 'SCH001') &&
        (cleanId == '101' || cleanId == '102' || cleanId == '103')) {
      final names = {'101': 'Ravi Kumar', '102': 'Priya Sharma', '103': 'Ananya Reddy'};
      return ParentVerificationPreview(
        schoolCode: cleanCode,
        schoolName: school.name,
        studentName: names[cleanId] ?? 'Student $cleanId',
        rollNumber: cleanId,
        admissionNumber: 'ADM00$cleanId',
        classLabel: 'Class 8-A',
        maskedContact: '+91 ******${cleanContact.length >= 4 ? cleanContact.substring(cleanContact.length - 4) : '3456'}',
        rosterId: 'roster_std_${cleanCode}_$cleanId',
        requiresPin: false,
      );
    }

    throw Exception(
      'No student record found matching identifier "$cleanId" in school $cleanCode. Please check with your school.',
    );
  }

  /// Generates an identity verification challenge (OTP or PIN verification session)
  Future<IdentityVerificationChallenge> sendIdentityVerification({
    required String schoolCode,
    required String targetType, // 'student' | 'teacher' | 'parent'
    required String rosterId,
    required String contactMethod, // 'sms' | 'email' | 'pin'
  }) async {
    final challengeId = 'CHAL-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(9999)}';
    final expiresAt = DateTime.now().add(const Duration(minutes: 10));
    const otpCode = '123456'; // Deterministic fallback code for dev/test verification

    String maskedRecipient = 'registered contact';
    try {
      final coll = targetType == 'teacher' ? 'roster_teachers' : 'roster_students';
      final doc = await _firestore.collection(coll).doc(rosterId).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (contactMethod == 'sms') {
          final phone = (data['parentPhone'] ?? data['phone'] ?? '').toString();
          if (phone.length >= 4) {
            maskedRecipient = '+91 ******${phone.substring(phone.length - 4)}';
          }
        } else if (contactMethod == 'email') {
          final email = (data['parentEmail'] ?? data['email'] ?? '').toString();
          if (email.contains('@')) {
            final parts = email.split('@');
            final namePart = parts[0];
            final masked = namePart.length > 2 ? '${namePart.substring(0, 2)}***' : '***';
            maskedRecipient = '$masked@${parts[1]}';
          }
        }
      }
    } catch (_) {}

    try {
      await _firestore.collection('verification_challenges').doc(challengeId).set({
        'challengeId': challengeId,
        'schoolCode': schoolCode,
        'targetType': targetType,
        'rosterId': rosterId,
        'channel': contactMethod,
        'code': otpCode,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(expiresAt),
      });
    } catch (_) {}

    return IdentityVerificationChallenge(
      challengeId: challengeId,
      recipientMasked: maskedRecipient,
      channel: contactMethod,
      expiresAt: expiresAt,
    );
  }

  /// Verifies an OTP challenge or PIN
  Future<bool> verifyIdentityChallenge({
    required String challengeId,
    required String code,
    String? pin,
    String? rosterId,
    String? targetType,
  }) async {
    final cleanCode = code.trim();

    // 1. PIN verification against roster record if provided
    if (pin != null && pin.trim().isNotEmpty && rosterId != null && targetType != null) {
      try {
        final coll = targetType == 'teacher' ? 'roster_teachers' : 'roster_students';
        final doc = await _firestore.collection(coll).doc(rosterId).get();
        if (doc.exists && doc.data() != null) {
          final expectedPin = doc.data()!['verificationPin']?.toString();
          if (expectedPin != null && expectedPin.isNotEmpty) {
            return expectedPin == pin.trim();
          }
        }
      } catch (_) {}
    }

    // 2. Fallback for test/demo environments
    if (cleanCode == '123456' || cleanCode == '4821' || cleanCode == '5819') {
      return true;
    }

    // 3. Check Firestore challenge
    try {
      final doc = await _firestore.collection('verification_challenges').doc(challengeId).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final expectedCode = data['code']?.toString();
        final status = data['status']?.toString();
        final expiresAt = (data['expiresAt'] as Timestamp?)?.toDate();

        if (status == 'pending' &&
            (expiresAt == null || expiresAt.isAfter(DateTime.now())) &&
            expectedCode == cleanCode) {
          await _firestore.collection('verification_challenges').doc(challengeId).update({
            'status': 'verified',
            'verifiedAt': FieldValue.serverTimestamp(),
          });
          return true;
        }
      }
    } catch (_) {}

    return false;
  }

  /// Verifies that a student record exists in the school roster and is eligible for registration
  Future<StudentVerificationPreview> lookupStudentRecord(
    String schoolCode,
    String rollOrAdmission,
  ) async {
    final cleanCode = schoolCode.trim().toUpperCase();
    final cleanIdentifier = rollOrAdmission.trim();

    if (cleanCode.isEmpty || cleanIdentifier.isEmpty) {
      throw Exception('Please provide both School Code and Roll Number / Admission Number.');
    }

    final school = await verifySchoolCode(cleanCode);
    if (school == null) {
      throw Exception('Invalid or unregistered School Code ($cleanCode).');
    }
    if (school.status == 'suspended' || school.status == 'deactivated') {
      throw Exception('The school is currently inactive or suspended. Please contact your school administrator.');
    }

    // 1. Check in roster_students collection
    QuerySnapshot<Map<String, dynamic>>? rosterSnap;
    try {
      rosterSnap = await _firestore
          .collection('roster_students')
          .where('schoolCode', isEqualTo: cleanCode)
          .where('rollNumber', isEqualTo: cleanIdentifier)
          .limit(1)
          .get();

      if (rosterSnap.docs.isEmpty) {
        // Try admission number
        rosterSnap = await _firestore
            .collection('roster_students')
            .where('schoolCode', isEqualTo: cleanCode)
            .where('admissionNumber', isEqualTo: cleanIdentifier)
            .limit(1)
            .get();
      }
    } catch (_) {
      rosterSnap = null;
    }

    if (rosterSnap != null && rosterSnap.docs.isNotEmpty) {
      final doc = rosterSnap.docs.first;
      final student = RosterStudentModel.fromMap(doc.data(), doc.id);

      if (student.status == 'active') {
        throw Exception(
          'This student record is already registered. Please sign in with your credentials or contact school administration.',
        );
      }
      if (student.status == 'suspended' || student.status == 'deactivated') {
        throw Exception(
          'This student record has been suspended or deactivated. Please contact your school administrator.',
        );
      }

      return StudentVerificationPreview(
        studentName: student.studentName,
        classLabel: student.classLabel,
        schoolName: school.name,
        schoolCode: cleanCode,
        rollNumber: student.rollNumber,
        admissionNumber: student.admissionNumber,
        rosterId: doc.id,
        requiresPin: student.verificationPin.isNotEmpty,
      );
    }

    // 2. Check in users collection for pre-provisioned or demo student
    try {
      final userSnap = await _firestore
          .collection('users')
          .where('schoolCode', isEqualTo: cleanCode)
          .where('rollNumber', isEqualTo: cleanIdentifier)
          .limit(1)
          .get();

      if (userSnap.docs.isNotEmpty) {
        final user = UserModel.fromMap(userSnap.docs.first.data());
        if (user.isActive && user.status == 'active') {
          throw Exception(
            'This student record is already registered. Please sign in with your credentials.',
          );
        }

        return StudentVerificationPreview(
          studentName: user.name,
          classLabel: 'Class ${user.grade ?? "8"}-${user.section ?? "A"}',
          schoolName: school.name,
          schoolCode: cleanCode,
          rollNumber: user.rollNumber ?? cleanIdentifier,
          admissionNumber: user.admissionNumber ?? cleanIdentifier,
          rosterId: userSnap.docs.first.id,
          requiresPin: false,
        );
      }
    } catch (e) {
      if (e is Exception && e.toString().contains('already registered')) rethrow;
    }

    // Known demo student fallback for test ease
    if ((cleanCode == 'AP-KRI-042' || cleanCode == 'SCH001') &&
        (cleanIdentifier == '101' || cleanIdentifier == '102' || cleanIdentifier == '103')) {
      final names = {'101': 'Ravi Kumar', '102': 'Priya Sharma', '103': 'Ananya Reddy'};
      return StudentVerificationPreview(
        studentName: names[cleanIdentifier] ?? 'Student $cleanIdentifier',
        classLabel: 'Class 8-A',
        schoolName: school.name,
        schoolCode: cleanCode,
        rollNumber: cleanIdentifier,
        admissionNumber: 'ADM00$cleanIdentifier',
        rosterId: 'roster_std_${cleanCode}_$cleanIdentifier',
        requiresPin: false,
      );
    }

    throw Exception(
      'No student record found matching identifier "$cleanIdentifier" in school $cleanCode. Please verify details with your school.',
    );
  }

  /// Verifies that a teacher record exists in the school roster
  Future<TeacherVerificationPreview> lookupTeacherRecord(
    String schoolCode,
    String employeeId,
  ) async {
    final cleanCode = schoolCode.trim().toUpperCase();
    final cleanEmp = employeeId.trim();

    if (cleanCode.isEmpty || cleanEmp.isEmpty) {
      throw Exception('Please provide both School Code and Employee ID.');
    }

    final school = await verifySchoolCode(cleanCode);
    if (school == null) {
      throw Exception('Invalid or unregistered School Code ($cleanCode).');
    }
    if (school.status == 'suspended' || school.status == 'deactivated') {
      throw Exception('The school is currently inactive or suspended. Please contact your school administrator.');
    }

    // 1. Check in roster_teachers
    try {
      final rosterSnap = await _firestore
          .collection('roster_teachers')
          .where('schoolCode', isEqualTo: cleanCode)
          .where('employeeId', isEqualTo: cleanEmp)
          .limit(1)
          .get();

      if (rosterSnap.docs.isNotEmpty) {
        final doc = rosterSnap.docs.first;
        final teacher = RosterTeacherModel.fromMap(doc.data(), doc.id);

        if (teacher.status == 'active') {
          throw Exception(
            'This faculty account is already registered. Please sign in with your email and password.',
          );
        }
        if (teacher.status == 'suspended' || teacher.status == 'deactivated') {
          throw Exception('This faculty account has been suspended or deactivated.');
        }

        return TeacherVerificationPreview(
          teacherName: teacher.teacherName,
          employeeId: teacher.employeeId,
          email: teacher.email,
          assignedSubjects: teacher.assignedSubjects,
          assignedClasses: teacher.assignedClasses,
          schoolName: school.name,
          schoolCode: cleanCode,
          rosterId: doc.id,
        );
      }
    } catch (e) {
      if (e is Exception && (e.toString().contains('already registered') || e.toString().contains('suspended'))) {
        rethrow;
      }
    }

    // 2. Check in users collection for pre-provisioned teacher
    try {
      final userSnap = await _firestore
          .collection('users')
          .where('schoolCode', isEqualTo: cleanCode)
          .where('employeeId', isEqualTo: cleanEmp)
          .limit(1)
          .get();

      if (userSnap.docs.isNotEmpty) {
        final user = UserModel.fromMap(userSnap.docs.first.data());
        if (user.isActive && user.status == 'active') {
          throw Exception('This faculty account is already registered. Please log in.');
        }
        return TeacherVerificationPreview(
          teacherName: user.name,
          employeeId: user.employeeId ?? cleanEmp,
          email: user.email,
          assignedSubjects: user.assignedSubjects,
          assignedClasses: user.classIds ?? ['Class 8-A'],
          schoolName: school.name,
          schoolCode: cleanCode,
          rosterId: userSnap.docs.first.id,
        );
      }
    } catch (e) {
      if (e is Exception && e.toString().contains('already registered')) rethrow;
    }

    // Known demo teacher fallback
    if ((cleanCode == 'AP-KRI-042' || cleanCode == 'SCH001') &&
        (cleanEmp == 'EMP014' || cleanEmp == 'EMP001')) {
      return TeacherVerificationPreview(
        teacherName: 'Dr. Sarah Jenkins',
        employeeId: cleanEmp,
        email: 'teacher@edustreak.com',
        assignedSubjects: const ['Mathematics', 'Physics'],
        assignedClasses: const ['Class 8-A', 'Class 9-B'],
        schoolName: school.name,
        schoolCode: cleanCode,
        rosterId: 'roster_tch_${cleanCode}_$cleanEmp',
      );
    }

    throw Exception(
      'No faculty record found for Employee ID "$cleanEmp" in school $cleanCode. Please contact your Principal.',
    );
  }

  /// Atomically claims an eligible student roster record and provisions the authenticated student account
  Future<UserModel> claimStudentAccount({
    required String schoolCode,
    required String identifier,
    required String password,
    String? pin,
    String? customEmail,
  }) async {
    final cleanCode = schoolCode.trim().toUpperCase();
    final cleanId = identifier.trim();

    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters.');
    }

    final preview = await lookupStudentRecord(cleanCode, cleanId);

    // Guard against duplicate claims
    try {
      final rosterCheck = await _firestore.collection('roster_students').doc(preview.rosterId).get();
      if (rosterCheck.exists && rosterCheck.data() != null) {
        final rData = rosterCheck.data()!;
        if (rData['status'] == 'active' || rData['claimedByUid'] != null) {
          throw Exception('This student record has already been registered and claimed. Please sign in with your credentials.');
        }
      }
    } catch (e) {
      if (e is Exception && e.toString().contains('already been registered and claimed')) rethrow;
    }

    // Optional PIN verification check if roster student has a PIN configured
    if (preview.requiresPin && pin != null && pin.trim().isNotEmpty) {
      final rosterDoc = await _firestore.collection('roster_students').doc(preview.rosterId).get();
      if (rosterDoc.exists) {
        final expectedPin = rosterDoc.data()?['verificationPin']?.toString();
        if (expectedPin != null && expectedPin.isNotEmpty && expectedPin != pin.trim()) {
          throw Exception('Incorrect registration PIN. Please verify with your school.');
        }
      }
    }

    // Determine deterministic student authentication email
    final cleanNormCode = cleanCode.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final cleanNormRoll = preview.rollNumber.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

    String authEmail;
    if (customEmail != null && customEmail.trim().contains('@')) {
      authEmail = customEmail.trim();
    } else if (cleanNormRoll == '101') {
      authEmail = 'student1@edustreak.com';
    } else if (cleanNormRoll == '102') {
      authEmail = 'student2@edustreak.com';
    } else if (cleanNormRoll == '103') {
      authEmail = 'student3@edustreak.com';
    } else {
      authEmail = 'std_${cleanNormCode}_${cleanNormRoll}@student.edustreak.internal';
    }

    // 1. Create or bind Firebase Auth account
    UserCredential? credential;
    try {
      credential = await _auth.createUserWithEmailAndPassword(
        email: authEmail,
        password: password,
      );
    } on FirebaseAuthException catch (authErr) {
      if (authErr.code == 'email-already-in-use') {
        try {
          credential = await _auth.signInWithEmailAndPassword(
            email: authEmail,
            password: password,
          );
        } catch (_) {
          throw Exception('An account with these credentials already exists. Please sign in or reset password.');
        }
      } else {
        throw Exception(authErr.message ?? 'Registration authentication failed.');
      }
    }

    final authUser = credential.user;
    if (authUser == null) {
      throw Exception('Failed to create authenticated student session.');
    }

    final authUid = authUser.uid;

    // 2. Fetch full verified roster data to assign ONLY trusted institutional attributes
    final school = await verifySchoolCode(cleanCode);
    final schoolId = school?.id ?? 'sch_ap_001';

    String grade = '8';
    String section = 'A';
    String classId = 'Class 8-A';
    String academicYear = '2026-2027';

    try {
      final rDoc = await _firestore.collection('roster_students').doc(preview.rosterId).get();
      if (rDoc.exists && rDoc.data() != null) {
        final rData = rDoc.data()!;
        grade = rData['grade'] ?? grade;
        section = rData['section'] ?? section;
        classId = rData['classId'] ?? classId;
        academicYear = rData['academicYear'] ?? academicYear;
      }
    } catch (_) {}

    // 3. Atomically write/update user document and mark roster record active
    final userModel = UserModel(
      id: authUid,
      name: preview.studentName,
      email: authEmail,
      role: 'student',
      schoolId: schoolId,
      schoolCode: cleanCode,
      rollNumber: preview.rollNumber,
      admissionNumber: preview.admissionNumber,
      classId: classId,
      grade: grade,
      section: section,
      academicYear: academicYear,
      isActive: true,
      status: 'active',
      streak: 0,
      streakCount: 0,
      highestStreak: 0,
      xp: 0,
      level: 1,
    );

    final batch = _firestore.batch();
    batch.set(_firestore.collection('users').doc(authUid), userModel.toMap(), SetOptions(merge: true));

    // Update roster record to active and claimed
    final rosterRef = _firestore.collection('roster_students').doc(preview.rosterId);
    batch.set(
      rosterRef,
      {
        'status': 'active',
        'claimedByUid': authUid,
        'claimedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await batch.commit();

    // 4. Audit log registration
    _auditService.logAction(
      action: 'STUDENT_SCHOOL_REGISTERED',
      targetType: 'user',
      targetId: authUid,
      details: {
        'schoolCode': cleanCode,
        'schoolId': schoolId,
        'rollNumber': preview.rollNumber,
        'studentName': preview.studentName,
        'email': authEmail,
      },
    );

    return userModel;
  }

  /// Atomically claims an eligible faculty roster record
  Future<UserModel> claimTeacherAccount({
    required String schoolCode,
    required String employeeId,
    required String password,
    String? pin,
  }) async {
    final cleanCode = schoolCode.trim().toUpperCase();
    final cleanEmp = employeeId.trim();

    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters.');
    }

    final preview = await lookupTeacherRecord(cleanCode, cleanEmp);

    // Guard against duplicate claims
    try {
      final rosterCheck = await _firestore.collection('roster_teachers').doc(preview.rosterId).get();
      if (rosterCheck.exists && rosterCheck.data() != null) {
        final rData = rosterCheck.data()!;
        if (rData['status'] == 'active' || rData['claimedByUid'] != null) {
          throw Exception('This faculty record has already been registered and claimed. Please sign in with your credentials.');
        }
      }
    } catch (e) {
      if (e is Exception && e.toString().contains('already been registered and claimed')) rethrow;
    }

    // Optional PIN verification
    if (pin != null && pin.trim().isNotEmpty) {
      final rosterDoc = await _firestore.collection('roster_teachers').doc(preview.rosterId).get();
      if (rosterDoc.exists) {
        final expectedPin = rosterDoc.data()?['verificationPin']?.toString();
        if (expectedPin != null && expectedPin.isNotEmpty && expectedPin != pin.trim()) {
          throw Exception('Incorrect faculty verification PIN.');
        }
      }
    }

    final authEmail = preview.email;

    // 1. Create or bind Firebase Auth account
    UserCredential? credential;
    try {
      credential = await _auth.createUserWithEmailAndPassword(
        email: authEmail,
        password: password,
      );
    } on FirebaseAuthException catch (authErr) {
      if (authErr.code == 'email-already-in-use') {
        try {
          credential = await _auth.signInWithEmailAndPassword(
            email: authEmail,
            password: password,
          );
        } catch (_) {
          throw Exception('This faculty account is already created. Please sign in or reset password.');
        }
      } else {
        throw Exception(authErr.message ?? 'Faculty registration failed.');
      }
    }

    final authUser = credential.user;
    if (authUser == null) {
      throw Exception('Failed to create faculty authentication session.');
    }

    final authUid = authUser.uid;
    final school = await verifySchoolCode(cleanCode);
    final schoolId = school?.id ?? 'sch_ap_001';

    // 2. Provision UserModel with verified assigned classes and subjects
    final userModel = UserModel(
      id: authUid,
      name: preview.teacherName,
      email: authEmail,
      role: 'teacher',
      schoolId: schoolId,
      schoolCode: cleanCode,
      employeeId: preview.employeeId,
      assignedSubjects: preview.assignedSubjects,
      classIds: preview.assignedClasses,
      isActive: true,
      status: 'active',
    );

    final batch = _firestore.batch();
    batch.set(_firestore.collection('users').doc(authUid), userModel.toMap(), SetOptions(merge: true));

    final rosterRef = _firestore.collection('roster_teachers').doc(preview.rosterId);
    batch.set(
      rosterRef,
      {
        'status': 'active',
        'claimedByUid': authUid,
        'claimedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await batch.commit();

    _auditService.logAction(
      action: 'TEACHER_SCHOOL_REGISTERED',
      targetType: 'user',
      targetId: authUid,
      details: {
        'schoolCode': cleanCode,
        'employeeId': preview.employeeId,
        'teacherName': preview.teacherName,
        'email': authEmail,
      },
    );

    return userModel;
  }

  /// Registers a parent and links to their verified student
  Future<UserModel> registerParentAndLinkChild({
    required String parentName,
    required String email,
    required String password,
    required String schoolCode,
    required String studentIdentifier,
    required String verificationPin,
  }) async {
    final cleanEmail = email.trim();
    final cleanCode = schoolCode.trim().toUpperCase();
    final cleanId = studentIdentifier.trim();
    final cleanPin = verificationPin.trim();

    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      throw Exception('Please enter a valid email address.');
    }
    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters.');
    }
    if (cleanPin.isEmpty) {
      throw Exception('Please enter the Student Verification PIN.');
    }

    // Verify school
    final school = await verifySchoolCode(cleanCode);
    if (school == null) {
      throw Exception('Invalid School Code.');
    }
    if (school.status == 'suspended' || school.status == 'deactivated') {
      throw Exception('This school is currently inactive or suspended. Please contact school administration.');
    }

    // Look up student record
    final studentPreview = await lookupStudentRecord(cleanCode, cleanId);

    // Verify PIN against student roster
    try {
      final rDoc = await _firestore.collection('roster_students').doc(studentPreview.rosterId).get();
      if (rDoc.exists) {
        final expectedPin = rDoc.data()?['verificationPin']?.toString();
        if (expectedPin != null && expectedPin.isNotEmpty && expectedPin != cleanPin) {
          throw Exception('Invalid Student Verification PIN. Please check the PIN provided by the school.');
        }
      }
    } catch (e) {
      if (e is Exception && e.toString().contains('PIN')) rethrow;
    }

    // Create Firebase Auth user for parent
    UserCredential credential;
    try {
      credential = await _auth.createUserWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );
    } on FirebaseAuthException catch (authErr) {
      if (authErr.code == 'email-already-in-use') {
        try {
          credential = await _auth.signInWithEmailAndPassword(
            email: cleanEmail,
            password: password,
          );
        } catch (_) {
          throw Exception('An account with this email already exists.');
        }
      } else {
        throw Exception(authErr.message ?? 'Parent registration failed.');
      }
    }

    final authUser = credential.user;
    if (authUser == null) throw Exception('Parent authentication failed.');

    final parentUid = authUser.uid;
    final studentId = studentPreview.rosterId;

    final parentModel = UserModel(
      id: parentUid,
      name: parentName.trim(),
      email: cleanEmail,
      role: 'parent',
      schoolId: school.id,
      schoolCode: cleanCode,
      childId: studentId,
      childIds: [studentId],
      isActive: true,
      status: 'active',
    );

    await _firestore.collection('users').doc(parentUid).set(
      parentModel.toMap(),
      SetOptions(merge: true),
    );

    _auditService.logAction(
      action: 'PARENT_REGISTERED_AND_LINKED',
      targetType: 'user',
      targetId: parentUid,
      details: {
        'schoolCode': cleanCode,
        'childRosterId': studentId,
        'studentName': studentPreview.studentName,
        'parentEmail': cleanEmail,
      },
    );

    return parentModel;
  }

  /// Updates account registration/activation status (by Principal or Central Admin)
  Future<void> updateAccountStatus({
    required String entityId,
    required String newStatus, // 'active', 'suspended', 'deactivated', 'not_registered'
    required String role, // 'student' or 'teacher'
    required String schoolId,
    String? reason,
  }) async {
    final isActive = newStatus == 'active';

    final batch = _firestore.batch();
    final userRef = _firestore.collection('users').doc(entityId);
    batch.update(userRef, {
      'status': newStatus,
      'isActive': isActive,
    });

    final rosterCollection = role == 'student' ? 'roster_students' : 'roster_teachers';
    final rosterRef = _firestore.collection(rosterCollection).doc(entityId);
    batch.update(rosterRef, {
      'status': newStatus,
    });

    try {
      await batch.commit();
    } catch (_) {
      // If one of the docs doesn't exist, update user directly
      await userRef.update({
        'status': newStatus,
        'isActive': isActive,
      });
    }

    _auditService.logAction(
      action: 'ACCOUNT_STATUS_UPDATED',
      targetType: 'user',
      targetId: entityId,
      details: {
        'newStatus': newStatus,
        'role': role,
        'schoolId': schoolId,
        'reason': reason ?? 'Status changed by school administrator',
      },
    );
  }
}
