import 'package:cloud_firestore/cloud_firestore.dart';

/// Immutable record of an XP earn or spend event.
/// Preserves the strict separation between Lifetime XP and Spendable XP.
class XpTransactionModel {
  final String id;
  final String userId;
  final String? schoolId;
  final int amount; // Positive for earn (+XP), negative for spend (-XP)
  final String type; // 'earn', 'spend', 'reward', 'refund'
  final String reason; // e.g. 'Homework submission', 'Practice Arena MCQ', 'Avatar purchase: 🔥 Fire'
  final int balanceAfter; // Spendable points balance after transaction
  final DateTime timestamp;

  const XpTransactionModel({
    required this.id,
    required this.userId,
    this.schoolId,
    required this.amount,
    required this.type,
    required this.reason,
    required this.balanceAfter,
    required this.timestamp,
  });

  factory XpTransactionModel.fromMap(Map<String, dynamic> map, {String id = ''}) {
    DateTime parsedTime = DateTime.now();
    if (map['timestamp'] != null) {
      if (map['timestamp'] is Timestamp) {
        parsedTime = (map['timestamp'] as Timestamp).toDate();
      } else if (map['timestamp'] is DateTime) {
        parsedTime = map['timestamp'] as DateTime;
      } else if (map['timestamp'] is String) {
        parsedTime = DateTime.tryParse(map['timestamp']) ?? DateTime.now();
      }
    }

    return XpTransactionModel(
      id: id.isNotEmpty ? id : (map['id'] ?? ''),
      userId: map['userId'] ?? '',
      schoolId: map['schoolId'],
      amount: (map['amount'] as num?)?.toInt() ?? 0,
      type: map['type'] ?? 'earn',
      reason: map['reason'] ?? '',
      balanceAfter: (map['balanceAfter'] as num?)?.toInt() ?? 0,
      timestamp: parsedTime,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'schoolId': schoolId,
      'amount': amount,
      'type': type,
      'reason': reason,
      'balanceAfter': balanceAfter,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
