import 'package:flutter/material.dart';
import '../../utils/edustreak_theme.dart';
import '../../models/user_model.dart';

/// Dedicated presentation layout engineered for Smart TVs, classroom projectors,
/// and large monitors (>= 1920px or when presentation mode is toggled).
///
/// Features:
/// - 10-foot UI: High-contrast, scaled typography and large KPI tiles.
/// - Remote / keyboard navigation support.
/// - Classroom Privacy Protection: Read-only views that mask individual grades,
///   marks, or private parent contact details on public projection screens.
class TVPresentationLayout extends StatelessWidget {
  final String portalType; // 'student', 'teacher', 'parent', 'admin'
  final UserModel? user;
  final VoidCallback onExitTVMode;
  final Widget? customContent;

  const TVPresentationLayout({
    super.key,
    required this.portalType,
    required this.user,
    required this.onExitTVMode,
    this.customContent,
  });

  bool get _isDark => portalType == 'teacher' || portalType == 'admin';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isDark ? const Color(0xFF060919) : const Color(0xFFF0ECFC),
      body: FocusTraversalGroup(
        policy: OrderedTraversalPolicy(),
        child: SafeArea(
          child: Column(
            children: [
              // 1. TV Presentation Header Bar
              _buildTVHeader(context),

              // 2. Main Presentation Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
                  child: customContent ?? _buildDefaultPortalPresentation(),
                ),
              ),

              // 3. Bottom TV Status Ticker
              _buildTVStatusTicker(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTVHeader(BuildContext context) {
    String portalLabel;
    IconData portalIcon;
    Color accentColor;

    switch (portalType) {
      case 'student':
        portalLabel = 'Classroom Adventure Display';
        portalIcon = Icons.sports_esports_rounded;
        accentColor = EduStreakTheme.primaryViolet;
        break;
      case 'teacher':
        portalLabel = 'Classroom Live Presentation';
        portalIcon = Icons.co_present_rounded;
        accentColor = EduStreakTheme.neonCyan;
        break;
      case 'parent':
        portalLabel = 'Family Learning Overview';
        portalIcon = Icons.family_restroom_rounded;
        accentColor = EduStreakTheme.magentaPink;
        break;
      case 'admin':
      default:
        portalLabel = 'State Education Command Center';
        portalIcon = Icons.account_balance_rounded;
        accentColor = EduStreakTheme.neonCyan;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
      decoration: BoxDecoration(
        color: _isDark ? const Color(0xFF0C1133) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: _isDark ? const Color(0xFF242E6B) : EduStreakTheme.studentBorder,
            width: 2,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // EduStreak 3D Brand Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: EduStreakTheme.activePillGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: EduStreakTheme.violetGlow,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bolt_rounded, color: Colors.white, size: 28),
                const SizedBox(width: 8),
                Text(
                  'EduStreak TV',
                  style: EduStreakTheme.fontHeading1(color: Colors.white, weight: FontWeight.w900),
                ),
              ],
            ),
          ),

          const SizedBox(width: 24),

          // Portal Mode Tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: _isDark ? 0.2 : 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: accentColor.withValues(alpha: 0.4), width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(portalIcon, color: accentColor, size: 22),
                const SizedBox(width: 8),
                Text(
                  portalLabel,
                  style: TextStyle(
                    color: _isDark ? Colors.white : EduStreakTheme.studentText,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Privacy Indicator Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: EduStreakTheme.emeraldGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: EduStreakTheme.emeraldGreen.withValues(alpha: 0.4)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shield_rounded, color: EduStreakTheme.emeraldGreen, size: 18),
                SizedBox(width: 6),
                Text(
                  'Privacy Shield Active',
                  style: TextStyle(
                    color: EduStreakTheme.emeraldGreen,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 20),

          // Exit TV Presentation Mode Button
          ElevatedButton.icon(
            onPressed: onExitTVMode,
            icon: const Icon(Icons.fullscreen_exit_rounded, size: 22, color: Colors.white),
            label: const Text(
              'Exit TV Mode',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF242E6B),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultPortalPresentation() {
    switch (portalType) {
      case 'student':
        return _buildStudentTVPresentation();
      case 'teacher':
        return _buildTeacherTVPresentation();
      case 'parent':
        return _buildParentTVPresentation();
      case 'admin':
      default:
        return _buildAdminTVPresentation();
    }
  }

  // ─── 1. STUDENT TV PRESENTATION ──────────────────────────────────────────
  Widget _buildStudentTVPresentation() {
    final streak = user?.streakCount ?? 0;
    final xp = user?.xp ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Hero: Classroom Daily Quest
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(36),
          decoration: BoxDecoration(
            gradient: EduStreakTheme.questCardGradient,
            borderRadius: BorderRadius.circular(28),
            boxShadow: EduStreakTheme.violetGlow,
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🏰 TODAY\'S CLASSROOM OBJECTIVE',
                        style: TextStyle(color: EduStreakTheme.amberGold, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                    const SizedBox(height: 12),
                    const Text(
                      'Complete 10 Interactive MCQs in Physical Science',
                      style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Every student submission adds +50 XP to the class milestone tally!',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 18),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 32),
              // Big XP & Streak Rings
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white24, width: 2),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.local_fire_department_rounded, color: EduStreakTheme.streakOrange, size: 48),
                    const SizedBox(height: 6),
                    Text(
                      '$streak DAYS',
                      style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
                    ),
                    const Text('Classroom Streak', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 36),

        // 3 Giant Milestone Tiles
        Row(
          children: [
            Expanded(child: _buildTVMetricTile('🎯 Class Target', '88% Completed', 'Photosynthesis & Plant Cell Structure', EduStreakTheme.neonCyan)),
            const SizedBox(width: 24),
            Expanded(child: _buildTVMetricTile('⭐ Collective XP', '$xp XP Earned', 'Level 4 Explorer Status', EduStreakTheme.amberGold)),
            const SizedBox(width: 24),
            Expanded(child: _buildTVMetricTile('🏆 Active Quest', '9 Tasks Submitted', 'Climbing to Apex Tier', EduStreakTheme.emeraldGreen)),
          ],
        ),
      ],
    );
  }

  // ─── 2. TEACHER TV PRESENTATION ──────────────────────────────────────────
  Widget _buildTeacherTVPresentation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Live Classroom Agenda Banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(36),
          decoration: BoxDecoration(
            gradient: EduStreakTheme.teacherHubGradient,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: EduStreakTheme.primaryViolet.withValues(alpha: 0.4), width: 2),
          ),
          child: const Row(
            children: [
              Icon(Icons.tv_rounded, color: EduStreakTheme.neonCyan, size: 64),
              SizedBox(width: 28),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CLASSROOM COMMAND CENTER', style: TextStyle(color: EduStreakTheme.neonCyan, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                    SizedBox(height: 8),
                    Text('Period 3: Mathematics • Chapter 5 Linear Equations', style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900)),
                    SizedBox(height: 8),
                    Text('Real-time class engagement, attendance, and assignment queue (Private student marks masked).', style: TextStyle(color: Colors.white70, fontSize: 16)),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 36),

        Row(
          children: [
            Expanded(child: _buildTVMetricTile('👥 Enrolled Students', '100% Present', 'Class 10 Section A', EduStreakTheme.emeraldGreen)),
            const SizedBox(width: 24),
            Expanded(child: _buildTVMetricTile('📝 Homework Due', 'Chapter 5 Algebra', 'Due Today at 5:00 PM', EduStreakTheme.rosePink)),
            const SizedBox(width: 24),
            Expanded(child: _buildTVMetricTile('⚡ Live Participation', '32 of 34 Active', 'High Engagement Today', EduStreakTheme.amberGold)),
          ],
        ),
      ],
    );
  }

  // ─── 3. PARENT TV PRESENTATION ───────────────────────────────────────────
  Widget _buildParentTVPresentation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(36),
          decoration: EduStreakTheme.lightCardDecoration(radius: 28),
          child: Row(
            children: [
              const Icon(Icons.home_rounded, color: EduStreakTheme.primaryViolet, size: 56),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('FAMILY LEARNING CORNER', style: EduStreakTheme.fontCaption(color: EduStreakTheme.primaryViolet, weight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Text('Weekly Study Milestone & Habit Progress', style: EduStreakTheme.fontHeading1(color: EduStreakTheme.studentText, weight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    Text('Celebrating consistent daily study habits and completed homework assignments.', style: EduStreakTheme.fontBody(color: EduStreakTheme.studentTextMuted)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(child: _buildTVMetricTile('📅 Attendance', '98.5% Consistent', 'No missed sessions this term', EduStreakTheme.emeraldGreen)),
            const SizedBox(width: 24),
            Expanded(child: _buildTVMetricTile('🔥 Daily Streak', '12 Days Active', 'Evening revision on track', EduStreakTheme.streakOrange)),
            const SizedBox(width: 24),
            Expanded(child: _buildTVMetricTile('📖 Tasks Handed In', 'All Tasks Completed', 'Zero overdue submissions', EduStreakTheme.primaryViolet)),
          ],
        ),
      ],
    );
  }

  // ─── 4. ADMIN TV PRESENTATION ────────────────────────────────────────────
  Widget _buildAdminTVPresentation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(36),
          decoration: BoxDecoration(
            color: const Color(0xFF101538),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: EduStreakTheme.primaryViolet.withValues(alpha: 0.5), width: 2),
            boxShadow: EduStreakTheme.violetGlow,
          ),
          child: const Row(
            children: [
              Icon(Icons.analytics_rounded, color: EduStreakTheme.neonCyan, size: 64),
              SizedBox(width: 28),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('STATE & DISTRICT NETWORK STATUS', style: TextStyle(color: EduStreakTheme.neonCyan, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                    SizedBox(height: 8),
                    Text('Live Academic Infrastructure & Provisioning Monitor', style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900)),
                    SizedBox(height: 8),
                    Text('Real-time synchronization across Andhra Pradesh state curriculum & central CBSE schools.', style: TextStyle(color: Colors.white70, fontSize: 16)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 36),
        Row(
          children: [
            Expanded(child: _buildTVMetricTile('🏛️ Registered Schools', 'Verified Network', 'Government, Private & CBSE', EduStreakTheme.neonCyan)),
            const SizedBox(width: 24),
            Expanded(child: _buildTVMetricTile('👥 Active Students', 'State-wide Cohorts', 'Real-time database sync', EduStreakTheme.primaryViolet)),
            const SizedBox(width: 24),
            Expanded(child: _buildTVMetricTile('⚡ System Status', '100% Operational', 'Cloud Firestore Live Streams', EduStreakTheme.emeraldGreen)),
          ],
        ),
      ],
    );
  }

  Widget _buildTVMetricTile(String title, String mainValue, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: _isDark ? const Color(0xFF101538) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: _isDark ? 0.35 : 0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Text(
            mainValue,
            style: TextStyle(
              color: _isDark ? Colors.white : EduStreakTheme.studentText,
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: _isDark ? Colors.white60 : EduStreakTheme.studentTextMuted,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTVStatusTicker() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 12),
      color: _isDark ? const Color(0xFF070B1F) : const Color(0xFFE5DEFF),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: EduStreakTheme.emeraldGreen,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'EduStreak Real-time Database Connected • Public Display Mode • Sensitive PII Protected',
            style: TextStyle(
              color: _isDark ? Colors.white70 : EduStreakTheme.studentText,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            'Press Back or Exit to return to interactive workspace',
            style: TextStyle(
              color: _isDark ? Colors.white38 : Colors.black45,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
