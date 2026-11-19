import 'package:flutter/material.dart';
import '../../utils/edustreak_theme.dart';
import '../../utils/responsive_breakpoints.dart';

class RegistrationStepItem {
  final String title;
  final String subtitle;
  final IconData icon;

  const RegistrationStepItem({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

/// A responsive step indicator for the 4-step school-managed registration flow.
/// Adapts gracefully from 320px mobile screens to large desktop monitors.
class RegistrationStepIndicator extends StatelessWidget {
  final int currentStep; // 0 to 3
  final int totalSteps;
  final List<RegistrationStepItem>? customSteps;
  final bool isDark;

  const RegistrationStepIndicator({
    super.key,
    required this.currentStep,
    this.totalSteps = 4,
    this.customSteps,
    this.isDark = true,
  });

  static const List<RegistrationStepItem> defaultSteps = [
    RegistrationStepItem(
      title: 'School Verification',
      subtitle: 'Code & Record',
      icon: Icons.school_rounded,
    ),
    RegistrationStepItem(
      title: 'Identity Verification',
      subtitle: 'OTP / PIN',
      icon: Icons.verified_user_rounded,
    ),
    RegistrationStepItem(
      title: 'Create Password',
      subtitle: 'Credentials',
      icon: Icons.lock_outline_rounded,
    ),
    RegistrationStepItem(
      title: 'Account Activated',
      subtitle: 'Access Portal',
      icon: Icons.check_circle_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final steps = customSteps ?? defaultSteps;
    final isCompact = context.screenWidth < 920;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 20,
        vertical: isCompact ? 10 : 16,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141033) : const Color(0xFFF9F7FE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2C2456) : const Color(0xFFE5DCF9),
          width: 1,
        ),
      ),
      child: isCompact ? _buildCompactView(context, steps) : _buildExpandedView(context, steps),
    );
  }

  /// Compact view for mobile devices (320px - 919px) with zero overflow guarantee
  Widget _buildCompactView(BuildContext context, List<RegistrationStepItem> steps) {
    final activeIndex = currentStep.clamp(0, steps.length - 1);
    final activeStep = steps[activeIndex];
    final progress = (activeIndex + 1) / steps.length;

    final primaryColor = isDark ? EduStreakTheme.cyanAccent : EduStreakTheme.primaryViolet;
    final textHeadingColor = isDark ? Colors.white : EduStreakTheme.textNavy;
    final textMutedColor = isDark ? const Color(0xFFA5A0C8) : EduStreakTheme.studentTextMuted;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [EduStreakTheme.primaryViolet, EduStreakTheme.cyanAccent],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${activeIndex + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      activeStep.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textHeadingColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Step ${activeIndex + 1} of ${steps.length}',
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          activeStep.subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: textMutedColor,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 5,
            backgroundColor: isDark ? const Color(0xFF231D45) : const Color(0xFFE2D9F3),
            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
          ),
        ),
      ],
    );
  }

  /// Expanded view for laptops and desktops
  Widget _buildExpandedView(BuildContext context, List<RegistrationStepItem> steps) {
    return Row(
      children: List.generate(steps.length * 2 - 1, (index) {
        if (index.isOdd) {
          // Connector line
          final stepBeforeIndex = index ~/ 2;
          final isCompleted = currentStep > stepBeforeIndex;
          return Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              color: isCompleted
                  ? (isDark ? EduStreakTheme.cyanAccent : EduStreakTheme.primaryViolet)
                  : (isDark ? const Color(0xFF2C2456) : const Color(0xFFE2D9F3)),
            ),
          );
        }

        final stepIndex = index ~/ 2;
        final isCompleted = currentStep > stepIndex;
        final isActive = currentStep == stepIndex;
        final step = steps[stepIndex];

        return Flexible(
          child: _buildStepPill(
            stepNumber: stepIndex + 1,
            step: step,
            isCompleted: isCompleted,
            isActive: isActive,
          ),
        );
      }),
    );
  }

  Widget _buildStepPill({
    required int stepNumber,
    required RegistrationStepItem step,
    required bool isCompleted,
    required bool isActive,
  }) {
    Color badgeColor;
    Color iconColor;
    Widget badgeContent;

    if (isCompleted) {
      badgeColor = const Color(0xFF10B981);
      iconColor = Colors.white;
      badgeContent = const Icon(Icons.check_rounded, size: 16, color: Colors.white);
    } else if (isActive) {
      badgeColor = EduStreakTheme.primaryViolet;
      iconColor = Colors.white;
      badgeContent = Text(
        '$stepNumber',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      );
    } else {
      badgeColor = isDark ? const Color(0xFF251F47) : const Color(0xFFEADBFC);
      iconColor = isDark ? const Color(0xFF756D99) : const Color(0xFF9E95B8);
      badgeContent = Text(
        '$stepNumber',
        style: TextStyle(
          color: iconColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    final headingColor = isActive
        ? (isDark ? Colors.white : EduStreakTheme.textNavy)
        : (isCompleted
            ? (isDark ? const Color(0xFFD6D0F5) : EduStreakTheme.textNavy)
            : (isDark ? const Color(0xFF756D99) : const Color(0xFF9E95B8)));

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: badgeColor,
            shape: BoxShape.circle,
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: EduStreakTheme.primaryViolet.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(child: badgeContent),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                step.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: headingColor,
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
              Text(
                step.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isDark ? const Color(0xFF8881AB) : const Color(0xFF7B7599),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
