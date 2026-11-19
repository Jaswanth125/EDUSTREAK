import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../models/user_model.dart';
import '../../models/task_model.dart';
import '../../models/assessment_model.dart';
import '../../services/task_service.dart';
import '../../services/assessment_service.dart';
import '../../utils/edustreak_theme.dart';
import '../shared/skill_matrix_screen.dart';

/// Comprehensive Student Progress Screen embedding the 6-Axis Skill Intelligence Graph
/// alongside authentic, real-time subject mastery and homework completion analytics.
class StudentProgressScreen extends StatefulWidget {
  const StudentProgressScreen({super.key});

  @override
  State<StudentProgressScreen> createState() => _StudentProgressScreenState();
}

class _StudentProgressScreenState extends State<StudentProgressScreen> with SingleTickerProviderStateMixin {
  late TabController _viewTabController;
  late final TaskService _taskService = TaskService();
  late final AssessmentService _assessmentService = AssessmentService();

  String _timeframeFilter = 'This Month';

  @override
  void initState() {
    super.initState();
    _viewTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _viewTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final currentUser = userProvider.currentUser;

    if (currentUser == null) {
      return const Center(
        child: CircularProgressIndicator(color: EduStreakTheme.primaryViolet),
      );
    }

    return Container(
      color: EduStreakTheme.studentDarkBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar & View Switcher
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPageHeader(),
                const SizedBox(height: 16),
                _buildViewTabBar(),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Main Views
          Expanded(
            child: TabBarView(
              controller: _viewTabController,
              children: [
                // 1. Competency Skill Matrix (Embedded 6-Axis Radar Graph)
                SkillMatrixScreen(
                  studentId: currentUser.id,
                  studentName: currentUser.name,
                  showAppBar: false,
                ),

                // 2. Academic & Subject Mastery (Real Firestore Data)
                _buildAcademicMasteryView(currentUser),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── PAGE HEADER ────────────────────────────────────────────────────────
  Widget _buildPageHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: EduStreakTheme.primaryViolet.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: EduStreakTheme.primaryViolet.withValues(alpha: 0.4),
              width: 1.2,
            ),
          ),
          child: const Icon(Icons.insights_rounded, color: EduStreakTheme.primaryViolet, size: 22),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Student Progress & Competency 📊',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 2),
              Text(
                'Evaluate real learning competencies, subject mastery, and homework grades.',
                style: TextStyle(
                  color: EduStreakTheme.studentDarkTextMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── VIEW TAB BAR ───────────────────────────────────────────────────────
  Widget _buildViewTabBar() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: EduStreakTheme.studentDarkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: EduStreakTheme.studentDarkBorder),
      ),
      child: TabBar(
        controller: _viewTabController,
        indicator: BoxDecoration(
          color: EduStreakTheme.primaryViolet,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: EduStreakTheme.studentDarkTextMuted,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        tabs: const [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.radar_rounded, size: 16),
                SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Skill Matrix',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_stories_rounded, size: 16),
                SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Subject Mastery',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── ACADEMIC MASTERY VIEW (TIED TO REAL TASKS & ASSESSMENTS) ───────────
  Widget _buildAcademicMasteryView(UserModel user) {
    return StreamBuilder<List<TaskModel>>(
      stream: _taskService.getTasksForStudent(user.id),
      builder: (context, taskSnapshot) {
        if (taskSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: EduStreakTheme.primaryViolet),
          );
        }

        final tasks = taskSnapshot.data ?? [];
        final totalTasks = tasks.length;
        final submittedTasks = tasks.where((t) {
          final sub = t.submissions[user.id];
          return sub == 'submitted' || sub == 'completed';
        }).length;

        final gradedTasks = tasks.where((t) => t.marks[user.id] != null).toList();
        double totalMarksPercent = 0.0;
        for (var t in gradedTasks) {
          final mark = (t.marks[user.id] as num).toDouble();
          totalMarksPercent += mark; // Marks are recorded 0-100
        }
        final averageGrade = gradedTasks.isNotEmpty
            ? (totalMarksPercent / gradedTasks.length).round()
            : 0;

        final completionRate = totalTasks > 0
            ? ((submittedTasks / totalTasks) * 100).round()
            : 0;

        // Group tasks by subject
        final Map<String, List<TaskModel>> subjectTasks = {};
        for (var t in tasks) {
          final subj = t.subject.isNotEmpty ? t.subject : 'General';
          subjectTasks.putIfAbsent(subj, () => []).add(t);
        }

        return StreamBuilder<List<AssessmentModel>>(
          stream: _assessmentService.getAssessmentsForStudent(
            studentId: user.id,
            classId: user.classId,
          ),
          builder: (context, assessSnapshot) {
            final assessments = assessSnapshot.data ?? [];
            final totalAssessments = assessments.length;
            final scoredAssessments = assessments.where((a) => a.scores.containsKey(user.id)).toList();

            double testScoreSum = 0.0;
            for (final a in scoredAssessments) {
              final s = a.scores[user.id] ?? 0.0;
              if (a.totalMarks > 0) {
                testScoreSum += (s / a.totalMarks) * 100.0;
              }
            }
            final avgTestMastery = scoredAssessments.isNotEmpty
                ? (testScoreSum / scoredAssessments.length).round()
                : 0;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timeframe filter pills
                  _buildTimeframeFilterPills(),
                  const SizedBox(height: 16),

                  // KPI Summary Cards: Diligence vs Tested Mastery
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 700;
                      return isWide
                          ? Row(
                              children: [
                                Expanded(child: _buildMetricCard('Homework Diligence', '$completionRate%', '$submittedTasks of $totalTasks submitted', Icons.task_alt_rounded, const Color(0xFF10B981))),
                                const SizedBox(width: 12),
                                Expanded(child: _buildMetricCard('Tested Mastery', scoredAssessments.isNotEmpty ? '$avgTestMastery%' : 'No Tests Scored', '${scoredAssessments.length} of $totalAssessments exams scored', Icons.quiz_rounded, const Color(0xFF06B6D4))),
                                const SizedBox(width: 12),
                                Expanded(child: _buildMetricCard('Avg HW Grade', averageGrade > 0 ? '$averageGrade%' : 'Not Graded', '${gradedTasks.length} tasks evaluated', Icons.grade_rounded, const Color(0xFFFBBF24))),
                                const SizedBox(width: 12),
                                Expanded(child: _buildMetricCard('Lifetime XP Earned', '${user.xp} XP', 'Level ${user.level} Scholar', Icons.bolt_rounded, const Color(0xFF38BDF8))),
                              ],
                            )
                          : Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: _buildMetricCard('Homework Diligence', '$completionRate%', '$submittedTasks of $totalTasks submitted', Icons.task_alt_rounded, const Color(0xFF10B981))),
                                    const SizedBox(width: 12),
                                    Expanded(child: _buildMetricCard('Tested Mastery', scoredAssessments.isNotEmpty ? '$avgTestMastery%' : 'No Tests', '${scoredAssessments.length} of $totalAssessments exams scored', Icons.quiz_rounded, const Color(0xFF06B6D4))),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(child: _buildMetricCard('Avg HW Grade', averageGrade > 0 ? '$averageGrade%' : 'Not Graded', '${gradedTasks.length} tasks evaluated', Icons.grade_rounded, const Color(0xFFFBBF24))),
                                    const SizedBox(width: 12),
                                    Expanded(child: _buildMetricCard('Lifetime XP Earned', '${user.xp} XP', 'Level ${user.level} Scholar', Icons.bolt_rounded, const Color(0xFF38BDF8))),
                                  ],
                                ),
                              ],
                            );
                    },
                  ),

                  const SizedBox(height: 16),

                  // Explanatory Banner: Section 8 prompt requirement
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C57FF).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF6C57FF).withOpacity(0.25)),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.info_outline_rounded, color: Color(0xFFA855F7), size: 18),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Practice Diligence tracks homework consistency and deadlines. Tested Mastery evaluates retention and problem solving under test conditions.',
                            style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Subject Breakdown Section
                  const Text(
                    'Subject Performance Breakdown',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),

              if (subjectTasks.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: EduStreakTheme.studentDarkCard,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: EduStreakTheme.studentDarkBorder),
                  ),
                  child: const Center(
                    child: Column(
                      children: [
                        Icon(Icons.assignment_outlined, size: 44, color: EduStreakTheme.studentDarkTextMuted),
                        SizedBox(height: 10),
                        Text(
                          'No homework tasks assigned yet',
                          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'When teachers assign and evaluate tasks, subject mastery will be calculated here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: EduStreakTheme.studentDarkTextMuted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...subjectTasks.entries.map((entry) {
                  final subj = entry.key;
                  final list = entry.value;
                  final subTotal = list.length;
                  final subDone = list.where((t) {
                    final s = t.submissions[user.id];
                    return s == 'submitted' || s == 'completed';
                  }).length;
                  final subPct = subTotal > 0 ? (subDone / subTotal) : 0.0;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: EduStreakTheme.studentDarkCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: EduStreakTheme.studentDarkBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              subj,
                              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                            ),
                            Text(
                              '$subDone/$subTotal Tasks Completed (${(subPct * 100).toInt()}%)',
                              style: const TextStyle(color: EduStreakTheme.studentDarkTextMuted, fontSize: 12.5),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: subPct,
                            minHeight: 8,
                            backgroundColor: EduStreakTheme.studentDarkCardSub,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              subPct >= 0.75
                                  ? const Color(0xFF10B981)
                                  : (subPct >= 0.4 ? const Color(0xFFFBBF24) : EduStreakTheme.primaryViolet),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          );
        },
      );
    },
  );
}

  Widget _buildTimeframeFilterPills() {
    final filters = ['This Week', 'This Month', 'This Term', 'All Time'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final isSelected = _timeframeFilter == f;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(f),
              selected: isSelected,
              onSelected: (_) => setState(() => _timeframeFilter = f),
              backgroundColor: EduStreakTheme.studentDarkCard,
              selectedColor: EduStreakTheme.primaryViolet,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : EduStreakTheme.studentDarkTextMuted,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
              side: BorderSide(
                color: isSelected ? EduStreakTheme.primaryViolet : EduStreakTheme.studentDarkBorder,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: EduStreakTheme.studentDarkCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: EduStreakTheme.studentDarkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: EduStreakTheme.studentDarkTextMuted, fontSize: 13, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: EduStreakTheme.studentDarkTextMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
