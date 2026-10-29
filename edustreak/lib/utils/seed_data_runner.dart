import 'package:flutter/material.dart';
import '../services/seed_data_service.dart';

/// Run this to seed the database with example data
/// Call from a button in admin dashboard or run once on app initialization
class SeedDataRunner {
  static Future<void> runSeedData(BuildContext? context) async {
    try {
      final service = SeedDataService();
      await service.seedAllData();
      
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Seed data created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error seeding data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

