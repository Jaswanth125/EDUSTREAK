import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// The 6 Core Competency Dimensions of EduStreak
class SkillDimensionDef {
  final String id;
  final String label;
  final String shortLabel;
  final String description;
  final IconData icon;
  final Color accentColor;

  const SkillDimensionDef({
    required this.id,
    required this.label,
    required this.shortLabel,
    required this.description,
    required this.icon,
    required this.accentColor,
  });

  static const String conceptualUnderstanding = 'conceptual_understanding';
  static const String problemSolving = 'problem_solving';
  static const String criticalThinking = 'critical_thinking';
  static const String applicationSkills = 'application_skills';
  static const String consistencyDiscipline = 'consistency_discipline';
  static const String communicationExpression = 'communication_expression';

  static const List<SkillDimensionDef> coreDimensions = [
    SkillDimensionDef(
      id: conceptualUnderstanding,
      label: 'Conceptual Understanding',
      shortLabel: 'Concepts',
      description: 'Mastery of foundational theories, definitions, principles, and subject taxonomies.',
      icon: Icons.psychology_outlined,
      accentColor: Color(0xFF35C9FF), // Cyan
    ),
    SkillDimensionDef(
      id: problemSolving,
      label: 'Problem Solving',
      shortLabel: 'Problem Solving',
      description: 'Step-by-step logic, numerical deduction, analytical breakdown, and procedural accuracy.',
      icon: Icons.extension_outlined,
      accentColor: Color(0xFF7950FF), // Violet
    ),
    SkillDimensionDef(
      id: criticalThinking,
      label: 'Critical Thinking',
      shortLabel: 'Critical Thinking',
      description: 'Evaluating claims, identifying assumptions, comparing arguments, and evidence analysis.',
      icon: Icons.lightbulb_outline_rounded,
      accentColor: Color(0xFFFBBF24), // Amber
    ),
    SkillDimensionDef(
      id: applicationSkills,
      label: 'Application Skills',
      shortLabel: 'Application',
      description: 'Transferring theoretical principles to real-world scenarios, case studies, and hands-on experiments.',
      icon: Icons.build_circle_outlined,
      accentColor: Color(0xFF10B981), // Emerald
    ),
    SkillDimensionDef(
      id: consistencyDiscipline,
      label: 'Consistency & Discipline',
      shortLabel: 'Discipline',
      description: 'Timeliness of submissions, rigorous task completion, homework streaks, and diligence.',
      icon: Icons.fact_check_outlined,
      accentColor: Color(0xFFEC4899), // Pink
    ),
    SkillDimensionDef(
      id: communicationExpression,
      label: 'Communication & Expression',
      shortLabel: 'Expression',
      description: 'Clarity of written solutions, descriptive depth, logical articulation, and reasoning structure.',
      icon: Icons.forum_outlined,
      accentColor: Color(0xFF8B5CF6), // Purple
    ),
  ];

  static SkillDimensionDef getById(String id) {
    return coreDimensions.firstWhere(
      (d) => d.id == id,
      orElse: () => coreDimensions.first,
    );
  }

  static List<String> get allIds => coreDimensions.map((d) => d.id).toList();
  static List<String> get allLabels => coreDimensions.map((d) => d.label).toList();
}

/// A single piece of verified assessment evidence mapping onto one or more skills
class SkillEvidenceModel {
  final String id;
  final String studentId;
  final String schoolId;
  final String skillId;
  final String dimensionName;
  final String source; // quiz_mcq, homework_task, exam, teacher_rubric, practical_assignment
  final String sourceTitle;
  final double rawScore;
  final double maxScore;
  final double normalizedScore; // 0.0 to 100.0
  final double weight; // Recency & source weighting multiplier
  final String subject;
  final String topic;
  final String? evaluatorId;
  final String? evaluatorName;
  final String? feedback;
  final int? rubricLevel; // 1 (Novice) to 5 (Advanced)
  final DateTime timestamp;
  final String periodKey; // e.g. "2026-11", "Term-1"

  const SkillEvidenceModel({
    required this.id,
    required this.studentId,
    required this.schoolId,
    required this.skillId,
    required this.dimensionName,
    required this.source,
    required this.sourceTitle,
    required this.rawScore,
    required this.maxScore,
    required this.normalizedScore,
    this.weight = 1.0,
    this.subject = 'General',
    this.topic = '',
    this.evaluatorId,
    this.evaluatorName,
    this.feedback,
    this.rubricLevel,
    required this.timestamp,
    required this.periodKey,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'schoolId': schoolId,
      'skillId': skillId,
      'dimensionName': dimensionName,
      'source': source,
      'sourceTitle': sourceTitle,
      'rawScore': rawScore,
      'maxScore': maxScore,
      'normalizedScore': normalizedScore,
      'weight': weight,
      'subject': subject,
      'topic': topic,
      'evaluatorId': evaluatorId,
      'evaluatorName': evaluatorName,
      'feedback': feedback,
      'rubricLevel': rubricLevel,
      'timestamp': Timestamp.fromDate(timestamp),
      'periodKey': periodKey,
    };
  }

  factory SkillEvidenceModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return SkillEvidenceModel(
      id: docId.isNotEmpty ? docId : (map['id'] ?? ''),
      studentId: map['studentId'] ?? '',
      schoolId: map['schoolId'] ?? '',
      skillId: map['skillId'] ?? SkillDimensionDef.conceptualUnderstanding,
      dimensionName: map['dimensionName'] ?? '',
      source: map['source'] ?? 'homework_task',
      sourceTitle: map['sourceTitle'] ?? '',
      rawScore: (map['rawScore'] as num?)?.toDouble() ?? 0.0,
      maxScore: (map['maxScore'] as num?)?.toDouble() ?? 100.0,
      normalizedScore: (map['normalizedScore'] as num?)?.toDouble() ?? 0.0,
      weight: (map['weight'] as num?)?.toDouble() ?? 1.0,
      subject: map['subject'] ?? 'General',
      topic: map['topic'] ?? '',
      evaluatorId: map['evaluatorId'],
      evaluatorName: map['evaluatorName'],
      feedback: map['feedback'],
      rubricLevel: (map['rubricLevel'] as num?)?.toInt(),
      timestamp: parseDate(map['timestamp']),
      periodKey: map['periodKey'] ?? '',
    );
  }
}

/// Evaluated score and confidence metrics for a single skill dimension
class SkillScoreModel {
  final String skillId;
  final String label;
  final double score; // 0.0 - 100.0
  final double? previousScore;
  final int activityCount;
  final String confidenceLevel; // 'low', 'moderate', 'high'
  final double confidencePercentage; // 0.0 - 100.0
  final bool isAssessed; // False if activityCount == 0 (honest zero-mock)
  final DateTime? lastAssessedAt;

  const SkillScoreModel({
    required this.skillId,
    required this.label,
    required this.score,
    this.previousScore,
    required this.activityCount,
    required this.confidenceLevel,
    required this.confidencePercentage,
    required this.isAssessed,
    this.lastAssessedAt,
  });

  double get delta => previousScore != null ? (score - previousScore!) : 0.0;

  String get trend {
    if (!isAssessed || previousScore == null) return 'unassessed';
    if (delta > 2.0) return 'up';
    if (delta < -2.0) return 'down';
    return 'stable';
  }

  Map<String, dynamic> toMap() {
    return {
      'skillId': skillId,
      'label': label,
      'score': score,
      'previousScore': previousScore,
      'activityCount': activityCount,
      'confidenceLevel': confidenceLevel,
      'confidencePercentage': confidencePercentage,
      'isAssessed': isAssessed,
      'lastAssessedAt': lastAssessedAt != null ? Timestamp.fromDate(lastAssessedAt!) : null,
    };
  }

  factory SkillScoreModel.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return SkillScoreModel(
      skillId: map['skillId'] ?? '',
      label: map['label'] ?? '',
      score: (map['score'] as num?)?.toDouble() ?? 0.0,
      previousScore: (map['previousScore'] as num?)?.toDouble(),
      activityCount: (map['activityCount'] as num?)?.toInt() ?? 0,
      confidenceLevel: map['confidenceLevel'] ?? 'low',
      confidencePercentage: (map['confidencePercentage'] as num?)?.toDouble() ?? 0.0,
      isAssessed: map['isAssessed'] ?? false,
      lastAssessedAt: parseDate(map['lastAssessedAt']),
    );
  }
}

/// Comprehensive Student Skill Intelligence Profile
class StudentSkillProfileModel {
  final String studentId;
  final String studentName;
  final String schoolId;
  final String periodKey;
  final Map<String, SkillScoreModel> skills;
  final double compositeScore;
  final List<String> strengths;
  final List<String> growthAreas;
  final double evidenceCoverage; // Percentage of the 6 dimensions assessed
  final DateTime lastCalculatedAt;

  // Explicit separation: Assignment Completion vs. Assessment Performance
  final double assignmentCompletionRate; // 0.0 to 100.0 (% tasks completed)
  final double assessmentPerformanceScore; // 0.0 to 100.0 (% exam/quiz scores)
  final int totalAssignmentsCount;
  final int completedAssignmentsCount;
  final int totalAssessmentsCount;
  final int completedAssessmentsCount;

  const StudentSkillProfileModel({
    required this.studentId,
    required this.studentName,
    required this.schoolId,
    required this.periodKey,
    required this.skills,
    required this.compositeScore,
    this.strengths = const [],
    this.growthAreas = const [],
    required this.evidenceCoverage,
    required this.lastCalculatedAt,
    this.assignmentCompletionRate = 0.0,
    this.assessmentPerformanceScore = 0.0,
    this.totalAssignmentsCount = 0,
    this.completedAssignmentsCount = 0,
    this.totalAssessmentsCount = 0,
    this.completedAssessmentsCount = 0,
  });

  List<double> get radarCurrentValues => SkillDimensionDef.coreDimensions.map((d) {
        final s = skills[d.id];
        return (s != null && s.isAssessed) ? s.score : 0.0;
      }).toList();

  List<double> get radarPreviousValues => SkillDimensionDef.coreDimensions.map((d) {
        final s = skills[d.id];
        return (s != null && s.previousScore != null) ? s.previousScore! : 0.0;
      }).toList();

  int get assessedDimensionsCount => skills.values.where((s) => s.isAssessed).length;

  int get totalActivitiesAssessed =>
      skills.values.fold(0, (acc, s) => acc + s.activityCount);

  List<String> get unassessedSkills => SkillDimensionDef.coreDimensions
      .where((d) => skills[d.id] == null || !skills[d.id]!.isAssessed)
      .map((d) => d.label)
      .toList();

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'schoolId': schoolId,
      'periodKey': periodKey,
      'skills': skills.map((k, v) => MapEntry(k, v.toMap())),
      'compositeScore': compositeScore,
      'strengths': strengths,
      'growthAreas': growthAreas,
      'evidenceCoverage': evidenceCoverage,
      'lastCalculatedAt': Timestamp.fromDate(lastCalculatedAt),
      'assignmentCompletionRate': assignmentCompletionRate,
      'assessmentPerformanceScore': assessmentPerformanceScore,
      'totalAssignmentsCount': totalAssignmentsCount,
      'completedAssignmentsCount': completedAssignmentsCount,
      'totalAssessmentsCount': totalAssessmentsCount,
      'completedAssessmentsCount': completedAssessmentsCount,
    };
  }

  factory StudentSkillProfileModel.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    final rawSkills = map['skills'] as Map<String, dynamic>? ?? {};
    final skillsMap = <String, SkillScoreModel>{};
    rawSkills.forEach((k, v) {
      if (v is Map<String, dynamic>) {
        skillsMap[k] = SkillScoreModel.fromMap(v);
      }
    });

    return StudentSkillProfileModel(
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      schoolId: map['schoolId'] ?? '',
      periodKey: map['periodKey'] ?? 'current',
      skills: skillsMap,
      compositeScore: (map['compositeScore'] as num?)?.toDouble() ?? 0.0,
      strengths: List<String>.from(map['strengths'] ?? []),
      growthAreas: List<String>.from(map['growthAreas'] ?? []),
      evidenceCoverage: (map['evidenceCoverage'] as num?)?.toDouble() ?? 0.0,
      lastCalculatedAt: parseDate(map['lastCalculatedAt']),
      assignmentCompletionRate: (map['assignmentCompletionRate'] as num?)?.toDouble() ?? 0.0,
      assessmentPerformanceScore: (map['assessmentPerformanceScore'] as num?)?.toDouble() ?? 0.0,
      totalAssignmentsCount: (map['totalAssignmentsCount'] as num?)?.toInt() ?? 0,
      completedAssignmentsCount: (map['completedAssignmentsCount'] as num?)?.toInt() ?? 0,
      totalAssessmentsCount: (map['totalAssessmentsCount'] as num?)?.toInt() ?? 0,
      completedAssessmentsCount: (map['completedAssessmentsCount'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Attributable Teacher Rubric Evaluation Record
class TeacherRubricEvaluationModel {
  final String id;
  final String schoolId;
  final String teacherId;
  final String teacherName;
  final String studentId;
  final String studentName;
  final String skillId;
  final int rubricLevel; // 1: Novice, 2: Developing, 3: Competent, 4: Proficient, 5: Advanced
  final double rubricScore; // 20, 40, 60, 80, 100
  final String assessmentTitle;
  final String evidenceNotes;
  final DateTime timestamp;

  const TeacherRubricEvaluationModel({
    required this.id,
    required this.schoolId,
    required this.teacherId,
    required this.teacherName,
    required this.studentId,
    required this.studentName,
    required this.skillId,
    required this.rubricLevel,
    required this.rubricScore,
    required this.assessmentTitle,
    required this.evidenceNotes,
    required this.timestamp,
  });

  static String getRubricLevelLabel(int level) {
    switch (level) {
      case 5:
        return 'Advanced (Mastery)';
      case 4:
        return 'Proficient (Consistent)';
      case 3:
        return 'Competent (Satisfactory)';
      case 2:
        return 'Developing (Emerging)';
      case 1:
      default:
        return 'Novice (Foundational)';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'schoolId': schoolId,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'studentId': studentId,
      'studentName': studentName,
      'skillId': skillId,
      'rubricLevel': rubricLevel,
      'rubricScore': rubricScore,
      'assessmentTitle': assessmentTitle,
      'evidenceNotes': evidenceNotes,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory TeacherRubricEvaluationModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return TeacherRubricEvaluationModel(
      id: docId.isNotEmpty ? docId : (map['id'] ?? ''),
      schoolId: map['schoolId'] ?? '',
      teacherId: map['teacherId'] ?? '',
      teacherName: map['teacherName'] ?? '',
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      skillId: map['skillId'] ?? SkillDimensionDef.conceptualUnderstanding,
      rubricLevel: (map['rubricLevel'] as num?)?.toInt() ?? 3,
      rubricScore: (map['rubricScore'] as num?)?.toDouble() ?? 60.0,
      assessmentTitle: map['assessmentTitle'] ?? 'Classroom Observation',
      evidenceNotes: map['evidenceNotes'] ?? '',
      timestamp: parseDate(map['timestamp']),
    );
  }
}

/// Historical Timeline Point for growth tracking
class SkillTimelinePoint {
  final String periodLabel;
  final DateTime date;
  final Map<String, double> scores;
  final double compositeScore;

  const SkillTimelinePoint({
    required this.periodLabel,
    required this.date,
    required this.scores,
    required this.compositeScore,
  });
}
