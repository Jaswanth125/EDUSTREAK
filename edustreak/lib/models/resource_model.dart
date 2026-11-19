import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing a learning resource (textbook, notes, presentation, worksheet, external link)
/// uploaded by teachers and accessible to students of that school, class, and subject.
class ResourceModel {
  final String id;
  final String schoolId;
  final String classId;
  final String className;
  final String? section;
  final String subject;
  final String chapter;
  final String? topic;
  final String title;
  final String description;
  final String resourceType; // 'pdf', 'docx', 'pptx', 'image', 'weblink', 'other'
  final String fileUrl;
  final String? fileSize;
  final String uploadedBy;
  final String uploadedByName;
  final DateTime createdAt;
  final bool isPublished;

  const ResourceModel({
    required this.id,
    required this.schoolId,
    required this.classId,
    required this.className,
    this.section,
    required this.subject,
    required this.chapter,
    this.topic,
    required this.title,
    this.description = '',
    required this.resourceType,
    required this.fileUrl,
    this.fileSize,
    required this.uploadedBy,
    required this.uploadedByName,
    required this.createdAt,
    this.isPublished = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'schoolId': schoolId,
      'classId': classId,
      'className': className,
      'section': section,
      'subject': subject,
      'chapter': chapter,
      'topic': topic,
      'title': title,
      'description': description,
      'resourceType': resourceType,
      'fileUrl': fileUrl,
      'fileSize': fileSize,
      'uploadedBy': uploadedBy,
      'uploadedByName': uploadedByName,
      'createdAt': Timestamp.fromDate(createdAt),
      'isPublished': isPublished,
    };
  }

  factory ResourceModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return ResourceModel(
      id: docId ?? map['id']?.toString() ?? '',
      schoolId: map['schoolId']?.toString() ?? '',
      classId: map['classId']?.toString() ?? '',
      className: map['className']?.toString() ?? '',
      section: map['section']?.toString(),
      subject: map['subject']?.toString() ?? 'General',
      chapter: map['chapter']?.toString() ?? 'Unit 1',
      topic: map['topic']?.toString(),
      title: map['title']?.toString() ?? 'Untitled Resource',
      description: map['description']?.toString() ?? '',
      resourceType: map['resourceType']?.toString() ?? 'pdf',
      fileUrl: map['fileUrl']?.toString() ?? '',
      fileSize: map['fileSize']?.toString(),
      uploadedBy: map['uploadedBy']?.toString() ?? '',
      uploadedByName: map['uploadedByName']?.toString() ?? 'Teacher',
      createdAt: parseDate(map['createdAt']),
      isPublished: map['isPublished'] != false,
    );
  }

  ResourceModel copyWith({
    String? title,
    String? description,
    String? subject,
    String? chapter,
    String? topic,
    String? resourceType,
    String? fileUrl,
    String? fileSize,
    bool? isPublished,
  }) {
    return ResourceModel(
      id: id,
      schoolId: schoolId,
      classId: classId,
      className: className,
      section: section,
      subject: subject ?? this.subject,
      chapter: chapter ?? this.chapter,
      topic: topic ?? this.topic,
      title: title ?? this.title,
      description: description ?? this.description,
      resourceType: resourceType ?? this.resourceType,
      fileUrl: fileUrl ?? this.fileUrl,
      fileSize: fileSize ?? this.fileSize,
      uploadedBy: uploadedBy,
      uploadedByName: uploadedByName,
      createdAt: createdAt,
      isPublished: isPublished ?? this.isPublished,
    );
  }
}
