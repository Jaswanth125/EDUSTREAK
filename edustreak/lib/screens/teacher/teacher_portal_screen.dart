import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/edustreak_theme.dart';
import '../../widgets/edustreak_illustrations.dart';
import '../../widgets/responsive/responsive_scaffold.dart';
import '../../widgets/responsive/adaptive_dashboard_grid.dart';
import '../../providers/user_provider.dart';
import '../../services/auth_service.dart';
import '../../services/task_service.dart';
import '../../models/task_model.dart';
import '../../models/user_model.dart';
import '../../utils/class_name_helper.dart';
import 'class_management_screen.dart';
import 'attendance_screen.dart' as teacher_att;
import 'teacher_assignments_screen.dart';
import 'teacher_assessments_tab.dart';
import 'students_list_screen.dart';
import 'teacher_profile_dialog.dart';
import 'learning_resources_tab.dart';
import 'teacher_ai_teaching_hub_tab.dart';
import 'teacher_leaderboard_tab.dart';
import 'chat_list_screen.dart';

class TeacherPortalScreen extends StatefulWidget {
  final ValueChanged<String>? onPortalSwitch;

  const TeacherPortalScreen({super.key, this.onPortalSwitch});

  @override
  State<TeacherPortalScreen> createState() => _TeacherPortalScreenState();
}

class _TeacherPortalScreenState extends State<TeacherPortalScreen> {
  int _selectedNavIndex = 0;
  String _selectedClassFilter = 'Class 8-A';

  Future<void> _logout() async {
    final nav = Navigator.of(context, rootNavigator: true);
    await AuthService().signOut();
    if (mounted) {
      Provider.of<UserProvider>(context, listen: false).clearUser();
      nav.pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).currentUser;

    final teacherName = user?.name.isNotEmpty == true ? user!.name : 'Teacher';
    final teacherSubjects = (user != null && user.assignedSubjects.isNotEmpty)
        ? user.assignedSubjects.join(', ')
        : 'Faculty';
    final userClassIds = user?.classIds;
    final userClassId = user?.classId;
    final List<String> rawTeacherClasses = (userClassIds != null && userClassIds.isNotEmpty)
        ? userClassIds
        : (userClassId != null && userClassId.isNotEmpty ? [userClassId] : <String>[]);

    // Build display class names to prevent any raw ID leakage
    final List<String> teacherClasses = rawTeacherClasses
        .map((c) => ClassNameHelper.formatClassNameSync(c, fallback: ''))
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList();

    if (teacherClasses.isEmpty) {
      _selectedClassFilter = '';
    } else if (!teacherClasses.contains(_selectedClassFilter)) {
      _selectedClassFilter = teacherClasses.first;
    }

    return ResponsiveScaffold(
      portalType: 'teacher',
      selectedIndex: _selectedNavIndex,
      onItemSelected: (index) => setState(() => _selectedNavIndex = index),
      onLogout: _logout,
      user: user,
      userName: teacherName,
      userSubtitle: teacherSubjects,
      headerTitle: 'Teacher Portal',
      headerSubtitle: '$teacherName • $teacherSubjects',
      portalIcon: Icons.co_present_rounded,
      portalIconColor: EduStreakTheme.neonCyan,
      contextPillText: _selectedClassFilter.isNotEmpty ? _selectedClassFilter : 'No Cohorts',
      contextPillOptions: teacherClasses.isNotEmpty ? teacherClasses : const ['No Cohorts'],
      onContextPillChanged: (val) => setState(() => _selectedClassFilter = val == 'No Cohorts' ? '' : val),
      onDevSwitchPortal: null, // Switch Profile removed as per workflow requirement
      avatarWidget: Builder(
        builder: (ctx) {
          final isCompact = MediaQuery.sizeOf(ctx).width < 500;
          final avatar = InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => TeacherProfileDialog.show(context, user),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF8774FF), Color(0xFF6C57FF)],
                ),
                border: Border.all(color: EduStreakTheme.primaryViolet, width: 2),
              ),
              child: Center(
                child: Text(
                  teacherName.isNotEmpty ? teacherName[0].toUpperCase() : 'T',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );

          if (isCompact) {
            return Stack(
              clipBehavior: Clip.none,
              children: [
                avatar,
                Positioned(
                  right: -1,
                  bottom: -1,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: EduStreakTheme.emeraldGreen,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF0C1030), width: 1.5),
                    ),
                  ),
                ),
              ],
            );
          }

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: EduStreakTheme.neonCyan.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: EduStreakTheme.neonCyan.withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: EduStreakTheme.emeraldGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _selectedClassFilter.isNotEmpty ? 'Live: $_selectedClassFilter' : 'No Active Cohort',
                      style: EduStreakTheme.fontLabel(
                        color: EduStreakTheme.neonCyan,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              avatar,
            ],
          );
        },
      ),
      body: _buildCurrentTab(user, teacherClasses),
    );
  }

  Widget _buildCurrentTab(UserModel? user, List<String> teacherClasses) {
    switch (_selectedNavIndex) {
      case 0:
        return _buildDashboardContent(user, teacherClasses);
      case 1:
        return const ClassManagementScreen();
      case 2:
        return const teacher_att.AttendanceScreen();
      case 3:
        return const TeacherAssignmentsScreen(showAppBar: false);
      case 4:
        return TeacherAssessmentsTab(user: user);
      case 5:
        return TeacherAiTeachingHubTab(user: user);
      case 6:
        return const StudentsListScreen(showAppBar: false);
      case 7:
        return LearningResourcesTab(user: user);
      case 8:
        return const ChatListScreen(showAppBar: false);
      case 9:
        return TeacherLeaderboardTab(user: user);
      default:
        return _buildDashboardContent(user, teacherClasses);
    }
  }

  // ─── TEACHER DASHBOARD CONTENT (EXACT MATCH TO REFERENCE IMAGE) ─────────
  Widget _buildDashboardContent(UserModel? user, List<String> teacherClasses) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting Row
          _buildGreetingRow(user, teacherClasses),

          const SizedBox(height: 20),

          // 4 Top Metric Cards (Live Firestore Streams)
          _buildTopMetricCards(user, teacherClasses),

          const SizedBox(height: 22),

          // Middle Row: Today's Schedule + Class Insight - 8A
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 950) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left: Today's Schedule (flex: 3)
                    Expanded(
                      flex: 3,
                      child: _buildTodayScheduleCard(user, teacherClasses),
                    ),
                    const SizedBox(width: 20),
                    // Right: Class Insight - 8A (flex: 3)
                    Expanded(
                      flex: 3,
                      child: _buildClassInsightCard(user),
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildTodayScheduleCard(user, teacherClasses),
                    const SizedBox(height: 20),
                    _buildClassInsightCard(user),
                  ],
                );
              }
            },
          ),

          const SizedBox(height: 22),

          // Bottom Banner: AI Teaching Hub with Mascot
          _buildAiTeachingHubBanner(),
        ],
      ),
    );
  }

  // ─── GREETING ROW ────────────────────────────────────────────────────────
  Widget _buildGreetingRow(UserModel? user, List<String> teacherClasses) {
    final hour = DateTime.now().hour;
    final timeGreeting = hour < 12 ? 'Good Morning' : (hour < 17 ? 'Good Afternoon' : 'Good Evening');
    final teacherName = user?.name.isNotEmpty == true ? user!.name : 'Teacher';
    final cohortCount = teacherClasses.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 620;

        final avatarAndText = Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: EduStreakTheme.primaryViolet.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: EduStreakTheme.primaryViolet.withValues(alpha: 0.4)),
              ),
              child: const Icon(Icons.school_rounded, color: EduStreakTheme.primaryViolet, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          '$timeGreeting, $teacherName!',
                          style: EduStreakTheme.fontHeading1(
                            color: Colors.white,
                            weight: FontWeight.w800,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('👋', style: TextStyle(fontSize: 20)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'You have $cohortCount assigned cohort${cohortCount == 1 ? "" : "s"}. Track student progress, grade submissions, and review learning streaks.',
                    style: EduStreakTheme.fontBody(
                      color: EduStreakTheme.darkTextSub,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

        final actionBtn = ElevatedButton.icon(
          onPressed: () {
            setState(() => _selectedNavIndex = 5); // Jump to AI Teaching Hub
          },
          icon: const Icon(Icons.psychology_rounded, size: 18, color: Colors.white),
          label: const Text('AI Lesson Plan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          style: ElevatedButton.styleFrom(
            backgroundColor: EduStreakTheme.primaryViolet,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 4,
            minimumSize: isCompact ? const Size(double.infinity, 48) : null,
          ),
        );

        if (isCompact) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: EduStreakTheme.darkCardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                avatarAndText,
                const SizedBox(height: 14),
                actionBtn,
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          decoration: EduStreakTheme.darkCardDecoration(),
          child: Row(
            children: [
              Expanded(child: avatarAndText),
              const SizedBox(width: 16),
              actionBtn,
            ],
          ),
        );
      },
    );
  }

  // ─── 4 TOP METRIC CARDS ──────────────────────────────────────────────────
  Widget _buildTopMetricCards(UserModel? user, List<String> teacherClasses) {
    return AdaptiveDashboardGrid.metrics(
      mobileCols: 1,
      largeMobileCols: 2,
      tabletCols: 2,
      laptopCols: 4,
      desktopCols: 4,
      children: [
            // Card 1: Classes
            _buildMetricTile(
              title: '${teacherClasses.length} Classes',
              subtitle: 'Active assigned cohorts',
              icon: Icons.groups_rounded,
              color: EduStreakTheme.neonCyan,
            ),

            // Card 2: Students (Live Query)
            StreamBuilder<QuerySnapshot>(
              stream: user?.schoolId != null && user!.schoolId!.isNotEmpty
                  ? FirebaseFirestore.instance
                      .collection('users')
                      .where('role', isEqualTo: 'student')
                      .where('schoolId', isEqualTo: user.schoolId)
                      .snapshots()
                  : FirebaseFirestore.instance
                      .collection('users')
                      .where('role', isEqualTo: 'student')
                      .snapshots(),
              builder: (context, snapshot) {
                final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                return _buildMetricTile(
                  title: '$count Students',
                  subtitle: count == 0 ? 'No students enrolled' : 'Active cohort enrollment',
                  icon: Icons.school_rounded,
                  color: EduStreakTheme.primaryViolet,
                );
              },
            ),

            // Card 3: Assignments (Live from TaskService)
            StreamBuilder<List<TaskModel>>(
              stream: TaskService().getTasksForTeacher(user?.id ?? ''),
              builder: (context, snapshot) {
                final tasks = snapshot.data ?? [];
                int pendingReview = 0;
                for (final t in tasks) {
                  pendingReview += t.submissions.keys.where((studentId) => t.marks[studentId] == null).length;
                }
                return _buildMetricTile(
                  title: '${tasks.length} Assignments',
                  subtitle: pendingReview > 0
                      ? '$pendingReview awaiting review'
                      : (tasks.isEmpty ? 'No assignments posted' : 'All submissions graded'),
                  icon: Icons.assignment_turned_in_rounded,
                  color: EduStreakTheme.magentaPink,
                );
              },
            ),

            // Card 4: Assessments (Live from Challenges)
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('challenges').snapshots(),
              builder: (context, snapshot) {
                final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                return _buildMetricTile(
                  title: '$count Assessments',
                  subtitle: count == 0 ? 'No active assessments' : 'Active challenges & tests',
                  icon: Icons.quiz_rounded,
                  color: EduStreakTheme.rosePink,
                );
              },
            ),
          ],
        );
  }

  Widget _buildMetricTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: EduStreakTheme.darkCardDecoration(
        borderColor: color.withValues(alpha: 0.35),
        glowOpacity: 0.15,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: EduStreakTheme.fontHeading2(
                    color: Colors.white,
                    weight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: EduStreakTheme.fontCaption(
                    color: EduStreakTheme.darkTextMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── TODAY'S SCHEDULE CARD ──────────────────────────────────────────────
  Widget _buildTodayScheduleCard(UserModel? user, List<String> teacherClasses) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: EduStreakTheme.darkCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 18, color: EduStreakTheme.neonCyan),
                  const SizedBox(width: 8),
                  Text(
                    'Today\'s Schedule',
                    style: EduStreakTheme.fontHeading2(
                      color: Colors.white,
                      weight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: EduStreakTheme.primaryViolet.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${teacherClasses.length} Cohorts',
                  style: EduStreakTheme.fontCaption(
                    color: EduStreakTheme.primaryVioletLight,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Stream real tasks and timetable for teacher's cohorts
          StreamBuilder<List<TaskModel>>(
            stream: TaskService().getTasksForTeacher(user?.id ?? ''),
            builder: (context, snapshot) {
              final tasks = snapshot.data ?? [];
              final now = DateTime.now();
              final todayTasks = tasks.where((t) {
                return t.dueDate.year == now.year &&
                    t.dueDate.month == now.month &&
                    t.dueDate.day == now.day;
              }).toList();

              final scheduleItems = <Map<String, dynamic>>[];
              for (int i = 0; i < teacherClasses.length; i++) {
                final cName = ClassNameHelper.formatClassNameSync(teacherClasses[i], fallback: 'Class 8A');
                final time = i == 0 ? '09:00 AM' : (i == 1 ? '10:30 AM' : '01:30 PM');
                final isCurrent = i == 0;
                scheduleItems.add({
                  'time': time,
                  'class': cName,
                  'subject': (user != null && user.assignedSubjects.isNotEmpty)
                      ? user.assignedSubjects.first
                      : 'Core Curriculum',
                  'topic': 'Scheduled Cohort Instruction',
                  'room': 'Room ${10 + i}',
                  'isCurrent': isCurrent,
                  'isDone': false,
                });
              }

              for (final t in todayTasks) {
                scheduleItems.add({
                  'time': '${t.dueDate.hour.toString().padLeft(2, '0')}:${t.dueDate.minute.toString().padLeft(2, '0')}',
                  'class': ClassNameHelper.formatClassNameSync(t.classId, fallback: 'Class 8A'),
                  'subject': t.subject.isNotEmpty ? t.subject : 'Assignment Due',
                  'topic': t.title,
                  'room': 'Submission Due',
                  'isCurrent': false,
                  'isDone': false,
                  'isTask': true,
                });
              }

              if (scheduleItems.isEmpty) {
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      const Icon(Icons.event_available_rounded, color: EduStreakTheme.darkTextMuted, size: 36),
                      const SizedBox(height: 8),
                      Text(
                        'No class sessions scheduled for today',
                        style: EduStreakTheme.fontLabel(color: EduStreakTheme.darkTextSub),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: scheduleItems.map((slot) {
                  final isDone = slot['isDone'] as bool;
                  final isCurrent = slot['isCurrent'] as bool;
                  final isTask = slot['isTask'] == true;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? const Color(0xFF1B2358)
                          : const Color(0xFF0F1434),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isTask
                            ? EduStreakTheme.magentaPink.withValues(alpha: 0.6)
                            : (isCurrent
                                ? EduStreakTheme.neonCyan
                                : const Color(0xFF222B5C)),
                        width: isCurrent || isTask ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Time indicator pill
                        Container(
                          width: 76,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? EduStreakTheme.neonCyan.withValues(alpha: 0.15)
                                : const Color(0xFF141A42),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              slot['time'] as String,
                              style: EduStreakTheme.fontCaption(
                                color: isCurrent ? EduStreakTheme.neonCyan : EduStreakTheme.darkTextSub,
                                weight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${slot['class']} • ${slot['subject']}',
                                style: EduStreakTheme.fontLabel(
                                  color: Colors.white,
                                  weight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                slot['topic'] as String,
                                style: EduStreakTheme.fontCaption(
                                  color: EduStreakTheme.darkTextMuted,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (isTask)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: EduStreakTheme.magentaPink.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Deadline',
                              style: EduStreakTheme.fontCaption(
                                color: EduStreakTheme.magentaPink,
                                weight: FontWeight.w800,
                              ),
                            ),
                          )
                        else if (isDone)
                          const Icon(Icons.check_circle_rounded, color: EduStreakTheme.emeraldGreen, size: 20)
                        else if (isCurrent)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: EduStreakTheme.neonCyan.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Active',
                              style: EduStreakTheme.fontCaption(
                                color: EduStreakTheme.neonCyan,
                                weight: FontWeight.w800,
                              ),
                            ),
                          )
                        else
                          Text(
                            slot['room'] as String,
                            style: EduStreakTheme.fontCaption(
                              color: EduStreakTheme.darkTextMuted,
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

  // ─── CLASS INSIGHT CARD ──────────────────────────────────────────────────
  Widget _buildClassInsightCard(UserModel? user) {
    if (_selectedClassFilter.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(28),
        decoration: EduStreakTheme.darkCardDecoration(),
        alignment: Alignment.center,
        child: Column(
          children: [
            const Icon(Icons.insights_rounded, size: 36, color: EduStreakTheme.darkTextMuted),
            const SizedBox(height: 10),
            Text(
              'No Cohort Selected',
              style: EduStreakTheme.fontHeading3(color: Colors.white, weight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Assign or select a class section to view submission and grading insights.',
              style: EduStreakTheme.fontCaption(color: EduStreakTheme.darkTextMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: EduStreakTheme.darkCardDecoration(),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('tasks')
            .where('classId', isEqualTo: _selectedClassFilter)
            .snapshots(),
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs ?? [];
          int totalSubmissions = 0;
          int gradedSubmissions = 0;
          double totalScorePct = 0;

          final Map<String, List<double>> subjectScores = {};

          for (final doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final maxMarks = (data['maxMarks'] as num?)?.toDouble() ?? 100.0;
            final subject = (data['subject'] as String?)?.isNotEmpty == true
                ? data['subject'] as String
                : 'General';
            final submissions = (data['submissions'] as Map<String, dynamic>?) ?? {};

            totalSubmissions += submissions.length;
            for (final sub in submissions.values) {
              if (sub is Map<String, dynamic> && sub['marks'] != null) {
                final marks = (sub['marks'] as num).toDouble();
                final pct = (marks / maxMarks).clamp(0.0, 1.0);
                gradedSubmissions++;
                totalScorePct += pct;
                subjectScores.putIfAbsent(subject, () => []).add(pct);
              }
            }
          }

          final double classAvg = gradedSubmissions > 0
              ? totalScorePct / gradedSubmissions
              : 0.0;
          final int classAvgPct = (classAvg * 100).round();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.insights_rounded, size: 18, color: EduStreakTheme.primaryVioletLight),
                      const SizedBox(width: 8),
                      Text(
                        'Class Insight - $_selectedClassFilter',
                        style: EduStreakTheme.fontHeading2(
                          color: Colors.white,
                          weight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: gradedSubmissions > 0
                          ? EduStreakTheme.emeraldGreen.withValues(alpha: 0.2)
                          : EduStreakTheme.darkNavySurface,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (gradedSubmissions > 0)
                          const Icon(Icons.check_circle_outline_rounded, size: 12, color: EduStreakTheme.emeraldGreen),
                        const SizedBox(width: 4),
                        Text(
                          gradedSubmissions > 0
                              ? '$gradedSubmissions / $totalSubmissions Graded'
                              : (totalSubmissions > 0 ? '$totalSubmissions Pending' : 'Pending Data'),
                          style: EduStreakTheme.fontCaption(
                            color: gradedSubmissions > 0 ? EduStreakTheme.emeraldGreen : EduStreakTheme.darkTextMuted,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Radial gauge + Average metric
              Row(
                children: [
                  SizedBox(
                    width: 90,
                    height: 90,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: gradedSubmissions > 0 ? classAvg : 0.0,
                          strokeWidth: 9,
                          backgroundColor: const Color(0xFF1E265C),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            gradedSubmissions > 0 ? EduStreakTheme.primaryViolet : EduStreakTheme.darkTextMuted,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              gradedSubmissions > 0 ? '$classAvgPct%' : '--',
                              style: EduStreakTheme.fontHeading2(
                                color: Colors.white,
                                weight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'Avg',
                              style: EduStreakTheme.fontCaption(
                                color: EduStreakTheme.darkTextSub,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          gradedSubmissions > 0
                              ? '$gradedSubmissions Graded Submissions'
                              : 'No Graded Submissions Yet',
                          style: EduStreakTheme.fontHeading3(
                            color: Colors.white,
                            weight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          gradedSubmissions > 0
                              ? 'Cohort performance is dynamically aggregated from assigned tasks and evaluations.'
                              : 'Create and grade tasks for $_selectedClassFilter in the Grade Submissions tab to populate cohort insights.',
                          style: EduStreakTheme.fontCaption(
                            color: EduStreakTheme.darkTextMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(color: Color(0xFF222B5C)),
              const SizedBox(height: 12),
              Text(
                'Subject Performance Breakdown:',
                style: EduStreakTheme.fontLabel(
                  color: EduStreakTheme.darkTextSub,
                  weight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              if (subjectScores.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'No graded subject assignments yet for this cohort.',
                    style: EduStreakTheme.fontCaption(color: EduStreakTheme.darkTextMuted),
                  ),
                )
              else
                ...subjectScores.entries.map((entry) {
                  final avg = entry.value.reduce((a, b) => a + b) / entry.value.length;
                  final pct = (avg * 100).round();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 80,
                          child: Text(
                            entry.key,
                            style: EduStreakTheme.fontCaption(
                              color: Colors.white,
                              weight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: avg,
                              minHeight: 7,
                              backgroundColor: const Color(0xFF1E265C),
                              valueColor: const AlwaysStoppedAnimation<Color>(EduStreakTheme.primaryViolet),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 38,
                          child: Text(
                            '$pct%',
                            style: EduStreakTheme.fontCaption(
                              color: EduStreakTheme.neonCyan,
                              weight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }

  // ─── AI TEACHING HUB BANNER ──────────────────────────────────────────────
  Widget _buildAiTeachingHubBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        gradient: EduStreakTheme.teacherHubGradient,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: EduStreakTheme.primaryViolet.withValues(alpha: 0.6),
          width: 1.5,
        ),
        boxShadow: EduStreakTheme.violetGlow,
      ),
      child: Row(
        children: [
          const AiRobotMascot(size: 72),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: EduStreakTheme.neonCyan.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'AI TEACHING ASSISTANT',
                        style: EduStreakTheme.fontCaption(
                          color: EduStreakTheme.neonCyan,
                          weight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Generate Lesson Plans & Quizzes in Seconds',
                  style: EduStreakTheme.fontHeading2(
                    color: Colors.white,
                    weight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Create differentiated homework, auto-graded quizzes, and SCERT-aligned practice sets with EduStreak AI.',
                  style: EduStreakTheme.fontBody(
                    color: EduStreakTheme.darkTextSub,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: () {
              setState(() => _selectedNavIndex = 5); // Jump to Teacher AI Tasks
            },
            icon: const Icon(Icons.auto_awesome_rounded, size: 18, color: Colors.white),
            label: const Text(
              'Launch AI Teaching Hub',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: EduStreakTheme.primaryViolet,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
            ),
          ),
        ],
      ),
    );
  }
}
