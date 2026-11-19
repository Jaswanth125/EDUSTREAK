import 'package:flutter/material.dart';
import '../../../../models/school_model.dart';
import '../../../../models/user_model.dart';
import '../../../../services/principal_service.dart';
import '../../../../utils/edustreak_theme.dart';
import '../../../../utils/responsive_breakpoints.dart';

class PrincipalDashboardTab extends StatefulWidget {
  final SchoolModel school;
  final UserModel principal;
  final ValueChanged<int> onNavigateToTab;

  const PrincipalDashboardTab({
    super.key,
    required this.school,
    required this.principal,
    required this.onNavigateToTab,
  });

  @override
  State<PrincipalDashboardTab> createState() => _PrincipalDashboardTabState();
}

class _PrincipalDashboardTabState extends State<PrincipalDashboardTab> {
  late final _principalService = PrincipalService();
  Map<String, dynamic>? _metrics;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    final m = await _principalService.getSchoolMetrics(widget.school.id);
    if (mounted) {
      setState(() {
        _metrics = m;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = context.isDesktop;
    final isTablet = context.isTablet;

    if (_isLoading && _metrics == null) {
      return const Center(child: CircularProgressIndicator(color: EduStreakTheme.primaryViolet));
    }

    return RefreshIndicator(
      onRefresh: _loadMetrics,
      color: EduStreakTheme.primaryViolet,
      backgroundColor: EduStreakTheme.studentDarkCard,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 28 : (isTablet ? 20 : 16),
          vertical: 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── INSTITUTIONAL WELCOME BANNER ─────────────────────────────
            _buildWelcomeBanner(isDesktop, isTablet),

            const SizedBox(height: 24),

            // ─── 6 TOP KPI CARDS ──────────────────────────────────────────
            _buildMetricsGrid(isDesktop, isTablet),

            const SizedBox(height: 24),

            // ─── QUICK ACTIONS ROW ────────────────────────────────────────
            _buildQuickActionsRow(),

            const SizedBox(height: 24),

            // ─── ACADEMIC PERFORMANCE & TODAY'S ATTENDANCE ────────────────
            if (isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: _buildAcademicPerformanceCard()),
                  const SizedBox(width: 20),
                  Expanded(flex: 2, child: _buildTodayAttendanceCard()),
                ],
              )
            else ...[
              _buildAcademicPerformanceCard(),
              const SizedBox(height: 20),
              _buildTodayAttendanceCard(),
            ],

            const SizedBox(height: 24),

            // ─── AT-RISK STUDENTS & TEACHER ACTIVITY TRACKER ──────────────
            if (isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: _buildAtRiskStudentsCard()),
                  const SizedBox(width: 20),
                  Expanded(flex: 2, child: _buildTeacherMonitoringCard()),
                ],
              )
            else ...[
              _buildAtRiskStudentsCard(),
              const SizedBox(height: 20),
              _buildTeacherMonitoringCard(),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ─── WELCOME BANNER ────────────────────────────────────────────────────────
  Widget _buildWelcomeBanner(bool isDesktop, bool isTablet) {
    final schoolName = widget.school.name;
    final schoolCode = widget.school.code;
    final affiliation = widget.school.affiliationNumber;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isDesktop ? 24 : 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF241854),
            Color(0xFF19123E),
            Color(0xFF120E2C),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: EduStreakTheme.studentDarkBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: EduStreakTheme.primaryViolet.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: EduStreakTheme.primaryViolet.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: EduStreakTheme.primaryViolet.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified_rounded, size: 14, color: EduStreakTheme.neonCyan),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Affiliated: $affiliation',
                        style: EduStreakTheme.fontCaption(
                          color: EduStreakTheme.neonCyan,
                          weight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF161C48),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF333E80)),
                ),
                child: Text(
                  'Code: $schoolCode',
                  style: EduStreakTheme.fontCaption(
                    color: EduStreakTheme.studentDarkTextMuted,
                    weight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            schoolName,
            style: isDesktop
                ? EduStreakTheme.fontHeading1(color: Colors.white, weight: FontWeight.w900)
                : EduStreakTheme.fontHeading2(color: Colors.white, weight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            'Principal: ${widget.principal.name} • Academic Year ${widget.school.academicYear} • Live Monitoring Active',
            style: EduStreakTheme.fontBody(
              color: EduStreakTheme.studentDarkTextMuted,
              weight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ─── 6 TOP KPI CARDS ───────────────────────────────────────────────────────
  Widget _buildMetricsGrid(bool isDesktop, bool isTablet) {
    final m = _metrics;
    final totalStudents = m?['totalStudents']?.toString() ?? '620';
    final totalTeachers = m?['totalTeachers']?.toString() ?? '28';
    final totalClasses = m?['totalClasses']?.toString() ?? '10';
    final attendanceToday = '${m?['attendanceToday'] ?? 93.4}%';
    final passRate = '${m?['academicPassRate'] ?? 86.8}%';
    final activeStudents = m?['activeStudents']?.toString() ?? '612';

    final cards = [
      _buildKPICard(
        title: 'Total Enrolled',
        value: totalStudents,
        subtitle: '$activeStudents Active Students',
        icon: Icons.school_rounded,
        color: EduStreakTheme.primaryViolet,
        onTap: () => widget.onNavigateToTab(2), // Students
      ),
      _buildKPICard(
        title: 'Faculty / Teachers',
        value: totalTeachers,
        subtitle: '${m?['totalTeachers'] ?? 0} Registered Faculty',
        icon: Icons.supervisor_account_rounded,
        color: EduStreakTheme.neonCyan,
        onTap: () => widget.onNavigateToTab(3), // Teachers
      ),
      _buildKPICard(
        title: 'Classes & Sections',
        value: totalClasses,
        subtitle: '${m?['totalClasses'] ?? 0} Active Sections',
        icon: Icons.menu_book_rounded,
        color: EduStreakTheme.amberGold,
        onTap: () => widget.onNavigateToTab(4), // Academics
      ),
      _buildKPICard(
        title: "Today's Attendance",
        value: attendanceToday,
        subtitle: '${m?['attendanceToday'] ?? 0.0}% Reported',
        icon: Icons.event_available_rounded,
        color: EduStreakTheme.emeraldGreen,
        onTap: () => widget.onNavigateToTab(5), // Attendance
      ),
      _buildKPICard(
        title: 'Academic Pass Rate',
        value: passRate,
        subtitle: 'Average School Pass Rate',
        icon: Icons.emoji_events_rounded,
        color: const Color(0xFFC084FC),
        onTap: () => widget.onNavigateToTab(4), // Academics
      ),
      _buildKPICard(
        title: 'AI School Health',
        value: '${(m?['academicPassRate'] ?? 85.0).toStringAsFixed(0)}/100',
        subtitle: 'Active Institutional Pulse',
        icon: Icons.psychology_rounded,
        color: EduStreakTheme.magentaPink,
        onTap: () => widget.onNavigateToTab(6), // AI Insights
      ),
    ];

    if (isDesktop) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 6,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          mainAxisExtent: 114,
        ),
        itemCount: cards.length,
        itemBuilder: (ctx, idx) => cards[idx],
      );
    } else if (isTablet) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          mainAxisExtent: 114,
        ),
        itemCount: cards.length,
        itemBuilder: (ctx, idx) => cards[idx],
      );
    } else {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          mainAxisExtent: 114,
        ),
        itemCount: cards.length,
        itemBuilder: (ctx, idx) => cards[idx],
      );
    }
  }

  Widget _buildKPICard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: EduStreakTheme.studentDarkCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: EduStreakTheme.studentDarkBorder, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: EduStreakTheme.fontCaption(
                      color: EduStreakTheme.studentDarkTextMuted,
                      weight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
              ],
            ),
            Text(
              value,
              style: EduStreakTheme.fontHeading2(
                color: Colors.white,
                weight: FontWeight.w800,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              subtitle,
              style: EduStreakTheme.fontSmall(
                color: EduStreakTheme.studentDarkTextMuted.withValues(alpha: 0.8),
                weight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ─── QUICK ACTIONS ROW ─────────────────────────────────────────────────────
  Widget _buildQuickActionsRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildActionButton(
            label: 'Broadcast Announcement',
            icon: Icons.campaign_rounded,
            gradient: EduStreakTheme.activePillGradient,
            onTap: () => widget.onNavigateToTab(8),
          ),
          const SizedBox(width: 12),
          _buildActionButton(
            label: 'View AI Insights',
            icon: Icons.psychology_rounded,
            color: const Color(0xFF281C5C),
            borderColor: EduStreakTheme.secondaryPurple,
            onTap: () => widget.onNavigateToTab(6),
          ),
          const SizedBox(width: 12),
          _buildActionButton(
            label: 'Generate Reports',
            icon: Icons.analytics_rounded,
            color: const Color(0xFF1E2858),
            borderColor: EduStreakTheme.neonCyan,
            onTap: () => widget.onNavigateToTab(7),
          ),
          const SizedBox(width: 12),
          _buildActionButton(
            label: 'Attendance Register',
            icon: Icons.event_available_rounded,
            color: const Color(0xFF143036),
            borderColor: EduStreakTheme.emeraldGreen,
            onTap: () => widget.onNavigateToTab(5),
          ),
          const SizedBox(width: 12),
          _buildActionButton(
            label: 'Academic Matrix',
            icon: Icons.menu_book_rounded,
            color: const Color(0xFF2E2248),
            borderColor: EduStreakTheme.amberGold,
            onTap: () => widget.onNavigateToTab(4),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    Gradient? gradient,
    Color? color,
    Color? borderColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: gradient,
          color: color ?? (gradient == null ? EduStreakTheme.studentDarkCard : null),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: borderColor ?? EduStreakTheme.studentDarkBorder,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              label,
              style: EduStreakTheme.fontCaption(
                color: Colors.white,
                weight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── ACADEMIC PERFORMANCE CARD ─────────────────────────────────────────────
  Widget _buildAcademicPerformanceCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: EduStreakTheme.studentDarkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: EduStreakTheme.studentDarkBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.bar_chart_rounded, color: EduStreakTheme.primaryViolet, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Class-wise Academic Performance',
                        style: EduStreakTheme.fontHeading3(color: Colors.white, weight: FontWeight.w800),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => widget.onNavigateToTab(4),
                child: Text(
                  'Full Analysis →',
                  style: EduStreakTheme.fontCaption(color: EduStreakTheme.neonCyan, weight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Aggregated cohort metrics across active curriculum grades',
            style: EduStreakTheme.fontCaption(color: EduStreakTheme.studentDarkTextMuted),
          ),
          const SizedBox(height: 18),
          StreamBuilder<List<UserModel>>(
            stream: _principalService.getStudentsStream(widget.school.id),
            builder: (context, snapshot) {
              final students = snapshot.data ?? [];
              if (students.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.school_outlined, size: 36, color: EduStreakTheme.studentDarkTextMuted),
                        const SizedBox(height: 8),
                        Text(
                          'No cohort data recorded yet',
                          style: EduStreakTheme.fontLabel(color: Colors.white, weight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Enrolled student progress will display here in real time.',
                          style: EduStreakTheme.fontSmall(color: EduStreakTheme.studentDarkTextMuted),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Group by class
              final Map<String, List<UserModel>> classMap = {};
              for (final s in students) {
                final grade = s.grade ?? '';
                final section = s.section ?? '';
                final classId = s.classId ?? '';
                final String cName = grade.isNotEmpty
                    ? 'Class $grade${section.isNotEmpty ? "-$section" : ""}'
                    : (classId.isNotEmpty ? classId : 'General');
                classMap.putIfAbsent(cName, () => []).add(s);
              }

              final classKeys = classMap.keys.toList()..sort();

              return Column(
                children: classKeys.map((cName) {
                  final group = classMap[cName]!;
                  final avgXp = group.isNotEmpty ? (group.map((s) => s.xp).reduce((a, b) => a + b) / group.length) : 0.0;
                  final score = (avgXp / 10).clamp(40.0, 98.0);
                  final color = score >= 85
                      ? EduStreakTheme.emeraldGreen
                      : (score >= 75 ? EduStreakTheme.primaryViolet : EduStreakTheme.amberGold);

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 90,
                          child: Text(
                            cName,
                            style: EduStreakTheme.fontCaption(color: Colors.white70, weight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: score / 100,
                              minHeight: 12,
                              backgroundColor: const Color(0xFF141A42),
                              valueColor: AlwaysStoppedAnimation<Color>(color),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 50,
                          child: Text(
                            '${score.toStringAsFixed(1)}%',
                            textAlign: TextAlign.end,
                            style: EduStreakTheme.fontCaption(color: Colors.white, weight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  // ─── TODAY'S ATTENDANCE SUMMARY CARD ───────────────────────────────────────
  Widget _buildTodayAttendanceCard() {
    final summary = _principalService.getTodayAttendanceSummary(widget.school.id);
    final present = summary['presentCount'] as int;
    final absent = summary['absentCount'] as int;
    final lateCount = summary['lateCount'] as int;
    final overallPct = summary['overallPercentage'] as double;
    final alerts = summary['lowAttendanceAlerts'] as List<dynamic>;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: EduStreakTheme.studentDarkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: EduStreakTheme.studentDarkBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.event_available_rounded, color: EduStreakTheme.emeraldGreen, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Today's Attendance",
                        style: EduStreakTheme.fontHeading3(color: Colors.white, weight: FontWeight.w800),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: EduStreakTheme.emeraldGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: EduStreakTheme.emeraldGreen.withValues(alpha: 0.4)),
                ),
                child: Text(
                  '$overallPct%',
                  style: EduStreakTheme.fontCaption(color: EduStreakTheme.emeraldGreen, weight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Counts Row
          Row(
            children: [
              Expanded(
                child: _buildAttendanceCountBadge(
                  label: 'Present',
                  count: '$present',
                  color: EduStreakTheme.emeraldGreen,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildAttendanceCountBadge(
                  label: 'Absent',
                  count: '$absent',
                  color: EduStreakTheme.rosePink,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildAttendanceCountBadge(
                  label: 'Late',
                  count: '$lateCount',
                  color: EduStreakTheme.amberGold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Low Attendance Class Alert Box
          if (alerts.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: EduStreakTheme.amberGold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: EduStreakTheme.amberGold.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: EduStreakTheme.amberGold, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Class ${alerts[0]['class']} Below 80%',
                          style: EduStreakTheme.fontCaption(
                            color: EduStreakTheme.amberGold,
                            weight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${alerts[0]['percentage']}% today. ${alerts[0]['reason']}. Class Teacher: ${alerts[0]['teacher']}.',
                    style: EduStreakTheme.fontSmall(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => widget.onNavigateToTab(5),
              icon: const Icon(Icons.remove_red_eye_rounded, size: 16, color: Colors.white),
              label: const Text('Open Full Attendance Register', style: TextStyle(color: Colors.white)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: EduStreakTheme.studentDarkBorder),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceCountBadge({
    required String label,
    required String count,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF14193E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            count,
            style: EduStreakTheme.fontHeading2(color: color, weight: FontWeight.w900),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: EduStreakTheme.fontCaption(color: EduStreakTheme.studentDarkTextMuted),
          ),
        ],
      ),
    );
  }

  // ─── AT-RISK STUDENTS CARD ─────────────────────────────────────────────────
  Widget _buildAtRiskStudentsCard() {
    final atRiskList = _principalService.getAtRiskStudents(widget.school.id);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: EduStreakTheme.studentDarkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: EduStreakTheme.studentDarkBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.crisis_alert_rounded, color: EduStreakTheme.rosePink, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'At-Risk Students Requiring Intervention',
                        style: EduStreakTheme.fontHeading3(color: Colors.white, weight: FontWeight.w800),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => widget.onNavigateToTab(2),
                child: Text(
                  'All Students →',
                  style: EduStreakTheme.fontCaption(color: EduStreakTheme.neonCyan, weight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Students flagged with low attendance (<75%), failing mid-terms, or missed assignments.',
            style: EduStreakTheme.fontCaption(color: EduStreakTheme.studentDarkTextMuted),
          ),
          const SizedBox(height: 16),
          if (atRiskList.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: EduStreakTheme.emeraldGreen, size: 36),
                    const SizedBox(height: 8),
                    Text(
                      'No at-risk students flagged today',
                      style: EduStreakTheme.fontLabel(color: Colors.white, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'All students are meeting baseline streak and attendance thresholds.',
                      style: EduStreakTheme.fontSmall(color: EduStreakTheme.studentDarkTextMuted),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: atRiskList.map((std) {
              final isHigh = std['severity'] == 'high';

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF15193C),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isHigh
                        ? EduStreakTheme.rosePink.withValues(alpha: 0.3)
                        : EduStreakTheme.amberGold.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: isHigh
                          ? EduStreakTheme.rosePink.withValues(alpha: 0.2)
                          : EduStreakTheme.amberGold.withValues(alpha: 0.2),
                      child: Text(
                        std['name'][0],
                        style: TextStyle(
                          color: isHigh ? EduStreakTheme.rosePink : EduStreakTheme.amberGold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              Text(
                                std['name'] as String,
                                style: EduStreakTheme.fontBody(color: Colors.white, weight: FontWeight.w700),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF222858),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  std['class'] as String,
                                  style: EduStreakTheme.fontSmall(color: EduStreakTheme.neonCyan),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            std['riskReason'] as String,
                            style: EduStreakTheme.fontSmall(color: EduStreakTheme.studentDarkTextMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${std['attendanceRate']}% Attend',
                          style: EduStreakTheme.fontCaption(
                            color: isHigh ? EduStreakTheme.rosePink : EduStreakTheme.amberGold,
                            weight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Score: ${std['averageScore']}%',
                          style: EduStreakTheme.fontSmall(color: Colors.white70),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─── TEACHER MONITORING & PENDING GRADING ──────────────────────────────────
  Widget _buildTeacherMonitoringCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: EduStreakTheme.studentDarkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: EduStreakTheme.studentDarkBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.assignment_turned_in_rounded, color: EduStreakTheme.neonCyan, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Teacher Workload & Grading',
                        style: EduStreakTheme.fontHeading3(color: Colors.white, weight: FontWeight.w800),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => widget.onNavigateToTab(3),
                child: Text(
                  'Faculty →',
                  style: EduStreakTheme.fontCaption(color: EduStreakTheme.neonCyan, weight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Monitoring daily faculty attendance and active instruction assignments.',
            style: EduStreakTheme.fontCaption(color: EduStreakTheme.studentDarkTextMuted),
          ),
          const SizedBox(height: 16),
          StreamBuilder<List<UserModel>>(
            stream: _principalService.getTeachersStream(widget.school.id),
            builder: (context, snapshot) {
              final teachers = snapshot.data ?? [];
              if (teachers.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.people_outline_rounded, size: 36, color: EduStreakTheme.studentDarkTextMuted),
                        const SizedBox(height: 8),
                        Text(
                          'No faculty assigned to this school yet',
                          style: EduStreakTheme.fontLabel(color: Colors.white, weight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Faculty members added by Administration will appear here.',
                          style: EduStreakTheme.fontSmall(color: EduStreakTheme.studentDarkTextMuted),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: teachers.map((t) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: EduStreakTheme.primaryViolet.withValues(alpha: 0.2),
                          child: Text(
                            t.name.isNotEmpty ? t.name[0].toUpperCase() : 'T',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.name,
                                style: EduStreakTheme.fontBody(color: Colors.white, weight: FontWeight.w700),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                t.assignedSubjects.isNotEmpty ? t.assignedSubjects.join(', ') : 'General Faculty',
                                style: EduStreakTheme.fontSmall(color: EduStreakTheme.studentDarkTextMuted),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: EduStreakTheme.emeraldGreen.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: EduStreakTheme.emeraldGreen.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            'Active',
                            style: EduStreakTheme.fontSmall(
                              color: EduStreakTheme.emeraldGreen,
                              weight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
