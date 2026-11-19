import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/user_provider.dart';
import '../services/realtime_chat_service.dart';
import '../utils/edustreak_theme.dart';
import 'edustreak_illustrations.dart';

class SidebarItem {
  final String title;
  final IconData icon;
  final String? badge;

  const SidebarItem({required this.title, required this.icon, this.badge});
}

class PortalSidebar extends StatelessWidget {
  final String portalType; // 'student', 'teacher', 'parent', 'admin'
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final VoidCallback? onLogout;
  final bool isCollapsed;
  final String? userName;
  final String? userSubtitle;
  final bool? isDark;
  final String? userId;

  const PortalSidebar({
    super.key,
    required this.portalType,
    required this.selectedIndex,
    required this.onItemSelected,
    this.onLogout,
    this.isCollapsed = false,
    this.userName,
    this.userSubtitle,
    this.isDark,
    this.userId,
  });

  bool _getEffectiveDark(BuildContext context) {
    if (isDark != null) return isDark!;
    if (portalType == 'teacher' || portalType == 'admin' || portalType == 'principal' || portalType == 'parent') return true;
    try {
      return Provider.of<ThemeProvider>(context).isDarkMode;
    } catch (_) {
      return portalType == 'student' || portalType == 'principal' || portalType == 'parent';
    }
  }

  List<SidebarItem> _getItems(int unreadCount) {
    final msgBadge = unreadCount > 0 ? '$unreadCount' : null;
    switch (portalType) {
      case 'student':
        return [
          const SidebarItem(title: 'Dashboard', icon: Icons.dashboard_rounded),
          const SidebarItem(title: 'My Learning', icon: Icons.menu_book_rounded),
          const SidebarItem(title: 'Practice Arena', icon: Icons.sports_esports_rounded),
          const SidebarItem(title: 'Homework', icon: Icons.assignment_rounded),
          const SidebarItem(title: 'Assessments', icon: Icons.quiz_rounded),
          const SidebarItem(title: 'Progress & Skills', icon: Icons.insights_rounded),
          const SidebarItem(title: 'Attendance', icon: Icons.calendar_month_rounded),
          const SidebarItem(title: 'Achievements', icon: Icons.emoji_events_rounded),
          const SidebarItem(title: 'Class Leaderboard', icon: Icons.leaderboard_rounded),
          const SidebarItem(title: 'Store & Inventory', icon: Icons.storefront_rounded),
          SidebarItem(title: 'Messages', icon: Icons.chat_bubble_rounded, badge: msgBadge),
          const SidebarItem(title: 'AI Study Buddy', icon: Icons.auto_awesome_rounded),
        ];
      case 'principal':
        return [
          const SidebarItem(title: 'Dashboard', icon: Icons.dashboard_rounded),
          const SidebarItem(title: 'School Overview', icon: Icons.account_balance_rounded),
          const SidebarItem(title: 'Students', icon: Icons.school_rounded),
          const SidebarItem(title: 'Teachers', icon: Icons.supervisor_account_rounded),
          const SidebarItem(title: 'Academics', icon: Icons.menu_book_rounded),
          const SidebarItem(title: 'Attendance', icon: Icons.event_available_rounded),
          const SidebarItem(title: 'AI School Insights', icon: Icons.psychology_rounded, badge: 'AI'),
          const SidebarItem(title: 'Parents & Guardians', icon: Icons.family_restroom_rounded),
          const SidebarItem(title: 'Approvals & Compliance', icon: Icons.approval_rounded),
          const SidebarItem(title: 'Reports & Analytics', icon: Icons.analytics_rounded),
          const SidebarItem(title: 'Announcements', icon: Icons.campaign_rounded),
          SidebarItem(title: 'Messages', icon: Icons.chat_bubble_rounded, badge: msgBadge),
          const SidebarItem(title: 'Settings & Profile', icon: Icons.settings_rounded),
        ];
      case 'teacher':
        return [
          const SidebarItem(title: 'Dashboard', icon: Icons.dashboard_rounded),
          const SidebarItem(title: 'My Classes', icon: Icons.groups_rounded),
          const SidebarItem(title: 'Attendance', icon: Icons.event_available_rounded),
          const SidebarItem(title: 'Assignments', icon: Icons.assignment_turned_in_rounded),
          const SidebarItem(title: 'Assessments', icon: Icons.quiz_rounded),
          const SidebarItem(title: 'AI Teaching Hub', icon: Icons.psychology_rounded),
          const SidebarItem(title: 'Student Insights', icon: Icons.trending_up_rounded),
          const SidebarItem(title: 'Resources', icon: Icons.folder_shared_rounded),
          SidebarItem(title: 'Messages', icon: Icons.chat_bubble_rounded, badge: msgBadge),
          const SidebarItem(title: 'Class Leaderboard', icon: Icons.leaderboard_rounded),
        ];
      case 'parent':
        return [
          const SidebarItem(title: 'Dashboard', icon: Icons.dashboard_rounded),
          const SidebarItem(title: 'My Child', icon: Icons.child_care_rounded),
          const SidebarItem(title: 'Progress Report', icon: Icons.bar_chart_rounded),
          const SidebarItem(title: 'Attendance', icon: Icons.calendar_month_rounded),
          const SidebarItem(title: 'Homework', icon: Icons.assignment_late_rounded),
          const SidebarItem(title: 'Results', icon: Icons.verified_rounded),
          SidebarItem(title: 'Messages', icon: Icons.chat_bubble_rounded, badge: msgBadge),
        ];
      case 'admin':
      default:
        return [
          const SidebarItem(title: 'Dashboard', icon: Icons.dashboard_rounded),
          const SidebarItem(title: 'Schools', icon: Icons.account_balance_rounded),
          const SidebarItem(title: 'Principals', icon: Icons.admin_panel_settings_rounded),
          const SidebarItem(title: 'Curriculum', icon: Icons.layers_rounded),
          const SidebarItem(title: 'Students', icon: Icons.school_rounded),
          const SidebarItem(title: 'Teachers', icon: Icons.supervisor_account_rounded),
          const SidebarItem(title: 'Parents', icon: Icons.family_restroom_rounded),
          const SidebarItem(title: 'Academics', icon: Icons.menu_book_rounded),
          const SidebarItem(title: 'Reports & Analytics', icon: Icons.analytics_rounded),
          const SidebarItem(title: 'Platform Settings', icon: Icons.settings_rounded),
          SidebarItem(title: 'Messages', icon: Icons.chat_bubble_rounded, badge: msgBadge),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    String? currentUid = userId;
    if (currentUid == null) {
      try {
        currentUid = Provider.of<UserProvider>(context, listen: false).currentUser?.id;
      } catch (_) {}
    }

    if (currentUid != null && currentUid.isNotEmpty) {
      return StreamBuilder<int>(
        stream: RealtimeChatService().getTotalUnreadCountStream(currentUid),
        builder: (context, snapshot) {
          final unread = snapshot.data ?? 0;
          return _buildSidebarContent(context, _getItems(unread));
        },
      );
    }

    return _buildSidebarContent(context, _getItems(0));
  }

  Widget _buildSidebarContent(BuildContext context, List<SidebarItem> items) {
    final isDarkEffective = _getEffectiveDark(context);
    final isPurpleDark = portalType == 'student' || portalType == 'principal' || portalType == 'parent' || portalType == 'teacher';
    final width = isCollapsed ? 76.0 : 240.0;

    final sidebarBg = isDarkEffective
        ? (isPurpleDark ? EduStreakTheme.studentDarkSidebar : const Color(0xFF0C1030))
        : const Color(0xFFFFFFFF);

    final borderColor = isDarkEffective
        ? (isPurpleDark ? EduStreakTheme.studentDarkBorder : const Color(0xFF222B5C))
        : EduStreakTheme.studentBorder;

    final unselectedTextColor = isDarkEffective
        ? (isPurpleDark ? EduStreakTheme.studentDarkTextMuted : EduStreakTheme.darkTextMuted)
        : const Color(0xFF5B5579);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: width,
      decoration: BoxDecoration(
        color: sidebarBg,
        border: Border(
          right: BorderSide(
            color: borderColor,
            width: 1.2,
          ),
        ),
        boxShadow: isDarkEffective
            ? null
            : [
                BoxShadow(
                  color: EduStreakTheme.primaryViolet.withValues(alpha: 0.05),
                  blurRadius: 15,
                  offset: const Offset(4, 0),
                ),
              ],
      ),
      child: Column(
        children: [
          // Logo & Brand Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 12 : 20, vertical: 20),
            child: Row(
              mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                const EduStreak3DLogo(size: 36),
                if (!isCollapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'EduStreak',
                      style: EduStreakTheme.fontHeading2(
                        color: isDarkEffective ? Colors.white : EduStreakTheme.studentText,
                        weight: FontWeight.w900,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Navigation Items List
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 8 : 14),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final item = items[index];
                final isSelected = index == selectedIndex;

                return InkWell(
                  onTap: () => onItemSelected(index),
                  borderRadius: BorderRadius.circular(22),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: EdgeInsets.symmetric(
                      horizontal: isCollapsed ? 0 : 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: isSelected ? EduStreakTheme.activePillGradient : null,
                      color: isSelected ? null : Colors.transparent,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: EduStreakTheme.primaryViolet.withValues(alpha: 0.38),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: isCollapsed
                        ? Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Center(
                                child: Icon(
                                  item.icon,
                                  size: 22,
                                  color: isSelected
                                      ? Colors.white
                                      : unselectedTextColor,
                                ),
                              ),
                              if (item.badge != null && !isSelected)
                                Positioned(
                                  top: -2,
                                  right: 6,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: item.title == 'Messages'
                                          ? EduStreakTheme.primaryViolet
                                          : EduStreakTheme.streakOrange,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                                    child: Center(
                                      child: Text(
                                        item.badge!,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          )
                        : Row(
                            children: [
                              Icon(
                                item.icon,
                                size: 20,
                                color: isSelected
                                    ? Colors.white
                                    : unselectedTextColor,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: EduStreakTheme.fontLabel(
                                    color: isSelected
                                        ? Colors.white
                                        : unselectedTextColor,
                                    weight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (item.badge != null && !isSelected)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: item.title == 'Messages'
                                        ? EduStreakTheme.primaryViolet
                                        : EduStreakTheme.streakOrange.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    item.badge!,
                                    style: TextStyle(
                                      color: item.title == 'Messages'
                                          ? Colors.white
                                          : EduStreakTheme.streakOrange,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                  ),
                );
              },
            ),
          ),

          // User info & Logout row
          LayoutBuilder(
            builder: (context, constraints) {
              final showExpanded = !isCollapsed && constraints.maxWidth > 140;
              return Container(
                padding: EdgeInsets.symmetric(horizontal: showExpanded ? 16 : 8, vertical: 16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: borderColor,
                      width: 1.0,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: showExpanded ? MainAxisAlignment.spaceBetween : MainAxisAlignment.center,
                  children: [
                    if (showExpanded) ...[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              userName ?? 'User',
                              style: EduStreakTheme.fontLabel(
                                color: isDarkEffective ? Colors.white : EduStreakTheme.studentText,
                                weight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              userSubtitle ?? portalType.toUpperCase(),
                              style: EduStreakTheme.fontCaption(
                                color: isDarkEffective
                                    ? (isPurpleDark ? EduStreakTheme.studentDarkHighlight : EduStreakTheme.darkTextMuted)
                                    : EduStreakTheme.studentTextMuted,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    IconButton(
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      padding: const EdgeInsets.all(6),
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        Icons.logout_rounded,
                        size: 20,
                        color: isDarkEffective ? Colors.redAccent.shade100 : Colors.redAccent,
                      ),
                      tooltip: 'Sign Out',
                      onPressed: onLogout,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
