import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/school_model.dart';
import '../models/user_model.dart';
import 'audit_service.dart';
import 'email_invitation_service.dart';

class SchoolService {
  final FirebaseFirestore? _customFirestore;
  FirebaseFirestore get _firestore => _customFirestore ?? FirebaseFirestore.instance;
  final AuditService _auditService = AuditService();
  final EmailInvitationService _emailInvitationService = EmailInvitationService();

  SchoolService({FirebaseFirestore? firestore}) : _customFirestore = firestore;

  CollectionReference<Map<String, dynamic>> get _schoolsRef =>
      _firestore.collection('schools');

  /// Stream of all registered schools
  Stream<List<SchoolModel>> getSchoolsStream({
    String? categoryFilter,
    String? statusFilter,
    String? districtFilter,
    String? searchQuery,
  }) {
    try {
      Query<Map<String, dynamic>> query = _schoolsRef.orderBy('name');

      if (categoryFilter != null && categoryFilter.isNotEmpty && categoryFilter != 'All') {
        // Map display to type name
        String typeVal = categoryFilter.toLowerCase();
        if (typeVal.contains('gov')) {
          query = query.where('type', isEqualTo: 'government');
        } else if (typeVal.contains('pvt') || typeVal.contains('private')) {
          query = query.where('type', isEqualTo: 'privateSchool');
        } else if (typeVal.contains('cbse')) {
          query = query.where('type', isEqualTo: 'cbse');
        }
      }

      if (statusFilter != null && statusFilter.isNotEmpty && statusFilter != 'All') {
        query = query.where('status', isEqualTo: statusFilter.toLowerCase());
      }

      if (districtFilter != null && districtFilter.isNotEmpty && districtFilter != 'All') {
        query = query.where('district', isEqualTo: districtFilter);
      }

      return query.snapshots().map((snapshot) {
        var list = snapshot.docs
            .map((doc) => SchoolModel.fromMap(doc.data(), doc.id))
            .toList();

        if (searchQuery != null && searchQuery.trim().isNotEmpty) {
          final q = searchQuery.trim().toLowerCase();
          list = list.where((s) =>
              s.name.toLowerCase().contains(q) ||
              s.code.toLowerCase().contains(q) ||
              s.district.toLowerCase().contains(q) ||
              s.mandal.toLowerCase().contains(q)).toList();
        }

        return list;
      });
    } catch (_) {
      return Stream.value(<SchoolModel>[]);
    }
  }

  /// Get school by ID
  Future<SchoolModel?> getSchool(String schoolId) async {
    try {
      final doc = await _schoolsRef.doc(schoolId).get();
      if (doc.exists && doc.data() != null) {
        return SchoolModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Resolve school by unique School Code (e.g. AP-KRI-042)
  Future<SchoolModel?> getSchoolByCode(String code) async {
    try {
      final query = await _schoolsRef
          .where('code', isEqualTo: code.trim().toUpperCase())
          .limit(1)
          .get();
      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        return SchoolModel.fromMap(doc.data(), doc.id);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Create a new school with unique code validation and audit logging
  Future<SchoolModel> createSchool({
    required String name,
    required String code,
    required SchoolType type,
    required String district,
    String state = 'Andhra Pradesh',
    String address = '',
    String mandal = '',
    String pincode = '',
    String contactPerson = '',
    String contactPhone = '',
    String contactEmail = '',
    String affiliationNumber = '',
    String academicYear = '2024-2025',
    List<String>? supportedClasses,
    required String curriculumTemplateId,
    int initialStudents = 0,
    int initialTeachers = 0,
  }) async {
    final normCode = code.trim().toUpperCase();

    // Verify code uniqueness
    final existing = await getSchoolByCode(normCode);
    if (existing != null) {
      throw Exception('School Code "$normCode" is already registered to ${existing.name}.');
    }

    final docRef = _schoolsRef.doc();
    final school = SchoolModel(
      id: docRef.id,
      name: name.trim(),
      code: normCode,
      type: type,
      status: 'active',
      address: address.trim(),
      mandal: mandal.trim(),
      district: district.trim(),
      state: state.trim(),
      pincode: pincode.trim(),
      contactPerson: contactPerson.trim(),
      contactPhone: contactPhone.trim(),
      contactEmail: contactEmail.trim(),
      affiliationNumber: affiliationNumber.trim(),
      academicYear: academicYear.trim(),
      supportedClasses: supportedClasses ?? const [
        'Class 6',
        'Class 7',
        'Class 8',
        'Class 9',
        'Class 10',
      ],
      totalStudents: initialStudents,
      totalTeachers: initialTeachers,
      curriculumTemplateId: curriculumTemplateId,
      establishedDate: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await docRef.set(school.toMap());

    // Audit log
    await _auditService.logAction(
      action: 'SCHOOL_CREATED',
      targetType: 'school',
      targetId: school.id,
      details: {
        'code': school.code,
        'name': school.name,
        'type': school.type.name,
        'district': school.district,
      },
    );

    return school;
  }

  /// Update an existing school's operational metadata
  Future<void> updateSchool(SchoolModel school) async {
    await _schoolsRef.doc(school.id).set(school.toMap(), SetOptions(merge: true));

    await _auditService.logAction(
      action: 'SCHOOL_UPDATED',
      targetType: 'school',
      targetId: school.id,
      details: {
        'name': school.name,
        'status': school.status,
        'academicYear': school.academicYear,
      },
    );
  }

  /// Update school operational status (active, suspended, archived, deactivated)
  Future<void> updateSchoolStatus(String schoolId, String status, {String reason = ''}) async {
    await _schoolsRef.doc(schoolId).update({
      'status': status,
      'isActive': status == 'active',
      'updatedAt': DateTime.now().toIso8601String(),
    });

    await _auditService.logAction(
      action: 'SCHOOL_STATUS_CHANGED',
      targetType: 'school',
      targetId: schoolId,
      details: {
        'newStatus': status,
        'reason': reason,
      },
    );
  }

  /// Generates a validated unique school code based on school type and district
  Future<String> generateUniqueSchoolCode({
    required SchoolType type,
    required String district,
  }) async {
    String prefix;
    switch (type) {
      case SchoolType.government:
        prefix = 'AP';
        break;
      case SchoolType.cbse:
        prefix = 'CBSE';
        break;
      case SchoolType.privateSchool:
        prefix = 'PVT';
        break;
    }

    final distCode = district.replaceAll(RegExp(r'[^a-zA-Z]'), '').toUpperCase();
    final distTag = distCode.length >= 3 ? distCode.substring(0, 3) : 'GEN';

    final rng = Random();
    for (int attempts = 0; attempts < 50; attempts++) {
      final numSuffix = (rng.nextInt(900) + 100).toString(); // 100-999
      final candidate = '$prefix-$distTag-$numSuffix';
      final existing = await getSchoolByCode(candidate);
      if (existing == null) {
        return candidate;
      }
    }

    return '$prefix-$distTag-${DateTime.now().millisecondsSinceEpoch % 10000}';
  }

  /// Assign a Principal to an authorized school with bidirectional linking and audit trail
  Future<void> assignPrincipalToSchool({
    required String schoolId,
    required String principalUid,
    required String principalName,
    required String principalEmail,
  }) async {
    final batch = _firestore.batch();

    // 1. Update school document
    final schoolRef = _schoolsRef.doc(schoolId);
    batch.update(schoolRef, {
      'principalId': principalUid,
      'principalName': principalName.trim(),
      'principalEmail': principalEmail.trim(),
      'updatedAt': DateTime.now().toIso8601String(),
    });

    // 2. Fetch school code for user context
    final schoolSnap = await schoolRef.get();
    final schoolCode = schoolSnap.data()?['code'] ?? '';

    // 3. Update user document
    final userRef = _firestore.collection('users').doc(principalUid);
    batch.update(userRef, {
      'schoolId': schoolId,
      'schoolCode': schoolCode,
      'role': 'principal',
      'status': 'active',
      'isActive': true,
      'updatedAt': DateTime.now().toIso8601String(),
    });

    await batch.commit();

    await _auditService.logAction(
      action: 'PRINCIPAL_ASSIGNED',
      targetType: 'school',
      targetId: schoolId,
      schoolId: schoolId,
      schoolCode: schoolCode,
      details: {
        'principalUid': principalUid,
        'principalName': principalName,
        'principalEmail': principalEmail,
      },
    );
  }

  /// Securely transfer school leadership from existing Principal to a new Principal
  Future<void> transferSchoolPrincipal({
    required String schoolId,
    required String newPrincipalUid,
    required String newPrincipalName,
    required String newPrincipalEmail,
    required String reason,
  }) async {
    final school = await getSchool(schoolId);
    if (school == null) throw Exception('School not found.');

    final formerPrincipalId = school.principalId;
    final formerPrincipalName = school.principalName;

    final batch = _firestore.batch();

    // Deactivate former principal's administrative binding if present
    if (formerPrincipalId != null && formerPrincipalId.isNotEmpty) {
      final formerUserRef = _firestore.collection('users').doc(formerPrincipalId);
      batch.update(formerUserRef, {
        'status': 'deactivated',
        'isActive': false,
        'previousSchoolId': schoolId,
        'transferredAt': DateTime.now().toIso8601String(),
      });
    }

    // Bind new principal to school
    final schoolRef = _schoolsRef.doc(schoolId);
    batch.update(schoolRef, {
      'principalId': newPrincipalUid,
      'principalName': newPrincipalName.trim(),
      'principalEmail': newPrincipalEmail.trim(),
      'updatedAt': DateTime.now().toIso8601String(),
    });

    // Update new principal user record
    final newUserRef = _firestore.collection('users').doc(newPrincipalUid);
    batch.update(newUserRef, {
      'schoolId': schoolId,
      'schoolCode': school.code,
      'role': 'principal',
      'status': 'active',
      'isActive': true,
      'updatedAt': DateTime.now().toIso8601String(),
    });

    await batch.commit();

    await _auditService.logAction(
      action: 'PRINCIPAL_TRANSFERRED',
      targetType: 'school',
      targetId: schoolId,
      schoolId: schoolId,
      schoolCode: school.code,
      reason: reason,
      details: {
        'formerPrincipalId': formerPrincipalId,
        'formerPrincipalName': formerPrincipalName,
        'newPrincipalUid': newPrincipalUid,
        'newPrincipalName': newPrincipalName,
        'newPrincipalEmail': newPrincipalEmail,
      },
    );
  }

  /// Approve a school registration request and activate the institution
  Future<void> approveSchoolRegistration(String schoolId) async {
    await updateSchoolStatus(schoolId, 'active', reason: 'Central Admin approval');
    await _auditService.logAction(
      action: 'SCHOOL_REGISTRATION_APPROVED',
      targetType: 'school',
      targetId: schoolId,
      schoolId: schoolId,
      details: {'status': 'active'},
    );
  }

  /// Reject a school registration application with mandatory reason
  Future<void> rejectSchoolRegistration(String schoolId, String reason) async {
    await _schoolsRef.doc(schoolId).update({
      'status': 'deactivated',
      'isActive': false,
      'rejectionReason': reason,
      'updatedAt': DateTime.now().toIso8601String(),
    });

    await _auditService.logAction(
      action: 'SCHOOL_REGISTRATION_REJECTED',
      targetType: 'school',
      targetId: schoolId,
      schoolId: schoolId,
      reason: reason,
      details: {'status': 'deactivated', 'reason': reason},
    );
  }

  /// Stream of all registered and invited Principals across all schools
  Stream<List<UserModel>> getAllPrincipalsStream({String? searchQuery, String? statusFilter}) {
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection('users')
          .where('role', isEqualTo: 'principal');

      return query.snapshots().map((snapshot) {
        var list = snapshot.docs.map((doc) {
          return UserModel.fromMap(
            Map<String, dynamic>.from(doc.data())..['id'] = doc.id,
          );
        }).toList();

        if (searchQuery != null && searchQuery.trim().isNotEmpty) {
          final q = searchQuery.trim().toLowerCase();
          list = list.where((u) =>
              u.name.toLowerCase().contains(q) ||
              u.email.toLowerCase().contains(q) ||
              (u.schoolCode ?? '').toLowerCase().contains(q)).toList();
        }

        if (statusFilter != null && statusFilter.isNotEmpty && statusFilter != 'All') {
          final sf = statusFilter.toLowerCase();
          list = list.where((u) => u.status.toLowerCase() == sf).toList();
        }

        return list;
      });
    } catch (_) {
      return Stream.value(<UserModel>[]);
    }
  }

  /// Create and invite a new Principal account bound to an authorized school with real email dispatch
  Future<UserModel> createAndInvitePrincipal({
    required String name,
    required String email,
    required String schoolId,
    required String schoolCode,
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    // 1. Check if user email already exists and is already an active account
    final existingUserSnap = await _firestore
        .collection('users')
        .where('email', isEqualTo: cleanEmail)
        .limit(1)
        .get();

    String principalUid;
    if (existingUserSnap.docs.isNotEmpty) {
      final existingDoc = existingUserSnap.docs.first;
      final existingData = existingDoc.data();
      if (existingData['status'] == 'active' && existingData['isActive'] == true) {
        throw Exception('An active account with email $cleanEmail already exists.');
      }
      principalUid = existingDoc.id;
    } else {
      principalUid = _firestore.collection('users').doc().id;
    }

    // 2. Prevent duplicate pending invitations for the same email
    final existingInviteSnap = await _firestore
        .collection('invitations')
        .where('principalEmail', isEqualTo: cleanEmail)
        .where('status', whereIn: ['pending', 'sent', 'sending'])
        .limit(1)
        .get();

    if (existingInviteSnap.docs.isNotEmpty) {
      final pendingDoc = existingInviteSnap.docs.first;
      final code = pendingDoc.data()['invitationCode']?.toString() ?? pendingDoc.id;
      throw Exception('An active invitation ($code) has already been dispatched to $cleanEmail. You can use Resend Invitation instead.');
    }

    // 3. Generate codes and cryptographically secure token
    final normCode = schoolCode.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    final inviteCode = 'INV-PRIN-$normCode-${(1000 + Random().nextInt(9000))}';
    final inviteToken = _emailInvitationService.generateSecureToken();
    final acceptanceUrl = _emailInvitationService.generateAcceptanceUrl(inviteCode, inviteToken);
    final expiresAt = DateTime.now().add(const Duration(days: 7));

    final principalUser = UserModel(
      id: principalUid,
      name: name.trim(),
      email: cleanEmail,
      role: 'principal',
      schoolId: schoolId,
      schoolCode: schoolCode,
      status: 'invited',
      isActive: true,
      academicYear: '2026-2027',
    );

    final batch = _firestore.batch();
    final userRef = _firestore.collection('users').doc(principalUid);
    final userMap = principalUser.toMap();
    userMap['invitationCode'] = inviteCode;
    batch.set(userRef, userMap, SetOptions(merge: true));

    final invitationRef = _firestore.collection('invitations').doc(inviteCode);
    batch.set(invitationRef, {
      'invitationCode': inviteCode,
      'invitationToken': inviteToken,
      'acceptanceUrl': acceptanceUrl,
      'principalUid': principalUid,
      'principalName': name.trim(),
      'principalEmail': cleanEmail,
      'schoolId': schoolId,
      'schoolCode': schoolCode,
      'role': 'principal',
      'status': 'sending',
      'emailDeliveryStatus': 'sending',
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(expiresAt),
    });

    final schoolRef = _schoolsRef.doc(schoolId);
    batch.update(schoolRef, {
      'principalId': principalUid,
      'principalName': name.trim(),
      'principalEmail': cleanEmail,
      'updatedAt': DateTime.now().toIso8601String(),
    });

    await batch.commit();

    // 4. Fetch school name for email template
    String schoolName = 'Assigned School';
    try {
      final schoolSnap = await _schoolsRef.doc(schoolId).get();
      if (schoolSnap.exists && schoolSnap.data() != null) {
        schoolName = schoolSnap.data()!['name']?.toString() ?? schoolName;
      }
    } catch (_) {}

    // 5. Dispatch email via EmailInvitationService
    await _emailInvitationService.sendPrincipalInvitationEmail(
      principalEmail: cleanEmail,
      principalName: name.trim(),
      schoolName: schoolName,
      schoolCode: schoolCode,
      invitationCode: inviteCode,
      invitationToken: inviteToken,
      acceptanceUrl: acceptanceUrl,
      expiresAt: expiresAt,
    );

    await _auditService.logAction(
      action: 'PRINCIPAL_INVITED',
      targetType: 'user',
      targetId: principalUid,
      schoolId: schoolId,
      schoolCode: schoolCode,
      details: {
        'principalName': name.trim(),
        'email': cleanEmail,
        'status': 'invited',
        'invitationCode': inviteCode,
      },
    );

    return principalUser;
  }

  /// Resends an invitation email to a Principal
  Future<EmailDispatchResult> resendPrincipalInvitation(UserModel principal) async {
    final cleanEmail = principal.email.trim().toLowerCase();

    // Look up invitation document
    QuerySnapshot<Map<String, dynamic>> inviteSnap = await _firestore
        .collection('invitations')
        .where('principalEmail', isEqualTo: cleanEmail)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    String inviteCode = '';
    String? existingToken;
    String schoolCode = principal.schoolCode ?? 'AP-KRI-SVVM';
    String schoolName = 'Assigned School';

    if (inviteSnap.docs.isNotEmpty) {
      final data = inviteSnap.docs.first.data();
      inviteCode = data['invitationCode']?.toString() ?? inviteSnap.docs.first.id;
      existingToken = data['invitationToken']?.toString();
      schoolCode = data['schoolCode']?.toString() ?? schoolCode;
    } else {
      final normCode = schoolCode.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
      inviteCode = 'INV-PRIN-$normCode-${(1000 + Random().nextInt(9000))}';
    }

    if (principal.schoolId != null && principal.schoolId!.isNotEmpty) {
      try {
        final sSnap = await _schoolsRef.doc(principal.schoolId!).get();
        if (sSnap.exists && sSnap.data() != null) {
          schoolName = sSnap.data()!['name']?.toString() ?? schoolName;
        }
      } catch (_) {}
    }

    final result = await _emailInvitationService.resendPrincipalInvitationEmail(
      principalEmail: cleanEmail,
      principalName: principal.name,
      schoolName: schoolName,
      schoolCode: schoolCode,
      invitationCode: inviteCode,
      existingToken: existingToken,
    );

    await _auditService.logAction(
      action: 'PRINCIPAL_INVITATION_RESENT',
      targetType: 'user',
      targetId: principal.id,
      schoolId: principal.schoolId ?? '',
      schoolCode: schoolCode,
      details: {
        'principalEmail': cleanEmail,
        'invitationCode': inviteCode,
        'provider': result.provider,
        'status': result.status,
      },
    );

    return result;
  }

  /// Revokes an active invitation for a Principal
  Future<void> revokePrincipalInvitation(UserModel principal, {String reason = ''}) async {
    final cleanEmail = principal.email.trim().toLowerCase();

    final inviteSnap = await _firestore
        .collection('invitations')
        .where('principalEmail', isEqualTo: cleanEmail)
        .get();

    final batch = _firestore.batch();
    for (var doc in inviteSnap.docs) {
      batch.update(doc.reference, {
        'status': 'revoked',
        'revokedAt': FieldValue.serverTimestamp(),
        'revocationReason': reason,
      });
    }

    final userRef = _firestore.collection('users').doc(principal.id);
    batch.update(userRef, {
      'status': 'revoked',
      'isActive': false,
      'updatedAt': DateTime.now().toIso8601String(),
    });

    if (principal.schoolId != null && principal.schoolId!.isNotEmpty) {
      final schoolRef = _schoolsRef.doc(principal.schoolId!);
      batch.update(schoolRef, {
        'principalId': null,
        'principalName': null,
        'principalEmail': null,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    }

    await batch.commit();

    await _auditService.logAction(
      action: 'PRINCIPAL_INVITATION_REVOKED',
      targetType: 'user',
      targetId: principal.id,
      schoolId: principal.schoolId ?? '',
      details: {'principalEmail': cleanEmail, 'reason': reason},
    );
  }

  /// Toggle Principal account status (active, suspended, deactivated)
  Future<void> updatePrincipalStatus(String principalUid, String newStatus, {String reason = ''}) async {
    final isActive = newStatus == 'active';
    await _firestore.collection('users').doc(principalUid).update({
      'status': newStatus,
      'isActive': isActive,
      'updatedAt': DateTime.now().toIso8601String(),
    });

    await _auditService.logAction(
      action: 'PRINCIPAL_STATUS_CHANGED',
      targetType: 'user',
      targetId: principalUid,
      reason: reason,
      details: {'newStatus': newStatus, 'isActive': isActive},
    );
  }

  /// Real-time live count of schools grouped by type
  Future<Map<String, int>> getRealSchoolCounts() async {
    try {
      final allSnapshot = await _schoolsRef.get();
      int gov = 0;
      int pvt = 0;
      int cbse = 0;
      int active = 0;
      int suspended = 0;
      int pending = 0;

      for (var doc in allSnapshot.docs) {
        final data = doc.data();
        final type = data['type']?.toString().toLowerCase();
        final status = data['status']?.toString().toLowerCase() ?? 'active';

        if (status == 'pending_approval' || status == 'pending') {
          pending++;
        } else if (status == 'active' || data['isActive'] == true) {
          active++;
        } else {
          suspended++;
        }

        if (type == 'government') {
          gov++;
        } else if (type == 'privateschool' || type == 'private') {
          pvt++;
        } else if (type == 'cbse') {
          cbse++;
        }
      }

      return {
        'total': allSnapshot.docs.length,
        'government': gov,
        'private': pvt,
        'cbse': cbse,
        'active': active,
        'suspended': suspended,
        'pending': pending,
      };
    } catch (e) {
      return {'total': 0, 'government': 0, 'private': 0, 'cbse': 0, 'active': 0, 'suspended': 0};
    }
  }

  /// Auto-seeds realistic standard institutions into Firestore if collection is empty
  Future<void> seedInitialSchoolsIfEmpty() async {
    try {
      final snapshot = await _schoolsRef.limit(1).get();
      if (snapshot.docs.isNotEmpty) return; // Already has data

      final sampleSchools = [
        SchoolModel(
          id: 'sch_ap_001',
          name: 'Z.P. High School, Kankipadu',
          code: 'AP-KRI-042',
          type: SchoolType.government,
          status: 'active',
          address: 'Main Road, Kankipadu Village',
          mandal: 'Kankipadu',
          district: 'Krishna',
          state: 'Andhra Pradesh',
          pincode: '521151',
          contactPerson: 'K. Venkateswara Rao (Headmaster)',
          contactPhone: '+91 94401 23456',
          contactEmail: 'zphs.kankipadu@apgov.edu.in',
          affiliationNumber: 'AP-SCERT-1984-KRI',
          academicYear: '2024-2025',
          supportedClasses: const ['Class 6', 'Class 7', 'Class 8', 'Class 9', 'Class 10'],
          totalStudents: 620,
          totalTeachers: 28,
          curriculumTemplateId: 'AP_STATE_GOVT',
          establishedDate: DateTime(1984, 6, 12),
        ),
        SchoolModel(
          id: 'sch_ap_002',
          name: 'AP Model School, Guntur Rural',
          code: 'AP-GNT-109',
          type: SchoolType.government,
          status: 'active',
          address: 'Pedakakani Cross, Guntur Bypass',
          mandal: 'Pedakakani',
          district: 'Guntur',
          state: 'Andhra Pradesh',
          pincode: '522509',
          contactPerson: 'Dr. M. Sailaja (Principal)',
          contactPhone: '+91 94402 34567',
          contactEmail: 'apms.guntur@apgov.edu.in',
          affiliationNumber: 'APMS-GNT-2013-09',
          academicYear: '2024-2025',
          supportedClasses: const ['Class 6', 'Class 7', 'Class 8', 'Class 9', 'Class 10', 'Class 11', 'Class 12'],
          totalStudents: 780,
          totalTeachers: 34,
          curriculumTemplateId: 'AP_STATE_GOVT',
          establishedDate: DateTime(2013, 7, 1),
        ),
        SchoolModel(
          id: 'sch_cbse_001',
          name: 'Kendriya Vidyalaya No. 1, Vijayawada',
          code: 'CBSE-AP-012',
          type: SchoolType.cbse,
          status: 'active',
          address: 'Railway Colony, Satyanarayanapuram',
          mandal: 'Vijayawada Urban',
          district: 'NTR District',
          state: 'Andhra Pradesh',
          pincode: '520011',
          contactPerson: 'S. N. Sharma (Principal)',
          contactPhone: '+91 866 253 4411',
          contactEmail: 'kv1.vijayawada@kvs.ac.in',
          affiliationNumber: 'CBSE-AFF-012890',
          academicYear: '2024-2025',
          supportedClasses: const ['Class 6', 'Class 7', 'Class 8', 'Class 9', 'Class 10', 'Class 11', 'Class 12'],
          totalStudents: 1450,
          totalTeachers: 62,
          curriculumTemplateId: 'CBSE_CENTRAL',
          establishedDate: DateTime(1992, 8, 15),
        ),
        SchoolModel(
          id: 'sch_pvt_001',
          name: 'Sri Chaitanya Techno School, Tirupati',
          code: 'PVT-TPT-088',
          type: SchoolType.privateSchool,
          status: 'active',
          address: 'Renigunta Road, Korlagunta Junction',
          mandal: 'Tirupati Urban',
          district: 'Tirupati',
          state: 'Andhra Pradesh',
          pincode: '517501',
          contactPerson: 'R. K. Varma (Dean)',
          contactPhone: '+91 877 228 9001',
          contactEmail: 'tirupati.techno@srichaitanya.net',
          affiliationNumber: 'PVT-AP-TPT-2010',
          academicYear: '2024-2025',
          supportedClasses: const ['Class 6', 'Class 7', 'Class 8', 'Class 9', 'Class 10'],
          totalStudents: 940,
          totalTeachers: 45,
          curriculumTemplateId: 'PRIVATE_CUSTOM',
          establishedDate: DateTime(2010, 5, 20),
        ),
      ];

      for (var s in sampleSchools) {
        await _schoolsRef.doc(s.id).set(s.toMap());
      }
    } catch (e) {
      // Non-fatal fallback
    }
  }
}
