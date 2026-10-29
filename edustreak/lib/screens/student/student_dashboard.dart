import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/user_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/auth_service.dart';
import '../../utils/theme.dart';
import '../../models/user_model.dart';
import '../../widgets/streak_counter.dart';
import '../../widgets/xp_progress_bar.dart';
import '../../widgets/badge_display.dart';
import '../../widgets/tiered_profile_picture.dart';
import '../../widgets/app_logo.dart';
import '../shared/leaderboard_screen.dart';
import '../shared/skill_matrix_screen.dart';
import 'tasks_screen.dart';
import 'challenges_screen.dart';
import 'store_screen.dart';
import 'attendance_screen.dart';
import '../chat/chat_inbox_screen.dart';
import 'study_assistant_screen.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: AppLogo(size: 36),
        ),
        leadingWidth: 72,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            boxShadow: AppTheme.primaryGlowShadow,
          ),
        ),
        foregroundColor: Colors.white,
        title: Text(
          'Welcome, ${user.name}!',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        elevation: 0,
        actions: [
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
        children: [
          _buildHomeTab(user),
          const TasksScreen(),
          const ChallengesScreen(),
          const LeaderboardScreen(showAppBar: false),
          SkillMatrixScreen(studentId: user.id, studentName: user.name, showAppBar: false),
          const StudyAssistantScreen(showAppBar: false),
          const ChatInboxScreen(showAppBar: false),
          _buildProfileTab(user),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.darkSurface,
              AppTheme.darkSurfaceVariant,
            ],
          ),
          border: Border(
            top: BorderSide(
              color: AppTheme.primaryColor.withOpacity(0.2),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.15),
              blurRadius: 30,
              spreadRadius: -5,
              offset: const Offset(0, -10),
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
          selectedFontSize: 11,
          unselectedFontSize: 10,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 11,
            letterSpacing: 0.3,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 10,
          ),
          items: [
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: _currentIndex == 0
                    ? BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.4),
                            blurRadius: 8,
                            spreadRadius: 0,
                          ),
                        ],
                      )
                    : null,
                child: Icon(
                  Icons.home,
                  size: _currentIndex == 0 ? 22 : 20,
                ),
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: _currentIndex == 1
                    ? BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue[400]!, Colors.blue[600]!],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      )
                    : null,
                child: Icon(
                  Icons.assignment,
                  size: _currentIndex == 1 ? 22 : 20,
                ),
              ),
              label: 'Tasks',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: _currentIndex == 2
                    ? BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.orange[400]!, Colors.orange[600]!],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      )
                    : null,
                child: Icon(
                  Icons.emoji_events,
                  size: _currentIndex == 2 ? 22 : 20,
                ),
              ),
              label: 'Challenges',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: _currentIndex == 3
                    ? BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.purple[400]!, Colors.purple[600]!],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      )
                    : null,
                child: Icon(
                  Icons.leaderboard,
                  size: _currentIndex == 3 ? 22 : 20,
                ),
              ),
              label: 'Leaderboard',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: _currentIndex == 4
                    ? BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.teal[400]!, Colors.teal[600]!],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      )
                    : null,
                child: Icon(
                  Icons.radar,
                  size: _currentIndex == 4 ? 22 : 20,
                ),
              ),
              label: 'Skills',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: _currentIndex == 5
                    ? BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.indigo[400]!, Colors.indigo[600]!],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      )
                    : null,
                child: Icon(
                  Icons.school,
                  size: _currentIndex == 5 ? 22 : 20,
                ),
              ),
              label: 'Assistant',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: _currentIndex == 6
                    ? BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.pink[400]!, Colors.pink[600]!],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      )
                    : null,
                child: Icon(
                  Icons.chat,
                  size: _currentIndex == 6 ? 22 : 20,
                ),
              ),
              label: 'Messages',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: _currentIndex == 7
                    ? BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.grey[400]!, Colors.grey[600]!],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      )
                    : null,
                child: Icon(
                  Icons.person,
                  size: _currentIndex == 7 ? 22 : 20,
                ),
              ),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeTab(user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Streak Counter
          StreakCounter(streak: user.streak),
          const SizedBox(height: 24),
          
          // XP Progress
          XPProgressBar(xp: user.xp, level: user.level),
          const SizedBox(height: 24),
          
          // Stats Cards Row
          Row(
            children: [
              Expanded(
                child: _buildStatMiniCard(
                  icon: Icons.star,
                  value: '${user.xp}',
                  label: 'XP',
                  color: Colors.amber,
                )
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 600.ms)
                    .slideY(begin: 0.2, end: 0, duration: 600.ms),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatMiniCard(
                  icon: Icons.trending_up,
                  value: '${user.level}',
                  label: 'Level',
                  color: Colors.blue,
                )
                    .animate()
                    .fadeIn(delay: 300.ms, duration: 600.ms)
                    .slideY(begin: 0.2, end: 0, duration: 600.ms),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatMiniCard(
                  icon: Icons.emoji_events,
                  value: '${user.badges.length}',
                  label: 'Badges',
                  color: Colors.purple,
                )
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 600.ms)
                    .slideY(begin: 0.2, end: 0, duration: 600.ms),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Daily Motivation Banner
          _buildMotivationBanner(user)
              .animate()
              .fadeIn(delay: 450.ms, duration: 600.ms)
              .slideY(begin: 0.1, end: 0),
          const SizedBox(height: 24),
          
          // Badges Section
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple[400]!, Colors.purple[600]!],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.workspace_premium, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Your Badges',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                      letterSpacing: 0.5,
                    ),
              ),
            ],
          )
              .animate()
              .fadeIn(delay: 500.ms, duration: 600.ms)
              .slideX(begin: -0.2, end: 0, duration: 600.ms),
          const SizedBox(height: 16),
          BadgeDisplay(userId: user.id, badges: user.badges),
          const SizedBox(height: 24),
          
          // Quick Actions
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.dashboard, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                      letterSpacing: 0.5,
                    ),
              ),
            ],
          )
              .animate()
              .fadeIn(delay: 600.ms, duration: 600.ms)
              .slideX(begin: -0.2, end: 0, duration: 600.ms),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  icon: Icons.assignment,
                  title: 'Tasks',
                  onTap: () => setState(() => _currentIndex = 1),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionCard(
                  icon: Icons.emoji_events,
                  title: 'Challenges',
                  onTap: () => setState(() => _currentIndex = 2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  icon: Icons.leaderboard,
                  title: 'Leaderboard',
                  onTap: () => setState(() => _currentIndex = 3),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionCard(
                  icon: Icons.store,
                  title: 'Store',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const StoreScreen()),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  icon: Icons.calendar_today,
                  title: 'Attendance',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const StudentAttendanceScreen()),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionCard(
                  icon: Icons.school,
                  title: 'Study Assistant',
                  onTap: () => setState(() => _currentIndex = 5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatMiniCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.2),
            color.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 12,
            spreadRadius: 0,
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
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
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
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    // Different gradients for different actions
    LinearGradient getGradient() {
      switch (icon) {
        case Icons.assignment:
          return LinearGradient(
            colors: [Colors.blue[400]!, Colors.blue[600]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
        case Icons.emoji_events:
          return LinearGradient(
            colors: [Colors.orange[400]!, Colors.orange[600]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
        case Icons.leaderboard:
          return LinearGradient(
            colors: [Colors.purple[400]!, Colors.purple[600]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
        case Icons.store:
          return LinearGradient(
            colors: [Colors.green[400]!, Colors.green[600]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
        case Icons.calendar_today:
          return LinearGradient(
            colors: [Colors.teal[400]!, Colors.teal[600]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
        case Icons.school:
          return LinearGradient(
            colors: [Colors.indigo[400]!, Colors.indigo[600]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
        default:
          return AppTheme.primaryGradient;
      }
    }

    return Container(
      decoration: BoxDecoration(
        gradient: getGradient(),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (icon == Icons.assignment
                    ? Colors.blue
                    : icon == Icons.emoji_events
                        ? Colors.orange
                        : icon == Icons.leaderboard
                            ? Colors.purple
                            : icon == Icons.store
                                ? Colors.green
                                : icon == Icons.calendar_today
                                    ? Colors.teal
                                    : Colors.indigo)
                .withOpacity(0.4),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            spreadRadius: -5,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.4),
                      width: 2,
                    ),
                  ),
                  child: Icon(icon, size: 28, color: Colors.white),
                )
                    .animate()
                    .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.1, 1.1), duration: 200.ms)
                    .then()
                    .scale(begin: const Offset(1.1, 1.1), end: const Offset(1.0, 1.0), duration: 200.ms),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: 0.3,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileTab(user) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getProfileData(user),
      builder: (context, snapshot) {
        final rank = snapshot.data?['rank'] ?? 0;
        final completedTasks = snapshot.data?['completedTasks'] ?? 0;
        final totalStudents = snapshot.data?['totalStudents'] ?? 1;
        final rankPercent = totalStudents > 0 ? ((totalStudents - rank + 1) / totalStudents * 100).round() : 0;

        return SingleChildScrollView(
          child: Column(
            children: [
              // Profile Header with Gradient
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Profile Picture
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: TieredProfilePicture(
                        user: user,
                        size: 100,
                        showTierBorder: false,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Username
                    Text(
                      user.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Email
                    Text(
                      user.email,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Role Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'STUDENT',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Stats Section
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(26),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF2B2E63),
                            const Color(0xFF191B30),
                          ],
                        ),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.08),
                          width: 1.4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Performance Overview',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Live stats from your class progress',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              Icon(Icons.insights, color: Colors.white.withOpacity(0.8)),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              _buildPerformanceChip(
                                icon: Icons.emoji_events,
                                iconColor: Colors.amberAccent,
                                label: 'Rank',
                                value: rank > 0 ? '#$rank' : 'N/A',
                                sublabel: rankPercent > 0 ? 'Top $rankPercent%' : 'No data',
                              ),
                              _buildPerformanceChip(
                                icon: Icons.workspace_premium,
                                iconColor: Colors.purpleAccent,
                                label: 'Badges',
                                value: '${user.badges.length}',
                                sublabel: 'Earned so far',
                              ),
                              _buildPerformanceChip(
                                icon: Icons.local_fire_department,
                                iconColor: Colors.orangeAccent,
                                label: 'Streak',
                                value: '${user.streakCount} days',
                                sublabel: 'Highest ${user.highestStreak}',
                              ),
                              _buildPerformanceChip(
                                icon: Icons.check_circle,
                                iconColor: Colors.tealAccent,
                                label: 'Completed',
                                value: '$completedTasks tasks',
                                sublabel: 'Total submissions',
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _buildProgressRow('XP Points', user.xp, 10000, Icons.star, Colors.amber),
                          const SizedBox(height: 18),
                          _buildProgressRow('Level', user.level, 20, Icons.trending_up, Colors.lightBlueAccent),
                          const SizedBox(height: 18),
                          _buildProgressRow('Highest Streak', user.highestStreak, 30, Icons.local_fire_department, Colors.deepOrangeAccent),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Settings Section
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: AppTheme.darkCardGradient,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                        boxShadow: AppTheme.cardGlowShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  gradient: AppTheme.primaryGradient,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.settings, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Settings',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Consumer<ThemeProvider>(
                            builder: (context, themeProvider, _) {
                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.1),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          themeProvider.isDarkMode
                                              ? Icons.dark_mode
                                              : Icons.light_mode,
                                          color: AppTheme.primaryColor,
                                          size: 24,
                                        ),
                                        const SizedBox(width: 12),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Theme',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Text(
                                              themeProvider.isDarkMode
                                                  ? 'Dark Mode'
                                                  : 'Light Mode',
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(0.7),
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    Switch(
                                      value: themeProvider.isDarkMode,
                                      onChanged: (value) {
                                        themeProvider.setThemeMode(
                                          value ? ThemeMode.dark : ThemeMode.light,
                                        );
                                      },
                                      activeColor: AppTheme.primaryColor,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _getProfileData(user) async {
    try {
      // Calculate rank
      int rank = 0;
      int totalStudents = 1;
      if (user.classId != null) {
        final studentsSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'student')
            .where('classId', isEqualTo: user.classId)
            .get();

        final students = studentsSnapshot.docs
            .map((doc) => UserModel.fromMap(doc.data()..['id'] = doc.id))
            .toList();

        totalStudents = students.length;
        students.sort((a, b) => b.xp.compareTo(a.xp));
        rank = students.indexWhere((s) => s.id == user.id) + 1;
        if (rank == 0) rank = totalStudents; // If not found, set to last
      }

      // Count completed tasks
      final completedTasksSnapshot = await FirebaseFirestore.instance
          .collection('taskSubmissions')
          .where('studentId', isEqualTo: user.id)
          .where('isSubmitted', isEqualTo: true)
          .count()
          .get();

      final completedTasks = completedTasksSnapshot.count;

      return {
        'rank': rank,
        'totalStudents': totalStudents,
        'completedTasks': completedTasks,
      };
    } catch (e) {
      return {'rank': 0, 'totalStudents': 1, 'completedTasks': 0};
    }
  }

  Widget _buildPerformanceChip({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String sublabel,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      constraints: const BoxConstraints(minWidth: 150),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  sublabel,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRow(String label, int current, int max, IconData icon, Color color) {
    final percentage = (current / max).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Text(
              '$current / $max',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 8,
            backgroundColor: AppTheme.darkBorder,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildMotivationBanner(dynamic user) {
    final streak = user.streak ?? 0;
    String quote;
    String badgeTitle;
    IconData icon;
    Color color;

    if (streak == 0) {
      quote = "Start your streak today! Every journey begins with a single step.";
      badgeTitle = "Day 1 Awaits";
      icon = Icons.flag_circle_rounded;
      color = AppTheme.cyanColor;
    } else if (streak < 3) {
      quote = "Great momentum! Keep learning today to build a lasting habit.";
      badgeTitle = "Building Momentum";
      icon = Icons.local_fire_department_rounded;
      color = AppTheme.streakColor;
    } else if (streak < 7) {
      quote = "You're on fire! Almost a full week of consistent learning.";
      badgeTitle = "Streak Warrior";
      icon = Icons.bolt_rounded;
      color = AppTheme.warningColor;
    } else if (streak < 14) {
      quote = "Two-week champion! Consistency is your superpower.";
      badgeTitle = "Consistency Hero";
      icon = Icons.military_tech_rounded;
      color = AppTheme.secondaryColor;
    } else {
      quote = "Unstoppable dedication! You're setting an example for the whole school.";
      badgeTitle = "Legendary Learner";
      icon = Icons.workspace_premium_rounded;
      color = AppTheme.goldColor;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.18),
            AppTheme.darkSurfaceVariant.withOpacity(0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 16,
            spreadRadius: -4,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.18),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.4)),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      badgeTitle,
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.darkBorder,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '🔥 $streak Days',
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  quote,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

