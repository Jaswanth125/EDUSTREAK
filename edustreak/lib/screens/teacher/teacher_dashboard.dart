import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/user_provider.dart';
import '../../services/auth_service.dart';
import '../../utils/theme.dart';
import '../../widgets/app_logo.dart';
import 'attendance_screen.dart';
import 'assign_task_screen.dart';
import 'students_list_screen.dart';
import '../chat/chat_inbox_screen.dart';
import 'grade_tasks_screen.dart';
import 'class_management_screen.dart';
import 'teacher_ai_tasks_screen.dart';
import '../shared/leaderboard_screen.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final screens = [
      _buildHomeTab(user),
      const AttendanceScreen(),
      const AssignTaskScreen(),
      const GradeTasksScreen(),
      const StudentsListScreen(),
      const LeaderboardScreen(showAppBar: false),
      const ChatInboxScreen(showAppBar: false),
    ];

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: AppLogo(size: 32),
        ),
        leadingWidth: 68,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            boxShadow: AppTheme.primaryGlowShadow,
          ),
        ),
        foregroundColor: Colors.white,
        title: Text(
          _currentIndex == 0
              ? 'Teacher Hub'
              : [
                  'Teacher Hub',
                  'Attendance',
                  'Assign Tasks',
                  'Grade Tasks',
                  'Students',
                  'Leaderboard',
                  'Messages',
                ][_currentIndex],
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            tooltip: 'AI Tasks Review',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TeacherAiTasksScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.class_),
            tooltip: 'Manage Classes',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ClassManagementScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await AuthService().signOut();
              if (mounted) {
                userProvider.clearUser();
              }
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHomeTab(user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Banner
          _buildWelcomeBanner(user),
          const SizedBox(height: 20),

          // Quick Stats Row
          _buildQuickStats(user),
          const SizedBox(height: 24),

          // Quick Actions
          _buildSectionHeader('Quick Actions', Icons.flash_on),
          const SizedBox(height: 12),
          _buildQuickActions(),
          const SizedBox(height: 24),

          // Recent Activity header
          _buildSectionHeader('Recent Activity', Icons.history),
          const SizedBox(height: 12),
          _buildRecentActivity(user),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildWelcomeBanner(user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.primaryGlowShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.4),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : 'T',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, ${user.name.split(' ').first}! 👋',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage your classroom efficiently',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'TEACHER',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.1, end: 0);
  }

  Widget _buildQuickStats(user) {
    return FutureBuilder<Map<String, int>>(
      future: _fetchTeacherStats(user),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? {};
        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.people,
                label: 'Students',
                value: '${stats['students'] ?? 0}',
                color: Colors.blue,
                delay: 100,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.assignment,
                label: 'Tasks',
                value: '${stats['tasks'] ?? 0}',
                color: Colors.orange,
                delay: 200,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.pending_actions,
                label: 'Pending',
                value: '${stats['pending'] ?? 0}',
                color: Colors.red,
                delay: 300,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    int delay = 0,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.2),
            color.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: delay.ms, duration: 500.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      _QuickActionData('Attendance', Icons.check_circle_outline, Colors.green, 1),
      _QuickActionData('Assign Task', Icons.assignment_add, Colors.blue, 2),
      _QuickActionData('Grade Tasks', Icons.grading, Colors.orange, 3),
      _QuickActionData('AI Review', Icons.auto_awesome, Colors.purple, () {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => const TeacherAiTasksScreen(),
        ));
      }),
      _QuickActionData('Students', Icons.people, Colors.teal, 4),
      _QuickActionData('Classes', Icons.class_, Colors.indigo, () {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => const ClassManagementScreen(),
        ));
      }),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.0,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: actions.length,
      itemBuilder: (context, i) {
        final a = actions[i];
        return _buildActionTile(a, i);
      },
    );
  }

  Widget _buildActionTile(_QuickActionData action, int index) {
    return GestureDetector(
      onTap: () {
        if (action.destination is int) {
          setState(() => _currentIndex = action.destination as int);
        } else if (action.destination is Function) {
          (action.destination as Function)();
        }
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              action.color.withValues(alpha: 0.25),
              action.color.withValues(alpha: 0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: action.color.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: action.color.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: action.color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(action.icon, color: action.color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              action.label,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ).animate(delay: (index * 80).ms).fadeIn(duration: 400.ms).scale(
        begin: const Offset(0.8, 0.8),
        end: const Offset(1.0, 1.0),
        duration: 400.ms,
        curve: Curves.easeOut,
      ),
    );
  }

  Widget _buildRecentActivity(user) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tasks')
          .where('assignedBy', isEqualTo: user.id)
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final taskDocs = snapshot.data?.docs ?? [];
        final List<Map<String, dynamic>> recentSubmissions = [];

        for (final doc in taskDocs) {
          final data = doc.data() as Map<String, dynamic>;
          final taskTitle = data['title'] ?? 'Assignment';
          final submissions = (data['submissions'] as Map<String, dynamic>?) ?? {};
          final marks = (data['marks'] as Map<String, dynamic>?) ?? {};

          for (final entry in submissions.entries) {
            final studentId = entry.key;
            final isSubmitted = entry.value == 'submitted';
            if (isSubmitted) {
              final isGraded = marks.containsKey(studentId);
              final shortId = studentId.length > 4 ? studentId.substring(0, 4).toUpperCase() : studentId;
              recentSubmissions.add({
                'studentName': 'Student #$shortId',
                'taskTitle': taskTitle,
                'isGraded': isGraded,
                'submittedAt': data['createdAt'] ?? Timestamp.now(),
              });
            }
          }
        }

        if (recentSubmissions.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.darkSurface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.darkBorder.withValues(alpha: 0.5)),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.inbox, color: AppTheme.textTertiary, size: 40),
                  const SizedBox(height: 8),
                  Text(
                    'No recent student submissions',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: recentSubmissions.take(5).toList().asMap().entries.map((indexed) {
            final index = indexed.key;
            final item = indexed.value;
            final studentName = item['studentName'] as String;
            final taskTitle = item['taskTitle'] as String;
            final isGraded = item['isGraded'] as bool;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.darkSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isGraded
                      ? Colors.green.withValues(alpha: 0.3)
                      : Colors.orange.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (isGraded ? Colors.green : Colors.orange)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isGraded ? Icons.check_circle : Icons.pending,
                      color: isGraded ? Colors.green : Colors.orange,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          studentName,
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          taskTitle,
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isGraded ? Colors.green : Colors.orange)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isGraded ? 'Graded' : 'Pending',
                      style: TextStyle(
                        color: isGraded ? Colors.green : Colors.orange,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate(delay: (index * 80).ms).fadeIn(duration: 400.ms);
          }).toList(),
        );
      },
    );
  }

  Future<Map<String, int>> _fetchTeacherStats(user) async {
    try {
      // Count students in teacher's classes
      int studentCount = 0;
      int taskCount = 0;
      int pendingCount = 0;

      if (user.classIds != null && user.classIds!.isNotEmpty) {
        for (final classId in user.classIds!) {
          final students = await FirebaseFirestore.instance
              .collection('users')
              .where('classId', isEqualTo: classId)
              .where('role', isEqualTo: 'student')
              .count()
              .get();
          studentCount += students.count ?? 0;
        }
      }

      // Count tasks and pending evaluations
      final tasksSnapshot = await FirebaseFirestore.instance
          .collection('tasks')
          .where('assignedBy', isEqualTo: user.id)
          .get();

      taskCount = tasksSnapshot.docs.length;
      if (taskCount == 0) {
        final altTasks = await FirebaseFirestore.instance
            .collection('tasks')
            .where('teacherId', isEqualTo: user.id)
            .get();
        taskCount = altTasks.docs.length;
        for (final doc in altTasks.docs) {
          final data = doc.data();
          final submissions = (data['submissions'] as Map<String, dynamic>?) ?? {};
          final marks = (data['marks'] as Map<String, dynamic>?) ?? {};
          for (final sub in submissions.entries) {
            if (sub.value == 'submitted' && !marks.containsKey(sub.key)) {
              pendingCount++;
            }
          }
        }
      } else {
        for (final doc in tasksSnapshot.docs) {
          final data = doc.data();
          final submissions = (data['submissions'] as Map<String, dynamic>?) ?? {};
          final marks = (data['marks'] as Map<String, dynamic>?) ?? {};
          for (final sub in submissions.entries) {
            if (sub.value == 'submitted' && !marks.containsKey(sub.key)) {
              pendingCount++;
            }
          }
        }
      }

      return {
        'students': studentCount,
        'tasks': taskCount,
        'pending': pendingCount,
      };
    } catch (e) {
      return {'students': 0, 'tasks': 0, 'pending': 0};
    }
  }

  Widget _buildBottomNav() {
    final navItems = [
      _NavItem(Icons.home_rounded, Icons.home_outlined, 'Home'),
      _NavItem(Icons.check_circle_rounded, Icons.check_circle_outline, 'Attendance'),
      _NavItem(Icons.assignment_rounded, Icons.assignment_outlined, 'Assign'),
      _NavItem(Icons.grading_rounded, Icons.grading, 'Grade'),
      _NavItem(Icons.people_rounded, Icons.people_outline, 'Students'),
      _NavItem(Icons.leaderboard_rounded, Icons.leaderboard_outlined, 'Board'),
      _NavItem(Icons.chat_rounded, Icons.chat_outlined, 'Messages'),
    ];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppTheme.darkSurface, AppTheme.darkSurfaceVariant],
        ),
        border: Border(
          top: BorderSide(
            color: AppTheme.primaryColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: AppTheme.textTertiary,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedFontSize: 10,
        unselectedFontSize: 9,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        items: navItems.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: _currentIndex == i
                  ? BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.4),
                          blurRadius: 8,
                        ),
                      ],
                    )
                  : null,
              child: Icon(
                _currentIndex == i ? item.activeIcon : item.icon,
                size: _currentIndex == i ? 22 : 20,
              ),
            ),
            label: item.label,
          );
        }).toList(),
      ),
    );
  }
}

class _QuickActionData {
  final String label;
  final IconData icon;
  final Color color;
  final dynamic destination; // int index or Function

  _QuickActionData(this.label, this.icon, this.color, this.destination);
}

class _NavItem {
  final IconData activeIcon;
  final IconData icon;
  final String label;
  _NavItem(this.activeIcon, this.icon, this.label);
}
