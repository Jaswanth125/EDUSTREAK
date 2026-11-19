import 'package:flutter/material.dart';
import '../../utils/edustreak_theme.dart';
import '../../utils/responsive_breakpoints.dart';

/// Shows an adaptive dialog that turns into a full-width bottom sheet on mobile devices
/// and a centered modal dialog on tablets, laptops, desktops, and smart TVs.
Future<T?> showAdaptiveEduStreakModal<T>({
  required BuildContext context,
  String? title,
  required Widget Function(BuildContext) builder,
  Widget? icon,
  bool isDark = false,
  double maxWidth = 560,
  List<Widget>? actions,
}) {
  final isMobile = context.screenWidth < 600;
  final hasTitle = title != null && title.isNotEmpty;

  if (isMobile) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final bottomInset = MediaQuery.viewInsetsOf(ctx).bottom;

        return Container(
          padding: EdgeInsets.only(bottom: bottomInset),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF101538) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: isDark ? EduStreakTheme.primaryViolet.withValues(alpha: 0.3) : EduStreakTheme.studentBorder,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Drag Handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Header (if title exists)
                if (hasTitle) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      children: [
                        if (icon != null) ...[
                          icon,
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: Text(
                            title,
                            style: EduStreakTheme.fontHeading2(
                              color: isDark ? Colors.white : EduStreakTheme.studentText,
                              weight: FontWeight.w800,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close_rounded, color: isDark ? Colors.white54 : Colors.black45),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                ],

                // Scrollable Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: hasTitle ? const EdgeInsets.all(20) : EdgeInsets.zero,
                    child: builder(ctx),
                  ),
                ),

                // Optional Action Buttons
                if (actions != null && actions.isNotEmpty) ...[
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Wrap(
                      alignment: WrapAlignment.end,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: actions,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // Tablet / Desktop / TV Centered Dialog
  return showDialog<T>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: isDark ? const Color(0xFF101538) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isDark ? EduStreakTheme.primaryViolet.withValues(alpha: 0.35) : EduStreakTheme.studentBorder,
          width: 1.2,
        ),
      ),
      titlePadding: hasTitle ? null : EdgeInsets.zero,
      contentPadding: hasTitle ? null : EdgeInsets.zero,
      title: hasTitle
          ? Row(
              children: [
                if (icon != null) ...[
                  icon,
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: EduStreakTheme.fontHeading2(
                      color: isDark ? Colors.white : EduStreakTheme.studentText,
                      weight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            )
          : null,
      content: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: SingleChildScrollView(
          child: builder(ctx),
        ),
      ),
      actions: actions,
    ),
  );
}
