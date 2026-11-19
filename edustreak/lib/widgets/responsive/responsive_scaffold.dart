import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/edustreak_theme.dart';
import '../../utils/responsive_breakpoints.dart';
import '../../models/user_model.dart';
import '../portal_sidebar.dart';
import '../portal_header.dart';
import 'responsive_bottom_nav.dart';
import 'tv_presentation_layout.dart';

/// The central adaptive scaffold that orchestrates layout transformation across
/// Mobile, Large Mobile, Tablet, Laptop, Desktop, and Smart TV / Classroom Displays.
class ResponsiveScaffold extends StatefulWidget {
  final String portalType; // 'student', 'teacher', 'parent', 'admin'
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final VoidCallback? onLogout;
  final UserModel? user;
  final String? userName;
  final String? userSubtitle;
  final String headerTitle;
  final String headerSubtitle;
  final IconData portalIcon;
  final Color portalIconColor;
  final String contextPillText;
  final List<String>? contextPillOptions;
  final ValueChanged<String>? onContextPillChanged;
  final Widget? avatarWidget;
  final ValueChanged<String>? onDevSwitchPortal;
  final VoidCallback? onNotificationTap;
  final Widget body;
  final Widget? tvCustomContent;

  const ResponsiveScaffold({
    super.key,
    required this.portalType,
    required this.selectedIndex,
    required this.onItemSelected,
    this.onLogout,
    this.user,
    this.userName,
    this.userSubtitle,
    required this.headerTitle,
    required this.headerSubtitle,
    required this.portalIcon,
    this.portalIconColor = EduStreakTheme.primaryViolet,
    required this.contextPillText,
    this.contextPillOptions,
    this.onContextPillChanged,
    this.avatarWidget,
    this.onDevSwitchPortal,
    this.onNotificationTap,
    required this.body,
    this.tvCustomContent,
  });

  @override
  State<ResponsiveScaffold> createState() => _ResponsiveScaffoldState();
}

class _ResponsiveScaffoldState extends State<ResponsiveScaffold> {
  bool _isTVPresentationActive = false;

  bool _getIsDark(BuildContext context) {
    if (widget.portalType == 'teacher' || widget.portalType == 'admin' || widget.portalType == 'principal' || widget.portalType == 'parent') return true;
    try {
      return Provider.of<ThemeProvider>(context).isDarkMode;
    } catch (_) {
      return widget.portalType == 'student' || widget.portalType == 'principal' || widget.portalType == 'parent';
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = context.screenWidth;
    final isHandheld = context.isHandheld; // < 768
    final isTablet = context.isRail;       // 768 - 1023
    final isTVWidth = width >= ResponsiveBreakpoints.tvMin;
    final isDark = _getIsDark(context);
    final isPurpleDark = widget.portalType == 'student' || widget.portalType == 'principal' || widget.portalType == 'parent';

    // Trigger TV Presentation Mode if explicitly toggled OR on massive display (unless exited, excluded for teacher portal)
    if ((_isTVPresentationActive || isTVWidth) && widget.portalType != 'teacher') {
      return TVPresentationLayout(
        portalType: widget.portalType,
        user: widget.user,
        customContent: widget.tvCustomContent,
        onExitTVMode: () {
          setState(() {
            _isTVPresentationActive = false;
          });
        },
      );
    }

    final effectiveUserName = widget.userName ?? widget.user?.name ?? 'User';
    final effectiveUserSubtitle = widget.userSubtitle ?? widget.portalType.toUpperCase();

    final scaffoldBg = isDark
        ? (isPurpleDark ? EduStreakTheme.studentDarkBg : EduStreakTheme.darkNavyBg)
        : (widget.portalType == 'student' ? EduStreakTheme.studentBg : const Color(0xFFF8F9FC));

    return Scaffold(
      backgroundColor: scaffoldBg,

      // ─── MOBILE DRAWER (For secondary navigation items on handheld devices) ─
      drawer: isHandheld
          ? Drawer(
              child: PortalSidebar(
                portalType: widget.portalType,
                selectedIndex: widget.selectedIndex,
                userName: effectiveUserName,
                userSubtitle: effectiveUserSubtitle,
                isDark: isDark,
                onLogout: widget.onLogout,
                onItemSelected: (index) {
                  widget.onItemSelected(index);
                  Navigator.pop(context); // Close drawer
                },
              ),
            )
          : null,

      // ─── MOBILE BOTTOM NAVIGATION BAR ────────────────────────────────────
      bottomNavigationBar: isHandheld
          ? ResponsiveBottomNav(
              portalType: widget.portalType,
              selectedIndex: widget.selectedIndex,
              onItemSelected: widget.onItemSelected,
            )
          : null,

      body: Row(
        children: [
          // ─── LAPTOP / DESKTOP SIDEBAR OR TABLET NAVIGATION RAIL ──────────
          if (!isHandheld)
            PortalSidebar(
              portalType: widget.portalType,
              selectedIndex: widget.selectedIndex,
              isCollapsed: isTablet, // 72px compact rail on tablet
              userName: effectiveUserName,
              userSubtitle: effectiveUserSubtitle,
              isDark: isDark,
              onLogout: widget.onLogout,
              onItemSelected: widget.onItemSelected,
            ),

          // ─── MAIN PORTAL CANVAS ──────────────────────────────────────────
          Expanded(
            child: Column(
              children: [
                // Top Navigation Header
                _buildResponsiveHeader(context, isHandheld, isDark),

                // Main Content Body with Max Content Width constraint on wide desktop
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: ResponsiveBreakpoints.maxContentWidth,
                      ),
                      child: widget.body,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveHeader(BuildContext context, bool isHandheld, bool isDark) {
    final isStudent = widget.portalType == 'student';

    if (isHandheld) {
      // Compact Mobile Top Bar with Drawer Trigger
      final screenWidth = MediaQuery.sizeOf(context).width;
      final isVeryNarrow = screenWidth < 380;

      final headerBg = isDark
          ? (isStudent ? EduStreakTheme.studentDarkHeader : const Color(0xFF0C1030))
          : Colors.white;

      final headerBorder = isDark
          ? (isStudent ? EduStreakTheme.studentDarkBorder : const Color(0xFF222B5C))
          : EduStreakTheme.studentBorder;

      return Container(
        padding: EdgeInsets.symmetric(horizontal: isVeryNarrow ? 8 : 12, vertical: 8),
        decoration: BoxDecoration(
          color: headerBg,
          border: Border(
            bottom: BorderSide(
              color: headerBorder,
              width: 1.2,
            ),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Row(
            children: [
              Builder(
                builder: (scaffoldContext) => IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  icon: Icon(
                    Icons.menu_rounded,
                    color: isDark ? Colors.white : EduStreakTheme.studentText,
                    size: 22,
                  ),
                  tooltip: 'Menu',
                  onPressed: () => Scaffold.of(scaffoldContext).openDrawer(),
                ),
              ),
              const SizedBox(width: 4),

              // Portal Icon Pill
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: widget.portalIconColor.withValues(alpha: isDark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(widget.portalIcon, size: 18, color: widget.portalIconColor),
              ),
              const SizedBox(width: 8),

              // Title & Subtitle (Condensed)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.headerTitle,
                      style: EduStreakTheme.fontHeading3(
                        color: isDark ? Colors.white : EduStreakTheme.studentText,
                        weight: FontWeight.w800,
                      ).copyWith(fontSize: isVeryNarrow ? 14 : 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      widget.contextPillText,
                      style: EduStreakTheme.fontCaption(
                        color: isDark
                            ? (isStudent ? EduStreakTheme.studentDarkHighlight : EduStreakTheme.darkTextSub)
                            : EduStreakTheme.studentTextMuted,
                        weight: FontWeight.w500,
                      ).copyWith(fontSize: 10),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Portal Switcher (discreet)
              if (widget.onDevSwitchPortal != null)
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  tooltip: 'Switch Portal',
                  icon: Icon(
                    Icons.swap_horiz_rounded,
                    color: isDark ? Colors.white70 : Colors.black54,
                    size: 19,
                  ),
                  color: isDark ? const Color(0xFF141A42) : Colors.white,
                  onSelected: widget.onDevSwitchPortal,
                  itemBuilder: (context) => [
                    _buildMenuItem('student', 'Student Portal', Icons.school, isDark),
                    _buildMenuItem('teacher', 'Teacher Portal', Icons.co_present, isDark),
                    _buildMenuItem('parent', 'Parent Portal', Icons.family_restroom, isDark),
                    _buildMenuItem('admin', 'Admin Portal', Icons.admin_panel_settings, isDark),
                  ],
                ),

              // Notification Bell (Mobile)
              if (widget.onNotificationTap != null)
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  icon: Icon(
                    Icons.notifications_none_rounded,
                    color: isDark ? Colors.white70 : Colors.black87,
                    size: 20,
                  ),
                  onPressed: widget.onNotificationTap,
                ),

              // Avatar / Profile Pill
              if (widget.avatarWidget != null) ...[
                const SizedBox(width: 4),
                widget.avatarWidget!,
              ],
            ],
          ),
        ),
      );
    }

    final screenWidth = MediaQuery.sizeOf(context).width;
    final showTVMode = screenWidth >= 1024 && widget.portalType != 'teacher';

    // Tablet, Laptop, Desktop Header (Full featured with Classroom TV Mode button on >= 1024px)
    return PortalHeader(
      title: widget.headerTitle,
      subtitle: widget.headerSubtitle,
      portalIcon: widget.portalIcon,
      portalIconColor: widget.portalIconColor,
      contextPillText: widget.contextPillText,
      contextPillOptions: widget.contextPillOptions,
      onContextPillChanged: widget.onContextPillChanged,
      onNotificationTap: widget.onNotificationTap,
      isDark: isDark,
      avatarWidget: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Classroom TV Mode Toggle Button
          if (showTVMode) ...[
            Tooltip(
              message: 'Classroom / TV Presentation Mode',
              child: InkWell(
                onTap: () {
                  setState(() {
                    _isTVPresentationActive = true;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF161C48) : const Color(0xFFF3F0FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? const Color(0xFF333E80) : const Color(0xFFDDD6FE),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.tv_rounded, size: 16, color: EduStreakTheme.primaryViolet),
                      const SizedBox(width: 6),
                      Text(
                        'TV Mode',
                        style: EduStreakTheme.fontLabel(
                          color: isDark ? Colors.white70 : EduStreakTheme.studentText,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
          if (widget.avatarWidget != null) widget.avatarWidget!,
        ],
      ),
      onDevSwitchPortal: widget.onDevSwitchPortal,
    );
  }

  PopupMenuItem<String> _buildMenuItem(String value, String label, IconData icon, bool isDark) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: EduStreakTheme.primaryViolet),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 13)),
        ],
      ),
    );
  }
}
