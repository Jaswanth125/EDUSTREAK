// Quick script to upload badges - Run this in your Flutter app's main or admin screen
// 
// Usage:
// 1. Import this in your admin screen or main.dart
// 2. Call: BadgeService.uploadBadgesToFirestore()
// 3. Or use the UploadBadgesScreen widget

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'lib/services/badge_service.dart';
import 'package:edustreak/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Upload badges directly
  try {
    await BadgeService.uploadBadgesToFirestore();
    print('✅ Badges uploaded successfully!');
  } catch (e) {
    print('❌ Error: $e');
  }
}

