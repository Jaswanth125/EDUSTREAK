import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String role; // student, teacher, principal, parent, admin
  final String? classId;
  final String? profileImageUrl;

  bool get isPrincipal => role.toLowerCase() == 'principal';
  bool get isTeacher => role.toLowerCase() == 'teacher';
  bool get isStudent => role.toLowerCase() == 'student';
  bool get isParent => role.toLowerCase() == 'parent';
  bool get isAdmin => role.toLowerCase() == 'admin';
  
  // Institutional / Multi-school scope
  final String? schoolId;
  final String? schoolCode;
  final String? rollNumber;
  final String? admissionNumber;
  final String? employeeId;
  final String? grade; // e.g. "8"
  final String? section; // e.g. "A"
  final String? academicYear; // e.g. "2026-2027"
  final bool isActive;
  final String status; // 'active', 'not_registered', 'suspended', 'deactivated'
  
  // Student specific
  final int streak; // Legacy field - kept for backward compatibility
  final int streakCount; // Daily login streak count
  final int highestStreak; // Highest streak achieved
  final int xp;
  final int spendablePoints; // Spendable points for store purchases (preserves lifetime xp)
  final int level;
  final List<String> badges;
  final List<String> purchasedItems; // Store items purchased
  final List<String> redeemedAvatars; // Redeemed avatars
  final String? currentAvatar; // Current avatar ID
  
  // Parent specific
  final String? childId; // For backward compatibility
  final List<String> childIds; // For parents with multiple children
  
  // Teacher specific
  final List<String>? classIds; // Classes taught by teacher
  final List<String> assignedSubjects; // Subjects taught (e.g. ['Science', 'Biology'])
  
  // Login tracking
  final DateTime? lastLogin; // Last login timestamp (legacy)
  final DateTime? lastLoginDate; // Last login date (date only, for streak calculation)

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.classId,
    this.profileImageUrl,
    this.schoolId,
    this.schoolCode,
    this.rollNumber,
    this.admissionNumber,
    this.employeeId,
    this.grade,
    this.section,
    this.academicYear,
    this.isActive = true,
    this.status = 'active',
    this.streak = 0,
    this.streakCount = 0,
    this.highestStreak = 0,
    this.xp = 0,
    this.spendablePoints = 0,
    this.level = 1,
    this.badges = const [],
    this.purchasedItems = const [],
    this.redeemedAvatars = const [],
    this.currentAvatar,
    this.childId,
    this.childIds = const [],
    this.classIds,
    this.assignedSubjects = const [],
    this.lastLogin,
    this.lastLoginDate,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    // Handle lastLogin conversion from Firestore Timestamp
    DateTime? lastLogin;
    if (map['lastLogin'] != null) {
      if (map['lastLogin'] is Timestamp) {
        lastLogin = (map['lastLogin'] as Timestamp).toDate();
      } else if (map['lastLogin'] is DateTime) {
        lastLogin = map['lastLogin'] as DateTime;
      }
    }
    
    // Handle lastLoginDate conversion from Firestore Timestamp
    DateTime? lastLoginDate;
    if (map['lastLoginDate'] != null) {
      if (map['lastLoginDate'] is Timestamp) {
        lastLoginDate = (map['lastLoginDate'] as Timestamp).toDate();
      } else if (map['lastLoginDate'] is DateTime) {
        lastLoginDate = map['lastLoginDate'] as DateTime;
      }
    }

    // Resolve childIds with fallback to single childId
    List<String> childIdsList = [];
    if (map['childIds'] != null) {
      childIdsList = List<String>.from(map['childIds']);
    } else if (map['childId'] != null && map['childId'].toString().isNotEmpty) {
      childIdsList = [map['childId'].toString()];
    }
    
    final bool active = map['isActive'] ?? true;
    final String resolvedStatus = map['status'] ?? (active ? 'active' : 'suspended');

    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? '',
      classId: map['classId'],
      profileImageUrl: map['profileImageUrl'],
      schoolId: map['schoolId'],
      schoolCode: map['schoolCode'],
      rollNumber: map['rollNumber'],
      admissionNumber: map['admissionNumber'],
      employeeId: map['employeeId'],
      grade: map['grade'],
      section: map['section'],
      academicYear: map['academicYear'],
      isActive: active,
      status: resolvedStatus,
      streak: map['streak'] ?? 0,
      streakCount: map['streakCount'] ?? 0,
      highestStreak: map['highestStreak'] ?? 0,
      xp: map['xp'] ?? 0,
      spendablePoints: map['spendablePoints'] ?? (map['xp'] ?? 0),
      level: map['level'] ?? 1,
      badges: List<String>.from(map['badges'] ?? []),
      purchasedItems: List<String>.from(map['purchasedItems'] ?? []),
      redeemedAvatars: List<String>.from(map['redeemedAvatars'] ?? []),
      currentAvatar: map['currentAvatar'],
      childId: map['childId'],
      childIds: childIdsList,
      classIds: map['classIds'] != null ? List<String>.from(map['classIds']) : null,
      assignedSubjects: List<String>.from(map['assignedSubjects'] ?? []),
      lastLogin: lastLogin,
      lastLoginDate: lastLoginDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'classId': classId,
      'profileImageUrl': profileImageUrl,
      'schoolId': schoolId,
      'schoolCode': schoolCode,
      'rollNumber': rollNumber,
      'admissionNumber': admissionNumber,
      'employeeId': employeeId,
      'grade': grade,
      'section': section,
      'academicYear': academicYear,
      'isActive': isActive,
      'status': status,
      'streak': streak,
      'streakCount': streakCount,
      'highestStreak': highestStreak,
      'xp': xp,
      'spendablePoints': spendablePoints,
      'level': level,
      'badges': badges,
      'purchasedItems': purchasedItems,
      'redeemedAvatars': redeemedAvatars,
      'currentAvatar': currentAvatar,
      'childId': childId,
      'childIds': childIds,
      'classIds': classIds,
      'assignedSubjects': assignedSubjects,
      'lastLogin': lastLogin != null ? Timestamp.fromDate(lastLogin!) : null,
      'lastLoginDate': lastLoginDate != null ? Timestamp.fromDate(lastLoginDate!) : null,
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? classId,
    String? profileImageUrl,
    String? schoolId,
    String? schoolCode,
    String? rollNumber,
    String? admissionNumber,
    String? employeeId,
    String? grade,
    String? section,
    String? academicYear,
    bool? isActive,
    String? status,
    int? streak,
    int? streakCount,
    int? highestStreak,
    int? xp,
    int? spendablePoints,
    int? level,
    List<String>? badges,
    List<String>? purchasedItems,
    List<String>? redeemedAvatars,
    String? currentAvatar,
    String? childId,
    List<String>? childIds,
    List<String>? classIds,
    List<String>? assignedSubjects,
    DateTime? lastLogin,
    DateTime? lastLoginDate,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      classId: classId ?? this.classId,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      schoolId: schoolId ?? this.schoolId,
      schoolCode: schoolCode ?? this.schoolCode,
      rollNumber: rollNumber ?? this.rollNumber,
      admissionNumber: admissionNumber ?? this.admissionNumber,
      employeeId: employeeId ?? this.employeeId,
      grade: grade ?? this.grade,
      section: section ?? this.section,
      academicYear: academicYear ?? this.academicYear,
      isActive: isActive ?? this.isActive,
      status: status ?? this.status,
      streak: streak ?? this.streak,
      streakCount: streakCount ?? this.streakCount,
      highestStreak: highestStreak ?? this.highestStreak,
      xp: xp ?? this.xp,
      spendablePoints: spendablePoints ?? this.spendablePoints,
      level: level ?? this.level,
      badges: badges ?? this.badges,
      purchasedItems: purchasedItems ?? this.purchasedItems,
      redeemedAvatars: redeemedAvatars ?? this.redeemedAvatars,
      currentAvatar: currentAvatar ?? this.currentAvatar,
      childId: childId ?? this.childId,
      childIds: childIds ?? this.childIds,
      classIds: classIds ?? this.classIds,
      assignedSubjects: assignedSubjects ?? this.assignedSubjects,
      lastLogin: lastLogin ?? this.lastLogin,
      lastLoginDate: lastLoginDate ?? this.lastLoginDate,
    );
  }
}
