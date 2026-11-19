import 'package:cloud_firestore/cloud_firestore.dart';

class RosterTeacherModel {
  final String id;
  final String schoolId;
  final String schoolCode;
  final String teacherName;
  final String employeeId;
  final String email;
  final String? phone;
  final List<String> assignedSubjects;
  final List<String> assignedClasses;
  final String academicYear;
  final String verificationPin;
  final String status; // 'not_registered', 'active', 'suspended', 'deactivated'
  final String? claimedByUid;
  final DateTime? claimedAt;
  final DateTime createdAt;

  const RosterTeacherModel({
    required this.id,
    required this.schoolId,
    required this.schoolCode,
    required this.teacherName,
    required this.employeeId,
    required this.email,
    this.phone,
    required this.assignedSubjects,
    required this.assignedClasses,
    required this.academicYear,
    required this.verificationPin,
    this.status = 'not_registered',
    this.claimedByUid,
    this.claimedAt,
    required this.createdAt,
  });

  bool get isRegistered => status == 'active';
  bool get isEligibleForRegistration => status == 'not_registered';

  factory RosterTeacherModel.fromMap(Map<String, dynamic> map, [String? docId]) {
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

    List<String> subjects = [];
    if (map['assignedSubjects'] != null) {
      subjects = List<String>.from(map['assignedSubjects']);
    } else if (map['subjects'] != null) {
      subjects = List<String>.from(map['subjects']);
    }

    List<String> classes = [];
    if (map['assignedClasses'] != null) {
      classes = List<String>.from(map['assignedClasses']);
    } else if (map['classes'] != null) {
      classes = List<String>.from(map['classes']);
    }

    return RosterTeacherModel(
      id: docId ?? map['id'] ?? '',
      schoolId: map['schoolId'] ?? '',
      schoolCode: (map['schoolCode'] ?? '').toString().toUpperCase(),
      teacherName: map['teacherName'] ?? map['name'] ?? '',
      employeeId: (map['employeeId'] ?? '').toString().trim(),
      email: (map['email'] ?? '').toString().trim(),
      phone: map['phone']?.toString().trim(),
      assignedSubjects: subjects,
      assignedClasses: classes,
      academicYear: map['academicYear'] ?? '2026-2027',
      verificationPin: (map['verificationPin'] ?? '5678').toString(),
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
      'teacherName': teacherName,
      'employeeId': employeeId,
      'email': email,
      'phone': phone,
      'assignedSubjects': assignedSubjects,
      'assignedClasses': assignedClasses,
      'academicYear': academicYear,
      'verificationPin': verificationPin,
      'status': status,
      'claimedByUid': claimedByUid,
      'claimedAt': claimedAt != null ? Timestamp.fromDate(claimedAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  RosterTeacherModel copyWith({
    String? id,
    String? schoolId,
    String? schoolCode,
    String? teacherName,
    String? employeeId,
    String? email,
    String? phone,
    List<String>? assignedSubjects,
    List<String>? assignedClasses,
    String? academicYear,
    String? verificationPin,
    String? status,
    String? claimedByUid,
    DateTime? claimedAt,
    DateTime? createdAt,
  }) {
    return RosterTeacherModel(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      schoolCode: schoolCode ?? this.schoolCode,
      teacherName: teacherName ?? this.teacherName,
      employeeId: employeeId ?? this.employeeId,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      assignedSubjects: assignedSubjects ?? this.assignedSubjects,
      assignedClasses: assignedClasses ?? this.assignedClasses,
      academicYear: academicYear ?? this.academicYear,
      verificationPin: verificationPin ?? this.verificationPin,
      status: status ?? this.status,
      claimedByUid: claimedByUid ?? this.claimedByUid,
      claimedAt: claimedAt ?? this.claimedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
