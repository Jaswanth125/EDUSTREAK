import 'package:flutter/material.dart';
import '../../utils/edustreak_theme.dart';

class BottomNavItem {
  final int index;
  final String label;
  final IconData icon;
  final IconData? activeIcon;
  final String? badge;

  const BottomNavItem({
    required this.index,
    required this.label,
    required this.icon,
    this.activeIcon,
    this.badge,
  });
}

/// A touch-friendly, responsive bottom navigation bar tailored to the EduStreak
/// aesthetic with guaranteed minimum 48px touch targets and smooth selection glow.
class ResponsiveBottomNav extends StatelessWidget {
  final String portalType; // 'student', 'teacher', 'parent', 'admin'
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final VoidCallback? onMoreTap;

  const ResponsiveBottomNav({
    super.key,
    required this.portalType,
    required this.selectedIndex,
    required this.onItemSelected,
    this.onMoreTap,
  });

  bool get _isDark => portalType == 'teacher' || portalType == 'admin' || portalType == 'principal';

  List<BottomNavItem> get _items {
    switch (portalType) {
      case 'student':
        return const [
          BottomNavItem(index: 0, label: 'Home', icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard_rounded),
          BottomNavItem(index: 1, label: 'Learn', icon: Icons.menu_book_outlined, activeIcon: Icons.menu_book_rounded),
          BottomNavItem(index: 3, label: 'Homework', icon: Icons.assignment_outlined, activeIcon: Icons.assignment_rounded),
          BottomNavItem(index: 4, label: 'Progress', icon: Icons.insights_outlined, activeIcon: Icons.insights_rounded),
          BottomNavItem(index: 5, label: 'Attend', icon: Icons.event_available_outlined, activeIcon: Icons.event_available_rounded),
        ];
      case 'principal':
        return const [
          BottomNavItem(index: 0, label: 'Overview', icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard_rounded),
          BottomNavItem(index: 2, label: 'Students', icon: Icons.school_outlined, activeIcon: Icons.school_rounded),
          BottomNavItem(index: 3, label: 'Teachers', icon: Icons.supervisor_account_outlined, activeIcon: Icons.supervisor_account_rounded),
          BottomNavItem(index: 4, label: 'Academics', icon: Icons.menu_book_outlined, activeIcon: Icons.menu_book_rounded),
          BottomNavItem(index: 6, label: 'AI Insights', icon: Icons.psychology_outlined, activeIcon: Icons.psychology_rounded, badge: 'AI'),
        ];
      case 'teacher':
        return const [
          BottomNavItem(index: 0, label: 'Home', icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard_rounded),
          BottomNavItem(index: 1, label: 'Classes', icon: Icons.groups_outlined, activeIcon: Icons.groups_rounded),
          BottomNavItem(index: 2, label: 'Attend', icon: Icons.event_available_outlined, activeIcon: Icons.event_available_rounded),
          BottomNavItem(index: 3, label: 'Assignments', icon: Icons.assignment_turned_in_outlined, activeIcon: Icons.assignment_turned_in_rounded),
          BottomNavItem(index: 5, label: 'AI Hub', icon: Icons.psychology_outlined, activeIcon: Icons.psychology_rounded),
          BottomNavItem(index: 8, label: 'Messages', icon: Icons.chat_bubble_outline_rounded, activeIcon: Icons.chat_bubble_rounded),
        ];
      case 'parent':
        return const [
          BottomNavItem(index: 0, label: 'Home', icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard_rounded),
          BottomNavItem(index: 1, label: 'Child', icon: Icons.child_care_outlined, activeIcon: Icons.child_care_rounded),
          BottomNavItem(index: 2, label: 'Progress', icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart_rounded),
          BottomNavItem(index: 3, label: 'Attend', icon: Icons.calendar_month_outlined, activeIcon: Icons.calendar_month_rounded),
          BottomNavItem(index: 4, label: 'Homework', icon: Icons.assignment_late_outlined, activeIcon: Icons.assignment_late_rounded, badge: '3'),
        ];
      case 'admin':
      default:
        return const [
          BottomNavItem(index: 0, label: 'Overview', icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard_rounded),
          BottomNavItem(index: 1, label: 'Schools', icon: Icons.account_balance_outlined, activeIcon: Icons.account_balance_rounded),
          BottomNavItem(index: 2, label: 'Principals', icon: Icons.admin_panel_settings_outlined, activeIcon: Icons.admin_panel_settings_rounded),
          BottomNavItem(index: 3, label: 'Curriculum', icon: Icons.layers_outlined, activeIcon: Icons.layers_rounded),
          BottomNavItem(index: 8, label: 'Analytics', icon: Icons.analytics_outlined, activeIcon: Icons.analytics_rounded),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 380;
    final isUltraCompact = screenWidth < 340;
    final isDense = isCompact || _items.length > 5;

    final isPurpleDark = portalType == 'student' || portalType == 'principal' || portalType == 'parent';
    final navBg = _isDark
        ? (isPurpleDark ? EduStreakTheme.studentDarkSidebar : const Color(0xFF0C1030))
        : Colors.white;
    final navBorder = _isDark
        ? (isPurpleDark ? EduStreakTheme.studentDarkBorder : const Color(0xFF222B5C))
        : EduStreakTheme.studentBorder;

    return Container(
      decoration: BoxDecoration(
        color: navBg,
        border: Border(
          top: BorderSide(
            color: navBorder,
            width: 1.2,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: _isDark ? 0.35 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60 + (bottomInset > 0 ? 0 : 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _items.map((item) {
              final isSelected = selectedIndex == item.index;

              return Expanded(
                child: InkWell(
                  onTap: () => onItemSelected(item.index),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 56, // comfortable > 48px touch target
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: EdgeInsets.symmetric(
                                horizontal: isUltraCompact ? 5 : (isDense ? 8 : 14),
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? (_isDark
                                        ? EduStreakTheme.primaryViolet.withValues(alpha: 0.25)
                                        : EduStreakTheme.primaryViolet.withValues(alpha: 0.15))
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                isSelected ? (item.activeIcon ?? item.icon) : item.icon,
                                size: isUltraCompact ? 19 : 22,
                                color: isSelected
                                    ? EduStreakTheme.primaryViolet
                                    : (_isDark ? EduStreakTheme.darkTextMuted : EduStreakTheme.studentTextMuted),
                              ),
                            ),
                            if (item.badge != null)
                              Positioned(
                                right: -4,
                                top: -2,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: EduStreakTheme.rosePink,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                  child: Text(
                                    item.badge!,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Text(
                              item.label,
                              style: TextStyle(
                                fontSize: isUltraCompact ? 9 : 10,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected
                                    ? (_isDark ? Colors.white : EduStreakTheme.studentText)
                                    : (_isDark ? EduStreakTheme.darkTextMuted : EduStreakTheme.studentTextMuted),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
