import 'package:flutter/material.dart';
import '../services/seed_data_service.dart';
import '../services/ap_school_pilot_service.dart';

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

  /// Run persistent real AP School Pilot setup for Sri Venkateswara Vidya Mandir
  static Future<Map<String, dynamic>?> runApSchoolPilot(BuildContext? context) async {
    try {
      final service = ApSchoolPilotService();
      final stats = await service.seedApSchoolPilot();

      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('AP School Pilot (Sri Venkateswara Vidya Mandir) seeded: ${stats['studentsCount']} students, ${stats['teachersCount']} teachers!'),
            backgroundColor: Colors.green,
          ),
        );
      }
      return stats;
    } catch (e) {
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error seeding AP School Pilot: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  /// Revert AP School Pilot data safely
  static Future<void> revertApSchoolPilot(BuildContext? context) async {
    try {
      final service = ApSchoolPilotService();
      await service.revertApSchoolPilot();

      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('AP School Pilot data reverted successfully.'),
            backgroundColor: Colors.blueGrey,
          ),
        );
      }
    } catch (e) {
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error reverting AP School Pilot: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

