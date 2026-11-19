import 'package:flutter_test/flutter_test.dart';
import 'package:edustreak/models/school_insight_model.dart';
import 'package:edustreak/services/school_insights_service.dart';

void main() {
  group('SchoolInsightModel & Serialization Tests', () {
    test('SchoolInsightModel round-trip serialization and copyWith', () {
      final now = DateTime(2026, 11, 10, 10, 30);
      final insight = SchoolInsightModel(
        id: 'ins_test_01',
        schoolId: 'sch_ap_001',
        category: 'academic',
        severity: 'critical',
        title: 'Class 10B Academic Regression in Science',
        finding: 'Class 10B science average dropped from 78.5% to 64.2%.',
        interpretation: 'Difficulty in organic chemistry foundational principles.',
        recommendedAction: 'Schedule remedial bridge sessions twice weekly.',
        supportingMetrics: {'currentAvg': 64.2, 'dropPct': 14.3},
        observationPeriod: 'Past 3 Weeks',
        affectedEntity: 'Class 10B • Science',
        affectedCount: 34,
        confidenceLevel: 'High (95%)',
        timestamp: now,
        isReviewed: false,
        status: 'open',
      );

      // Verify toMap
      final map = insight.toMap();
      expect(map['id'], equals('ins_test_01'));
      expect(map['schoolId'], equals('sch_ap_001'));
      expect(map['category'], equals('academic'));
      expect(map['severity'], equals('critical'));
      expect(map['finding'], contains('dropped from 78.5% to 64.2%'));
      expect(map['interpretation'], contains('organic chemistry'));
      expect(map['affectedCount'], equals(34));
      expect(map['isReviewed'], isFalse);
      expect(map['status'], equals('open'));

      // Verify fromMap
      final restored = SchoolInsightModel.fromMap(map, 'ins_test_01');
      expect(restored.id, equals(insight.id));
      expect(restored.schoolId, equals(insight.schoolId));
      expect(restored.category, equals(insight.category));
      expect(restored.severity, equals(insight.severity));
      expect(restored.finding, equals(insight.finding));
      expect(restored.interpretation, equals(insight.interpretation));
      expect(restored.recommendedAction, equals(insight.recommendedAction));
      expect(restored.affectedCount, equals(34));
      expect(restored.confidenceLevel, equals('High (95%)'));

      // Verify copyWith lifecycle progression
      final reviewed = restored.copyWith(
        isReviewed: true,
        assignedTo: 'usr_teacher_science_01',
        assignedToName: 'Mr. Rajesh Kumar',
        actionTaken: 'Remedial timetable published; first session held.',
        status: 'resolved',
      );

      expect(reviewed.isReviewed, isTrue);
      expect(reviewed.assignedTo, equals('usr_teacher_science_01'));
      expect(reviewed.assignedToName, equals('Mr. Rajesh Kumar'));
      expect(reviewed.actionTaken, contains('Remedial timetable'));
      expect(reviewed.status, equals('resolved'));
    });
  });

  group('SchoolAnalyticsMetrics & Evidence Calculation Tests', () {
    test('Calculates composite Health Score accurately based on empirical performance', () {
      final highPerfMetrics = SchoolAnalyticsMetrics(
        totalStudents: 120,
        totalTeachers: 12,
        totalClasses: 4,
        overallAttendance: 92.5,
        overallAcademicAverage: 84.0,
        homeworkCompletionRate: 88.0,
        pendingGradingCount: 2,
        chronicAbsentCount: 1,
        classAverages: {'10A': 85.0, '10B': 83.0},
        subjectAverages: {'Science': 82.0, 'Math': 86.0},
        classAttendance: {'10A': 93.0, '10B': 92.0},
        lastCalculated: DateTime(2026, 11, 10),
      );

      final summary = highPerfMetrics.toSummaryMap();
      expect(summary['healthScore'], equals(88));
      expect(summary['overallAttendance'], equals(92.5));
      expect(summary['overallAcademicAverage'], equals(84.0));
      expect(summary['homeworkCompletionRate'], equals(88.0));
      expect(summary['pendingGradingCount'], equals(2));
      expect(summary['chronicAbsentCount'], equals(1));
    });

    test('Threshold Engine generates multi-category insights from genuine metrics', () {
      final service = SchoolInsightsService();

      final laggingMetrics = SchoolAnalyticsMetrics(
        totalStudents: 80,
        totalTeachers: 8,
        totalClasses: 2,
        overallAttendance: 79.2, // Below 85% benchmark
        overallAcademicAverage: 71.4, // Below 75% benchmark
        homeworkCompletionRate: 85.0, // High momentum
        pendingGradingCount: 12, // Exceeds threshold (delay)
        chronicAbsentCount: 6, // Exceeds chronic threshold (> 3)
        classAverages: {
          'Class 10A': 81.0,
          'Class 10B': 61.8, // Critically low section (< 70%)
        },
        subjectAverages: {
          'Mathematics': 62.5, // Lowest subject
          'Science': 78.0,
          'Social Studies': 74.0,
        },
        classAttendance: {
          'Class 10A': 88.0,
          'Class 10B': 70.4, // Lagging attendance (< 80%)
        },
        lastCalculated: DateTime(2026, 11, 10),
      );

      final insights = service.evaluateMetricsToInsights('sch_ap_001', laggingMetrics);

      // Verify insight count & categories
      expect(insights.isNotEmpty, isTrue);

      final categories = insights.map((i) => i.category).toSet();
      expect(categories.contains('academic'), isTrue);
      expect(categories.contains('attendance'), isTrue);
      expect(categories.contains('teacher_activity'), isTrue);
      expect(categories.contains('homework'), isTrue);

      // Verify academic regression detection
      final academicInsight = insights.firstWhere((i) => i.category == 'academic');
      expect(academicInsight.affectedEntity, contains('Class 10B'));
      expect(academicInsight.finding, contains('61.8%'));
      expect(academicInsight.severity, equals('critical'));

      // Verify teacher pending evaluations detection
      final teacherInsight = insights.firstWhere((i) => i.category == 'teacher_activity');
      expect(teacherInsight.finding, contains('12 submitted student assignments'));

      // Verify attendance detection
      final attInsight = insights.firstWhere((i) => i.category == 'attendance');
      expect(attInsight.affectedEntity, equals('Multiple Classes'));
      expect(attInsight.finding, contains('6 students'));
      expect(attInsight.severity, equals('critical'));
    });
  });

  group('Assistant Grounded Deterministic Synthesis Tests', () {
    test('Answers academic inquiries using exact empirical class averages', () async {
      final service = SchoolInsightsService();
      final metrics = SchoolAnalyticsMetrics(
        totalStudents: 60,
        totalTeachers: 6,
        totalClasses: 2,
        overallAttendance: 88.5,
        overallAcademicAverage: 79.2,
        homeworkCompletionRate: 82.0,
        pendingGradingCount: 4,
        chronicAbsentCount: 2,
        classAverages: {
          'Class 10A': 83.5,
          'Class 10B': 74.9, // Lowest class
        },
        subjectAverages: {
          'Mathematics': 73.0,
          'Science': 85.4,
        },
        classAttendance: {
          'Class 10A': 91.0,
          'Class 10B': 86.0,
        },
        lastCalculated: DateTime(2026, 11, 10),
      );

      final response = await service.askSchoolAssistant(
        'sch_ap_001',
        'Which class needs the most attention?',
        cachedMetrics: metrics,
      );

      expect(response, contains('Class 10B'));
      expect(response, contains('74.9%'));
      expect(response, contains('79.2%')); // Overall average
      expect(response, contains('Recommended Executive Action'));
    });

    test('Answers subject inquiries with lowest subject identification', () async {
      final service = SchoolInsightsService();
      final metrics = SchoolAnalyticsMetrics(
        totalStudents: 60,
        totalTeachers: 6,
        totalClasses: 2,
        overallAttendance: 88.5,
        overallAcademicAverage: 79.2,
        homeworkCompletionRate: 82.0,
        pendingGradingCount: 4,
        chronicAbsentCount: 2,
        classAverages: {'Class 10A': 83.5, 'Class 10B': 74.9},
        subjectAverages: {
          'Mathematics': 71.5, // Lowest subject
          'Science': 86.9,
        },
        classAttendance: {'Class 10A': 91.0, 'Class 10B': 86.0},
        lastCalculated: DateTime(2026, 11, 10),
      );

      final response = await service.askSchoolAssistant(
        'sch_ap_001',
        'What is our lowest performing subject?',
        cachedMetrics: metrics,
      );

      expect(response, contains('Mathematics'));
      expect(response, contains('71.5%'));
    });

    test('Answers teacher workflow inquiries with real pending grading backlog', () async {
      final service = SchoolInsightsService();
      final metrics = SchoolAnalyticsMetrics(
        totalStudents: 60,
        totalTeachers: 6,
        totalClasses: 2,
        overallAttendance: 88.5,
        overallAcademicAverage: 79.2,
        homeworkCompletionRate: 83.4,
        pendingGradingCount: 14,
        chronicAbsentCount: 2,
        classAverages: {'Class 10A': 83.5, 'Class 10B': 74.9},
        subjectAverages: {'Mathematics': 71.5, 'Science': 86.9},
        classAttendance: {'Class 10A': 91.0, 'Class 10B': 86.0},
        lastCalculated: DateTime(2026, 11, 10),
      );

      final response = await service.askSchoolAssistant(
        'sch_ap_001',
        'Show faculty grading turnaround status',
        cachedMetrics: metrics,
      );

      expect(response, contains('14 submissions'));
      expect(response, contains('83.4%'));
    });
  });
}
