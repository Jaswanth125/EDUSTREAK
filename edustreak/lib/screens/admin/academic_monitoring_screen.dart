import 'package:flutter/material.dart';
import '../../models/school_model.dart';
import '../../services/school_service.dart';
import '../../utils/edustreak_theme.dart';

class AcademicMonitoringScreen extends StatefulWidget {
  const AcademicMonitoringScreen({super.key});

  @override
  State<AcademicMonitoringScreen> createState() => _AcademicMonitoringScreenState();
}

class _AcademicMonitoringScreenState extends State<AcademicMonitoringScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _schoolService = SchoolService();
  List<SchoolModel> _schools = [];
  String? _selectedSchoolId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSchools();
  }

  Future<void> _loadSchools() async {
    try {
      final stream = _schoolService.getSchoolsStream();
      final list = await stream.first;
      if (mounted) setState(() => _schools = list);
    } catch (_) {}
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF070B1E),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1535),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: EduStreakTheme.cardBorder),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 750;
                final titleWidget = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Academic Performance & Monitoring', style: EduStreakTheme.fontHeading3(color: Colors.white, weight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text('Real-time homework completion, term assessments pass rates, and pedagogical quality audits.', style: EduStreakTheme.fontCaption(color: EduStreakTheme.textMuted)),
                  ],
                );

                final controlsWidget = Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: isCompact ? double.infinity : 220,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141A42),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF26326E)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String?>(
                            value: _selectedSchoolId,
                            dropdownColor: const Color(0xFF141A42),
                            isExpanded: true,
                            hint: const Text('All Institutions', style: TextStyle(color: Colors.white70, fontSize: 12), overflow: TextOverflow.ellipsis),
                            icon: const Icon(Icons.arrow_drop_down, color: Colors.white54),
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            items: [
                              const DropdownMenuItem<String?>(value: null, child: Text('All Institutions', overflow: TextOverflow.ellipsis)),
                              ..._schools.map((s) => DropdownMenuItem<String?>(value: s.id, child: Text('${s.name} (${s.code})', overflow: TextOverflow.ellipsis))),
                            ],
                            onChanged: (val) => setState(() => _selectedSchoolId = val),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF141A42),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF26326E)),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        indicator: BoxDecoration(
                          color: EduStreakTheme.primaryViolet,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white60,
                        tabs: const [
                          Tab(text: 'Homework & Assignments'),
                          Tab(text: 'Examinations & Pass Rates'),
                          Tab(text: 'Learning Activity & Quizzes'),
                        ],
                      ),
                    ),
                  ],
                );

                if (isCompact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      titleWidget,
                      const SizedBox(height: 14),
                      controlsWidget,
                    ],
                  );
                }

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: titleWidget),
                    const SizedBox(width: 16),
                    controlsWidget,
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          // Tabs
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildHomeworkTab(),
                _buildExaminationsTab(),
                _buildActivityTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeworkTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < 650;
              final c1 = _buildMetricCard('Total Assigned Tasks', '2,480', Icons.assignment_rounded, const Color(0xFF7C6FFF));
              final c2 = _buildMetricCard('On-Time Submissions', '88.4%', Icons.done_all_rounded, Colors.greenAccent);
              final c3 = _buildMetricCard('Pending Evaluations', '312', Icons.pending_actions_rounded, Colors.orangeAccent);
              final c4 = _buildMetricCard('Overdue Tasks', '4.2%', Icons.warning_amber_rounded, Colors.redAccent);

              if (isSmall) {
                return Column(
                  children: [
                    Row(children: [Expanded(child: c1), const SizedBox(width: 12), Expanded(child: c2)]),
                    const SizedBox(height: 12),
                    Row(children: [Expanded(child: c3), const SizedBox(width: 12), Expanded(child: c4)]),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: c1),
                  const SizedBox(width: 16),
                  Expanded(child: c2),
                  const SizedBox(width: 16),
                  Expanded(child: c3),
                  const SizedBox(width: 16),
                  Expanded(child: c4),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1535),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: EduStreakTheme.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Recent State-Wide Assignments', style: EduStreakTheme.fontHeading3(color: Colors.white, weight: FontWeight.w700)),
                const SizedBox(height: 14),
                _buildAssignmentRow('Class 10 Mathematics: Quadratic Equations Problem Set', 'Z.P. High School, Kankipadu', '94% Submitted', 'Due Today'),
                _buildAssignmentRow('Class 9 Physical Science: Motion & Laws of Newton', 'AP Model School, Guntur Rural', '82% Submitted', 'Due Tomorrow'),
                _buildAssignmentRow('Class 8 English: Christmas Carol Comprehension', 'Kendriya Vidyalaya No. 1, Vijayawada', '98% Submitted', 'Due in 2 days'),
                _buildAssignmentRow('Class 10 Social: Climate of India Chart & Map Work', 'Sri Chaitanya Techno School, Tirupati', '91% Submitted', 'Due in 3 days'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentRow(String title, String school, String sub, String due) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 500;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: EduStreakTheme.primaryViolet.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.assignment_turned_in_rounded, size: 18, color: EduStreakTheme.primaryVioletLight),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: EduStreakTheme.fontLabel(color: Colors.white, weight: FontWeight.w700), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(school, style: EduStreakTheme.fontCaption(color: EduStreakTheme.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (isCompact) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                            child: Text(sub, style: const TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                          Text(due, style: EduStreakTheme.fontCaption(color: Colors.white60)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (!isCompact) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                  child: Text(sub, style: const TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Text(due, style: EduStreakTheme.fontCaption(color: Colors.white60)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildExaminationsTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < 650;
              final c1 = _buildMetricCard('State Pass Percentage', '91.8%', Icons.military_tech_rounded, Colors.greenAccent);
              final c2 = _buildMetricCard('A1 Grade Rate', '34.2%', Icons.grade_rounded, Colors.cyanAccent);
              final c3 = _buildMetricCard('Remediation Required', '8.2%', Icons.support_agent_rounded, Colors.redAccent);

              if (isSmall) {
                return Column(
                  children: [
                    Row(children: [Expanded(child: c1), const SizedBox(width: 12), Expanded(child: c2)]),
                    const SizedBox(height: 12),
                    c3,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: c1),
                  const SizedBox(width: 16),
                  Expanded(child: c2),
                  const SizedBox(width: 16),
                  Expanded(child: c3),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1535),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: EduStreakTheme.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Scheduled State Assessment Calendar (2024-2025)', style: EduStreakTheme.fontHeading3(color: Colors.white, weight: FontWeight.w700)),
                const SizedBox(height: 14),
                _buildExamRow('Formative Assessment 1 (FA-1)', 'July 2024', 'Completed', Colors.greenAccent),
                _buildExamRow('Formative Assessment 2 (FA-2)', 'September 2024', 'Completed', Colors.greenAccent),
                _buildExamRow('Summative Assessment 1 (SA-1 Half Yearly)', 'November 2024', 'Completed', Colors.greenAccent),
                _buildExamRow('Formative Assessment 3 (FA-3)', 'January 2025', 'Active Published', Colors.cyanAccent),
                _buildExamRow('Summative Assessment 2 (SA-2 Final Board)', 'April 2025', 'Scheduled', Colors.orangeAccent),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamRow(String title, String month, String status, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 500;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.quiz_rounded, size: 18, color: Colors.white70),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: EduStreakTheme.fontLabel(color: Colors.white, weight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                    if (isCompact) ...[
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(month, style: EduStreakTheme.fontCaption(color: EduStreakTheme.textMuted)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                            child: Text(status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (!isCompact) ...[
                const SizedBox(width: 12),
                Text(month, style: EduStreakTheme.fontCaption(color: EduStreakTheme.textMuted)),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                  child: Text(status, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildActivityTab() {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1535),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: EduStreakTheme.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Practice Arena & AI Study Sessions', style: EduStreakTheme.fontHeading3(color: Colors.white, weight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Aggregated live metrics for interactive student learning on EduStreak.', style: EduStreakTheme.fontCaption(color: EduStreakTheme.textMuted)),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                final isSmall = constraints.maxWidth < 650;
                final c1 = _buildMetricCard('Quizzes Attempted Today', '4,890', Icons.sports_esports_rounded, const Color(0xFF00E5FF));
                final c2 = _buildMetricCard('Average Quiz Score', '86.4%', Icons.insights_rounded, Colors.greenAccent);
                final c3 = _buildMetricCard('Avg AI Buddy Session', '18.4 mins', Icons.auto_awesome_rounded, EduStreakTheme.primaryVioletLight);

                if (isSmall) {
                  return Column(
                    children: [
                      Row(children: [Expanded(child: c1), const SizedBox(width: 12), Expanded(child: c2)]),
                      const SizedBox(height: 12),
                      c3,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: c1),
                    const SizedBox(width: 16),
                    Expanded(child: c2),
                    const SizedBox(width: 16),
                    Expanded(child: c3),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String val, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF141A42),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(val, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                Text(title, style: EduStreakTheme.fontCaption(color: EduStreakTheme.textMuted), overflow: TextOverflow.ellipsis, maxLines: 1),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
