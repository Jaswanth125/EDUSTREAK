import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/user_provider.dart';
import '../../services/auth_service.dart';
import '../../utils/theme.dart';
import '../../widgets/streak_counter.dart';
import '../../widgets/xp_progress_bar.dart';
import '../../widgets/badge_display.dart';
import '../../widgets/tiered_profile_picture.dart';
import '../../widgets/app_logo.dart';
import '../shared/leaderboard_screen.dart';
import 'tasks_screen.dart';
import 'challenges_screen.dart';
import 'store_screen.dart';
import 'study_assistant_screen.dart';
import 'attendance_screen.dart';
import '../chat/realtime_chat_list_screen.dart';

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
          const LeaderboardScreen(),
          const RealtimeChatListScreen(),
          _buildProfileTab(user),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.darkSurface,
          border: Border(
            top: BorderSide(
              color: AppTheme.darkBorder.withOpacity(0.3),
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
              color: AppTheme.primaryColor.withOpacity(0.1),
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
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          items: [
            const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            const BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Tasks'),
            const BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: 'Challenges'),
            const BottomNavigationBarItem(icon: Icon(Icons.leaderboard), label: 'Leaderboard'),
            const BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Messages'),
            const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
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
          
          // Badges Section
          Text(
            'Your Badges',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                  letterSpacing: 0.5,
                ),
          )
              .animate()
              .fadeIn(delay: 200.ms, duration: 600.ms)
              .slideX(begin: -0.2, end: 0, duration: 600.ms),
          const SizedBox(height: 16),
          BadgeDisplay(userId: user.id, badges: user.badges),
          const SizedBox(height: 24),
          
          // Quick Actions
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                  letterSpacing: 0.5,
                ),
          )
              .animate()
              .fadeIn(delay: 300.ms, duration: 600.ms)
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
                  icon: Icons.school,
                  title: 'Study Assistant',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const StudyAssistantScreen()),
                  ),
                ),
              ),
              const SizedBox(width: 16),
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
            ],
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
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.darkCardGradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: AppTheme.cardGlowShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.4),
                        blurRadius: 12,
                        spreadRadius: 0,
                      ),
                    ],
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
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileTab(user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TieredProfilePicture(
            user: user,
            size: 120,
            showTierBorder: true,
          )
              .animate()
              .fadeIn(duration: 600.ms)
              .scale(begin: const Offset(0.5, 0.5), duration: 600.ms, curve: Curves.elasticOut),
          const SizedBox(height: 20),
          Text(
            user.name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
          )
              .animate()
              .fadeIn(delay: 200.ms, duration: 600.ms)
              .slideY(begin: 0.2, end: 0, duration: 600.ms),
          const SizedBox(height: 8),
          Text(
            user.email,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          )
              .animate()
              .fadeIn(delay: 300.ms, duration: 600.ms)
              .slideY(begin: 0.2, end: 0, duration: 600.ms),
          const SizedBox(height: 32),
          _buildStatCard('Current Streak', '${user.streak} days', Icons.local_fire_department)
              .animate()
              .fadeIn(delay: 400.ms, duration: 600.ms)
              .slideX(begin: -0.2, end: 0, duration: 600.ms),
          _buildStatCard('Total XP', '${user.xp} XP', Icons.star)
              .animate()
              .fadeIn(delay: 500.ms, duration: 600.ms)
              .slideX(begin: -0.2, end: 0, duration: 600.ms),
          _buildStatCard('Level', 'Level ${user.level}', Icons.trending_up)
              .animate()
              .fadeIn(delay: 600.ms, duration: 600.ms)
              .slideX(begin: -0.2, end: 0, duration: 600.ms),
          _buildStatCard('Badges Earned', '${user.badges.length} badges', Icons.emoji_events)
              .animate()
              .fadeIn(delay: 700.ms, duration: 600.ms)
              .slideX(begin: -0.2, end: 0, duration: 600.ms),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        gradient: AppTheme.darkCardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.darkBorder.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: AppTheme.cardGlowShadow,
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        title: Text(
          label,
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
        ),
      ),
    );
  }
}

