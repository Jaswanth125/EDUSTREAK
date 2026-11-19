import 'package:cloud_firestore/cloud_firestore.dart';

class RosterStudentModel {
  final String id;
  final String schoolId;
  final String schoolCode;
  final String studentName;
  final String rollNumber;
  final String admissionNumber;
  final String grade; // e.g. "8" or "10"
  final String section; // e.g. "A" or "B"
  final String classId; // e.g. "class_ap-kri-042_8_a"
  final String academicYear; // e.g. "2026-2027"
  final String? email;
  final String? parentName;
  final String? parentPhone;
  final String? parentEmail;
  final String verificationPin; // 4-6 digit PIN for verification or parent linking
  final String status; // 'not_registered', 'registration_in_progress', 'active', 'suspended', 'deactivated'
  final String? claimedByUid;
  final DateTime? claimedAt;
  final DateTime createdAt;

  const RosterStudentModel({
    required this.id,
    required this.schoolId,
    required this.schoolCode,
    required this.studentName,
    required this.rollNumber,
    required this.admissionNumber,
    required this.grade,
    required this.section,
    required this.classId,
    required this.academicYear,
    this.email,
    this.parentName,
    this.parentPhone,
    this.parentEmail,
    required this.verificationPin,
    this.status = 'not_registered',
    this.claimedByUid,
    this.claimedAt,
    required this.createdAt,
  });

  bool get isRegistered => status == 'active';
  bool get isEligibleForRegistration => status == 'not_registered';

  String get classLabel => 'Class $grade-$section';

  factory RosterStudentModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    DateTime? claimedAt;
    if (map['claimedAt'] != null) {
      if (map['claimedAt'] is Timestamp) {
        claimedAt = (map['claimedAt'] as Timestamp).toDate();
      } else if (map['claimedAt'] is DateTime) {
        claimedAt = map['claimedAt'] as DateTime;
      }
    }

    DateTime createdAt = DateTime.now();
    if (map['createdAt'] != null) {
      if (map['createdAt'] is Timestamp) {
        createdAt = (map['createdAt'] as Timestamp).toDate();
      } else if (map['createdAt'] is DateTime) {
        createdAt = map['createdAt'] as DateTime;
      }
    }

    return RosterStudentModel(
      id: docId ?? map['id'] ?? '',
      schoolId: map['schoolId'] ?? '',
      schoolCode: (map['schoolCode'] ?? '').toString().toUpperCase(),
      studentName: map['studentName'] ?? map['name'] ?? '',
      rollNumber: (map['rollNumber'] ?? '').toString().trim(),
      admissionNumber: (map['admissionNumber'] ?? map['rollNumber'] ?? '').toString().trim(),
      grade: (map['grade'] ?? '').toString().trim(),
      section: (map['section'] ?? '').toString().trim().toUpperCase(),
      classId: map['classId'] ?? 'Class ${map['grade']}-${map['section']}',
      academicYear: map['academicYear'] ?? '2026-2027',
      email: map['email'],
      parentName: map['parentName'],
      parentPhone: map['parentPhone'],
      parentEmail: map['parentEmail'],
      verificationPin: (map['verificationPin'] ?? '1234').toString(),
      status: map['status'] ?? (map['isActive'] == true ? 'active' : 'not_registered'),
      claimedByUid: map['claimedByUid'],
      claimedAt: claimedAt,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'schoolId': schoolId,
      'schoolCode': schoolCode.toUpperCase(),
      'studentName': studentName,
      'rollNumber': rollNumber,
      'admissionNumber': admissionNumber,
      'grade': grade,
      'section': section,
      'classId': classId,
      'academicYear': academicYear,
      'email': email,
      'parentName': parentName,
      'parentPhone': parentPhone,
      'parentEmail': parentEmail,
      'verificationPin': verificationPin,
      'status': status,
      'claimedByUid': claimedByUid,
      'claimedAt': claimedAt != null ? Timestamp.fromDate(claimedAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  RosterStudentModel copyWith({
    String? id,
    String? schoolId,
    String? schoolCode,
    String? studentName,
    String? rollNumber,
    String? admissionNumber,
    String? grade,
    String? section,
    String? classId,
    String? academicYear,
    String? email,
    String? parentName,
    String? parentPhone,
    String? parentEmail,
    String? verificationPin,
    String? status,
    String? claimedByUid,
    DateTime? claimedAt,
    DateTime? createdAt,
  }) {
    return RosterStudentModel(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      schoolCode: schoolCode ?? this.schoolCode,
      studentName: studentName ?? this.studentName,
      rollNumber: rollNumber ?? this.rollNumber,
      admissionNumber: admissionNumber ?? this.admissionNumber,
      grade: grade ?? this.grade,
      section: section ?? this.section,
      classId: classId ?? this.classId,
      academicYear: academicYear ?? this.academicYear,
      email: email ?? this.email,
      parentName: parentName ?? this.parentName,
      parentPhone: parentPhone ?? this.parentPhone,
      parentEmail: parentEmail ?? this.parentEmail,
      verificationPin: verificationPin ?? this.verificationPin,
      status: status ?? this.status,
      claimedByUid: claimedByUid ?? this.claimedByUid,
      claimedAt: claimedAt ?? this.claimedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
