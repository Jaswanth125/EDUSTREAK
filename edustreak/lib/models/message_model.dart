import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String? senderName;
  final String? senderRole;
  final String text;
  final DateTime? timestamp;
  final bool read;
  final List<String> readBy;
  final String type; // 'text', 'image', 'file'
  final String? attachmentUrl;
  final String? attachmentName;
  final int? attachmentSize;
  final String? replyToId;
  final String? replyToText;
  final String? replyToSender;
  final Map<String, List<String>> reactions;
  final bool isEdited;
  final bool isDeleted;
  final String deliveryStatus; // 'sending', 'sent', 'delivered', 'read', 'failed'

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    this.senderName,
    this.senderRole,
    required this.text,
    required this.timestamp,
    required this.read,
    this.readBy = const [],
    this.type = 'text',
    this.attachmentUrl,
    this.attachmentName,
    this.attachmentSize,
    this.replyToId,
    this.replyToText,
    this.replyToSender,
    this.reactions = const {},
    this.isEdited = false,
    this.isDeleted = false,
    this.deliveryStatus = 'sent',
  });

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return null;
    }

    Map<String, List<String>> parseReactions(dynamic val) {
      if (val is Map) {
        final result = <String, List<String>>{};
        val.forEach((k, v) {
          if (v is List) {
            result[k.toString()] = v.map((e) => e.toString()).toList();
          }
        });
        return result;
      }
      return {};
    }

    return MessageModel(
      id: map['id']?.toString() ?? '',
      chatId: map['chatId']?.toString() ?? '',
      senderId: map['senderId']?.toString() ?? '',
      senderName: map['senderName']?.toString(),
      senderRole: map['senderRole']?.toString(),
      text: map['text']?.toString() ?? '',
      timestamp: parseDate(map['timestamp']),
      read: map['read'] == true,
      readBy: (map['readBy'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      type: map['type']?.toString() ?? 'text',
      attachmentUrl: map['attachmentUrl']?.toString(),
      attachmentName: map['attachmentName']?.toString(),
      attachmentSize: (map['attachmentSize'] is num) ? (map['attachmentSize'] as num).toInt() : null,
      replyToId: map['replyToId']?.toString(),
      replyToText: map['replyToText']?.toString(),
      replyToSender: map['replyToSender']?.toString(),
      reactions: parseReactions(map['reactions']),
      isEdited: map['isEdited'] == true,
      isDeleted: map['isDeleted'] == true,
      deliveryStatus: map['deliveryStatus']?.toString() ?? (map['read'] == true ? 'read' : 'delivered'),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      if (senderName != null) 'senderName': senderName,
      if (senderRole != null) 'senderRole': senderRole,
      'text': text,
      'timestamp': timestamp != null ? Timestamp.fromDate(timestamp!) : null,
      'read': read,
      'readBy': readBy,
      'type': type,
      if (attachmentUrl != null) 'attachmentUrl': attachmentUrl,
      if (attachmentName != null) 'attachmentName': attachmentName,
      if (attachmentSize != null) 'attachmentSize': attachmentSize,
      if (replyToId != null) 'replyToId': replyToId,
      if (replyToText != null) 'replyToText': replyToText,
      if (replyToSender != null) 'replyToSender': replyToSender,
      'reactions': reactions,
      'isEdited': isEdited,
      'isDeleted': isDeleted,
      'deliveryStatus': deliveryStatus,
    };
  }

  MessageModel copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? senderName,
    String? senderRole,
    String? text,
    DateTime? timestamp,
    bool? read,
    List<String>? readBy,
    String? type,
    String? attachmentUrl,
    String? attachmentName,
    int? attachmentSize,
    String? replyToId,
    String? replyToText,
    String? replyToSender,
    Map<String, List<String>>? reactions,
    bool? isEdited,
    bool? isDeleted,
    String? deliveryStatus,
  }) {
    return MessageModel(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderRole: senderRole ?? this.senderRole,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      read: read ?? this.read,
      readBy: readBy ?? this.readBy,
      type: type ?? this.type,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      attachmentName: attachmentName ?? this.attachmentName,
      attachmentSize: attachmentSize ?? this.attachmentSize,
      replyToId: replyToId ?? this.replyToId,
      replyToText: replyToText ?? this.replyToText,
      replyToSender: replyToSender ?? this.replyToSender,
      reactions: reactions ?? this.reactions,
      isEdited: isEdited ?? this.isEdited,
      isDeleted: isDeleted ?? this.isDeleted,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
    );
  }
}

