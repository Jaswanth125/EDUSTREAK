import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String from;
  final String to;
  final String text;
  final DateTime timestamp;
  final List<String> readBy;

  const ChatMessage({
    required this.id,
    required this.from,
    required this.to,
    required this.text,
    required this.timestamp,
    required this.readBy,
  });

  factory ChatMessage.fromDoc(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      from: data['from'] ?? '',
      to: data['to'] ?? '',
      text: data['text'] ?? '',
      timestamp: data['timestamp'] is Timestamp
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      readBy: List<String>.from(data['readBy'] ?? const []),
    );
  }
}

