import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/resource_model.dart';

class ResourceService {
  FirebaseFirestore? _customFirestore;
  FirebaseStorage? _customStorage;

  ResourceService([this._customFirestore, this._customStorage]);

  FirebaseFirestore? get _firestore {
    if (_customFirestore != null) return _customFirestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  FirebaseStorage? get _storage {
    if (_customStorage != null) return _customStorage;
    try {
      return FirebaseStorage.instance;
    } catch (_) {
      return null;
    }
  }

  CollectionReference<Map<String, dynamic>>? _collection() {
    return _firestore?.collection('learning_resources');
  }

  /// Create a new learning resource document
  Future<String> createResource(ResourceModel resource) async {
    final col = _collection();
    if (col == null) return '';
    final docRef = col.doc();
    final toSave = resource.copyWith().toMap()..['id'] = docRef.id;
    await docRef.set(toSave);
    return docRef.id;
  }

  /// Update resource metadata
  Future<void> updateResource(String resourceId, Map<String, dynamic> data) async {
    await _collection()?.doc(resourceId).update(data);
  }

  /// Toggle published state
  Future<void> togglePublishStatus(String resourceId, bool isPublished) async {
    await _collection()?.doc(resourceId).update({'isPublished': isPublished});
  }

  /// Delete resource
  Future<void> deleteResource(String resourceId) async {
    await _collection()?.doc(resourceId).delete();
  }

  /// Real-time stream of resources for a teacher (filtered by school and teacher ID)
  Stream<List<ResourceModel>> getResourcesForTeacher({
    required String schoolId,
    required String teacherId,
  }) {
    final col = _collection();
    if (col == null) return Stream.value(<ResourceModel>[]);
    Query<Map<String, dynamic>> query = col;
    if (schoolId.isNotEmpty) {
      query = query.where('schoolId', isEqualTo: schoolId);
    }
    if (teacherId.isNotEmpty) {
      query = query.where('uploadedBy', isEqualTo: teacherId);
    }

    return query.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ResourceModel.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Real-time stream of resources for a class (for students or class views)
  Stream<List<ResourceModel>> getResourcesForClass({
    required String schoolId,
    required String classId,
    String? subject,
  }) {
    final col = _collection();
    if (col == null) return Stream.value(<ResourceModel>[]);

    Query<Map<String, dynamic>> query = col
        .where('classId', isEqualTo: classId)
        .where('isPublished', isEqualTo: true);

    if (schoolId.isNotEmpty) {
      query = query.where('schoolId', isEqualTo: schoolId);
    }
    if (subject != null && subject.isNotEmpty && subject != 'All') {
      query = query.where('subject', isEqualTo: subject);
    }

    return query.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ResourceModel.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Upload file to Firebase Storage
  Future<String> uploadResourceFile({
    required Uint8List fileBytes,
    required String fileName,
    required String schoolId,
  }) async {
    final storage = _storage;
    if (storage == null) return '';
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final sanitizedName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final storagePath = 'learning_resources/$schoolId/${timestamp}_$sanitizedName';
    final ref = storage.ref().child(storagePath);

    final uploadTask = await ref.putData(fileBytes);
    return await uploadTask.ref.getDownloadURL();
  }
}
