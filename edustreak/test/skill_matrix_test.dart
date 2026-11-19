import 'package:flutter_test/flutter_test.dart';
import 'package:edustreak/models/task_model.dart';
import 'package:edustreak/models/skill_matrix_model.dart';

void main() {
  group('Skill Matrix Calculation Tests', () {
    test('Task performance calculation with real task models and submissions', () {
      const studentId = 'std_test_01';

      // 3 assigned tasks: 2 completed with marks, 1 pending
      final tasks = [
        TaskModel(
          id: 'task_01',
          classId: 'Class 10-A',
          title: 'Algebra Polynomials',
          description: 'Solve problems 1-10',
          assignedBy: 'teacher_01',
          assignedByName: 'Ms. Sarah',
          dueDate: DateTime.now().add(const Duration(days: 2)),
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
          assignedTo: [studentId],
          submissions: {studentId: 'submitted'},
          marks: {studentId: 90},
          maxMarks: 100,
        ),
        TaskModel(
          id: 'task_02',
          classId: 'Class 10-A',
          title: 'Science Chemical Equations',
          description: 'Balance 5 reactions',
          assignedBy: 'teacher_01',
          assignedByName: 'Ms. Sarah',
          dueDate: DateTime.now().add(const Duration(days: 3)),
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
          assignedTo: [studentId],
          submissions: {studentId: 'submitted'},
          marks: {studentId: 80},
          maxMarks: 100,
        ),
        TaskModel(
          id: 'task_03',
          classId: 'Class 10-A',
          title: 'English Essay',
          description: 'Write about climate change',
          assignedBy: 'teacher_02',
          assignedByName: 'Mr. David',
          dueDate: DateTime.now().add(const Duration(days: 5)),
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          assignedTo: [studentId],
          submissions: {},
          marks: {},
          maxMarks: 100,
        ),
      ];

      int totalAssigned = tasks.length; // 3
      int completedTasks = 0;
      double totalMarks = 0.0;
      double maxMarks = 0.0;

      for (final t in tasks) {
        final subStatus = t.submissions[studentId];
        if (subStatus == 'submitted' || subStatus == 'completed' || t.marks.containsKey(studentId)) {
          completedTasks++;
          if (t.marks.containsKey(studentId)) {
            totalMarks += (t.marks[studentId] as num).toDouble();
            maxMarks += t.maxMarks.toDouble();
          }
        }
      }

      expect(completedTasks, equals(2));
      expect(totalAssigned, equals(3));

      final completionRate = (completedTasks / totalAssigned) * 100; // 66.67%
      final averageGrade = maxMarks > 0 ? (totalMarks / maxMarks) * 100 : 0.0; // 170/200 = 85.0%

      final taskPerformance = (completionRate * 0.4) + (averageGrade * 0.6); // 26.67 + 51.0 = 77.67

      expect(taskPerformance, closeTo(77.67, 0.1));

      // SkillMatrixModel creation verification
      final matrix = SkillMatrixModel(
        studentId: studentId,
        studentName: 'Test Student',
        attendance: 94.0,
        taskPerformance: taskPerformance,
        engagement: 82.0,
        participation: 75.0,
        challengeCompletion: 80.0,
        overallProgress: 81.7,
      );

      expect(matrix.taskPerformance, closeTo(77.67, 0.1));
      expect(matrix.attendance, equals(94.0));
      expect(matrix.overallProgress, equals(81.7));
    });
  });
}
