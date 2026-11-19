import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/curriculum_model.dart';
import 'audit_service.dart';

class AcademicService {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  final AuditService _auditService = AuditService();

  CollectionReference<Map<String, dynamic>> get _academicYearsRef =>
      _firestore.collection('academic_years');

  /// Stream of all academic years
  Stream<List<AcademicYearModel>> getAcademicYearsStream() {
    try {
      return _academicYearsRef.orderBy('startDate', descending: true).snapshots().map((snapshot) {
        if (snapshot.docs.isEmpty) {
          // Return default fallback if not yet seeded
          return [
            AcademicYearModel(
              id: 'ay_2024_2025',
              label: '2024-2025',
              startDate: DateTime(2024, 6, 1),
              endDate: DateTime(2025, 4, 30),
              isCurrent: true,
            ),
          ];
        }
        return snapshot.docs.map((doc) => AcademicYearModel(
              id: doc.id,
              label: doc.data()['label'] ?? '2024-2025',
              startDate: (doc.data()['startDate'] as Timestamp?)?.toDate() ?? DateTime(2024, 6, 1),
              endDate: (doc.data()['endDate'] as Timestamp?)?.toDate() ?? DateTime(2025, 4, 30),
              isCurrent: doc.data()['isCurrent'] ?? false,
            )).toList();
      });
    } catch (_) {
      return Stream.value([
        AcademicYearModel(
          id: 'ay_2024_2025',
          label: '2024-2025',
          startDate: DateTime(2024, 6, 1),
          endDate: DateTime(2025, 4, 30),
          isCurrent: true,
        ),
      ]);
    }
  }

  /// Create a new Academic Year
  Future<void> createAcademicYear({
    required String label,
    required DateTime startDate,
    required DateTime endDate,
    bool isCurrent = false,
  }) async {
    final docId = 'ay_${label.replaceAll('-', '_')}';

    if (isCurrent) {
      // Mark all others as non-current
      final existing = await _academicYearsRef.where('isCurrent', isEqualTo: true).get();
      for (var d in existing.docs) {
        await d.reference.update({'isCurrent': false});
      }
    }

    await _academicYearsRef.doc(docId).set({
      'label': label,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'isCurrent': isCurrent,
      'status': isCurrent ? 'active' : 'upcoming',
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _auditService.logAction(
      action: 'ACADEMIC_YEAR_CREATED',
      targetType: 'academic_year',
      targetId: docId,
      details: {'label': label, 'isCurrent': isCurrent},
    );
  }

  /// Set the active academic year
  Future<void> setActiveAcademicYear(String academicYearId) async {
    final existing = await _academicYearsRef.where('isCurrent', isEqualTo: true).get();
    for (var d in existing.docs) {
      await d.reference.update({'isCurrent': false, 'status': 'completed'});
    }

    await _academicYearsRef.doc(academicYearId).update({
      'isCurrent': true,
      'status': 'active',
      'activatedAt': FieldValue.serverTimestamp(),
    });

    await _auditService.logAction(
      action: 'ACADEMIC_YEAR_ACTIVATED',
      targetType: 'academic_year',
      targetId: academicYearId,
      details: {'activeId': academicYearId},
    );
  }

  // ─── SCHOOL CLASS & SECTION MANAGEMENT ────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _classesRef(String schoolId) =>
      _firestore.collection('schools').doc(schoolId).collection('classes');

  /// Stream of classes and their sections for a specific school
  Stream<List<GradeClassModel>> getSchoolClassesStream(String schoolId) {
    try {
      return _classesRef(schoolId).orderBy('gradeNumber').snapshots().map((snapshot) {
        if (snapshot.docs.isEmpty) {
          return [];
        }
        return snapshot.docs.map((doc) => GradeClassModel.fromMap(doc.data())).toList();
      });
    } catch (_) {
      return Stream.value([]);
    }
  }

  /// Seed standard school classes (Class 6 - 10) if empty
  Future<void> seedStandardClassesIfEmpty(String schoolId) async {
    try {
      final snapshot = await _classesRef(schoolId).limit(1).get();
      if (snapshot.docs.isNotEmpty) return;

      final standardClasses = [
        GradeClassModel(
          id: 'cls_6',
          gradeNumber: 6,
          gradeName: 'Class 6',
          sections: const [
            SectionModel(id: 'sec_6_a', name: 'A', classId: 'cls_6', totalStudents: 32),
            SectionModel(id: 'sec_6_b', name: 'B', classId: 'cls_6', totalStudents: 30),
          ],
        ),
        GradeClassModel(
          id: 'cls_7',
          gradeNumber: 7,
          gradeName: 'Class 7',
          sections: const [
            SectionModel(id: 'sec_7_a', name: 'A', classId: 'cls_7', totalStudents: 34),
            SectionModel(id: 'sec_7_b', name: 'B', classId: 'cls_7', totalStudents: 33),
          ],
        ),
        GradeClassModel(
          id: 'cls_8',
          gradeNumber: 8,
          gradeName: 'Class 8',
          sections: const [
            SectionModel(id: 'sec_8_a', name: 'A', classId: 'cls_8', totalStudents: 35),
            SectionModel(id: 'sec_8_b', name: 'B', classId: 'cls_8', totalStudents: 35),
          ],
        ),
        GradeClassModel(
          id: 'cls_9',
          gradeNumber: 9,
          gradeName: 'Class 9',
          sections: const [
            SectionModel(id: 'sec_9_a', name: 'A', classId: 'cls_9', totalStudents: 38),
            SectionModel(id: 'sec_9_b', name: 'B', classId: 'cls_9', totalStudents: 36),
          ],
        ),
        GradeClassModel(
          id: 'cls_10',
          gradeNumber: 10,
          gradeName: 'Class 10',
          sections: const [
            SectionModel(id: 'sec_10_a', name: 'A', classId: 'cls_10', totalStudents: 40),
            SectionModel(id: 'sec_10_b', name: 'B', classId: 'cls_10', totalStudents: 38),
          ],
        ),
      ];

      for (var c in standardClasses) {
        await _classesRef(schoolId).doc(c.id).set(c.toMap());
      }
    } catch (_) {}
  }

  /// Add a section to an existing class
  Future<void> addSectionToClass(String schoolId, String classId, SectionModel section) async {
    final doc = await _classesRef(schoolId).doc(classId).get();
    if (!doc.exists) return;

    final gradeClass = GradeClassModel.fromMap(doc.data()!);
    final sections = List<SectionModel>.from(gradeClass.sections)..add(section);

    await _classesRef(schoolId).doc(classId).update({
      'sections': sections.map((s) => s.toMap()).toList(),
    });

    await _auditService.logAction(
      action: 'ACADEMIC_SECTION_ADDED',
      targetType: 'school',
      targetId: schoolId,
      details: {'classId': classId, 'sectionName': section.name},
    );
  }

  /// Assign a class teacher to a section
  Future<void> assignClassTeacher({
    required String schoolId,
    required String classId,
    required String sectionId,
    required String teacherId,
    required String teacherName,
  }) async {
    final doc = await _classesRef(schoolId).doc(classId).get();
    if (!doc.exists) return;

    final gradeClass = GradeClassModel.fromMap(doc.data()!);
    final sections = gradeClass.sections.map((s) {
      if (s.id == sectionId) {
        return SectionModel(
          id: s.id,
          name: s.name,
          classId: s.classId,
          classTeacherId: teacherId,
          classTeacherName: teacherName,
          totalStudents: s.totalStudents,
        );
      }
      return s;
    }).toList();

    await _classesRef(schoolId).doc(classId).update({
      'sections': sections.map((s) => s.toMap()).toList(),
    });

    await _auditService.logAction(
      action: 'CLASS_TEACHER_ASSIGNED',
      targetType: 'school',
      targetId: schoolId,
      details: {
        'classId': classId,
        'sectionId': sectionId,
        'teacherId': teacherId,
        'teacherName': teacherName,
      },
    );
  }
}
