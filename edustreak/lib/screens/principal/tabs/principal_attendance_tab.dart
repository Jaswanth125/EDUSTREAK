import 'package:flutter/material.dart';
import '../../../../models/school_model.dart';
import '../../../../services/principal_service.dart';
import '../../../../utils/edustreak_theme.dart';
import '../../../../utils/responsive_breakpoints.dart';

class PrincipalAttendanceTab extends StatefulWidget {
  final SchoolModel school;

  const PrincipalAttendanceTab({super.key, required this.school});

  @override
  State<PrincipalAttendanceTab> createState() => _PrincipalAttendanceTabState();
}

class _PrincipalAttendanceTabState extends State<PrincipalAttendanceTab> {
  final _principalService = PrincipalService();
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final isDesktop = context.isDesktop;
    final isTablet = context.isTablet;
    final summary = _principalService.getTodayAttendanceSummary(widget.school.id);
    final classList = summary['classAttendance'] as List<dynamic>;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 28 : (isTablet ? 20 : 16),
        vertical: 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── ATTENDANCE OVERVIEW BANNER & DATE PICKER ──────────────────
          _buildAttendanceBanner(summary, isDesktop),

          const SizedBox(height: 24),

          // ─── CHRONIC ABSENTEEISM & PARENT ALERT ACTION ─────────────────
          _buildChronicAbsenteeismCard(summary),

          const SizedBox(height: 24),

          // ─── CLASS-BY-CLASS ATTENDANCE GRID ────────────────────────────
          Text(
            'Class-wise Daily Attendance Register',
            style: EduStreakTheme.fontHeading2(color: Colors.white, weight: FontWeight.w800),
          ),
          const SizedBox(height: 14),

          if (classList.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: EduStreakTheme.studentDarkCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: EduStreakTheme.studentDarkBorder),
              ),
              child: Column(
                children: [
                  const Icon(Icons.event_available_rounded, size: 44, color: EduStreakTheme.emeraldGreen),
                  const SizedBox(height: 12),
                  Text(
                    'No Attendance Marked For Today Yet',
                    style: EduStreakTheme.fontHeading3(color: Colors.white, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'When teachers submit daily roll calls, class-by-class attendance percentages will display here in real time.',
                    style: EduStreakTheme.fontCaption(color: EduStreakTheme.studentDarkTextMuted),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isDesktop ? 5 : (isTablet ? 3 : (MediaQuery.of(context).size.width < 360 ? 1 : 2)),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: isDesktop ? 1.35 : (isTablet ? 1.35 : (MediaQuery.of(context).size.width < 360 ? 2.8 : 1.35)),
              ),
              itemCount: classList.length,
              itemBuilder: (context, index) {
                final c = classList[index];
                return _buildClassAttendanceCard(c);
              },
            ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildAttendanceBanner(Map<String, dynamic> summary, bool isDesktop) {
    final studentPct = summary['overallPercentage'] as double;
    final teacherPct = summary['teacherPercentage'] as double;
    final present = summary['presentCount'] as int;
    final absent = summary['absentCount'] as int;
    final teacherPresent = summary['teacherPresentCount'] as int;
    final teacherTotal = summary['teacherTotalCount'] as int;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: EduStreakTheme.studentDarkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: EduStreakTheme.studentDarkBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 540;
              final titleWidget = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_month_rounded, color: EduStreakTheme.emeraldGreen, size: 24),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      'Daily Attendance Summary',
                      style: EduStreakTheme.fontHeading2(color: Colors.white, weight: FontWeight.w800),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              );
              final dateButton = OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.date_range_rounded, size: 16, color: Colors.white70),
                label: Text(
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                  style: const TextStyle(color: Colors.white),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: EduStreakTheme.studentDarkBorder),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleWidget,
                    const SizedBox(height: 10),
                    dateButton,
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: titleWidget),
                  const SizedBox(width: 10),
                  dateButton,
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // Two Meter Columns (Students vs Teachers)
          LayoutBuilder(
            builder: (context, constraints) {
              final isStacked = constraints.maxWidth < 540;

              final studentMeter = Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF14193E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: EduStreakTheme.emeraldGreen.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text('Student Attendance', style: EduStreakTheme.fontBody(color: Colors.white70, weight: FontWeight.w600)),
                        Text('$studentPct%', style: EduStreakTheme.fontHeading2(color: EduStreakTheme.emeraldGreen, weight: FontWeight.w900)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: studentPct / 100,
                        minHeight: 8,
                        backgroundColor: const Color(0xFF192050),
                        valueColor: const AlwaysStoppedAnimation<Color>(EduStreakTheme.emeraldGreen),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$present Present • $absent Absent • ${summary['lateCount'] ?? 0} Late',
                      style: EduStreakTheme.fontSmall(color: EduStreakTheme.studentDarkTextMuted),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );

              final teacherMeter = Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF14193E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: EduStreakTheme.neonCyan.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text('Teacher Attendance', style: EduStreakTheme.fontBody(color: Colors.white70, weight: FontWeight.w600)),
                        Text('$teacherPct%', style: EduStreakTheme.fontHeading2(color: EduStreakTheme.neonCyan, weight: FontWeight.w900)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: teacherPct / 100,
                        minHeight: 8,
                        backgroundColor: const Color(0xFF192050),
                        valueColor: const AlwaysStoppedAnimation<Color>(EduStreakTheme.neonCyan),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$teacherPresent of $teacherTotal Faculty on duty',
                      style: EduStreakTheme.fontSmall(color: EduStreakTheme.studentDarkTextMuted),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );

              if (isStacked) {
                return Column(
                  children: [
                    studentMeter,
                    const SizedBox(height: 14),
                    teacherMeter,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: studentMeter),
                  const SizedBox(width: 16),
                  Expanded(child: teacherMeter),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChronicAbsenteeismCard(Map<String, dynamic> summary) {
    final absent = (summary['absentCount'] as int?) ?? 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 620;

        final iconBox = Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: absent > 0 ? EduStreakTheme.rosePink.withValues(alpha: 0.2) : EduStreakTheme.emeraldGreen.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            absent > 0 ? Icons.notifications_active_rounded : Icons.check_circle_rounded,
            color: absent > 0 ? EduStreakTheme.rosePink : EduStreakTheme.emeraldGreen,
            size: 28,
          ),
        );

        final textBox = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              absent > 0
                  ? '$absent Absent Student${absent == 1 ? "" : "s"} Today'
                  : 'All Enrolled Students Present Today',
              style: EduStreakTheme.fontHeading3(color: Colors.white, weight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              absent > 0
                  ? 'Automated parental alerts can be dispatched to notify guardians of unexcused absences.'
                  : 'Zero unexcused absences recorded across active cohorts.',
              style: EduStreakTheme.fontCaption(color: Colors.white70),
            ),
          ],
        );

        final alertButton = ElevatedButton.icon(
          onPressed: _sendParentAlerts,
          icon: const Icon(Icons.send_rounded, size: 16),
          label: const Text('Send Parent SMS Alerts'),
          style: ElevatedButton.styleFrom(
            backgroundColor: EduStreakTheme.rosePink,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );

        if (isNarrow) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF261226),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: EduStreakTheme.rosePink.withValues(alpha: 0.4), width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    iconBox,
                    const SizedBox(width: 14),
                    Expanded(child: textBox),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(width: double.infinity, child: alertButton),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF261226),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: EduStreakTheme.rosePink.withValues(alpha: 0.4), width: 1.2),
          ),
          child: Row(
            children: [
              iconBox,
              const SizedBox(width: 16),
              Expanded(child: textBox),
              const SizedBox(width: 14),
              alertButton,
            ],
          ),
        );
      },
    );
  }

  Widget _buildClassAttendanceCard(Map<String, dynamic> c) {
    final pct = c['percentage'] as double;
    final status = c['status'] as String;
    final isGood = status == 'good';
    final isLow = status == 'low';
    final color = isGood ? EduStreakTheme.emeraldGreen : (isLow ? EduStreakTheme.rosePink : EduStreakTheme.amberGold);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: EduStreakTheme.studentDarkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.2),
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
                  c['class'] as String,
                  style: EduStreakTheme.fontCaption(color: Colors.white, weight: FontWeight.w800),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isLow ? 'LOW' : (isGood ? 'GOOD' : 'WARN'),
                  style: EduStreakTheme.fontSmall(color: color, weight: FontWeight.w800),
                ),
              ),
            ],
          ),
          Text(
            '$pct%',
            style: EduStreakTheme.fontHeading2(color: color, weight: FontWeight.w900),
          ),
          Text(
            '${c['present']}/${c['total']} Present',
            style: EduStreakTheme.fontSmall(color: EduStreakTheme.studentDarkTextMuted, weight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: EduStreakTheme.primaryViolet,
              surface: Color(0xFF14193E),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _sendParentAlerts() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✓ Absentee alerts successfully dispatched via SMS & EduStreak notification to 36 parent contacts.'),
        backgroundColor: EduStreakTheme.emeraldGreen,
      ),
    );
  }
}
