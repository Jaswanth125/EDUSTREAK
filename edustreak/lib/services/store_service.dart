import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/store_item_model.dart';
import '../models/user_model.dart';
import 'gamification_service.dart';

class StoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GamificationService _gamificationService = GamificationService();

  Stream<List<StoreItemModel>> getStoreItems() {
    return _firestore
        .collection('store')
        .where('isActive', isEqualTo: true)
        .orderBy('pointsCost', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => StoreItemModel.fromMap(doc.data()..['id'] = doc.id))
          .toList();
    });
  }

  /// Get badges from store/badges
  Stream<List<Map<String, dynamic>>> getBadges() {
    return _firestore
        .collection('store')
        .doc('badges')
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return <Map<String, dynamic>>[];
      }
      final data = snapshot.data()!;
      if (data['badges'] == null) {
        return <Map<String, dynamic>>[];
      }
      final badges = data['badges'] as List;
      return badges.map((badge) => badge as Map<String, dynamic>).toList();
    });
  }

  /// Get avatars from store/avatars
  Stream<List<Map<String, dynamic>>> getAvatars() {
    return _firestore
        .collection('store')
        .doc('avatars')
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return <Map<String, dynamic>>[];
      }
      final data = snapshot.data()!;
      if (data['avatars'] == null) {
        return <Map<String, dynamic>>[];
      }
      final avatars = data['avatars'] as List;
      return avatars.map((avatar) => avatar as Map<String, dynamic>).toList();
    });
  }

  Future<void> purchaseItem(String userId, String itemId) async {
    try {
      // Get item details
      final itemDoc = await _firestore.collection('store').doc(itemId).get();
      if (!itemDoc.exists) throw Exception('Item not found');

      final item = StoreItemModel.fromMap(itemDoc.data()!..['id'] = itemDoc.id);

      // Get user data
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) throw Exception('User not found');

      final user = UserModel.fromMap(userDoc.data()!..['id'] = userDoc.id);

      // Check if user has enough points
      if (user.xp < item.pointsCost) {
        throw Exception('Insufficient points. Need ${item.pointsCost}, have ${user.xp}');
      }

      // Check if already purchased
      final purchasedItems = List<String>.from(userDoc.data()?['purchasedItems'] ?? []);
      if (purchasedItems.contains(itemId)) {
        throw Exception('Item already purchased');
      }

      // Deduct points and add item
      purchasedItems.add(itemId);
      final isFirstPurchase = purchasedItems.length == 1;
      
      await _firestore.collection('users').doc(userId).update({
        'xp': user.xp - item.pointsCost,
        'purchasedItems': purchasedItems,
        'currentAvatar': itemId, // Set as current avatar
      });
      
      // Award badges for purchases
      if (isFirstPurchase) {
        await _gamificationService.awardBadge(userId, 'explorer');
      }
      if (purchasedItems.length >= 5) {
        await _gamificationService.awardBadge(userId, 'collector');
      }
    } catch (e) {
      throw Exception('Failed to purchase item: $e');
    }
  }

  Future<List<String>> getPurchasedItems(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return [];
      return List<String>.from(userDoc.data()?['purchasedItems'] ?? []);
    } catch (e) {
      throw Exception('Failed to get purchased items: $e');
    }
  }

  Future<void> setCurrentAvatar(String userId, String itemId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) throw Exception('User not found');

      final purchasedItems = List<String>.from(userDoc.data()?['purchasedItems'] ?? []);
      if (!purchasedItems.contains(itemId)) {
        throw Exception('Item not purchased');
      }

      await _firestore.collection('users').doc(userId).update({
        'currentAvatar': itemId,
      });
    } catch (e) {
      throw Exception('Failed to set avatar: $e');
    }
  }

  /// Set current avatar from redeemed avatars
  Future<void> setCurrentAvatarFromRedeemed(String userId, String avatarId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) throw Exception('User not found');

      final redeemedAvatars = List<String>.from(userDoc.data()?['redeemedAvatars'] ?? []);
      if (!redeemedAvatars.contains(avatarId)) {
        throw Exception('Avatar not redeemed');
      }

      await _firestore.collection('users').doc(userId).update({
        'currentAvatar': avatarId,
      });
    } catch (e) {
      throw Exception('Failed to set avatar: $e');
    }
  }

  Future<void> initializeStore() async {
    try {
      // Check if store items already exist
      final snapshot = await _firestore.collection('store').limit(1).get();
      if (snapshot.docs.isNotEmpty) return; // Store already initialized

      // Add default store items
      final items = StoreItemModel.getDefaultItems();
      final batch = _firestore.batch();

      for (var item in items) {
        final ref = _firestore.collection('store').doc(item.id);
        batch.set(ref, item.toMap());
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to initialize store: $e');
    }
  }
}

