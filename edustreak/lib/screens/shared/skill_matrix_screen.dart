import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/skill_matrix_model.dart';
import '../../services/skill_matrix_service.dart';
import '../../utils/theme.dart';
import '../../widgets/app_logo.dart';

class SkillMatrixScreen extends StatefulWidget {
  final String studentId;
  final String? studentName;
  final bool showAppBar;
  final bool isTeacher;

  const SkillMatrixScreen({
    super.key,
    required this.studentId,
    this.studentName,
    this.showAppBar = true,
    this.isTeacher = false,
  });

  @override
  State<SkillMatrixScreen> createState() => _SkillMatrixScreenState();
}

class _SkillMatrixScreenState extends State<SkillMatrixScreen> {
  final SkillMatrixService _skillMatrixService = SkillMatrixService();
  SkillMatrixModel? _skillMatrix;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSkillMatrix();
  }

  Future<void> _loadSkillMatrix() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final skillMatrix = await _skillMatrixService.calculateSkillMatrix(widget.studentId);
      if (mounted) {
        setState(() {
          _skillMatrix = skillMatrix;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: widget.showAppBar
          ? AppBar(
              leading: Padding(
                padding: const EdgeInsets.only(left: 16),
                child: AppLogo(size: 30),
              ),
              leadingWidth: 66,
              flexibleSpace: Container(
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  boxShadow: AppTheme.primaryGlowShadow,
                ),
              ),
              foregroundColor: Colors.white,
              title: Text(
                widget.studentName ?? 'Skill Matrix',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadSkillMatrix,
                  tooltip: 'Refresh',
                ),
              ],
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading skill matrix',
                        style: TextStyle(color: Colors.red[700], fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: TextStyle(color: Colors.red[400], fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadSkillMatrix,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _skillMatrix == null
                  ? const Center(child: Text('No data available'))
                  : _buildSkillMatrixContent(),
    );
  }

  Widget _buildSkillMatrixContent() {
    final skillMatrix = _skillMatrix!;
    final skillValues = skillMatrix.skillValues;
    final skillLabels = SkillMatrixModel.skillLabels;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!widget.showAppBar) ...[
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Skill Matrix',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        skillMatrix.studentName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadSkillMatrix,
                  tooltip: 'Refresh',
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
          // Overall Score Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppTheme.primaryGlowShadow,
            ),
            child: Column(
              children: [
                Text(
                  'Overall Score',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${skillMatrix.overallScore.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: skillMatrix.overallScore / 100,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // ── Two Pillars: Practice Diligence vs Tested Mastery ──
          _buildDiligenceVsMasteryCards(skillMatrix),

          const SizedBox(height: 32),
          // Radar Chart
          Container(
            height: 400,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.darkSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.darkBorder,
                width: 1,
              ),
            ),
            child: RadarChart(
              RadarChartData(
                dataSets: [
                  RadarDataSet(
                    fillColor: AppTheme.primaryColor.withOpacity(0.3),
                    borderColor: AppTheme.primaryColor,
                    borderWidth: 2,
                    dataEntries: skillValues.map((value) {
                      return RadarEntry(value: value / 100); // Normalize to 0-1
                    }).toList(),
                  ),
                ],
                radarBorderData: BorderSide(
                  color: AppTheme.textTertiary.withOpacity(0.3),
                  width: 1,
                ),
                tickBorderData: BorderSide(
                  color: AppTheme.textTertiary.withOpacity(0.3),
                  width: 1,
                ),
                gridBorderData: BorderSide(
                  color: AppTheme.textTertiary.withOpacity(0.3),
                  width: 1,
                ),
                ticksTextStyle: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 10,
                ),
                tickCount: 5,
                radarShape: RadarShape.polygon,
                getTitle: (index, angle) {
                  return RadarChartTitle(
                    text: skillLabels[index],
                    angle: angle,
                    positionPercentageOffset: 0.15,
                  );
                },
                titleTextStyle: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          // Skill Details
          Text(
            'Skill Breakdown',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
          ),
          const SizedBox(height: 16),
          ...List.generate(skillLabels.length, (index) {
            return _buildSkillCard(
              skillLabels[index],
              skillValues[index],
              _getSkillIcon(skillLabels[index]),
              _getSkillColor(skillLabels[index]),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSkillCard(String label, double value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.darkBorder,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: value / 100,
                  backgroundColor: AppTheme.darkBorder,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '${value.toStringAsFixed(1)}%',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiligenceVsMasteryCards(SkillMatrixModel skillMatrix) {
    final profile = skillMatrix.profile;
    final hwRate = profile?.assignmentCompletionRate ?? skillMatrix.taskPerformance;
    final testScore = profile?.assessmentPerformanceScore ?? skillMatrix.conceptualUnderstanding;
    final totalHw = profile?.totalAssignmentsCount ?? 0;
    final doneHw = profile?.completedAssignmentsCount ?? 0;
    final totalTests = profile?.totalAssessmentsCount ?? 0;
    final doneTests = profile?.completedAssessmentsCount ?? 0;

    return Column(
      children: [
        // Two Pillars Row
        Row(
          children: [
            // Pillar 1: Practice Diligence (Homework)
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.darkSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF10B981).withOpacity(0.35)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.assignment_turned_in_rounded, color: Color(0xFF10B981), size: 18),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Practice Diligence',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${hwRate.toStringAsFixed(0)}%',
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          doneHw > 0 ? '($doneHw of $totalHw tasks)' : 'Homework completion',
                          style: const TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (hwRate / 100).clamp(0.0, 1.0),
                        backgroundColor: Colors.white10,
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                        minHeight: 5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Pillar 2: Tested Mastery (Assessments)
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.darkSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF06B6D4).withOpacity(0.35)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF06B6D4).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.quiz_rounded, color: Color(0xFF06B6D4), size: 18),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Tested Mastery',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${testScore.toStringAsFixed(0)}%',
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          doneTests > 0 ? '($doneTests of $totalTests tests evaluated)' : 'Exam & quiz accuracy',
                          style: const TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (testScore / 100).clamp(0.0, 1.0),
                        backgroundColor: Colors.white10,
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF06B6D4)),
                        minHeight: 5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Distinction Explanatory Banner (User prompt Section 8)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF6C57FF).withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF6C57FF).withOpacity(0.2)),
          ),
          child: Row(
            children: const [
              Icon(Icons.info_outline_rounded, color: Color(0xFFA855F7), size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Practice Diligence tracks homework consistency and deadlines. Tested Mastery evaluates retention and problem solving under test conditions.',
                  style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.3),
                ),
              ),
            ],
          ),
        ),

        // Strengths & Growth Areas (if available)
        if (profile != null && (profile.strengths.isNotEmpty || profile.growthAreas.isNotEmpty)) ...[
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (profile.strengths.isNotEmpty)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 14),
                            SizedBox(width: 6),
                            Text('Strong Concepts', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ...profile.strengths.take(3).map((s) => Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text('• $s', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                        )),
                      ],
                    ),
                  ),
                ),
              if (profile.strengths.isNotEmpty && profile.growthAreas.isNotEmpty)
                const SizedBox(width: 10),
              if (profile.growthAreas.isNotEmpty)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.bolt_rounded, color: Colors.amber, size: 14),
                            SizedBox(width: 6),
                            Text('Focus Concepts', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ...profile.growthAreas.take(3).map((g) => Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text('• $g', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                        )),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  IconData _getSkillIcon(String skill) {
    final lower = skill.toLowerCase();
    if (lower.contains('concept')) return Icons.psychology_outlined;
    if (lower.contains('problem')) return Icons.extension_outlined;
    if (lower.contains('critical')) return Icons.lightbulb_outline_rounded;
    if (lower.contains('application')) return Icons.build_circle_outlined;
    if (lower.contains('consistency') || lower.contains('discipline') || lower.contains('attendance')) return Icons.rule_rounded;
    if (lower.contains('communication') || lower.contains('expression') || lower.contains('participation')) return Icons.forum_outlined;
    if (lower.contains('challenge')) return Icons.emoji_events;
    if (lower.contains('task')) return Icons.assignment;
    if (lower.contains('progress')) return Icons.analytics;
    return Icons.star;
  }

  Color _getSkillColor(String skill) {
    final lower = skill.toLowerCase();
    if (lower.contains('concept')) return const Color(0xFF35C9FF);
    if (lower.contains('problem')) return const Color(0xFF7950FF);
    if (lower.contains('critical')) return const Color(0xFFFBBF24);
    if (lower.contains('application')) return const Color(0xFF10B981);
    if (lower.contains('consistency') || lower.contains('discipline') || lower.contains('attendance')) return const Color(0xFF3B82F6);
    if (lower.contains('communication') || lower.contains('expression') || lower.contains('participation')) return const Color(0xFFEC4899);
    return AppTheme.primaryColor;
  }
}

