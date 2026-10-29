import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

/// Service to manage badges in Firestore
class BadgeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Calculate level from XP (same formula as GamificationService)
  int _calculateLevelFromXP(int xp) {
    int getXPForLevel(int level) {
      return (level * 100) * (level + 1);
    }
    int level = 1;
    while (getXPForLevel(level) <= xp) {
      level++;
    }
    return level - 1;
  }

  /// Upload badges from JSON file to Firestore
  /// This should be called once to initialize badges
  static Future<void> uploadBadgesToFirestore() async {
    try {
      print('📦 Starting badge upload to Firestore...');
      
      final firestore = FirebaseFirestore.instance;
      
      // Load badges from JSON file in assets directory
      final String jsonString = await rootBundle.loadString('assets/store_badges.json');
      final List<dynamic> badgesJson = jsonDecode(jsonString);
      
      print('✅ Loaded ${badgesJson.length} badges from JSON');
      
      // Convert to List<Map<String, dynamic>>
      final List<Map<String, dynamic>> badges = badgesJson
          .map((badge) => badge as Map<String, dynamic>)
          .toList();
      
      // Get reference to store/badges document
      final badgesRef = firestore.collection('store').doc('badges');
      
      // Upload badges as an array in the main document
      await badgesRef.set({
        'badges': badges,
        'totalCount': badges.length,
        'lastUpdated': FieldValue.serverTimestamp(),
        'version': '1.0',
      }, SetOptions(merge: false));
      
      print('✅ Uploaded badges array to store/badges');
      
      // Also upload as individual documents for easier querying
      final itemsRef = badgesRef.collection('items');
      final batch = firestore.batch();
      int batchCount = 0;
      const int batchLimit = 500;
      
      for (var badge in badges) {
        final badgeId = badge['badgeId'] as String;
        final badgeItemRef = itemsRef.doc(badgeId);
        
        batch.set(badgeItemRef, {
          ...badge,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        batchCount++;
        
        // Firestore batch limit is 500, so commit in batches
        if (batchCount >= batchLimit) {
          await batch.commit();
          print('✅ Committed batch of $batchCount badges');
          batchCount = 0;
        }
      }
      
      // Commit remaining badges
      if (batchCount > 0) {
        await batch.commit();
        print('✅ Committed final batch of $batchCount badges');
      }
      
      print('✅ Successfully uploaded ${badges.length} badges to Firestore!');
      print('📍 Main document: store/badges');
      print('📍 Individual items: store/badges/items/{badgeId}');
      
    } catch (e) {
      print('❌ Error uploading badges: $e');
      rethrow;
    }
  }

  /// Get all badges from Firestore
  Future<List<Map<String, dynamic>>> getBadges() async {
    try {
      final badgesDoc = await _firestore.collection('store').doc('badges').get();
      
      if (!badgesDoc.exists) {
        return [];
      }
      
      final data = badgesDoc.data();
      if (data == null || data['badges'] == null) {
        return [];
      }
      
      final badges = data['badges'] as List;
      return badges.map((badge) => badge as Map<String, dynamic>).toList();
    } catch (e) {
      throw Exception('Failed to get badges: $e');
    }
  }

  /// Get a single badge by ID
  Future<Map<String, dynamic>?> getBadge(String badgeId) async {
    try {
      final badgeDoc = await _firestore
          .collection('store')
          .doc('badges')
          .collection('items')
          .doc(badgeId)
          .get();
      
      if (!badgeDoc.exists) {
        return null;
      }
      
      return badgeDoc.data();
    } catch (e) {
      throw Exception('Failed to get badge: $e');
    }
  }

  /// Redeem a badge for a user
  Future<void> redeemBadge(String userId, String badgeId) async {
    try {
      // Get badge details
      final badge = await getBadge(badgeId);
      if (badge == null) {
        throw Exception('Badge not found');
      }

      final price = badge['price'] as int;

      // Get user data
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        throw Exception('User not found');
      }

      final userData = userDoc.data()!;
      // Use XP consistently (not points field)
      final currentXP = (userData['xp'] as num?)?.toInt() ?? 0;
      
      // Ensure XP is not negative (fix any data issues)
      final safeXP = currentXP < 0 ? 0 : currentXP;

      // Check if user has enough points
      if (safeXP < price) {
        throw Exception('Insufficient points. Need $price, have $safeXP');
      }

      // Check if badge already redeemed
      // Handle badges as either List or Map (for backward compatibility)
      final badgesData = userData['badges'];
      bool alreadyRedeemed = false;
      
      if (badgesData is List) {
        // Badges stored as List<String>
        final badgesList = List<String>.from(badgesData);
        alreadyRedeemed = badgesList.contains(badgeId);
      } else if (badgesData is Map) {
        // Badges stored as Map<String, bool> (legacy format)
        final badgesMap = Map<String, dynamic>.from(badgesData);
        alreadyRedeemed = badgesMap[badgeId] == true;
      }
      
      if (alreadyRedeemed) {
        throw Exception('Badge already redeemed');
      }

      // Deduct points and mark badge as redeemed
      // Use arrayUnion to add badge to list (works for both List and Map formats)
      final badgesDataValue = userData['badges'];
      
      // Calculate new XP (ensure it doesn't go negative)
      final newXP = safeXP - price;
      final newLevel = _calculateLevelFromXP(newXP);
      
      if (badgesDataValue is List) {
        // Update as List
        final badgesList = List<String>.from(badgesDataValue);
        badgesList.add(badgeId);
        await _firestore.collection('users').doc(userId).update({
          'xp': newXP, // Update XP directly (not increment to avoid negative values)
          'level': newLevel, // Update level based on new XP
          'badges': badgesList,
        });
      } else {
        // Update as Map (legacy) or create new List
        await _firestore.collection('users').doc(userId).update({
          'xp': newXP, // Update XP directly
          'level': newLevel, // Update level based on new XP
          'badges': FieldValue.arrayUnion([badgeId]), // Convert to List format
        });
      }

      print('✅ Badge $badgeId redeemed for user $userId');
    } catch (e) {
      throw Exception('Failed to redeem badge: $e');
    }
  }

  /// Get user's redeemed badges
  Future<Map<String, bool>> getUserBadges(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        return {};
      }

      final userData = userDoc.data()!;
      final badgesData = userData['badges'];
      
      if (badgesData == null) {
        return {};
      }

      // Handle badges as either List or Map (for backward compatibility)
      if (badgesData is List) {
        // Badges stored as List<String> - convert to Map<String, bool>
        final badgesList = List<String>.from(badgesData);
        return Map<String, bool>.fromEntries(
          badgesList.map((badgeId) => MapEntry(badgeId, true)),
        );
      } else if (badgesData is Map) {
        // Badges stored as Map<String, bool> (legacy format)
        final badgesMap = Map<String, dynamic>.from(badgesData);
        return badgesMap.map((key, value) => MapEntry(key, value == true));
      }

      return {};
    } catch (e) {
      throw Exception('Failed to get user badges: $e');
    }
  }
}

