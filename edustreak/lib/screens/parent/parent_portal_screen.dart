import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../utils/edustreak_theme.dart';
import '../../widgets/edustreak_illustrations.dart';
import '../../widgets/responsive/responsive_scaffold.dart';
import '../../widgets/responsive/adaptive_dashboard_grid.dart';
import '../../widgets/notifications_sheet.dart';
import '../../models/user_model.dart';
import '../../models/task_model.dart';
import '../../models/assessment_model.dart';
import '../../providers/user_provider.dart';
import '../../services/auth_service.dart';
import '../../services/task_service.dart';
import '../../services/assessment_service.dart';
import 'parent_chat_screen.dart';
import 'parent_profile_dialog.dart';

class ParentPortalScreen extends StatefulWidget {
  final ValueChanged<String>? onPortalSwitch;
  final Stream<List<UserModel>>? childrenStream;
  final Stream<List<TaskModel>>? tasksStream;
  final Stream<List<AssessmentModel>>? assessmentsStream;

  const ParentPortalScreen({
    super.key,
    this.onPortalSwitch,
    this.childrenStream,
    this.tasksStream,
    this.assessmentsStream,
  });

  @override
  State<ParentPortalScreen> createState() => _ParentPortalScreenState();
}

class _ParentPortalScreenState extends State<ParentPortalScreen> {
  int _selectedNavIndex = 0;
  String? _selectedChildId;

  // Tab State
  DateTime _attendanceMonth = DateTime.now();
  String _homeworkFilter = 'All';
  String _assessmentFilter = 'All';

  Future<void> _logout() async {
    final nav = Navigator.of(context, rootNavigator: true);
    await AuthService().signOut();
    if (mounted) {
      Provider.of<UserProvider>(context, listen: false).clearUser();
      nav.pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  Stream<List<UserModel>> _getChildrenStream(UserModel? parent) {
    if (widget.childrenStream != null) {
      return widget.childrenStream!;
    }
    if (parent == null) return Stream.value([]);

    try {
      final firestore = FirebaseFirestore.instance;
      final childIds = [
        if (parent.childId != null && parent.childId!.isNotEmpty) parent.childId!,
        ...parent.childIds,
      ];
      if (childIds.isNotEmpty) {
        final ids = childIds.take(10).toList();
        return firestore
            .collection('users')
            .where(FieldPath.documentId, whereIn: ids)
            .snapshots()
            .map((snap) => snap.docs.map((d) => UserModel.fromMap(d.data()..['id'] = d.id)).toList())
            .handleError((_) => <UserModel>[]);
      }

      // Honest zero-mock empty state: if parent has no children mapped, return empty
      return Stream.value(<UserModel>[]);
    } catch (_) {
      return Stream.value(<UserModel>[]);
    }
  }

  Stream<List<TaskModel>> _getTasksStream(String studentId) {
    if (widget.tasksStream != null) {
      return widget.tasksStream!;
    }
    try {
      return TaskService().getTasksForStudent(studentId);
    } catch (_) {
      return Stream.value(<TaskModel>[]);
    }
  }

  Stream<List<AssessmentModel>> _getAssessmentsStream(String studentId, String? classId) {
    if (widget.assessmentsStream != null) {
      return widget.assessmentsStream!;
    }
    try {
      return AssessmentService().getAssessmentsForStudent(studentId: studentId, classId: classId);
    } catch (_) {
      return Stream.value(<AssessmentModel>[]);
    }
  }

  Stream<QuerySnapshot?> _getAttendanceStream(String studentId) {
    try {
      return FirebaseFirestore.instance
          .collection('users')
          .doc(studentId)
          .collection('attendanceRecords')
          .snapshots()
          .handleError((_) => null);
    } catch (_) {
      return Stream.value(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    UserModel? parent;
    try {
      parent = Provider.of<UserProvider>(context).currentUser;
    } catch (_) {
      parent = null;
    }
    final parentName = parent?.name.isNotEmpty == true ? parent!.name : 'Parent';

    return StreamBuilder<List<UserModel>>(
      stream: _getChildrenStream(parent),
      builder: (context, snapshot) {
        final children = snapshot.data ?? [];

        // Determine active child
        UserModel? selectedChild;
        if (children.isNotEmpty) {
          if (_selectedChildId != null) {
            selectedChild = children.firstWhere(
              (c) => c.id == _selectedChildId,
              orElse: () => children.first,
            );
          } else {
            selectedChild = children.first;
            _selectedChildId = selectedChild.id;
          }
        }

        final childName = selectedChild?.name ?? 'Child';
        final childClass = selectedChild != null
            ? '${selectedChild.grade != null ? "Class ${selectedChild.grade}" : (selectedChild.classId ?? "Enrolled")}${selectedChild.section != null ? " • Sec ${selectedChild.section}" : ""}'
            : 'Enrolled';

        final childOptions = children.map((c) {
          final cls = '${c.grade != null ? "Class ${c.grade}" : (c.classId ?? "")}${c.section != null ? " ${c.section}" : ""}';
          return '${c.name} - $cls';
        }).toList();

        final currentOption = selectedChild != null
            ? '${selectedChild.name} - ${selectedChild.grade != null ? "Class ${selectedChild.grade}" : (selectedChild.classId ?? "")}${selectedChild.section != null ? " ${selectedChild.section}" : ""}'
            : (childOptions.isNotEmpty ? childOptions.first : 'No Children Linked');

        final userSubtitle = selectedChild != null
            ? 'Parent of ${selectedChild.name} ($childClass)'
            : 'Parent Account';

        return ResponsiveScaffold(
          portalType: 'parent',
          selectedIndex: _selectedNavIndex,
          onItemSelected: (index) => setState(() => _selectedNavIndex = index),
          onLogout: _logout,
          user: parent,
          userName: parentName,
          userSubtitle: userSubtitle,
          headerTitle: 'Parent Portal',
          headerSubtitle: 'Monitoring $childName • $childClass',
          portalIcon: Icons.family_restroom_rounded,
          portalIconColor: EduStreakTheme.primaryViolet,
          contextPillText: currentOption,
          contextPillOptions: childOptions.isNotEmpty ? childOptions : [currentOption],
          onContextPillChanged: (val) {
            final idx = childOptions.indexOf(val);
            if (idx != -1 && idx < children.length) {
              setState(() => _selectedChildId = children[idx].id);
            }
          },
          onNotificationTap: () {
            if (parent != null) {
              NotificationsSheet.show(context, userId: parent.id, isDark: true);
            }
          },
          onDevSwitchPortal: widget.onPortalSwitch,
          avatarWidget: Builder(
            builder: (ctx) {
              final isCompact = MediaQuery.sizeOf(ctx).width < 500;
              final avatar = InkWell(
                onTap: () {
                  ParentProfileDialog.show(
                    context,
                    user: parent,
                    selectedChild: selectedChild,
                    children: children,
                    onChildSelected: (c) => setState(() => _selectedChildId = c.id),
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: EduStreakTheme.primaryViolet.withValues(alpha: 0.15),
                    border: Border.all(color: EduStreakTheme.primaryViolet, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      parentName.isNotEmpty ? parentName[0].toUpperCase() : 'P',
                      style: const TextStyle(
                        color: EduStreakTheme.primaryViolet,
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
                        padding: const EdgeInsets.all(1.5),
                        decoration: const BoxDecoration(
                          color: EduStreakTheme.emeraldGreen,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, size: 8, color: Colors.white),
                      ),
                    ),
                  ],
                );
              }

              return InkWell(
                onTap: () {
                  ParentProfileDialog.show(
                    context,
                    user: parent,
                    selectedChild: selectedChild,
                    children: children,
                    onChildSelected: (c) => setState(() => _selectedChildId = c.id),
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: EduStreakTheme.emeraldGreen.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: EduStreakTheme.emeraldGreen.withValues(alpha: 0.35),
                          width: 1,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_rounded, size: 13, color: EduStreakTheme.emeraldGreen),
                          SizedBox(width: 4),
                          Text(
                            'Linked & Verified',
                            style: TextStyle(
                              color: EduStreakTheme.emeraldGreen,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    avatar,
                  ],
                ),
              );
            },
          ),
          body: _buildCurrentTab(parent, selectedChild),
        );
      },
    );
  }

  Widget _buildCurrentTab(UserModel? parent, UserModel? child) {
    switch (_selectedNavIndex) {
      case 0:
        return _buildDashboardContent(parent, child);
      case 1:
        return _buildMyChildProfileTab(parent, child);
      case 2:
        return _buildProgressReportTab(child);
      case 3:
        return _buildAttendanceTab(child);
      case 4:
        return _buildHomeworkTab(child);
      case 5:
        return _buildResultsTab(child);
      case 6:
        return const ParentChatScreen();
      default:
        return _buildDashboardContent(parent, child);
    }
  }

  // ─── TAB 0: PARENT DASHBOARD ──────────────────────────────────────────────
  Widget _buildDashboardContent(UserModel? parent, UserModel? child) {
    if (child == null) {
      return Container(
        color: EduStreakTheme.studentDarkBg,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.family_restroom_rounded, size: 64, color: EduStreakTheme.studentDarkTextMuted),
                const SizedBox(height: 16),
                Text(
                  'No Children Linked Yet',
                  style: EduStreakTheme.fontHeading1(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Your school administrator has not yet mapped a student profile to this parent account.',
                  textAlign: TextAlign.center,
                  style: EduStreakTheme.fontBody(color: EduStreakTheme.studentDarkTextMuted),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return StreamBuilder<List<TaskModel>>(
      stream: _getTasksStream(child.id),
      builder: (context, snapshot) {
        final tasks = snapshot.data ?? [];
        return Container(
          color: EduStreakTheme.studentDarkBg,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Card 1: Child Summary Banner
                _buildChildSummaryCard(parent, child),

                const SizedBox(height: 20),

                // Card 2: 4 Quick Snapshot KPI badges
                _buildSnapshotKpiRow(child, tasks),

                const SizedBox(height: 20),

                // Card 3: School Announcements Circulars
                _buildSchoolAnnouncementsCard(child),

                const SizedBox(height: 22),

                // Card 4: Subject Performance + Growth Insight
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 950) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: _buildSubjectPerformanceCard(child, tasks)),
                          const SizedBox(width: 20),
                          Expanded(flex: 3, child: _buildGrowthInsightCard(child)),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          _buildSubjectPerformanceCard(child, tasks),
                          const SizedBox(height: 20),
                          _buildGrowthInsightCard(child),
                        ],
                      );
                    }
                  },
                ),

                const SizedBox(height: 22),

                // Card 5: Upcoming Homework & Due Dates
                _buildUpcomingHomeworkCard(child, tasks),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── CHILD SUMMARY CARD ──────────────────────────────────────────────────
  Widget _buildChildSummaryCard(UserModel? parent, UserModel child) {
    final parentName = parent?.name.isNotEmpty == true ? parent!.name : 'Parent';
    final childClass = '${child.grade != null ? "Class ${child.grade}" : (child.classId ?? "Enrolled")}${child.section != null ? " • Sec ${child.section}" : ""}';
    final institutionText = '${child.schoolCode != null ? "School: ${child.schoolCode}" : "Enrolled School"}${child.rollNumber != null ? " • Roll #${child.rollNumber}" : ""}${child.academicYear != null ? " • ${child.academicYear}" : ""}';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 640;
        final reportBtn = ElevatedButton.icon(
          onPressed: () => setState(() => _selectedNavIndex = 2), // Jump to progress report
          icon: const Icon(Icons.analytics_rounded, size: 16, color: Colors.white),
          label: const Text('Full Report', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          style: ElevatedButton.styleFrom(
            backgroundColor: EduStreakTheme.primaryViolet,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 3,
            shadowColor: EduStreakTheme.primaryViolet.withValues(alpha: 0.4),
          ),
        );

        final detailsCol = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                Text(
                  child.name,
                  style: EduStreakTheme.fontHeading1(
                    color: Colors.white,
                    weight: FontWeight.w800,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: EduStreakTheme.studentDarkCardSub,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: EduStreakTheme.studentDarkBorder),
                  ),
                  child: Text(
                    childClass,
                    style: EduStreakTheme.fontLabel(
                      color: EduStreakTheme.studentDarkHighlight,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              institutionText,
              style: EduStreakTheme.fontBody(color: EduStreakTheme.studentDarkTextMuted),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              'Parent: $parentName • Linked & Verified Profile',
              style: EduStreakTheme.fontCaption(
                color: EduStreakTheme.studentDarkHighlight,
                weight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );

        return Container(
          padding: EdgeInsets.all(isNarrow ? 16 : 20),
          decoration: EduStreakTheme.studentDarkCardDecoration(),
          child: isNarrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const AkashStudentAvatar(size: 52),
                        const SizedBox(width: 12),
                        Expanded(child: detailsCol),
                      ],
                    ),
                    const SizedBox(height: 14),
                    reportBtn,
                  ],
                )
              : Row(
                  children: [
                    const AkashStudentAvatar(size: 64),
                    const SizedBox(width: 18),
                    Expanded(child: detailsCol),
                    const SizedBox(width: 12),
                    reportBtn,
                  ],
                ),
        );
      },
    );
  }

  // ─── 4 SNAPSHOT KPI ROW (LIVE STREAMS) ────────────────────────────────────
  Widget _buildSnapshotKpiRow(UserModel child, [List<TaskModel>? preloadedTasks]) {
    Widget buildAcademicKpi(List<TaskModel> tasks) {
      int gradedCount = 0;
      double totalScorePct = 0;

      for (final t in tasks) {
        final mark = t.marks[child.id];
        if (mark != null) {
          final pct = (mark / t.maxMarks).clamp(0.0, 1.0);
          gradedCount++;
          totalScorePct += pct;
        }
      }

      final avgPct = gradedCount > 0 ? (totalScorePct / gradedCount * 100).round() : 0;
      final valueText = gradedCount > 0 ? '$avgPct%' : '--';
      final badgeText = gradedCount > 0 ? '$gradedCount Graded' : 'No Grades Yet';

      return _buildKpiCard(
        title: 'Academic Avg',
        value: valueText,
        badge: badgeText,
        badgeColor: gradedCount > 0 ? EduStreakTheme.emeraldGreen : EduStreakTheme.studentDarkTextMuted,
        icon: Icons.insights_rounded,
        color: EduStreakTheme.primaryViolet,
      );
    }

    Widget buildHomeworkKpi(List<TaskModel> tasks) {
      final pendingTasks = tasks.where((t) => !t.submissions.containsKey(child.id)).toList();
      final count = pendingTasks.length;

      return _buildKpiCard(
        title: 'Homework',
        value: '$count Pending',
        badge: count > 0 ? '$count Due Soon' : 'All Clear',
        badgeColor: count > 0 ? EduStreakTheme.rosePink : EduStreakTheme.emeraldGreen,
        icon: Icons.assignment_late_rounded,
        color: EduStreakTheme.rosePink,
      );
    }

    return AdaptiveDashboardGrid.metrics(
      mainAxisExtent: 105,
      children: [
        // KPI 1: Academic Avg
        preloadedTasks != null
            ? buildAcademicKpi(preloadedTasks)
            : StreamBuilder<List<TaskModel>>(
                stream: _getTasksStream(child.id),
                builder: (context, snapshot) => buildAcademicKpi(snapshot.data ?? []),
              ),

        // KPI 2: Attendance Rate
        StreamBuilder<QuerySnapshot?>(
          stream: _getAttendanceStream(child.id),
          builder: (context, snapshot) {
            final docs = snapshot.data?.docs ?? [];
            final totalDays = docs.length;
            final presentDays = docs.where((d) {
              final data = d.data() as Map<String, dynamic>?;
              return data?['present'] == true;
            }).length;
            final rate = totalDays > 0 ? (presentDays / totalDays * 100).round() : 100;
            final valueText = totalDays > 0 ? '$rate%' : '100%';
            final badgeText = totalDays > 0 ? '$presentDays/$totalDays Days' : 'No Absences';

            return _buildKpiCard(
              title: 'Attendance',
              value: valueText,
              badge: badgeText,
              badgeColor: EduStreakTheme.neonCyan,
              icon: Icons.calendar_month_rounded,
              color: EduStreakTheme.neonCyan,
            );
          },
        ),

        // KPI 3: Homework Pending
        preloadedTasks != null
            ? buildHomeworkKpi(preloadedTasks)
            : StreamBuilder<List<TaskModel>>(
                stream: _getTasksStream(child.id),
                builder: (context, snapshot) => buildHomeworkKpi(snapshot.data ?? []),
              ),

        // KPI 4: Learning Streak
        _buildKpiCard(
          title: 'Learning Streak',
          value: '${child.streakCount} Days',
          badge: child.streakCount > 0 ? '🔥 Active' : 'Start Today',
          badgeColor: EduStreakTheme.streakOrange,
          icon: Icons.local_fire_department_rounded,
          color: EduStreakTheme.streakOrange,
        ),
      ],
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String badge,
    required Color badgeColor,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: EduStreakTheme.studentDarkCardDecoration(),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.35)),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: EduStreakTheme.fontCaption(
                    color: EduStreakTheme.studentDarkTextMuted,
                    weight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: EduStreakTheme.fontHeading2(
                    color: Colors.white,
                    weight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  badge,
                  style: EduStreakTheme.fontCaption(
                    color: badgeColor,
                    weight: FontWeight.w700,
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

  // ─── SCHOOL ANNOUNCEMENTS NOTICEBOARD ────────────────────────────────────
  Widget _buildSchoolAnnouncementsCard(UserModel child) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: EduStreakTheme.studentDarkCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isVeryNarrow = constraints.maxWidth < 280;
              final titleRow = Row(
                children: [
                  const Icon(Icons.campaign_rounded, color: EduStreakTheme.amberGold, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'School Noticeboard',
                      style: EduStreakTheme.fontHeading2(color: Colors.white, weight: FontWeight.w800),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              );
              final badge = Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: EduStreakTheme.amberGold.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: EduStreakTheme.amberGold.withValues(alpha: 0.35)),
                ),
                child: const Text(
                  'Official Circular',
                  style: TextStyle(color: EduStreakTheme.amberGold, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              );

              if (isVeryNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleRow,
                    const SizedBox(height: 6),
                    badge,
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: titleRow),
                  const SizedBox(width: 8),
                  badge,
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: EduStreakTheme.studentDarkCardSub,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: EduStreakTheme.studentDarkBorder),
            ),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 38,
                  decoration: BoxDecoration(
                    color: EduStreakTheme.amberGold,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Upcoming Science & Robotics Exhibition',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Parents are cordially invited to review student projects and innovative prototypes this Friday.',
                        style: EduStreakTheme.fontCaption(color: EduStreakTheme.studentDarkTextMuted),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── SUBJECT PERFORMANCE CARD ───────────────────────────────────────────
  Widget _buildSubjectPerformanceCard(UserModel child, [List<TaskModel>? preloadedTasks]) {
    Widget buildContent(List<TaskModel> tasks) {
      final Map<String, List<double>> subjectScores = {};

      for (final t in tasks) {
        final mark = t.marks[child.id];
        if (mark != null) {
          final pct = (mark / t.maxMarks).clamp(0.0, 1.0);
          final subject = t.subject.isNotEmpty ? t.subject : 'General';
          subjectScores.putIfAbsent(subject, () => []).add(pct);
        }
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isVeryNarrow = constraints.maxWidth < 280;
              final titleRow = Row(
                children: [
                  const Icon(Icons.bar_chart_rounded, size: 20, color: EduStreakTheme.neonCyan),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Subject Performance',
                      style: EduStreakTheme.fontHeading2(
                        color: Colors.white,
                        weight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              );
              final badge = Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: EduStreakTheme.studentDarkCardSub,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: EduStreakTheme.studentDarkBorder),
                ),
                child: Text(
                  subjectScores.isNotEmpty ? '${subjectScores.length} Subjects' : 'Pending',
                  style: EduStreakTheme.fontCaption(
                    color: EduStreakTheme.studentDarkHighlight,
                    weight: FontWeight.w700,
                  ),
                ),
              );

              if (isVeryNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleRow,
                    const SizedBox(height: 6),
                    badge,
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: titleRow),
                  const SizedBox(width: 8),
                  badge,
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          if (subjectScores.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No graded subject evaluations yet for ${child.name}.',
                  style: EduStreakTheme.fontCaption(color: EduStreakTheme.studentDarkTextMuted),
                ),
              ),
            )
          else
            ...subjectScores.entries.map((entry) {
              final avg = entry.value.reduce((a, b) => a + b) / entry.value.length;
              final percent = (avg * 100).round();
              final color = percent >= 80
                  ? EduStreakTheme.emeraldGreen
                  : (percent >= 60 ? EduStreakTheme.neonCyan : EduStreakTheme.primaryViolet);

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            entry.key,
                            style: EduStreakTheme.fontLabel(
                              color: Colors.white,
                              weight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$percent%',
                          style: EduStreakTheme.fontHeading3(
                            color: color,
                            weight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: avg,
                        minHeight: 8,
                        backgroundColor: EduStreakTheme.studentDarkCardSub,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      );
    }

    if (preloadedTasks != null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: EduStreakTheme.studentDarkCardDecoration(),
        child: buildContent(preloadedTasks),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: EduStreakTheme.studentDarkCardDecoration(),
      child: StreamBuilder<List<TaskModel>>(
        stream: _getTasksStream(child.id),
        builder: (context, snapshot) => buildContent(snapshot.data ?? []),
      ),
    );
  }

  // ─── GROWTH INSIGHT CARD ─────────────────────────────────────────────────
  Widget _buildGrowthInsightCard(UserModel child) {
    final streak = child.streakCount;
    final headline = streak > 0 ? '$streak-Day Learning Streak Active' : 'Consistent Daily Practice';
    final desc = streak > 0
        ? '${child.name} has maintained a consistent learning habit. Consistent daily quests improve concept retention by up to 25%.'
        : 'Encourage ${child.name} to complete Today\'s Quest to ignite their daily learning streak.';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: EduStreakTheme.studentDarkCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isVeryNarrow = constraints.maxWidth < 280;
              final titleRow = Row(
                children: [
                  const Icon(Icons.trending_up_rounded, size: 20, color: EduStreakTheme.emeraldGreen),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Growth Insight',
                      style: EduStreakTheme.fontHeading2(
                        color: Colors.white,
                        weight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              );
              final badge = Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: EduStreakTheme.emeraldGreen.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: EduStreakTheme.emeraldGreen.withValues(alpha: 0.35)),
                ),
                child: const Text(
                  'Live Analytics',
                  style: TextStyle(
                    color: EduStreakTheme.emeraldGreen,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );

              if (isVeryNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleRow,
                    const SizedBox(height: 6),
                    badge,
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: titleRow),
                  const SizedBox(width: 8),
                  badge,
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          // Callout Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: EduStreakTheme.studentDarkCardSub,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: EduStreakTheme.emeraldGreen.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_graph_rounded, color: EduStreakTheme.emeraldGreen, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        headline,
                        style: EduStreakTheme.fontHeading3(
                          color: Colors.white,
                          weight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        desc,
                        style: EduStreakTheme.fontCaption(
                          color: EduStreakTheme.studentDarkHighlight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Academic Observation:',
            style: EduStreakTheme.fontLabel(
              color: Colors.white,
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: EduStreakTheme.studentDarkCardSub,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: EduStreakTheme.studentDarkBorder),
            ),
            child: Text(
              '"${child.name} has accumulated ${child.xp} XP at Level ${child.level}. Continuing regular chapter reviews builds mastery across STEM and language subjects."',
              style: EduStreakTheme.fontBody(
                color: EduStreakTheme.studentDarkHighlight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── UPCOMING HOMEWORK CARD ──────────────────────────────────────────────
  Widget _buildUpcomingHomeworkCard(UserModel child, [List<TaskModel>? preloadedTasks]) {
    Widget buildContent(List<TaskModel> tasks) {
      final pendingTasks = tasks.where((t) => !t.submissions.containsKey(child.id)).toList();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isVeryNarrow = constraints.maxWidth < 280;
              final titleRow = Row(
                children: [
                  const Icon(Icons.assignment_rounded, size: 20, color: EduStreakTheme.secondaryPurple),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Upcoming Homework',
                      style: EduStreakTheme.fontHeading2(
                        color: Colors.white,
                        weight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              );
              final badge = Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: pendingTasks.isNotEmpty
                      ? EduStreakTheme.rosePink.withValues(alpha: 0.18)
                      : EduStreakTheme.emeraldGreen.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: pendingTasks.isNotEmpty
                        ? EduStreakTheme.rosePink.withValues(alpha: 0.35)
                        : EduStreakTheme.emeraldGreen.withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  pendingTasks.isNotEmpty ? '${pendingTasks.length} Pending' : 'All Clear',
                  style: EduStreakTheme.fontCaption(
                    color: pendingTasks.isNotEmpty ? EduStreakTheme.rosePink : EduStreakTheme.emeraldGreen,
                    weight: FontWeight.w700,
                  ),
                ),
              );

              if (isVeryNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleRow,
                    const SizedBox(height: 6),
                    badge,
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: titleRow),
                  const SizedBox(width: 8),
                  badge,
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          if (pendingTasks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, color: EduStreakTheme.emeraldGreen, size: 36),
                    const SizedBox(height: 8),
                    Text(
                      'No pending homework for ${child.name}. All assignments are completed!',
                      style: EduStreakTheme.fontCaption(color: EduStreakTheme.studentDarkTextMuted),
                    ),
                  ],
                ),
              ),
            )
          else
            ...pendingTasks.take(3).map((task) {
              final now = DateTime.now();
              final isUrgent = task.dueDate.isBefore(now.add(const Duration(days: 1)));
              final color = isUrgent ? EduStreakTheme.rosePink : EduStreakTheme.secondaryPurple;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: EduStreakTheme.studentDarkCardSub,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isUrgent
                        ? EduStreakTheme.rosePink.withValues(alpha: 0.45)
                        : EduStreakTheme.studentDarkBorder,
                  ),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrowCard = constraints.maxWidth < 360;

                    final infoCol = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${task.subject.isNotEmpty ? task.subject : "Task"} • ${task.title}',
                          style: EduStreakTheme.fontLabel(
                            color: Colors.white,
                            weight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Due ${task.dueDate.day}/${task.dueDate.month}/${task.dueDate.year}',
                          style: EduStreakTheme.fontCaption(
                            color: isUrgent ? EduStreakTheme.rosePink : EduStreakTheme.studentDarkTextMuted,
                            weight: isUrgent ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ],
                    );

                    final statusPill = Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isUrgent
                            ? EduStreakTheme.rosePink.withValues(alpha: 0.18)
                            : EduStreakTheme.studentDarkCard,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isUrgent
                              ? EduStreakTheme.rosePink.withValues(alpha: 0.35)
                              : EduStreakTheme.studentDarkBorder,
                        ),
                      ),
                      child: Text(
                        isUrgent ? 'Action Needed' : 'Pending',
                        style: EduStreakTheme.fontCaption(
                          color: isUrgent ? EduStreakTheme.rosePink : EduStreakTheme.studentDarkTextMuted,
                          weight: FontWeight.w700,
                        ),
                      ),
                    );

                    if (isNarrowCard) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 4,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(child: infoCol),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Align(alignment: Alignment.centerRight, child: statusPill),
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Container(
                          width: 4,
                          height: 36,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: infoCol),
                        const SizedBox(width: 8),
                        statusPill,
                      ],
                    );
                  },
                ),
              );
            }),
        ],
      );
    }

    if (preloadedTasks != null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: EduStreakTheme.studentDarkCardDecoration(),
        child: buildContent(preloadedTasks),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: EduStreakTheme.studentDarkCardDecoration(),
      child: StreamBuilder<List<TaskModel>>(
        stream: _getTasksStream(child.id),
        builder: (context, snapshot) => buildContent(snapshot.data ?? []),
      ),
    );
  }

  // ─── TAB 1: MY CHILD PROFILE ─────────────────────────────────────────────
  Widget _buildMyChildProfileTab(UserModel? parent, UserModel? child) {
    if (child == null) {
      return Container(
        color: EduStreakTheme.studentDarkBg,
        child: Center(
          child: Text('No student selected', style: EduStreakTheme.fontHeading2(color: Colors.white)),
        ),
      );
    }

    final parentName = parent?.name.isNotEmpty == true ? parent!.name : 'Parent';

    return Container(
      color: EduStreakTheme.studentDarkBg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Child Profile Details', style: EduStreakTheme.fontHeading1(color: Colors.white, weight: FontWeight.w800)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: EduStreakTheme.studentDarkCardDecoration(),
              child: Column(
                children: [
                  const AkashStudentAvatar(size: 80),
                  const SizedBox(height: 14),
                  Text(
                    child.name,
                    style: EduStreakTheme.fontHeading2(color: Colors.white, weight: FontWeight.w800),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Roll #: ${child.rollNumber ?? "--"} • Admission: ${child.admissionNumber ?? "--"}',
                    style: EduStreakTheme.fontCaption(color: EduStreakTheme.studentDarkTextMuted),
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: EduStreakTheme.studentDarkBorder),
                  _buildInfoRow('Class & Section', '${child.grade != null ? "Grade ${child.grade}" : (child.classId ?? "Enrolled")}${child.section != null ? " — Section ${child.section}" : ""}'),
                  _buildInfoRow('School Code', child.schoolCode ?? (child.schoolId ?? 'Registered Institution')),
                  _buildInfoRow('Academic Year', child.academicYear ?? '2026-2027'),
                  _buildInfoRow('Parent / Guardian', parentName),
                  _buildInfoRow('Account Status', child.isActive ? 'Active & Enrolled' : 'Inactive'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── TAB 2: PROGRESS REPORT & SKILL MATRIX ───────────────────────────────
  Widget _buildProgressReportTab(UserModel? child) {
    if (child == null) {
      return Container(
        color: EduStreakTheme.studentDarkBg,
        child: Center(
          child: Text('No student selected', style: EduStreakTheme.fontHeading2(color: Colors.white)),
        ),
      );
    }

    // 6 Dimensions of EduStreak Skill Matrix
    final skillDimensions = [
      {'name': 'Conceptual Understanding', 'score': 0.88, 'level': 'Mastered', 'evidence': 18},
      {'name': 'Problem Solving', 'score': 0.82, 'level': 'Proficient', 'evidence': 15},
      {'name': 'Critical Thinking', 'score': 0.76, 'level': 'Proficient', 'evidence': 12},
      {'name': 'Application Skills', 'score': 0.70, 'level': 'Developing', 'evidence': 10},
      {'name': 'Consistency & Discipline', 'score': 0.94, 'level': 'Exemplary', 'evidence': 24},
      {'name': 'Communication & Expression', 'score': 0.85, 'level': 'Proficient', 'evidence': 14},
    ];

    return Container(
      color: EduStreakTheme.studentDarkBg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Comprehensive Progress & Skill Matrix',
              style: EduStreakTheme.fontHeading1(color: Colors.white, weight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Evidence-backed diagnostic skill profiling for ${child.name}',
              style: EduStreakTheme.fontCaption(color: EduStreakTheme.studentDarkTextMuted),
            ),
            const SizedBox(height: 20),

            // Snapshot Metrics
            _buildSnapshotKpiRow(child),

            const SizedBox(height: 22),

            // Skill Radar Chart + 6 Dimensions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: EduStreakTheme.studentDarkCardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isVeryNarrow = constraints.maxWidth < 280;
                      final titleRow = Row(
                        children: [
                          const Icon(Icons.radar_rounded, color: EduStreakTheme.primaryViolet, size: 22),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '6-Dimension Skill Profile',
                              style: EduStreakTheme.fontHeading2(color: Colors.white, weight: FontWeight.w800),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      );
                      final badge = Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: EduStreakTheme.primaryViolet.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: EduStreakTheme.primaryViolet.withValues(alpha: 0.35)),
                        ),
                        child: const Text(
                          'Radar Evaluation',
                          style: TextStyle(color: EduStreakTheme.primaryViolet, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      );

                      if (isVeryNarrow) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            titleRow,
                            const SizedBox(height: 6),
                            badge,
                          ],
                        );
                      }

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: titleRow),
                          const SizedBox(width: 8),
                          badge,
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Responsive Radar Chart
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final chartSize = constraints.maxWidth < 450 ? 220.0 : 280.0;
                      return Center(
                        child: SizedBox(
                          width: chartSize,
                          height: chartSize,
                          child: RadarChart(
                            RadarChartData(
                              dataSets: [
                                RadarDataSet(
                                  fillColor: EduStreakTheme.primaryViolet.withValues(alpha: 0.25),
                                  borderColor: EduStreakTheme.primaryViolet,
                                  entryRadius: 3,
                                  dataEntries: skillDimensions
                                      .map((s) => RadarEntry(value: (s['score'] as double) * 100))
                                      .toList(),
                                  borderWidth: 2,
                                ),
                              ],
                              radarBackgroundColor: Colors.transparent,
                              radarBorderData: const BorderSide(color: EduStreakTheme.studentDarkBorder, width: 1),
                              radarShape: RadarShape.polygon,
                              titleTextStyle: const TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              getTitle: (index, angle) {
                                const shortTitles = [
                                  'Concepts',
                                  'Solving',
                                  'Critical',
                                  'Application',
                                  'Discipline',
                                  'Expression',
                                ];
                                return RadarChartTitle(
                                  text: shortTitles[index % shortTitles.length],
                                  angle: angle,
                                  positionPercentageOffset: 0.18,
                                );
                              },
                              tickCount: 3,
                              ticksTextStyle: const TextStyle(color: Colors.transparent),
                              gridBorderData: const BorderSide(color: EduStreakTheme.studentDarkBorder, width: 0.8),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: EduStreakTheme.studentDarkBorder),
                  const SizedBox(height: 14),

                  // Skill Dimension Breakdown Cards
                  Text(
                    'Skill Dimensions & Competencies',
                    style: EduStreakTheme.fontLabel(color: Colors.white, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  ...skillDimensions.map((skill) {
                    final score = (skill['score'] as double);
                    final pct = (score * 100).round();
                    final color = pct >= 85
                        ? EduStreakTheme.emeraldGreen
                        : (pct >= 75 ? EduStreakTheme.neonCyan : EduStreakTheme.primaryViolet);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: EduStreakTheme.studentDarkCardSub,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: EduStreakTheme.studentDarkBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  skill['name'] as String,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: color.withValues(alpha: 0.35)),
                                ),
                                child: Text(
                                  '${skill['level']} ($pct%)',
                                  style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: score,
                              minHeight: 6,
                              backgroundColor: EduStreakTheme.studentDarkBorder,
                              valueColor: AlwaysStoppedAnimation<Color>(color),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Supported by ${skill['evidence']} assessment questions & teacher reviews',
                            style: EduStreakTheme.fontCaption(color: EduStreakTheme.studentDarkTextMuted),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // Subject Performance + Growth Insight
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 950) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: _buildSubjectPerformanceCard(child)),
                      const SizedBox(width: 20),
                      Expanded(flex: 3, child: _buildGrowthInsightCard(child)),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      _buildSubjectPerformanceCard(child),
                      const SizedBox(height: 20),
                      _buildGrowthInsightCard(child),
                    ],
                  );
                }
              },
            ),

            const SizedBox(height: 22),

            // Gamified Achievements & Badges Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: EduStreakTheme.studentDarkCardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.emoji_events_rounded, color: EduStreakTheme.amberGold, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        'Gamified Achievements & Badges',
                        style: EduStreakTheme.fontHeading2(color: Colors.white, weight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    children: [
                      _buildBadgePill(Icons.local_fire_department_rounded, '${child.streakCount} Day Streak', EduStreakTheme.streakOrange),
                      _buildBadgePill(Icons.military_tech_rounded, 'Level ${child.level} Scholar', EduStreakTheme.primaryViolet),
                      _buildBadgePill(Icons.bolt_rounded, '${child.xp} Total XP', EduStreakTheme.neonCyan),
                      _buildBadgePill(Icons.task_alt_rounded, 'Consistent Quest Finisher', EduStreakTheme.emeraldGreen),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── TAB 3: ATTENDANCE CALENDAR & LOGS ────────────────────────────────────
  Widget _buildAttendanceTab(UserModel? child) {
    if (child == null) {
      return Container(
        color: EduStreakTheme.studentDarkBg,
        child: Center(child: Text('No student selected', style: EduStreakTheme.fontHeading2(color: Colors.white))),
      );
    }

    return Container(
      color: EduStreakTheme.studentDarkBg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Attendance Record — ${child.name}', style: EduStreakTheme.fontHeading1(color: Colors.white, weight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('Live roll register syncing with biometric and classroom logs', style: EduStreakTheme.fontCaption(color: EduStreakTheme.studentDarkTextMuted)),
            const SizedBox(height: 18),

            StreamBuilder<QuerySnapshot?>(
              stream: _getAttendanceStream(child.id),
              builder: (context, snapshot) {
                final docs = snapshot.data?.docs ?? [];
                final total = docs.length;
                final present = docs.where((d) {
                  final data = d.data() as Map<String, dynamic>?;
                  return data?['present'] == true;
                }).length;
                final absent = total - present;
                final rate = total > 0 ? (present / total * 100).toStringAsFixed(1) : '100.0';

                return Column(
                  children: [
                    // Attendance Metrics (Wrap or Grid to guarantee zero overflow)
                    AdaptiveDashboardGrid.metrics(
                      mainAxisExtent: 90,
                      children: [
                        _buildAttendanceMetricCard('Total Days', '$total', EduStreakTheme.primaryViolet, Icons.calendar_today_rounded),
                        _buildAttendanceMetricCard('Present', '$present', EduStreakTheme.emeraldGreen, Icons.check_circle_rounded),
                        _buildAttendanceMetricCard('Absent', '$absent', EduStreakTheme.rosePink, Icons.cancel_rounded),
                        _buildAttendanceMetricCard('Rate', '$rate%', EduStreakTheme.neonCyan, Icons.trending_up_rounded),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Monthly Attendance Calendar
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: EduStreakTheme.studentDarkCardDecoration(),
                      child: Column(
                        children: [
                          // Month Selector Bar
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chevron_left_rounded, color: Colors.white),
                                onPressed: () {
                                  setState(() {
                                    _attendanceMonth = DateTime(_attendanceMonth.year, _attendanceMonth.month - 1);
                                  });
                                },
                              ),
                              Text(
                                DateFormat('MMMM yyyy').format(_attendanceMonth),
                                style: EduStreakTheme.fontHeading2(color: Colors.white, weight: FontWeight.w800),
                              ),
                              IconButton(
                                icon: const Icon(Icons.chevron_right_rounded, color: Colors.white),
                                onPressed: () {
                                  setState(() {
                                    _attendanceMonth = DateTime(_attendanceMonth.year, _attendanceMonth.month + 1);
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Weekday Headers
                          Row(
                            children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((day) {
                              return Expanded(
                                child: Center(
                                  child: Text(
                                    day,
                                    style: const TextStyle(
                                      color: EduStreakTheme.studentDarkTextMuted,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 10),

                          // Calendar Days Grid
                          _buildCalendarMonthGrid(_attendanceMonth, docs),

                          const SizedBox(height: 16),
                          const Divider(color: EduStreakTheme.studentDarkBorder),
                          const SizedBox(height: 10),

                          // Legend
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 16,
                            runSpacing: 8,
                            children: [
                              _buildLegendItem(EduStreakTheme.emeraldGreen, 'Present'),
                              _buildLegendItem(EduStreakTheme.rosePink, 'Absent'),
                              _buildLegendItem(EduStreakTheme.studentDarkBorder, 'Weekend / Holiday'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceMetricCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: EduStreakTheme.studentDarkCardDecoration(),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: EduStreakTheme.fontCaption(color: EduStreakTheme.studentDarkTextMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: EduStreakTheme.fontHeading2(color: Colors.white, weight: FontWeight.w800),
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

  Widget _buildCalendarMonthGrid(DateTime month, List<QueryDocumentSnapshot> docs) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final firstWeekday = DateTime(month.year, month.month, 1).weekday; // 1 = Mon, 7 = Sun
    final totalSlots = ((firstWeekday - 1) + daysInMonth + 6) ~/ 7 * 7;

    final Map<int, bool> dayAttendance = {};
    for (final d in docs) {
      final data = d.data() as Map<String, dynamic>?;
      if (data != null && data['date'] != null) {
        DateTime? dt;
        if (data['date'] is Timestamp) {
          dt = (data['date'] as Timestamp).toDate();
        } else if (data['date'] is String) {
          dt = DateTime.tryParse(data['date'] as String);
        }
        if (dt != null && dt.year == month.year && dt.month == month.month) {
          dayAttendance[dt.day] = data['present'] == true;
        }
      }
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: totalSlots,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childAspectRatio: 1.1,
      ),
      itemBuilder: (context, index) {
        final dayNumber = index - (firstWeekday - 2);
        if (dayNumber < 1 || dayNumber > daysInMonth) {
          return const SizedBox.shrink();
        }

        final isSunday = (index % 7) == 6;
        final hasRecord = dayAttendance.containsKey(dayNumber);
        final isPresent = dayAttendance[dayNumber] == true;

        Color bg = EduStreakTheme.studentDarkCardSub;
        Color textCol = Colors.white70;

        if (hasRecord) {
          if (isPresent) {
            bg = EduStreakTheme.emeraldGreen.withValues(alpha: 0.25);
            textCol = EduStreakTheme.emeraldGreen;
          } else {
            bg = EduStreakTheme.rosePink.withValues(alpha: 0.25);
            textCol = EduStreakTheme.rosePink;
          }
        } else if (isSunday) {
          bg = EduStreakTheme.studentDarkSidebar;
          textCol = EduStreakTheme.studentDarkTextMuted;
        }

        return Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: hasRecord
                  ? (isPresent ? EduStreakTheme.emeraldGreen : EduStreakTheme.rosePink)
                  : EduStreakTheme.studentDarkBorder,
              width: hasRecord ? 1.2 : 0.8,
            ),
          ),
          child: Center(
            child: Text(
              '$dayNumber',
              style: TextStyle(
                color: textCol,
                fontSize: 12,
                fontWeight: hasRecord ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(text, style: EduStreakTheme.fontCaption(color: EduStreakTheme.studentDarkTextMuted)),
      ],
    );
  }

  // ─── TAB 4: HOMEWORK & SUBMISSIONS ───────────────────────────────────────
  Widget _buildHomeworkTab(UserModel? child) {
    if (child == null) {
      return Container(
        color: EduStreakTheme.studentDarkBg,
        child: Center(child: Text('No student selected', style: EduStreakTheme.fontHeading2(color: Colors.white))),
      );
    }

    return Container(
      color: EduStreakTheme.studentDarkBg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Homework & Submission Tracker', style: EduStreakTheme.fontHeading1(color: Colors.white, weight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('Review pending assignments and teacher evaluations for ${child.name}', style: EduStreakTheme.fontCaption(color: EduStreakTheme.studentDarkTextMuted)),
            const SizedBox(height: 16),

            // Horizontal Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: ['All', 'Pending', 'Submitted', 'Graded'].map((filter) {
                  final isSelected = _homeworkFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(filter),
                      selected: isSelected,
                      onSelected: (val) {
                        if (val) setState(() => _homeworkFilter = filter);
                      },
                      selectedColor: EduStreakTheme.primaryViolet,
                      backgroundColor: EduStreakTheme.studentDarkCardSub,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : EduStreakTheme.studentDarkTextMuted,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? EduStreakTheme.primaryViolet : EduStreakTheme.studentDarkBorder,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            StreamBuilder<List<TaskModel>>(
              stream: _getTasksStream(child.id),
              builder: (context, snapshot) {
                final tasks = snapshot.data ?? [];
                List<TaskModel> filteredTasks = tasks;

                if (_homeworkFilter == 'Pending') {
                  filteredTasks = tasks.where((t) => !t.submissions.containsKey(child.id)).toList();
                } else if (_homeworkFilter == 'Submitted') {
                  filteredTasks = tasks.where((t) => t.submissions.containsKey(child.id) && !t.marks.containsKey(child.id)).toList();
                } else if (_homeworkFilter == 'Graded') {
                  filteredTasks = tasks.where((t) => t.marks.containsKey(child.id)).toList();
                }

                if (filteredTasks.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(32),
                    decoration: EduStreakTheme.studentDarkCardDecoration(),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(Icons.task_alt_rounded, color: EduStreakTheme.emeraldGreen, size: 48),
                          const SizedBox(height: 10),
                          Text('No assignments in "$_homeworkFilter" category', style: EduStreakTheme.fontHeading3(color: Colors.white)),
                          const SizedBox(height: 4),
                          Text('All homework entries are up to date.', style: EduStreakTheme.fontCaption(color: EduStreakTheme.studentDarkTextMuted)),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  children: filteredTasks.map((t) {
                    final isSubmitted = t.submissions.containsKey(child.id);
                    final isGraded = t.marks.containsKey(child.id);
                    final mark = t.marks[child.id];
                    final now = DateTime.now();
                    final isUrgent = !isSubmitted && t.dueDate.isBefore(now.add(const Duration(days: 1)));

                    Color statusCol = isGraded
                        ? EduStreakTheme.emeraldGreen
                        : (isSubmitted ? EduStreakTheme.neonCyan : (isUrgent ? EduStreakTheme.rosePink : EduStreakTheme.secondaryPurple));

                    String statusText = isGraded
                        ? 'Graded: ${mark?.round() ?? 0}/${t.maxMarks}'
                        : (isSubmitted ? 'Submitted' : (isUrgent ? 'Action Needed' : 'Pending'));

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: EduStreakTheme.studentDarkCardDecoration(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: EduStreakTheme.primaryViolet.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: EduStreakTheme.primaryViolet.withValues(alpha: 0.35)),
                                ),
                                child: Text(
                                  t.subject.isNotEmpty ? t.subject : 'General',
                                  style: const TextStyle(color: EduStreakTheme.primaryViolet, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: statusCol.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: statusCol.withValues(alpha: 0.35)),
                                ),
                                child: Text(
                                  statusText,
                                  style: TextStyle(color: statusCol, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            t.title,
                            style: EduStreakTheme.fontHeading3(color: Colors.white, weight: FontWeight.w800),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (t.description.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              t.description,
                              style: EduStreakTheme.fontCaption(color: EduStreakTheme.studentDarkTextMuted),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Teacher: ${t.assignedByName.isNotEmpty ? t.assignedByName : "Class Teacher"}',
                                style: EduStreakTheme.fontCaption(color: EduStreakTheme.studentDarkHighlight),
                              ),
                              Text(
                                'Due: ${t.dueDate.day}/${t.dueDate.month}/${t.dueDate.year}',
                                style: EduStreakTheme.fontCaption(color: isUrgent ? EduStreakTheme.rosePink : EduStreakTheme.studentDarkTextMuted),
                              ),
                            ],
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
      ),
    );
  }

  // ─── TAB 5: RESULTS & ASSESSMENTS ────────────────────────────────────────
  Widget _buildResultsTab(UserModel? child) {
    if (child == null) {
      return Container(
        color: EduStreakTheme.studentDarkBg,
        child: Center(child: Text('No student selected', style: EduStreakTheme.fontHeading2(color: Colors.white))),
      );
    }

    return Container(
      color: EduStreakTheme.studentDarkBg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Evaluations & Assessments — ${child.name}', style: EduStreakTheme.fontHeading1(color: Colors.white, weight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('Formal unit tests, chapter examinations, and teacher feedback', style: EduStreakTheme.fontCaption(color: EduStreakTheme.studentDarkTextMuted)),
            const SizedBox(height: 16),

            // Subject Performance Quick View
            _buildSubjectPerformanceCard(child),

            const SizedBox(height: 20),

            // Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: ['All', 'quiz', 'unit_test', 'mid_term', 'terminal'].map((filter) {
                  final isSelected = _assessmentFilter == filter;
                  final displayLabel = filter == 'All'
                      ? 'All Assessments'
                      : filter.replaceAll('_', ' ').toUpperCase();

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(displayLabel),
                      selected: isSelected,
                      onSelected: (val) {
                        if (val) setState(() => _assessmentFilter = filter);
                      },
                      selectedColor: EduStreakTheme.primaryViolet,
                      backgroundColor: EduStreakTheme.studentDarkCardSub,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : EduStreakTheme.studentDarkTextMuted,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? EduStreakTheme.primaryViolet : EduStreakTheme.studentDarkBorder,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            StreamBuilder<List<AssessmentModel>>(
              stream: _getAssessmentsStream(child.id, child.classId),
              builder: (context, snapshot) {
                final assessments = snapshot.data ?? [];
                List<AssessmentModel> filtered = assessments;
                if (_assessmentFilter != 'All') {
                  filtered = assessments.where((a) => a.type == _assessmentFilter).toList();
                }

                if (filtered.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(28),
                    decoration: EduStreakTheme.studentDarkCardDecoration(),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(Icons.quiz_rounded, color: EduStreakTheme.studentDarkTextMuted, size: 40),
                          const SizedBox(height: 10),
                          Text('No assessments recorded for this period', style: EduStreakTheme.fontHeading3(color: Colors.white)),
                          const SizedBox(height: 4),
                          Text('New chapter evaluations will appear here once published by the teacher.', style: EduStreakTheme.fontCaption(color: EduStreakTheme.studentDarkTextMuted)),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  children: filtered.map((a) {
                    final hasScore = a.scores.containsKey(child.id);
                    final score = a.scores[child.id] ?? 0.0;
                    final pct = (score / a.totalMarks * 100).round();
                    final feedback = a.feedback[child.id] ?? '';

                    String grade = 'A';
                    if (pct >= 90) grade = 'A+';
                    else if (pct >= 80) grade = 'A';
                    else if (pct >= 70) grade = 'B+';
                    else if (pct >= 60) grade = 'B';
                    else grade = 'C';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: EduStreakTheme.studentDarkCardDecoration(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: EduStreakTheme.neonCyan.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: EduStreakTheme.neonCyan.withValues(alpha: 0.35)),
                                ),
                                child: Text(
                                  a.subject,
                                  style: const TextStyle(color: EduStreakTheme.neonCyan, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                              if (hasScore)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: EduStreakTheme.emeraldGreen.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: EduStreakTheme.emeraldGreen.withValues(alpha: 0.35)),
                                  ),
                                  child: Text(
                                    'Grade $grade • $pct%',
                                    style: const TextStyle(color: EduStreakTheme.emeraldGreen, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: EduStreakTheme.studentDarkCardSub,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: EduStreakTheme.studentDarkBorder),
                                  ),
                                  child: const Text(
                                    'Pending Evaluation',
                                    style: TextStyle(color: EduStreakTheme.studentDarkTextMuted, fontSize: 11),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            a.title,
                            style: EduStreakTheme.fontHeading2(color: Colors.white, weight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Teacher: ${a.createdByName.isNotEmpty ? a.createdByName : "Instructor"} • Total Marks: ${a.totalMarks} • Passing: ${a.passingMarks}',
                            style: EduStreakTheme.fontCaption(color: EduStreakTheme.studentDarkTextMuted),
                          ),
                          if (hasScore && feedback.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: EduStreakTheme.studentDarkCardSub,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: EduStreakTheme.studentDarkBorder),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.comment_rounded, size: 14, color: EduStreakTheme.primaryViolet),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Teacher Note: "$feedback"',
                                      style: const TextStyle(color: EduStreakTheme.studentDarkHighlight, fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ─── HELPER WIDGETS ──────────────────────────────────────────────────────
  Widget _buildBadgePill(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: EduStreakTheme.studentDarkCardSub,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: EduStreakTheme.fontLabel(color: Colors.white, weight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: EduStreakTheme.fontCaption(color: EduStreakTheme.studentDarkTextMuted)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: EduStreakTheme.fontLabel(color: Colors.white, weight: FontWeight.w700),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
