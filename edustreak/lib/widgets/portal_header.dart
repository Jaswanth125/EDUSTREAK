import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../utils/edustreak_theme.dart';
import 'edustreak_illustrations.dart';

class PortalHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData portalIcon;
  final Color portalIconColor;
  final String contextPillText;
  final List<String>? contextPillOptions;
  final ValueChanged<String>? onContextPillChanged;
  final VoidCallback? onNotificationTap;
  final Widget? avatarWidget;
  final bool isDark;
  final ValueChanged<String>? onDevSwitchPortal; // Quick dev portal switcher

  const PortalHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.portalIcon,
    this.portalIconColor = EduStreakTheme.primaryViolet,
    required this.contextPillText,
    this.contextPillOptions,
    this.onContextPillChanged,
    this.onNotificationTap,
    this.avatarWidget,
    this.isDark = false,
    this.onDevSwitchPortal,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final isCompact = availableWidth < 850;
        final isUltraCompact = availableWidth < 380;

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isUltraCompact ? 6 : (isCompact ? 8 : 24),
            vertical: isCompact ? 10 : 16,
          ),
          decoration: BoxDecoration(
            color: isDark ? EduStreakTheme.studentDarkHeader : const Color(0xFFFFFFFF),
            border: Border(
              bottom: BorderSide(
                color: isDark ? EduStreakTheme.studentDarkBorder : EduStreakTheme.studentBorder,
                width: 1.2,
              ),
            ),
          ),
          child: Row(
            children: [
              // Left Icon + Title + Subtitle
              Container(
                padding: EdgeInsets.all(isUltraCompact ? 5 : (isCompact ? 6 : 8)),
                decoration: BoxDecoration(
                  color: isDark ? portalIconColor.withValues(alpha: 0.2) : EduStreakTheme.lavender,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? portalIconColor.withValues(alpha: 0.4) : const Color(0xFFDDD2F9),
                    width: 1.2,
                  ),
                ),
                child: Icon(portalIcon, size: isUltraCompact ? 17 : (isCompact ? 19 : 22), color: portalIconColor),
              ),
              SizedBox(width: isUltraCompact ? 5 : (isCompact ? 6 : 14)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: isCompact
                          ? EduStreakTheme.fontHeading3(
                              color: isDark ? Colors.white : EduStreakTheme.studentText,
                              weight: FontWeight.w800,
                            ).copyWith(fontSize: isUltraCompact ? 14 : null)
                          : EduStreakTheme.fontHeading2(
                              color: isDark ? Colors.white : EduStreakTheme.studentText,
                              weight: FontWeight.w800,
                            ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (!isCompact)
                      Text(
                        subtitle,
                        style: EduStreakTheme.fontCaption(
                          color: isDark ? EduStreakTheme.darkTextSub : EduStreakTheme.studentTextMuted,
                          weight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),

              // Dev Portal Switcher (discreet icon button to preview other portals)
              if (onDevSwitchPortal != null) ...[
                SizedBox(width: isUltraCompact ? 2 : (isCompact ? 3 : 8)),
                PopupMenuButton<String>(
                  tooltip: 'Switch Portal (Demo/Review)',
                  icon: Icon(
                    Icons.swap_horiz_rounded,
                    color: isDark ? Colors.white60 : Colors.black45,
                    size: isUltraCompact ? 16 : (isCompact ? 18 : 20),
                  ),
                  color: isDark ? const Color(0xFF141A42) : Colors.white,
                  onSelected: onDevSwitchPortal,
                  itemBuilder: (context) => [
                    _buildMenuItem('student', 'Student Portal (Akash)', Icons.school, isDark),
                    _buildMenuItem('teacher', 'Teacher Portal (Ms. Kavya)', Icons.co_present, isDark),
                    _buildMenuItem('principal', 'Principal Portal (Dr. Sharma)', Icons.account_balance_rounded, isDark),
                    _buildMenuItem('parent', 'Parent Portal (Mr. Ramesh)', Icons.family_restroom, isDark),
                    _buildMenuItem('admin', 'Central Admin Portal', Icons.admin_panel_settings, isDark),
                  ],
                ),
              ],

              SizedBox(width: isUltraCompact ? 2 : (isCompact ? 4 : 8)),

              // Context Selector Pill Dropdown (e.g. "Class 8 • Section A v")
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isUltraCompact ? 95 : (isCompact ? 140 : 260),
                ),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isUltraCompact ? 5 : (isCompact ? 6 : 14),
                    vertical: isCompact ? 4 : 7,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF161C48) : EduStreakTheme.softLavender,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? const Color(0xFF333E80) : const Color(0xFFDDD2F9),
                      width: 1.2,
                    ),
                  ),
                  child: contextPillOptions != null && contextPillOptions!.isNotEmpty
                      ? DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: contextPillOptions!.contains(contextPillText)
                                ? contextPillText
                                : contextPillOptions!.first,
                            dropdownColor: isDark ? const Color(0xFF161C48) : Colors.white,
                            isDense: true,
                            isExpanded: true,
                            icon: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: isUltraCompact ? 14 : (isCompact ? 16 : 18),
                              color: isDark ? Colors.white70 : EduStreakTheme.studentText,
                            ),
                            style: EduStreakTheme.fontLabel(
                              color: isDark ? Colors.white : EduStreakTheme.studentText,
                              weight: FontWeight.w600,
                            ).copyWith(fontSize: isUltraCompact ? 11 : null),
                            items: contextPillOptions!.map((opt) {
                              return DropdownMenuItem(
                                value: opt,
                                child: Text(opt, overflow: TextOverflow.ellipsis, maxLines: 1),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null && onContextPillChanged != null) {
                                onContextPillChanged!(val);
                              }
                            },
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                contextPillText,
                                style: EduStreakTheme.fontLabel(
                                  color: isDark ? Colors.white : EduStreakTheme.studentText,
                                  weight: FontWeight.w600,
                                ).copyWith(fontSize: isUltraCompact ? 11 : null),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: isCompact ? 2 : 4),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: isUltraCompact ? 12 : (isCompact ? 14 : 16),
                              color: isDark ? Colors.white70 : EduStreakTheme.studentText,
                            ),
                          ],
                        ),
                ),
              ),

              SizedBox(width: isUltraCompact ? 3 : (isCompact ? 4 : 14)),

              // Theme Toggle Button (Light / Dark Mode Switcher)
              Builder(
                builder: (context) {
                  ThemeProvider? themeProv;
                  try {
                    themeProv = Provider.of<ThemeProvider>(context, listen: true);
                  } catch (_) {
                    themeProv = null;
                  }
                  final isDarkActive = themeProv?.isDarkMode ?? isDark;
                  return Tooltip(
                    message: isDarkActive ? 'Switch to Light Theme' : 'Switch to Dark Theme',
                    child: InkWell(
                      onTap: themeProv != null ? () => themeProv?.toggleTheme() : null,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: EdgeInsets.all(isCompact ? 6 : 8),
                        decoration: BoxDecoration(
                          color: isDark ? EduStreakTheme.studentDarkCard : const Color(0xFFF3F0FF),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? EduStreakTheme.studentDarkBorder : const Color(0xFFDDD2F9),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          isDarkActive ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                          size: isCompact ? 16 : 19,
                          color: isDarkActive ? const Color(0xFFFBBF24) : EduStreakTheme.primaryViolet,
                        ),
                      ),
                    ),
                  );
                },
              ),

              SizedBox(width: isCompact ? 4 : 14),

              // Notification Bell
              InkWell(
                onTap: onNotificationTap,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: EdgeInsets.all(isCompact ? 6 : 8),
                  decoration: BoxDecoration(
                    color: isDark ? EduStreakTheme.studentDarkCard : const Color(0xFFF3F0FF),
                    border: Border.all(
                      color: isDark ? EduStreakTheme.studentDarkBorder : const Color(0xFFDDD2F9),
                      width: 1,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Stack(
                    children: [
                      Icon(
                        Icons.notifications_none_rounded,
                        size: isCompact ? 17 : 20,
                        color: isDark ? Colors.white70 : EduStreakTheme.studentText,
                      ),
                      Positioned(
                        right: 1,
                        top: 1,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(width: isCompact ? 5 : 16),

              // User Circular Avatar
              avatarWidget ?? const AkashStudentAvatar(radius: 18),
            ],
          ),
        );
      },
    );
  }

  PopupMenuItem<String> _buildMenuItem(String value, String text, IconData icon, bool isDark) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: EduStreakTheme.primaryViolet),
          const SizedBox(width: 10),
          Text(
            text,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
