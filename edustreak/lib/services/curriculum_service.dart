import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/curriculum_model.dart';
import 'audit_service.dart';

class CurriculumService {
  final FirebaseFirestore? _customFirestore;
  FirebaseFirestore? get _firestoreOrNull {
    if (_customFirestore != null) return _customFirestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  FirebaseFirestore get _firestore => _firestoreOrNull ?? FirebaseFirestore.instance;
  bool get _isFirebaseAvailable => _firestoreOrNull != null;
  final AuditService _auditService = AuditService();

  CurriculumService({FirebaseFirestore? firestore}) : _customFirestore = firestore;

  CollectionReference<Map<String, dynamic>> get _templatesRef =>
      _firestore.collection('curriculum_templates');

  /// Stream of all active curriculum templates (AP State Govt, CBSE, Private)
  Stream<List<CurriculumTemplateModel>> getTemplatesStream() {
    if (!_isFirebaseAvailable) {
      return Stream.value([]);
    }
    return _templatesRef.snapshots().map((snapshot) => snapshot.docs.map((doc) {
          final data = doc.data();
          final subjectsRaw = (data['standardSubjects'] as List<dynamic>?) ?? [];
          final subjects = subjectsRaw
              .map((s) => SubjectCurriculumModel.fromMap(s as Map<String, dynamic>))
              .toList();

          return CurriculumTemplateModel(
            id: doc.id,
            name: data['name'] ?? '',
            boardCode: data['boardCode'] ?? '',
            description: data['description'] ?? '',
            adoptedSchoolsCount: (data['adoptedSchoolsCount'] as num?)?.toInt() ?? 0,
            isActive: data['isActive'] ?? true,
            standardSubjects: subjects,
          );
        }).toList());
  }

  /// Get specific template by ID
  Future<CurriculumTemplateModel?> getTemplate(String templateId) async {
    try {
      final doc = await _templatesRef.doc(templateId).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final subjectsRaw = (data['standardSubjects'] as List<dynamic>?) ?? [];
        final subjects = subjectsRaw
            .map((s) => SubjectCurriculumModel.fromMap(s as Map<String, dynamic>))
            .toList();

        return CurriculumTemplateModel(
          id: doc.id,
          name: data['name'] ?? '',
          boardCode: data['boardCode'] ?? '',
          description: data['description'] ?? '',
          adoptedSchoolsCount: (data['adoptedSchoolsCount'] as num?)?.toInt() ?? 0,
          isActive: data['isActive'] ?? true,
          standardSubjects: subjects,
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Add a subject to a global curriculum template
  Future<void> addSubjectToTemplate(String templateId, SubjectCurriculumModel subject) async {
    final doc = await _templatesRef.doc(templateId).get();
    if (!doc.exists) return;

    final data = doc.data()!;
    final subjects = (data['standardSubjects'] as List<dynamic>?)
            ?.map((s) => SubjectCurriculumModel.fromMap(s as Map<String, dynamic>))
            .toList() ??
        [];

    subjects.add(subject);

    await _templatesRef.doc(templateId).update({
      'standardSubjects': subjects.map((s) => s.toMap()).toList(),
    });

    await _auditService.logAction(
      action: 'CURRICULUM_SUBJECT_ADDED',
      targetType: 'template',
      targetId: templateId,
      details: {'subjectId': subject.id, 'subjectName': subject.name},
    );
  }

  /// Update subject or chapters inside a template
  Future<void> updateTemplateSubject(String templateId, SubjectCurriculumModel subject) async {
    final doc = await _templatesRef.doc(templateId).get();
    if (!doc.exists) return;

    final data = doc.data()!;
    final subjects = (data['standardSubjects'] as List<dynamic>?)
            ?.map((s) => SubjectCurriculumModel.fromMap(s as Map<String, dynamic>))
            .toList() ??
        [];

    final idx = subjects.indexWhere((s) => s.id == subject.id);
    if (idx != -1) {
      subjects[idx] = subject;
    } else {
      subjects.add(subject);
    }

    await _templatesRef.doc(templateId).update({
      'standardSubjects': subjects.map((s) => s.toMap()).toList(),
    });

    await _auditService.logAction(
      action: 'CURRICULUM_SUBJECT_UPDATED',
      targetType: 'template',
      targetId: templateId,
      details: {'subjectId': subject.id, 'chaptersCount': subject.chapters.length},
    );
  }

  /// Delete a subject from a template
  Future<void> deleteTemplateSubject(String templateId, String subjectId) async {
    final doc = await _templatesRef.doc(templateId).get();
    if (!doc.exists) return;

    final data = doc.data()!;
    final subjects = (data['standardSubjects'] as List<dynamic>?)
            ?.map((s) => SubjectCurriculumModel.fromMap(s as Map<String, dynamic>))
            .toList() ??
        [];

    subjects.removeWhere((s) => s.id == subjectId);

    await _templatesRef.doc(templateId).update({
      'standardSubjects': subjects.map((s) => s.toMap()).toList(),
    });

    await _auditService.logAction(
      action: 'CURRICULUM_SUBJECT_DELETED',
      targetType: 'template',
      targetId: templateId,
      details: {'subjectId': subjectId},
    );
  }

  // ─── PRIVATE SCHOOL AUTONOMOUS CURRICULUM ISOLATION ───────────────────────

  CollectionReference<Map<String, dynamic>> _privateCurriculumRef(String schoolId) =>
      _firestore.collection('schools').doc(schoolId).collection('curriculum');

  /// Stream of subjects for an autonomous private school
  Stream<List<SubjectCurriculumModel>> getPrivateSchoolCurriculumStream(String schoolId) {
    if (!_isFirebaseAvailable) {
      return Stream.value([]);
    }
    return _privateCurriculumRef(schoolId).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => SubjectCurriculumModel.fromMap(doc.data()))
          .toList();
    });
  }

  /// Save or update a subject in a private school's isolated curriculum
  Future<void> savePrivateSchoolSubject(String schoolId, SubjectCurriculumModel subject) async {
    await _privateCurriculumRef(schoolId).doc(subject.id).set(subject.toMap());

    await _auditService.logAction(
      action: 'PRIVATE_CURRICULUM_UPDATED',
      targetType: 'school',
      targetId: schoolId,
      details: {'subjectId': subject.id, 'subjectName': subject.name},
    );
  }

  /// Delete a subject from private school isolated curriculum
  Future<void> deletePrivateSchoolSubject(String schoolId, String subjectId) async {
    await _privateCurriculumRef(schoolId).doc(subjectId).delete();

    await _auditService.logAction(
      action: 'PRIVATE_CURRICULUM_DELETED',
      targetType: 'school',
      targetId: schoolId,
      details: {'subjectId': subjectId},
    );
  }

  /// Initialize private school curriculum by copying from a base template if empty
  Future<void> initializePrivateCurriculumFromTemplate(String schoolId, String templateId) async {
    final existing = await _privateCurriculumRef(schoolId).limit(1).get();
    if (existing.docs.isNotEmpty) return; // Already initialized

    final template = await getTemplate(templateId);
    if (template == null) return;

    for (var subj in template.standardSubjects) {
      await _privateCurriculumRef(schoolId).doc(subj.id).set(subj.toMap());
    }

    await _auditService.logAction(
      action: 'PRIVATE_CURRICULUM_INITIALIZED',
      targetType: 'school',
      targetId: schoolId,
      details: {'clonedFromTemplate': templateId, 'subjectsCloned': template.standardSubjects.length},
    );
  }

  /// Record student topic completion in Firestore
  Future<void> recordTopicCompletion({
    required String studentId,
    required String subjectId,
    required String chapterId,
    required String topicId,
    int score = 100,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(studentId)
          .collection('topic_completions')
          .doc(topicId)
          .set({
        'topicId': topicId,
        'chapterId': chapterId,
        'subjectId': subjectId,
        'score': score,
        'completedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Non-fatal
    }
  }

  /// Get student's completed topic IDs
  Future<Set<String>> getCompletedTopicIds(String studentId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(studentId)
          .collection('topic_completions')
          .get();
      return snapshot.docs.map((d) => d.id).toSet();
    } catch (e) {
      return {};
    }
  }

  /// Auto-seed standard curriculum templates into Firestore if collection is empty
  Future<void> seedCurriculumTemplatesIfEmpty() async {
    try {
      final snapshot = await _templatesRef.limit(1).get();
      if (snapshot.docs.isNotEmpty) return;

      final class8Subjects = [
        {
          'id': 'subj_maths',
          'name': 'Mathematics',
          'code': 'MATH-8',
          'colorValue': 0xFF3B82F6,
          'completionPercentage': 0.0,
          'chapters': [
            {
              'id': 'm_ch1',
              'chapterNumber': 1,
              'title': 'Rational Numbers',
              'progress': 0.0,
              'topics': [
                {'id': 'm_t1', 'title': 'Properties of Rational Numbers', 'order': 1, 'estimatedMinutes': 25, 'isCompleted': false},
                {'id': 'm_t2', 'title': 'Representation on Number Line', 'order': 2, 'estimatedMinutes': 20, 'isCompleted': false},
              ]
            },
            {
              'id': 'm_ch2',
              'chapterNumber': 2,
              'title': 'Linear Equations in One Variable',
              'progress': 0.0,
              'topics': [
                {'id': 'm_t3', 'title': 'Solving Linear Expressions', 'order': 1, 'estimatedMinutes': 30, 'isCompleted': false},
                {'id': 'm_t4', 'title': 'Word Problems & Applications', 'order': 2, 'estimatedMinutes': 25, 'isCompleted': false},
              ]
            },
            {
              'id': 'm_ch3',
              'chapterNumber': 3,
              'title': 'Understanding Quadrilaterals',
              'progress': 0.0,
              'topics': [
                {'id': 'm_t5', 'title': 'Polygons & Angle Sum Property', 'order': 1, 'estimatedMinutes': 20, 'isCompleted': false},
              ]
            },
            {
              'id': 'm_ch4',
              'chapterNumber': 4,
              'title': 'Data Handling',
              'progress': 0.0,
              'topics': [
                {'id': 'm_t6', 'title': 'Histograms and Pie Charts', 'order': 1, 'estimatedMinutes': 25, 'isCompleted': false},
              ]
            },
          ]
        },
        {
          'id': 'subj_science',
          'name': 'Science',
          'code': 'SCI-8',
          'colorValue': 0xFF10B981,
          'completionPercentage': 0.0,
          'chapters': [
            {
              'id': 's_ch1',
              'chapterNumber': 1,
              'title': 'Crop Production and Management',
              'progress': 0.0,
              'topics': [
                {'id': 's_t1', 'title': 'Agricultural Practices', 'order': 1, 'estimatedMinutes': 20, 'isCompleted': false},
              ]
            },
            {
              'id': 's_ch2',
              'chapterNumber': 2,
              'title': 'Microorganisms: Friend and Foe',
              'progress': 0.0,
              'topics': [
                {'id': 's_t2', 'title': 'Commercial & Medicinal Uses', 'order': 1, 'estimatedMinutes': 25, 'isCompleted': false},
              ]
            },
            {
              'id': 's_ch3',
              'chapterNumber': 3,
              'title': 'Coal and Petroleum',
              'progress': 0.0,
              'topics': [
                {'id': 's_t3', 'title': 'Fossil Fuels and Refining', 'order': 1, 'estimatedMinutes': 20, 'isCompleted': false},
              ]
            },
            {
              'id': 's_ch4',
              'chapterNumber': 4,
              'title': 'Photosynthesis & Plant Nutrition',
              'progress': 0.0,
              'topics': [
                {'id': 's_t4', 'title': 'Chlorophyll and Solar Energy', 'order': 1, 'estimatedMinutes': 25, 'isCompleted': false},
                {'id': 's_t5', 'title': 'Light & Dark Reactions in Stomata', 'order': 2, 'estimatedMinutes': 30, 'isCompleted': false},
              ]
            },
          ]
        },
        {
          'id': 'subj_english',
          'name': 'English',
          'code': 'ENG-8',
          'colorValue': 0xFFEC4899,
          'completionPercentage': 0.0,
          'chapters': [
            {
              'id': 'e_ch1',
              'chapterNumber': 1,
              'title': 'The Best Christmas Present in the World',
              'progress': 0.0,
              'topics': [
                {'id': 'e_t1', 'title': 'Story Reading & Comprehension', 'order': 1, 'estimatedMinutes': 20, 'isCompleted': false},
              ]
            },
            {
              'id': 'e_ch2',
              'chapterNumber': 2,
              'title': 'The Tsunami',
              'progress': 0.0,
              'topics': [
                {'id': 'e_t2', 'title': 'Geography of Natural Hazards', 'order': 1, 'estimatedMinutes': 20, 'isCompleted': false},
              ]
            },
          ]
        },
        {
          'id': 'subj_social',
          'name': 'Social Studies',
          'code': 'SOC-8',
          'colorValue': 0xFF8B5CF6,
          'completionPercentage': 0.0,
          'chapters': [
            {
              'id': 'soc_ch1',
              'chapterNumber': 1,
              'title': 'How, When and Where',
              'progress': 0.0,
              'topics': [
                {'id': 'soc_t1', 'title': 'Periodisation in History', 'order': 1, 'estimatedMinutes': 20, 'isCompleted': false},
              ]
            },
            {
              'id': 'soc_ch2',
              'chapterNumber': 2,
              'title': 'From Trade to Territory',
              'progress': 0.0,
              'topics': [
                {'id': 'soc_t2', 'title': 'East India Company Beginnings', 'order': 1, 'estimatedMinutes': 25, 'isCompleted': false},
              ]
            },
          ]
        },
      ];

      await _templatesRef.doc('AP_STATE_GOVT').set({
        'name': 'AP State Govt',
        'boardCode': 'BSEAP',
        'description': 'Andhra Pradesh State Board Syllabus — SCERT aligned',
        'adoptedSchoolsCount': 128,
        'isActive': true,
        'standardSubjects': class8Subjects,
      });

      await _templatesRef.doc('CBSE_CENTRAL').set({
        'name': 'CBSE',
        'boardCode': 'CBSE',
        'description': 'Central Board of Secondary Education — NCERT standard',
        'adoptedSchoolsCount': 48,
        'isActive': true,
        'standardSubjects': class8Subjects,
      });

      await _templatesRef.doc('PRIVATE_CUSTOM').set({
        'name': 'Private Schools',
        'boardCode': 'INDEP',
        'description': 'Independent / Integrated curriculum with state alignment',
        'adoptedSchoolsCount': 72,
        'isActive': true,
        'standardSubjects': class8Subjects,
      });
    } catch (e) {
      // Non-fatal
    }
  }
}
