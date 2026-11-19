import 'package:flutter_test/flutter_test.dart';
import 'package:edustreak/models/skill_intelligence_model.dart';
import 'package:edustreak/models/skill_matrix_model.dart';
import 'package:edustreak/services/skill_intelligence_service.dart';

void main() {
  group('SkillDimensionDef – 6 Core Competency Dimensions', () {
    test('Contains exactly 6 core dimensions with non-empty metadata', () {
      final dims = SkillDimensionDef.coreDimensions;
      expect(dims.length, equals(6));

      final expectedIds = [
        SkillDimensionDef.conceptualUnderstanding,
        SkillDimensionDef.problemSolving,
        SkillDimensionDef.criticalThinking,
        SkillDimensionDef.applicationSkills,
        SkillDimensionDef.consistencyDiscipline,
        SkillDimensionDef.communicationExpression,
      ];

      expect(SkillDimensionDef.allIds, equals(expectedIds));

      for (final dim in dims) {
        expect(dim.id.isNotEmpty, isTrue);
        expect(dim.label.isNotEmpty, isTrue);
        expect(dim.shortLabel.isNotEmpty, isTrue);
        expect(dim.description.isNotEmpty, isTrue);
      }
    });

    test('getById returns matching dimension or fallback', () {
      final problemSolving = SkillDimensionDef.getById('problem_solving');
      expect(problemSolving.label, equals('Problem Solving'));

      final fallback = SkillDimensionDef.getById('non_existent');
      expect(fallback.id, equals(SkillDimensionDef.conceptualUnderstanding));
    });
  });

  group('SkillEvidenceModel Serialization & Weighting', () {
    test('Round-trip serialization maintains assessment evidence fidelity', () {
      final now = DateTime(2026, 11, 10, 14, 0);
      final evidence = SkillEvidenceModel(
        id: 'ev_test_101',
        studentId: 'std_42',
        schoolId: 'sch_demo',
        skillId: SkillDimensionDef.problemSolving,
        dimensionName: 'Problem Solving',
        source: 'quiz_mcq',
        sourceTitle: 'Physics: Kinematics Quiz',
        rawScore: 9.0,
        maxScore: 10.0,
        normalizedScore: 90.0,
        weight: 1.5,
        subject: 'Physics',
        topic: 'Motion in One Dimension',
        evaluatorId: 'tch_01',
        evaluatorName: 'Dr. Srinivasan',
        feedback: 'Excellent formula derivation',
        rubricLevel: 4,
        timestamp: now,
        periodKey: '2026-11',
      );

      final map = evidence.toMap();
      expect(map['id'], equals('ev_test_101'));
      expect(map['skillId'], equals('problem_solving'));
      expect(map['normalizedScore'], equals(90.0));
      expect(map['rubricLevel'], equals(4));

      final restored = SkillEvidenceModel.fromMap(map, 'ev_test_101');
      expect(restored.id, equals(evidence.id));
      expect(restored.sourceTitle, equals(evidence.sourceTitle));
      expect(restored.normalizedScore, equals(90.0));
      expect(restored.evaluatorName, equals('Dr. Srinivasan'));
      expect(restored.rubricLevel, equals(4));
    });
  });

  group('SkillScoreModel & Confidence Thresholds', () {
    test('Calculates confidence levels based on activity count N without fabricating scores', () {
      // N = 0: Unassessed
      final unassessed = SkillScoreModel(
        skillId: SkillDimensionDef.problemSolving,
        label: 'Problem Solving',
        score: 0.0,
        activityCount: 0,
        confidenceLevel: 'low',
        confidencePercentage: 0.0,
        isAssessed: false,
      );
      expect(unassessed.isAssessed, isFalse);
      expect(unassessed.confidenceLevel, equals('low'));

      // N = 2: Low / Preliminary
      final preliminary = SkillScoreModel(
        skillId: SkillDimensionDef.criticalThinking,
        label: 'Critical Thinking',
        score: 74.0,
        activityCount: 2,
        confidenceLevel: 'low',
        confidencePercentage: 35.0,
        isAssessed: true,
      );
      expect(preliminary.isAssessed, isTrue);
      expect(preliminary.confidenceLevel, equals('low'));

      // N = 5: Moderate
      final moderate = SkillScoreModel(
        skillId: SkillDimensionDef.applicationSkills,
        label: 'Application Skills',
        score: 82.5,
        activityCount: 5,
        confidenceLevel: 'moderate',
        confidencePercentage: 70.0,
        isAssessed: true,
      );
      expect(moderate.confidenceLevel, equals('moderate'));

      // N = 8: High
      final high = SkillScoreModel(
        skillId: SkillDimensionDef.conceptualUnderstanding,
        label: 'Conceptual Understanding',
        score: 91.0,
        activityCount: 8,
        confidenceLevel: 'high',
        confidencePercentage: 95.0,
        isAssessed: true,
      );
      expect(high.confidenceLevel, equals('high'));
    });
  });

  group('StudentSkillProfileModel & Radar Order', () {
    test('Profile computes composite scores, radar ordering, and unassessed dimensions', () {
      final now = DateTime(2026, 11, 10);
      final profile = StudentSkillProfileModel(
        studentId: 'st_101',
        studentName: 'Aarav Sharma',
        schoolId: 'sch_demo',
        periodKey: 'current',
        skills: {
          SkillDimensionDef.conceptualUnderstanding: SkillScoreModel(
            skillId: SkillDimensionDef.conceptualUnderstanding,
            label: 'Conceptual Understanding',
            score: 88.0,
            previousScore: 82.0,
            activityCount: 6,
            confidenceLevel: 'moderate',
            confidencePercentage: 80.0,
            isAssessed: true,
          ),
          SkillDimensionDef.problemSolving: SkillScoreModel(
            skillId: SkillDimensionDef.problemSolving,
            label: 'Problem Solving',
            score: 64.0,
            previousScore: 60.0,
            activityCount: 4,
            confidenceLevel: 'moderate',
            confidencePercentage: 65.0,
            isAssessed: true,
          ),
          SkillDimensionDef.criticalThinking: SkillScoreModel(
            skillId: SkillDimensionDef.criticalThinking,
            label: 'Critical Thinking',
            score: 0.0,
            activityCount: 0,
            confidenceLevel: 'low',
            confidencePercentage: 0.0,
            isAssessed: false, // NOT assessed
          ),
          SkillDimensionDef.applicationSkills: SkillScoreModel(
            skillId: SkillDimensionDef.applicationSkills,
            label: 'Application Skills',
            score: 78.0,
            previousScore: 72.0,
            activityCount: 5,
            confidenceLevel: 'moderate',
            confidencePercentage: 75.0,
            isAssessed: true,
          ),
          SkillDimensionDef.consistencyDiscipline: SkillScoreModel(
            skillId: SkillDimensionDef.consistencyDiscipline,
            label: 'Consistency & Discipline',
            score: 85.0,
            previousScore: 80.0,
            activityCount: 7,
            confidenceLevel: 'high',
            confidencePercentage: 90.0,
            isAssessed: true,
          ),
          SkillDimensionDef.communicationExpression: SkillScoreModel(
            skillId: SkillDimensionDef.communicationExpression,
            label: 'Communication & Expression',
            score: 75.0,
            previousScore: 70.0,
            activityCount: 3,
            confidenceLevel: 'moderate',
            confidencePercentage: 60.0,
            isAssessed: true,
          ),
        },
        compositeScore: 78.0,
        strengths: ['Conceptual Understanding', 'Consistency & Discipline'],
        growthAreas: ['Problem Solving'],
        evidenceCoverage: 5 / 6,
        lastCalculatedAt: now,
      );

      // Verify getters
      expect(profile.assessedDimensionsCount, equals(5));
      expect(profile.totalActivitiesAssessed, equals(25));
      expect(profile.unassessedSkills, contains('Critical Thinking'));
      expect(profile.unassessedSkills.length, equals(1));

      // Radar current values should return 6 entries in canonical dimension order
      final radarValues = profile.radarCurrentValues;
      expect(radarValues.length, equals(6));
      expect(radarValues[0], equals(88.0)); // Conceptual
      expect(radarValues[1], equals(64.0)); // Problem Solving
      expect(radarValues[2], equals(0.0));  // Critical Thinking (unassessed -> 0)
      expect(radarValues[3], equals(78.0)); // Application
      expect(radarValues[4], equals(85.0)); // Consistency
      expect(radarValues[5], equals(75.0)); // Communication

      // Serialization round-trip
      final map = profile.toMap();
      final restored = StudentSkillProfileModel.fromMap(map);
      expect(restored.studentId, equals('st_101'));
      expect(restored.compositeScore, equals(78.0));
      expect(restored.assessedDimensionsCount, equals(5));
      expect(restored.strengths.first, equals('Conceptual Understanding'));
    });
  });

  group('TeacherRubricEvaluationModel – 5-Tier Rubric', () {
    test('Correctly maps 5-tier rubrics into percentage scores and attributable audit trail', () {
      final now = DateTime(2026, 11, 10, 15, 30);
      final eval = TeacherRubricEvaluationModel(
        id: 'eval_001',
        schoolId: 'sch_demo',
        teacherId: 'tch_raman',
        teacherName: 'Mr. C. V. Raman',
        studentId: 'st_101',
        studentName: 'Aarav Sharma',
        skillId: SkillDimensionDef.criticalThinking,
        rubricLevel: 4, // Proficient (80%)
        rubricScore: 80.0,
        assessmentTitle: 'Term 1 Optics Laboratory Experiment',
        evidenceNotes: 'Student critically analyzed chromatic aberration without prompting.',
        timestamp: now,
      );

      expect(eval.rubricLevel, equals(4));
      expect(eval.rubricScore, equals(80.0));
      expect(eval.teacherName, equals('Mr. C. V. Raman'));

      final map = eval.toMap();
      expect(map['rubricLevel'], equals(4));
      expect(map['rubricScore'], equals(80.0));

      final restored = TeacherRubricEvaluationModel.fromMap(map, 'eval_001');
      expect(restored.rubricScore, equals(80.0));
      expect(restored.assessmentTitle, contains('Optics Laboratory'));
    });
  });

  group('SkillMatrixModel Backward Compatibility', () {
    test('Supports both legacy getters and 6 core dimensions simultaneously', () {
      final model = SkillMatrixModel(
        studentId: 'st_101',
        studentName: 'Aarav Sharma',
        conceptualUnderstanding: 85.0,
        problemSolving: 70.0,
        criticalThinking: 75.0,
        applicationSkills: 80.0,
        consistencyDiscipline: 90.0,
        communicationExpression: 65.0,
      );

      // Core order
      expect(model.coreCompetencyValues.length, equals(6));
      expect(model.coreCompetencyValues[0], equals(85.0));
      expect(model.coreCompetencyValues[1], equals(70.0));

      // Legacy skillValues should mirror core values
      expect(model.skillValues, equals(model.coreCompetencyValues));

      // Overall score
      final expectedAvg = (85 + 70 + 75 + 80 + 90 + 65) / 6;
      expect(model.overallScore, closeTo(expectedAvg, 0.01));
    });
  });

  group('SkillIntelligenceService – Grounded AI Skill Coach & Synthesis', () {
    test('Generates deterministic grounded recommendations tailored to student weaknesses', () async {
      final service = SkillIntelligenceService();
      final now = DateTime(2026, 11, 10);

      final profile = StudentSkillProfileModel(
        studentId: 'st_101',
        studentName: 'Aarav Sharma',
        schoolId: 'sch_demo',
        periodKey: 'current',
        skills: {
          SkillDimensionDef.conceptualUnderstanding: SkillScoreModel(
            skillId: SkillDimensionDef.conceptualUnderstanding,
            label: 'Conceptual Understanding',
            score: 90.0,
            activityCount: 8,
            confidenceLevel: 'high',
            confidencePercentage: 95.0,
            isAssessed: true,
          ),
          SkillDimensionDef.problemSolving: SkillScoreModel(
            skillId: SkillDimensionDef.problemSolving,
            label: 'Problem Solving',
            score: 58.0,
            activityCount: 4,
            confidenceLevel: 'moderate',
            confidencePercentage: 60.0,
            isAssessed: true,
          ),
        },
        compositeScore: 74.0,
        strengths: ['Conceptual Understanding'],
        growthAreas: ['Problem Solving'],
        evidenceCoverage: 2 / 6,
        lastCalculatedAt: now,
      );

      // Question on strengths
      final strengthResponse = await service.askSkillCoach(
        studentId: 'st_101',
        schoolId: 'sch_demo',
        question: 'What are my greatest strengths?',
        profile: profile,
      );
      expect(strengthResponse, contains('Conceptual Understanding'));

      // Question on improvement
      final improveResponse = await service.askSkillCoach(
        studentId: 'st_101',
        schoolId: 'sch_demo',
        question: 'How can I improve my weak skills?',
        profile: profile,
      );
      expect(improveResponse, contains('Problem Solving'));
    });
  });
}
