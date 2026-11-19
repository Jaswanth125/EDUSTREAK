import 'package:flutter/material.dart';
import '../../utils/edustreak_theme.dart';
import '../../utils/responsive_breakpoints.dart';

/// A responsive card container that adapts its padding, radius, and elevation
/// according to the device tier, avoiding excessive stretching on wide screens.
class ResponsiveCard extends StatelessWidget {
  final Widget child;
  final bool isDark;
  final EdgeInsetsGeometry? padding;
  final double? maxWidth;
  final double? radius;
  final Color? borderColor;
  final VoidCallback? onTap;

  const ResponsiveCard({
    super.key,
    required this.child,
    this.isDark = false,
    this.padding,
    this.maxWidth,
    this.radius,
    this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectivePadding = padding ??
        context.responsiveValue<EdgeInsetsGeometry>(
          mobile: const EdgeInsets.all(14),
          largeMobile: const EdgeInsets.all(16),
          tablet: const EdgeInsets.all(18),
          laptop: const EdgeInsets.all(20),
          desktop: const EdgeInsets.all(22),
          tv: const EdgeInsets.all(28),
        );

    final effectiveRadius = radius ??
        context.responsiveValue<double>(
          mobile: 14,
          largeMobile: 16,
          tablet: 18,
          laptop: 18,
          desktop: 20,
          tv: 24,
        );

    final decoration = isDark
        ? EduStreakTheme.darkCardDecoration(
            radius: effectiveRadius,
            borderColor: borderColor,
          )
        : EduStreakTheme.lightCardDecoration(
            radius: effectiveRadius,
            border: borderColor != null ? Border.all(color: borderColor!, width: 1.2) : null,
          );

    Widget cardWidget = Container(
      padding: effectivePadding,
      decoration: decoration,
      child: child,
    );

    if (onTap != null) {
      cardWidget = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(effectiveRadius),
        child: cardWidget,
      );
    }

    if (maxWidth != null) {
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth!),
          child: cardWidget,
        ),
      );
    }

    return cardWidget;
  }
}
