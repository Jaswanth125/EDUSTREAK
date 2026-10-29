import 'package:cloud_firestore/cloud_firestore.dart';

class ChallengeModel {
  final String id;
  final String title;
  final String description;
  final String type; // daily, weekly
  final int xpReward;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> assignedTo; // student IDs
  final Map<String, bool> completions; // studentId -> completed

  ChallengeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.xpReward,
    required this.startDate,
    required this.endDate,
    required this.assignedTo,
    this.completions = const {},
  });

  factory ChallengeModel.fromMap(Map<String, dynamic> map) {
    return ChallengeModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      type: map['type'] ?? 'daily',
      xpReward: map['xpReward'] ?? 50,
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: (map['endDate'] as Timestamp).toDate(),
      assignedTo: List<String>.from(map['assignedTo'] ?? []),
      completions: Map<String, bool>.from(map['completions'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type,
      'xpReward': xpReward,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'assignedTo': assignedTo,
      'completions': completions,
    };
  }

  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  bool isCompletedBy(String studentId) {
    return completions[studentId] ?? false;
  }
}

