import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/challenge_model.dart';
import 'gamification_service.dart';

class ChallengeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GamificationService _gamificationService = GamificationService();

  Future<void> createChallenge({
    required String title,
    required String description,
    required int xpReward,
    required DateTime dueDate,
    required List<String> assignedTo,
  }) async {
    try {
      final challengeId = _firestore.collection('challenges').doc().id;
      final challenge = ChallengeModel(
        id: challengeId,
        title: title,
        description: description,
        type: 'daily', // Default to daily, can be changed
        xpReward: xpReward,
        startDate: DateTime.now(),
        endDate: dueDate,
        assignedTo: assignedTo,
      );

      await _firestore.collection('challenges').doc(challengeId).set(challenge.toMap());
    } catch (e) {
      throw Exception('Failed to create challenge: $e');
    }
  }

  Future<void> createDailyChallenge({
    required String classId,
    required String title,
    required String description,
    required int xpReward,
  }) async {
    try {
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, now.day);
      final endDate = startDate.add(const Duration(days: 1));

      // Get all students in class
      final studentsSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'student')
          .where('classId', isEqualTo: classId)
          .get();

      final studentIds = studentsSnapshot.docs.map((doc) => doc.id).toList();

      final challengeId = _firestore.collection('challenges').doc().id;
      final challenge = ChallengeModel(
        id: challengeId,
        title: title,
        description: description,
        type: 'daily',
        xpReward: xpReward,
        startDate: startDate,
        endDate: endDate,
        assignedTo: studentIds,
      );

      await _firestore.collection('challenges').doc(challengeId).set(challenge.toMap());
    } catch (e) {
      throw Exception('Failed to create challenge: $e');
    }
  }

  Future<void> createWeeklyChallenge({
    required String classId,
    required String title,
    required String description,
    required int xpReward,
  }) async {
    try {
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, now.day);
      final endDate = startDate.add(const Duration(days: 7));

      final studentsSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'student')
          .where('classId', isEqualTo: classId)
          .get();

      final studentIds = studentsSnapshot.docs.map((doc) => doc.id).toList();

      final challengeId = _firestore.collection('challenges').doc().id;
      final challenge = ChallengeModel(
        id: challengeId,
        title: title,
        description: description,
        type: 'weekly',
        xpReward: xpReward,
        startDate: startDate,
        endDate: endDate,
        assignedTo: studentIds,
      );

      await _firestore.collection('challenges').doc(challengeId).set(challenge.toMap());
    } catch (e) {
      throw Exception('Failed to create challenge: $e');
    }
  }

  Future<void> completeChallenge(String challengeId, String studentId) async {
    try {
      final challengeDoc = await _firestore.collection('challenges').doc(challengeId).get();
      if (!challengeDoc.exists) return;

      final challenge = ChallengeModel.fromMap(
        challengeDoc.data() as Map<String, dynamic>..['id'] = challengeDoc.id,
      );

      if (!challenge.isActive) {
        throw Exception('Challenge is not active');
      }

      if (challenge.isCompletedBy(studentId)) {
        throw Exception('Challenge already completed');
      }

      // Mark as completed
      await _firestore.collection('challenges').doc(challengeId).update({
        'completions.$studentId': true,
      });

      // Award XP
      await _gamificationService.addXP(studentId, challenge.xpReward);

      // Check for challenge badges
      await _checkChallengeBadges(studentId);
      
      // Check for weekly challenge badge
      if (challenge.type == 'weekly') {
        await _checkWeeklyChallengeBadge(studentId);
      }
    } catch (e) {
      throw Exception('Failed to complete challenge: $e');
    }
  }

  Future<void> _checkChallengeBadges(String studentId) async {
    try {
      // Check total completed challenges
      final allChallengesSnapshot = await _firestore
          .collection('challenges')
          .where('assignedTo', arrayContains: studentId)
          .get();

      int completedCount = 0;
      for (var doc in allChallengesSnapshot.docs) {
        final challenge = ChallengeModel.fromMap(
          doc.data()..['id'] = doc.id,
        );
        if (challenge.isCompletedBy(studentId)) {
          completedCount++;
        }
      }

      final userDoc = await _firestore.collection('users').doc(studentId).get();
      final userBadges = List<String>.from(userDoc.data()?['badges'] ?? []);

      // Challenge Champion (10 challenges)
      if (completedCount >= 10 && !userBadges.contains('challenge_champion')) {
        await _gamificationService.awardBadge(studentId, 'challenge_champion');
      }
    } catch (e) {
      print('Error checking challenge badges: $e');
    }
  }

  Future<void> _checkWeeklyChallengeBadge(String studentId) async {
    try {
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 7));

      final weeklyChallengesSnapshot = await _firestore
          .collection('challenges')
          .where('type', isEqualTo: 'weekly')
          .where('assignedTo', arrayContains: studentId)
          .where('startDate', isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart))
          .where('startDate', isLessThan: Timestamp.fromDate(weekEnd))
          .get();

      int completedCount = 0;
      for (var doc in weeklyChallengesSnapshot.docs) {
        final challenge = ChallengeModel.fromMap(
          doc.data()..['id'] = doc.id,
        );
        if (challenge.isCompletedBy(studentId)) {
          completedCount++;
        }
      }

      // If all weekly challenges completed, award badge
      if (completedCount == weeklyChallengesSnapshot.docs.length && completedCount > 0) {
        final userDoc = await _firestore.collection('users').doc(studentId).get();
        final userBadges = List<String>.from(userDoc.data()?['badges'] ?? []);

        if (!userBadges.contains('week_warrior')) {
          await _gamificationService.awardBadge(studentId, 'week_warrior');
        }
      }
    } catch (e) {
      // Silently fail - badge check is not critical
      print('Error checking weekly challenge badge: $e');
    }
  }

  Stream<List<ChallengeModel>> getActiveChallengesForStudent(String studentId) {
    return _firestore
        .collection('challenges')
        .where('assignedTo', arrayContains: studentId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChallengeModel.fromMap(
                doc.data() as Map<String, dynamic>..['id'] = doc.id,
              ))
          .where((challenge) => challenge.isActive)
          .toList();
    });
  }

  Stream<List<ChallengeModel>> getChallengesForStudent(String studentId) {
    return _firestore
        .collection('challenges')
        .where('assignedTo', arrayContains: studentId)
        .orderBy('endDate', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChallengeModel.fromMap(
                doc.data() as Map<String, dynamic>..['id'] = doc.id,
              ))
          .toList();
    });
  }
}

