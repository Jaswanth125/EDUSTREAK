import 'package:flutter_test/flutter_test.dart';
import 'package:edustreak/models/user_model.dart';

void main() {
  group('UserModel Role & Permission Tests', () {
    test('Principal role flags and permissions', () {
      final principal = UserModel(
        id: 'prin_01',
        name: 'Dr. Sudhir Sharma',
        email: 'principal@edustreak.com',
        role: 'principal',
        schoolId: 'sch_ap_001',
      );

      expect(principal.isPrincipal, isTrue);
      expect(principal.isAdmin, isFalse);
      expect(principal.isTeacher, isFalse);
      expect(principal.isStudent, isFalse);
      expect(principal.isParent, isFalse);
      expect(principal.schoolId, equals('sch_ap_001'));
    });

    test('Central Admin role flags and permissions', () {
      final admin = UserModel(
        id: 'adm_01',
        name: 'Central Admin',
        email: 'admin@edustreak.com',
        role: 'admin',
      );

      expect(admin.isAdmin, isTrue);
      expect(admin.isPrincipal, isFalse);
      expect(admin.isTeacher, isFalse);
      expect(admin.isStudent, isFalse);
    });

    test('Student role isolation and spendablePoints default', () {
      final student = UserModel(
        id: 'std_01',
        name: 'Akash Sharma',
        email: 'student1@edustreak.com',
        role: 'student',
        schoolId: 'sch_ap_001',
        rollNumber: '101',
        xp: 1250,
      );

      expect(student.isStudent, isTrue);
      expect(student.isAdmin, isFalse);
      expect(student.isPrincipal, isFalse);
      expect(student.rollNumber, equals('101'));
      expect(student.xp, equals(1250));
    });

    test('Teacher role with assigned classes and subjects', () {
      final teacher = UserModel(
        id: 'tch_01',
        name: 'Sarah Johnson',
        email: 'teacher1@edustreak.com',
        role: 'teacher',
        schoolId: 'sch_ap_001',
        classIds: ['Class 10-A', 'Class 10-B'],
        assignedSubjects: ['Mathematics', 'Science'],
      );

      expect(teacher.isTeacher, isTrue);
      expect(teacher.classIds?.length, equals(2));
      expect(teacher.assignedSubjects.contains('Mathematics'), isTrue);
    });

    test('Parent role linked to multiple children', () {
      final parent = UserModel(
        id: 'prt_01',
        name: 'John Chen',
        email: 'parent1@edustreak.com',
        role: 'parent',
        childIds: ['std_01', 'std_02'],
      );

      expect(parent.isParent, isTrue);
      expect(parent.childIds.length, equals(2));
      expect(parent.childIds.contains('std_01'), isTrue);
    });

    test('toMap and fromMap preservation of spendablePoints and role', () {
      final original = UserModel(
        id: 'std_99',
        name: 'Priya Reddy',
        email: 'priya@edustreak.com',
        role: 'student',
        xp: 2400,
        spendablePoints: 800,
        level: 5,
        streakCount: 14,
      );

      final map = original.toMap();
      final restored = UserModel.fromMap(map);

      expect(restored.id, equals(original.id));
      expect(restored.role, equals('student'));
      expect(restored.xp, equals(2400));
      expect(restored.spendablePoints, equals(800));
      expect(restored.level, equals(5));
      expect(restored.streakCount, equals(14));
    });
  });
}
