import 'package:cloud_firestore/cloud_firestore.dart';

class SupportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch User Guide
  Future<String> getUserGuide() async {
    try {
      final doc = await _firestore.collection('support_info').doc('user_guide').get();
      if (doc.exists && doc.data() != null) {
        return doc.data()!['content'] ?? 'User guide content not available.';
      }
      return 'User guide content not available.';
    } catch (e) {
      return 'Error loading user guide: $e';
    }
  }

  // Fetch FAQs
  Future<List<Map<String, dynamic>>> getFAQs() async {
    try {
      final doc = await _firestore.collection('support_info').doc('faqs').get();
      if (doc.exists && doc.data() != null) {
        final faqs = doc.data()!['faqs'];
        if (faqs != null && faqs is List) {
          return List<Map<String, dynamic>>.from(faqs);
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Fetch Contact Support
  Future<List<Map<String, dynamic>>> getContacts() async {
    try {
      final doc = await _firestore.collection('support_info').doc('contact_support').get();
      if (doc.exists && doc.data() != null) {
        final contacts = doc.data()!['contacts'];
        if (contacts != null && contacts is List) {
          return List<Map<String, dynamic>>.from(contacts);
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}

