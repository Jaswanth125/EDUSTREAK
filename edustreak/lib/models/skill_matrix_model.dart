import 'skill_intelligence_model.dart';

class SkillMatrixModel {
  final String studentId;
  final String studentName;
  final double attendance; // 0-100 (Legacy)
  final double taskPerformance; // 0-100 (Legacy)
  final double engagement; // 0-100 (Legacy)
  final double participation; // 0-100 (Legacy)
  final double challengeCompletion; // 0-100 (Legacy)
  final double overallProgress; // 0-100 (Legacy)

  // 6 Core Assessment Dimensions
  final double conceptualUnderstanding;
  final double problemSolving;
  final double criticalThinking;
  final double applicationSkills;
  final double consistencyDiscipline;
  final double communicationExpression;

  final StudentSkillProfileModel? profile;

  SkillMatrixModel({
    required this.studentId,
    required this.studentName,
    this.attendance = 0,
    this.taskPerformance = 0,
    this.engagement = 0,
    this.participation = 0,
    this.challengeCompletion = 0,
    this.overallProgress = 0,
    double? conceptualUnderstanding,
    double? problemSolving,
    double? criticalThinking,
    double? applicationSkills,
    double? consistencyDiscipline,
    double? communicationExpression,
    this.profile,
  })  : conceptualUnderstanding = conceptualUnderstanding ?? taskPerformance,
        problemSolving = problemSolving ?? challengeCompletion,
        criticalThinking = criticalThinking ?? overallProgress,
        applicationSkills = applicationSkills ?? taskPerformance,
        consistencyDiscipline = consistencyDiscipline ?? attendance,
        communicationExpression = communicationExpression ?? participation;

  /// Get 6 core competency values in standard canonical order
  List<double> get coreCompetencyValues => [
        conceptualUnderstanding,
        problemSolving,
        criticalThinking,
        applicationSkills,
        consistencyDiscipline,
        communicationExpression,
      ];

  /// Get 6 core competency labels
  static List<String> get coreCompetencyLabels => SkillDimensionDef.allLabels;

  // Legacy compatibility getters
  List<double> get skillValues => coreCompetencyValues;
  static List<String> get skillLabels => coreCompetencyLabels;

  // Calculate overall score (average of the 6 core competency dimensions)
  double get overallScore {
    final sum = conceptualUnderstanding +
        problemSolving +
        criticalThinking +
        applicationSkills +
        consistencyDiscipline +
        communicationExpression;
    return sum / 6;
  }
}

