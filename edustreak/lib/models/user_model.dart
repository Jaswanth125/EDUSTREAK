import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String role; // student, teacher, parent, admin
  final String? classId;
  final String? profileImageUrl;
  
  // Student specific
  final int streak; // Legacy field - kept for backward compatibility
  final int streakCount; // Daily login streak count
  final int highestStreak; // Highest streak achieved
  final int xp;
  final int level;
  final List<String> badges;
  final List<String> purchasedItems; // Store items purchased
  final List<String> redeemedAvatars; // Redeemed avatars (similar to badges)
  final String? currentAvatar; // Current avatar ID
  
  // Parent specific
  final String? childId; // For parents to link to their child
  
  // Teacher specific
  final List<String>? classIds; // Classes taught by teacher
  
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
    this.streak = 0,
    this.streakCount = 0,
    this.highestStreak = 0,
    this.xp = 0,
    this.level = 1,
    this.badges = const [],
    this.purchasedItems = const [],
    this.redeemedAvatars = const [],
    this.currentAvatar,
    this.childId,
    this.classIds,
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
    
    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? '',
      classId: map['classId'],
      profileImageUrl: map['profileImageUrl'],
      streak: map['streak'] ?? 0,
      streakCount: map['streakCount'] ?? 0,
      highestStreak: map['highestStreak'] ?? 0,
      xp: map['xp'] ?? 0,
      level: map['level'] ?? 1,
      badges: List<String>.from(map['badges'] ?? []),
      purchasedItems: List<String>.from(map['purchasedItems'] ?? []),
      redeemedAvatars: List<String>.from(map['redeemedAvatars'] ?? []),
      currentAvatar: map['currentAvatar'],
      childId: map['childId'],
      classIds: map['classIds'] != null ? List<String>.from(map['classIds']) : null,
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
      'streak': streak,
      'streakCount': streakCount,
      'highestStreak': highestStreak,
      'xp': xp,
      'level': level,
      'badges': badges,
      'purchasedItems': purchasedItems,
      'redeemedAvatars': redeemedAvatars,
      'currentAvatar': currentAvatar,
      'childId': childId,
      'classIds': classIds,
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
    int? streak,
    int? streakCount,
    int? highestStreak,
    int? xp,
    int? level,
    List<String>? badges,
    List<String>? purchasedItems,
    List<String>? redeemedAvatars,
    String? currentAvatar,
    String? childId,
    List<String>? classIds,
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
      streak: streak ?? this.streak,
      streakCount: streakCount ?? this.streakCount,
      highestStreak: highestStreak ?? this.highestStreak,
      xp: xp ?? this.xp,
      level: level ?? this.level,
      badges: badges ?? this.badges,
      purchasedItems: purchasedItems ?? this.purchasedItems,
      redeemedAvatars: redeemedAvatars ?? this.redeemedAvatars,
      currentAvatar: currentAvatar ?? this.currentAvatar,
      childId: childId ?? this.childId,
      classIds: classIds ?? this.classIds,
      lastLogin: lastLogin ?? this.lastLogin,
      lastLoginDate: lastLoginDate ?? this.lastLoginDate,
    );
  }
}

