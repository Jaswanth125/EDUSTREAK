import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Utility to upload badges to Firestore
/// Run this once to populate the store/badges collection
class BadgeUploader {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Upload badges from JSON file to Firestore
  static Future<void> uploadBadges() async {
    try {
      print('📦 Starting badge upload...');
      
      // Load badges from JSON file
      final String jsonString = await rootBundle.loadString('assets/store_badges.json');
      final List<dynamic> badges = jsonDecode(jsonString);
      
      print('✅ Loaded ${badges.length} badges from JSON');
      
      // Get reference to store/badges document
      final badgesRef = _firestore.collection('store').doc('badges');
      
      // Check if badges already exist
      final badgesDoc = await badgesRef.get();
      if (badgesDoc.exists) {
        print('⚠️  Badges already exist in Firestore. Updating...');
      }
      
      // Upload badges as an array in a single document
      await badgesRef.set({
        'badges': badges,
        'totalCount': badges.length,
        'lastUpdated': FieldValue.serverTimestamp(),
        'version': '1.0',
      }, SetOptions(merge: false));
      
      print('✅ Successfully uploaded ${badges.length} badges to Firestore!');
      print('📍 Location: store/badges');
      
      // Also upload as individual documents for easier querying
      final batch = _firestore.batch();
      int batchCount = 0;
      
      for (var badge in badges) {
        final badgeId = badge['badgeId'] as String;
        final badgeItemRef = badgesRef.collection('items').doc(badgeId);
        
        batch.set(badgeItemRef, {
          ...badge,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        batchCount++;
        
        // Firestore batch limit is 500, so commit in batches
        if (batchCount >= 500) {
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
      
      print('✅ All badges uploaded successfully!');
      print('📊 Total badges: ${badges.length}');
      print('📍 Main document: store/badges');
      print('📍 Individual items: store/badges/items/{badgeId}');
      
    } catch (e) {
      print('❌ Error uploading badges: $e');
      rethrow;
    }
  }

  /// Upload badges from a List directly (for programmatic use)
  static Future<void> uploadBadgesFromList(List<Map<String, dynamic>> badges) async {
    try {
      print('📦 Starting badge upload from list...');
      
      final badgesRef = _firestore.collection('store').doc('badges');
      
      // Upload as array
      await badgesRef.set({
        'badges': badges,
        'totalCount': badges.length,
        'lastUpdated': FieldValue.serverTimestamp(),
        'version': '1.0',
      }, SetOptions(merge: false));
      
      // Upload as individual documents
      final batch = _firestore.batch();
      int batchCount = 0;
      
      for (var badge in badges) {
        final badgeId = badge['badgeId'] as String;
        final badgeItemRef = badgesRef.collection('items').doc(badgeId);
        
        batch.set(badgeItemRef, {
          ...badge,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        batchCount++;
        
        if (batchCount >= 500) {
          await batch.commit();
          batchCount = 0;
        }
      }
      
      if (batchCount > 0) {
        await batch.commit();
      }
      
      print('✅ Successfully uploaded ${badges.length} badges!');
    } catch (e) {
      print('❌ Error uploading badges: $e');
      rethrow;
    }
  }
}

