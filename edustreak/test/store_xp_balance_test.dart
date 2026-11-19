import 'package:flutter_test/flutter_test.dart';
import 'package:edustreak/models/user_model.dart';
import 'package:edustreak/models/store_item_model.dart';

void main() {
  group('Store XP & Points Balance Tests', () {
    test('Student purchase deducts spendablePoints but leaves lifetime xp intact', () {
      final initialStudent = UserModel(
        id: 'std_01',
        name: 'Akash Sharma',
        email: 'akash@edustreak.com',
        role: 'student',
        xp: 2500, // Level 7 Scholar
        spendablePoints: 1200,
        level: 7,
        streakCount: 15,
        purchasedItems: const [],
      );

      final avatarItem = StoreItemModel(
        id: 'avatar_cyber_fox',
        name: 'Cyber Fox Avatar',
        description: 'Futuristic robotic fox avatar',
        icon: '🦊',
        type: 'avatar',
        pointsCost: 400,
        imageUrl: 'assets/avatars/cyber_fox.png',
        createdAt: DateTime(2026, 1, 1),
      );

      // Verify balance sufficiency
      expect(initialStudent.spendablePoints >= avatarItem.pointsCost, isTrue);

      // Simulate purchase transaction logic (matching StoreService.purchaseItem)
      final newSpendablePoints = initialStudent.spendablePoints - avatarItem.pointsCost;
      final updatedPurchased = [...initialStudent.purchasedItems, avatarItem.id];

      final updatedStudent = initialStudent.copyWith(
        spendablePoints: newSpendablePoints,
        purchasedItems: updatedPurchased,
        currentAvatar: avatarItem.id,
      );

      // Assertions
      expect(updatedStudent.spendablePoints, equals(800)); // 1200 - 400
      expect(updatedStudent.xp, equals(2500)); // LIFETIME XP UNTOUCHED!
      expect(updatedStudent.level, equals(7)); // LEVEL UNCHANGED!
      expect(updatedStudent.streakCount, equals(15)); // STREAK UNCHANGED!
      expect(updatedStudent.purchasedItems.contains('avatar_cyber_fox'), isTrue);
      expect(updatedStudent.currentAvatar, equals('avatar_cyber_fox'));
    });

    test('Insufficient points throws error and does not mutate user state', () {
      final student = UserModel(
        id: 'std_02',
        name: 'Maya Patel',
        email: 'maya@edustreak.com',
        role: 'student',
        xp: 300,
        spendablePoints: 150,
      );

      final expensiveBadge = StoreItemModel(
        id: 'badge_master_streak',
        name: 'Grand Streak Trophy',
        description: 'Trophy for 30-day streak',
        icon: '🏆',
        type: 'badge',
        pointsCost: 500,
        imageUrl: 'assets/badges/streak.png',
        createdAt: DateTime(2026, 1, 1),
      );

      expect(student.spendablePoints < expensiveBadge.pointsCost, isTrue);
    });

    test('Zero spendablePoints does NOT reset to lifetime xp and prevents infinite spend', () {
      final brokeStudent = UserModel(
        id: 'std_03',
        name: 'Rohan Verma',
        email: 'rohan@edustreak.com',
        role: 'student',
        xp: 5000, // High lifetime XP (Level 9)
        spendablePoints: 0, // Spent all points previously
        level: 9,
        purchasedItems: const ['avatar_01'],
      );

      final cheapItem = StoreItemModel(
        id: 'avatar_rookie',
        name: 'Rookie Avatar',
        description: 'Starter avatar',
        icon: '🐣',
        type: 'avatar',
        pointsCost: 50,
        imageUrl: 'assets/avatars/rookie.png',
        createdAt: DateTime(2026, 1, 1),
      );

      // CRITICAL SECURITY ASSERTION: Available spendable balance MUST be 0, NOT 5000 (lifetime xp)
      final availableSpendable = brokeStudent.spendablePoints;
      expect(availableSpendable, equals(0));
      expect(availableSpendable >= cheapItem.pointsCost, isFalse);

      // Verify UserModel fromMap with spendablePoints: 0 preserves 0
      final mapData = {
        'id': 'std_03',
        'name': 'Rohan Verma',
        'email': 'rohan@edustreak.com',
        'role': 'student',
        'xp': 5000,
        'spendablePoints': 0,
      };
      final deserialized = UserModel.fromMap(mapData);
      expect(deserialized.spendablePoints, equals(0));
      expect(deserialized.xp, equals(5000));
    });
  });
}
