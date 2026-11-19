import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/badge_model.dart';
import 'notification_service.dart';
import 'attendance_summary_service.dart';

import '../models/xp_transaction_model.dart';

class GamificationService {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  NotificationService get _notificationService => NotificationService();
  AttendanceSummaryService get _attendanceSummaryService => AttendanceSummaryService();

  // XP required for each level (exponential growth)
  int getXPForLevel(int level) {
    return (level * 100) * (level + 1);
  }

  int getLevelFromXP(int xp) {
    int level = 1;
    while (getXPForLevel(level) <= xp) {
      level++;
    }
    return level - 1;
  }

  Future<void> addXP(
    String userId,
    int amount, {
    String reason = 'Activity completion',
    String type = 'earn',
  }) async {
    try {
      if (amount <= 0) {
        debugPrint('Warning: Attempted to add ${amount} XP (must be positive)');
        return;
      }

      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        debugPrint('Error: User $userId does not exist');
        throw Exception('User not found');
      }

      final userData = userDoc.data()!;
      final currentXP = (userData['xp'] as num?)?.toInt() ?? 0;
      final rawSpendable = (userData['spendablePoints'] as num?)?.toInt();
      // Initialize spendable to currentXP if never set
      final currentSpendable = rawSpendable ?? currentXP;
      final newXP = currentXP + amount;
      final newSpendable = currentSpendable + amount;
      final currentLevel = getLevelFromXP(currentXP);
      final newLevel = getLevelFromXP(newXP);

      debugPrint('Adding XP: User=$userId, Amount=$amount, Current=$currentXP, New=$newXP, Spendable=$currentSpendable->$newSpendable, Level=$currentLevel->$newLevel');

      await _firestore.collection('users').doc(userId).update({
        'xp': newXP,
        'spendablePoints': newSpendable,
        'level': newLevel,
      });

      // Audit trail in xp_transactions
      await recordXPTransaction(
        userId: userId,
        schoolId: userData['schoolId'] as String?,
        amount: amount,
        type: type,
        reason: reason,
        balanceAfter: newSpendable,
      );

      debugPrint('✅ XP updated successfully for user $userId');

      // Level up: check level-based badges and notify
      if (newLevel > currentLevel) {
        debugPrint('🎉 Level up! User $userId reached level $newLevel');
        await checkLevelBadges(userId, newLevel);
        // Leaderboard badge check only on level-up (rank may change) — not on every XP add
        await checkLeaderboardBadges(userId);
      }
    } catch (e) {
      debugPrint('❌ Error adding XP to user $userId: $e');
      throw Exception('Failed to add XP: $e');
    }
  }

  /// Record an XP transaction into the audit collection
  Future<void> recordXPTransaction({
    required String userId,
    String? schoolId,
    required int amount,
    required String type,
    required String reason,
    required int balanceAfter,
  }) async {
    try {
      final docRef = _firestore.collection('xp_transactions').doc();
      final tx = XpTransactionModel(
        id: docRef.id,
        userId: userId,
        schoolId: schoolId,
        amount: amount,
        type: type,
        reason: reason,
        balanceAfter: balanceAfter,
        timestamp: DateTime.now(),
      );
      await docRef.set(tx.toMap());
    } catch (e) {
      debugPrint('Error logging XP transaction: $e');
    }
  }

  /// Stream of user XP transactions for history inspection
  Stream<List<XpTransactionModel>> getXPTransactions(String userId) {
    return _firestore
        .collection('xp_transactions')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => XpTransactionModel.fromMap(doc.data(), id: doc.id))
            .toList());
  }

  Future<void> updateStreak(String userId, bool increment) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return;

      final currentStreak = userDoc.data()?['streak'] ?? 0;
      final newStreak = increment ? currentStreak + 1 : 0;

      await _firestore.collection('users').doc(userId).update({
        'streak': newStreak,
      });

      // Check for badge eligibility
      await checkStreakBadges(userId, newStreak);
    } catch (e) {
      throw Exception('Failed to update streak: $e');
    }
  }

  Future<void> checkStreakBadges(String userId, int streak) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final userBadges = List<String>.from(userDoc.data()?['badges'] ?? []);

    // Consistency King/Queen (7-day streak)
    if (streak >= 7 && !userBadges.contains('consistency_king')) {
      await awardBadge(userId, 'consistency_king');
    }
    
    // Dedicated Learner (20-day streak)
    if (streak >= 20 && !userBadges.contains('dedicated')) {
      await awardBadge(userId, 'dedicated');
    }
    
    // Streak Master (30-day streak)
    if (streak >= 30 && !userBadges.contains('streak_master')) {
      await awardBadge(userId, 'streak_master');
    }
    
    // Unbreakable (100-day streak)
    if (streak >= 100 && !userBadges.contains('unbreakable')) {
      await awardBadge(userId, 'unbreakable');
    }
  }

  /// Check attendance badges based on monthly attendance percentage
  /// 100% attendance = Attendance Hero badge (+50 XP)
  /// 90%+ attendance = Consistency Star badge (+30 XP)
  Future<void> checkAttendanceBadges(String userId, DateTime month) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return;

      final user = UserModel.fromMap(userDoc.data()!..['id'] = userDoc.id);
      if (user.classId == null) return;

      final userBadges = List<String>.from(userDoc.data()?['badges'] ?? []);

      // Get monthly attendance summary
      final summary = await _attendanceSummaryService.getStudentMonthlySummary(
        userId,
        user.classId!,
        month,
      );

      final percentage = summary['percentage'] ?? 0.0;
      final totalWorkingDays = summary['totalWorkingDays'] ?? 0;

      // Only award badges if there are actual working days
      if (totalWorkingDays == 0) return;

      // Check if badge was already awarded for this month
      final monthKey = '${month.year}-${month.month.toString().padLeft(2, '0')}';
      
      // Check if we've already checked this month (to avoid duplicate awards)
      final lastAttendanceCheck = userDoc.data()?['lastAttendanceCheck'] as String?;
      if (lastAttendanceCheck == monthKey) {
        return; // Already checked this month
      }

      bool badgeAwarded = false;

      // Attendance Hero: 100% attendance in a month (+50 XP)
      if (percentage == 100.0 && !userBadges.contains('attendance_hero')) {
        await awardBadge(userId, 'attendance_hero');
        badgeAwarded = true;
      }
      
      // Consistency Star: 90%+ attendance in a month (+30 XP)
      if (percentage >= 90.0 && percentage < 100.0 && !userBadges.contains('consistency_star')) {
        await awardBadge(userId, 'consistency_star');
        badgeAwarded = true;
      }

      // Update last check timestamp
      if (badgeAwarded) {
        await _firestore.collection('users').doc(userId).update({
          'lastAttendanceCheck': monthKey,
        });
      }
    } catch (e) {
      throw Exception('Failed to check attendance badges: $e');
    }
  }

  /// Check attendance badges for current month
  Future<void> checkCurrentMonthAttendanceBadges(String userId) async {
    await checkAttendanceBadges(userId, DateTime.now());
  }

  Future<void> checkAssignmentBadges(String userId) async {
    try {
      final tasksSnapshot = await _firestore
          .collection('tasks')
          .where('assignedTo', arrayContains: userId)
          .get();

      int completedOnTime = 0;
      for (var taskDoc in tasksSnapshot.docs) {
        final task = taskDoc.data();
        final submission = task['submissions']?[userId];
        if (submission == 'completed' || submission == 'submitted') {
          final dueDate = (task['dueDate'] as Timestamp).toDate();
          if (DateTime.now().isBefore(dueDate)) {
            completedOnTime++;
          }
        }
      }

      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userBadges = List<String>.from(userDoc.data()?['badges'] ?? []);

      // Assignment Ace (5 tasks on time)
      if (completedOnTime >= 5 && !userBadges.contains('assignment_ace')) {
        await awardBadge(userId, 'assignment_ace');
      }
      // Homework Hero (10 tasks on time)
      if (completedOnTime >= 10 && !userBadges.contains('homework_hero')) {
        await awardBadge(userId, 'homework_hero');
      }

      // Check for top performer badge (90+ marks in 5 assignments)
      int highMarksCount = 0;
      int goodMarksCount = 0; // 80+ marks
      int earlySubmissions = 0;
      int totalSubmissions = 0;
      
      for (var taskDoc in tasksSnapshot.docs) {
        final task = taskDoc.data();
        final submission = task['submissions']?[userId];
        final marks = task['marks']?[userId];
        final dueDate = (task['dueDate'] as Timestamp).toDate();
        
        if (submission == 'completed' || submission == 'submitted') {
          totalSubmissions++;
          if (DateTime.now().isBefore(dueDate)) {
            earlySubmissions++;
          }
        }
        
        if (marks != null) {
          final marksValue = (marks as num).toDouble();
          if (marksValue >= 90) {
            highMarksCount++;
          }
          if (marksValue >= 80) {
            goodMarksCount++;
          }
        }
      }
      
      if (highMarksCount >= 5 && !userBadges.contains('top_performer')) {
        await awardBadge(userId, 'top_performer');
      }
      
      // Knowledge Seeker (80+ in 10 assignments)
      if (goodMarksCount >= 10 && !userBadges.contains('knowledge_seeker')) {
        await awardBadge(userId, 'knowledge_seeker');
      }
      
      // First submission badge
      if (totalSubmissions == 1 && !userBadges.contains('first_submission')) {
        await awardBadge(userId, 'first_submission');
      }
      
      // Speed Demon (3 early submissions)
      if (earlySubmissions >= 3 && !userBadges.contains('speed_demon')) {
        await awardBadge(userId, 'speed_demon');
      }
    } catch (e) {
      throw Exception('Failed to check assignment badges: $e');
    }
  }

  Future<void> checkLevelBadges(String userId, int level) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userBadges = List<String>.from(userDoc.data()?['badges'] ?? []);

      // Level-based badges
      if (level >= 5 && !userBadges.contains('bronze_warrior')) {
        await awardBadge(userId, 'bronze_warrior');
      }
      if (level >= 10 && !userBadges.contains('silver_champion')) {
        await awardBadge(userId, 'silver_champion');
      }
      if (level >= 15 && !userBadges.contains('gold_legend')) {
        await awardBadge(userId, 'gold_legend');
      }
      if (level >= 20 && !userBadges.contains('platinum_master')) {
        await awardBadge(userId, 'platinum_master');
      }
      if (level >= 25 && !userBadges.contains('diamond_elite')) {
        await awardBadge(userId, 'diamond_elite');
      }
    } catch (e) {
      throw Exception('Failed to check level badges: $e');
    }
  }

  Future<void> checkLeaderboardBadges(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return;
      
      final user = UserModel.fromMap(userDoc.data()!..['id'] = userDoc.id);
      if (user.classId == null) return;
      
      // Get all students in same class (sort in memory to avoid composite index)
      final studentsSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'student')
          .where('classId', isEqualTo: user.classId)
          .get();
      
      final students = studentsSnapshot.docs
          .map((doc) => UserModel.fromMap(doc.data()..['id'] = doc.id))
          .toList();
      
      // Sort by XP in memory (descending)
      students.sort((a, b) => b.xp.compareTo(a.xp));
      
      // Find user's rank
      int rank = students.indexWhere((s) => s.id == userId) + 1;
      
      final userBadges = List<String>.from(userDoc.data()?['badges'] ?? []);
      
      // Legend badge (#1)
      if (rank == 1 && !userBadges.contains('legend')) {
        await awardBadge(userId, 'legend');
      }
      
      // Rising Star badge (Top 3)
      if (rank >= 1 && rank <= 3 && !userBadges.contains('rising_star')) {
        await awardBadge(userId, 'rising_star');
      }
    } catch (e) {
      // Silently fail - badge check is not critical
      print('Error checking leaderboard badges: $e');
    }
  }

  Future<void> awardBadge(String userId, String badgeId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userBadges = List<String>.from(userDoc.data()?['badges'] ?? []);

      if (!userBadges.contains(badgeId)) {
        userBadges.add(badgeId);
        final badges = BadgeModel.getDefaultBadges();
        final badge = badges.firstWhere(
          (b) => b.id == badgeId,
          orElse: () => BadgeModel(
            id: badgeId,
            name: badgeId,
            description: '',
            icon: '🏅',
            xpReward: 0,
            category: 'misc',
          ),
        );

        await _firestore.collection('users').doc(userId).update({
          'badges': userBadges,
        });

        // Add XP reward
        if (badge.xpReward > 0) {
          await addXP(userId, badge.xpReward);
        }

        // 🔔 Fire local notification so the student actually sees the badge award
        await _notificationService.init();
        await _notificationService.showLocalNotification(
          title: '${badge.icon} Badge Unlocked!',
          body: 'You earned the "${badge.name}" badge! +${badge.xpReward} XP',
          payload: 'badge:$badgeId',
        );

        debugPrint('🏅 Badge awarded: $badgeId to user $userId (+${badge.xpReward} XP)');
      }
    } catch (e) {
      throw Exception('Failed to award badge: $e');
    }
  }
}

