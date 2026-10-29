import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

/// Service to manage avatars in Firestore
class AvatarService {
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

  /// Upload avatars from JSON file to Firestore
  /// This should be called once to initialize avatars
  /// Any authenticated user can initialize avatars (first time only)
  static Future<void> uploadAvatarsToFirestore() async {
    try {
      print('📦 Starting avatar upload to Firestore...');
      
      final firestore = FirebaseFirestore.instance;
      
      // Check if avatars already exist
      final avatarsDoc = await firestore.collection('store').doc('avatars').get();
      if (avatarsDoc.exists) {
        print('⚠️  Avatars already exist in Firestore. Skipping upload.');
        return; // Avatars already initialized
      }
      
      // Load avatars from JSON file in assets directory
      final String jsonString = await rootBundle.loadString('assets/store_avatars.json');
      final List<dynamic> avatarsJson = jsonDecode(jsonString);
      
      print('✅ Loaded ${avatarsJson.length} avatars from JSON');
      
      // Convert to List<Map<String, dynamic>>
      final List<Map<String, dynamic>> avatars = avatarsJson
          .map((avatar) => avatar as Map<String, dynamic>)
          .toList();
      
      // Get reference to store/avatars document
      final avatarsRef = firestore.collection('store').doc('avatars');
      
      // Create main document first (this allows subcollection writes)
      await avatarsRef.set({
        'avatars': avatars,
        'totalCount': avatars.length,
        'lastUpdated': FieldValue.serverTimestamp(),
        'version': '1.0',
      }, SetOptions(merge: false));
      
      print('✅ Uploaded avatars array to store/avatars');
      
      // Also upload as individual documents for easier querying
      // Create items in subcollection (parent document must exist first)
      final itemsRef = avatarsRef.collection('items');
      WriteBatch? batch = firestore.batch();
      int batchCount = 0;
      const int batchLimit = 500;
      
      for (var avatar in avatars) {
        final avatarId = avatar['avatarId'] as String;
        final avatarItemRef = itemsRef.doc(avatarId);
        
        batch!.set(avatarItemRef, {
          ...avatar,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        batchCount++;
        
        // Firestore batch limit is 500, so commit in batches
        if (batchCount >= batchLimit) {
          await batch.commit();
          print('✅ Committed batch of $batchCount avatars');
          // Create new batch for next items
          batch = firestore.batch();
          batchCount = 0;
        }
      }
      
      // Commit remaining avatars
      if (batchCount > 0 && batch != null) {
        await batch.commit();
        print('✅ Committed final batch of $batchCount avatars');
      }
      
      print('✅ Successfully uploaded ${avatars.length} avatars to Firestore!');
      print('📍 Main document: store/avatars');
      print('📍 Individual items: store/avatars/items/{avatarId}');
      
    } catch (e) {
      print('❌ Error uploading avatars: $e');
      // Provide more helpful error messages
      if (e.toString().contains('PERMISSION_DENIED') || 
          e.toString().contains('permission')) {
        throw Exception('Permission denied. Make sure Firestore rules allow avatar creation, or contact admin.');
      } else if (e.toString().contains('assets') || 
                 e.toString().contains('Unable to load asset')) {
        throw Exception('Avatar data file not found. Please check that assets/store_avatars.json exists.');
      }
      rethrow;
    }
  }

  /// Get all avatars from Firestore
  Future<List<Map<String, dynamic>>> getAvatars() async {
    try {
      final avatarsDoc = await _firestore.collection('store').doc('avatars').get();
      
      if (!avatarsDoc.exists) {
        return [];
      }
      
      final data = avatarsDoc.data();
      if (data == null || data['avatars'] == null) {
        return [];
      }
      
      final avatars = data['avatars'] as List;
      return avatars.map((avatar) => avatar as Map<String, dynamic>).toList();
    } catch (e) {
      throw Exception('Failed to get avatars: $e');
    }
  }

  /// Get a single avatar by ID
  Future<Map<String, dynamic>?> getAvatar(String avatarId) async {
    try {
      final avatarDoc = await _firestore
          .collection('store')
          .doc('avatars')
          .collection('items')
          .doc(avatarId)
          .get();
      
      if (!avatarDoc.exists) {
        return null;
      }
      
      return avatarDoc.data();
    } catch (e) {
      throw Exception('Failed to get avatar: $e');
    }
  }

  /// Redeem an avatar for a user
  Future<void> redeemAvatar(String userId, String avatarId) async {
    try {
      // Get avatar details
      final avatar = await getAvatar(avatarId);
      if (avatar == null) {
        throw Exception('Avatar not found');
      }

      final price = avatar['price'] as int;

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

      // Check if avatar already redeemed
      // Handle avatars as either List or Map (for backward compatibility)
      final avatarsData = userData['redeemedAvatars'];
      bool alreadyRedeemed = false;
      
      if (avatarsData is List) {
        // Avatars stored as List<String>
        final avatarsList = List<String>.from(avatarsData);
        alreadyRedeemed = avatarsList.contains(avatarId);
      } else if (avatarsData is Map) {
        // Avatars stored as Map<String, bool> (legacy format)
        final avatarsMap = Map<String, dynamic>.from(avatarsData);
        alreadyRedeemed = avatarsMap[avatarId] == true;
      }
      
      if (alreadyRedeemed) {
        throw Exception('Avatar already redeemed');
      }

      // Deduct points and mark avatar as redeemed
      // Use arrayUnion to add avatar to list (works for both List and Map formats)
      final avatarsDataValue = userData['redeemedAvatars'];
      
      // Calculate new XP (ensure it doesn't go negative)
      final newXP = safeXP - price;
      final newLevel = _calculateLevelFromXP(newXP);
      
      // Get avatar icon/URL for profile picture
      final avatarIcon = avatar['icon'] as String? ?? avatar['iconUrl'] as String? ?? '';
      
      if (avatarsDataValue is List) {
        // Update as List
        final avatarsList = List<String>.from(avatarsDataValue);
        avatarsList.add(avatarId);
        await _firestore.collection('users').doc(userId).update({
          'xp': newXP, // Update XP directly (not increment to avoid negative values)
          'level': newLevel, // Update level based on new XP
          'redeemedAvatars': avatarsList,
          'currentAvatar': avatarId, // Set as current avatar
          'profileImageUrl': avatarIcon.isNotEmpty && (avatarIcon.startsWith('http') || avatarIcon.startsWith('https'))
              ? avatarIcon
              : null, // Set profile image if it's a URL, otherwise keep null
        });
      } else {
        // Update as Map (legacy) or create new List
        await _firestore.collection('users').doc(userId).update({
          'xp': newXP, // Update XP directly
          'level': newLevel, // Update level based on new XP
          'redeemedAvatars': FieldValue.arrayUnion([avatarId]), // Convert to List format
          'currentAvatar': avatarId, // Set as current avatar
          'profileImageUrl': avatarIcon.isNotEmpty && (avatarIcon.startsWith('http') || avatarIcon.startsWith('https'))
              ? avatarIcon
              : null, // Set profile image if it's a URL, otherwise keep null
        });
      }

      print('✅ Avatar $avatarId redeemed for user $userId and set as profile picture');
    } catch (e) {
      throw Exception('Failed to redeem avatar: $e');
    }
  }

  /// Get user's redeemed avatars
  Future<Map<String, bool>> getUserAvatars(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        return {};
      }

      final userData = userDoc.data()!;
      final avatarsData = userData['redeemedAvatars'];
      
      if (avatarsData == null) {
        return {};
      }

      // Handle avatars as either List or Map (for backward compatibility)
      if (avatarsData is List) {
        // Avatars stored as List<String> - convert to Map<String, bool>
        final avatarsList = List<String>.from(avatarsData);
        return Map<String, bool>.fromEntries(
          avatarsList.map((avatarId) => MapEntry(avatarId, true)),
        );
      } else if (avatarsData is Map) {
        // Avatars stored as Map<String, bool> (legacy format)
        final avatarsMap = Map<String, dynamic>.from(avatarsData);
        return avatarsMap.map((key, value) => MapEntry(key, value == true));
      }

      return {};
    } catch (e) {
      throw Exception('Failed to get user avatars: $e');
    }
  }
}

