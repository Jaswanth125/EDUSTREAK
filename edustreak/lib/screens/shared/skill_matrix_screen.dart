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

  const SkillMatrixScreen({
    super.key,
    required this.studentId,
    this.studentName,
    this.showAppBar = true,
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

  IconData _getSkillIcon(String skill) {
    switch (skill) {
      case 'Attendance':
        return Icons.calendar_today;
      case 'Task Performance':
        return Icons.assignment;
      case 'Engagement':
        return Icons.trending_up;
      case 'Participation':
        return Icons.people;
      case 'Challenges':
        return Icons.emoji_events;
      case 'Overall Progress':
        return Icons.analytics;
      default:
        return Icons.star;
    }
  }

  Color _getSkillColor(String skill) {
    switch (skill) {
      case 'Attendance':
        return Colors.green;
      case 'Task Performance':
        return Colors.blue;
      case 'Engagement':
        return Colors.orange;
      case 'Participation':
        return Colors.purple;
      case 'Challenges':
        return Colors.amber;
      case 'Overall Progress':
        return AppTheme.primaryColor;
      default:
        return Colors.grey;
    }
  }
}

