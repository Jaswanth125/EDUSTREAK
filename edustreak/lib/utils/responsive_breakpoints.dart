import 'package:flutter/material.dart';

/// Enumeration representing the 6 EduStreak responsive device tiers
enum DeviceTier {
  /// Mobile phones (< 600px)
  mobile,

  /// Large mobile phones & compact phablets (600 - 767px)
  largeMobile,

  /// Tablets in portrait and compact landscape (768 - 1023px)
  tablet,

  /// Laptops & standard displays (1024 - 1439px) - Exact reference image layout
  laptop,

  /// High-resolution desktop monitors (1440 - 1919px)
  desktop,

  /// Smart TVs, classroom projectors & ultra-wide displays (>= 1920px)
  tv,
}

/// Breakpoint constants and resolution queries
class ResponsiveBreakpoints {
  static const double mobileMax = 599.9;
  static const double largeMobileMax = 767.9;
  static const double tabletMax = 1023.9;
  static const double laptopMax = 1439.9;
  static const double desktopMax = 1919.9;
  static const double tvMin = 1920.0;

  /// Max content width for desktop to prevent cards from stretching too wide
  static const double maxContentWidth = 1560.0;

  /// Resolve [DeviceTier] from width
  static DeviceTier getTier(double width) {
    if (width < 600) return DeviceTier.mobile;
    if (width < 768) return DeviceTier.largeMobile;
    if (width < 1024) return DeviceTier.tablet;
    if (width < 1440) return DeviceTier.laptop;
    if (width < 1920) return DeviceTier.desktop;
    return DeviceTier.tv;
  }
}

/// Context extensions for effortless responsive queries
extension ResponsiveContextExtension on BuildContext {
  /// Screen size
  Size get screenSize => MediaQuery.sizeOf(this);
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;

  /// Device tier
  DeviceTier get deviceTier => ResponsiveBreakpoints.getTier(screenWidth);

  /// Helper boolean getters
  bool get isMobile => deviceTier == DeviceTier.mobile;
  bool get isLargeMobile => deviceTier == DeviceTier.largeMobile;
  bool get isTablet => deviceTier == DeviceTier.tablet;
  bool get isLaptop => deviceTier == DeviceTier.laptop;
  bool get isDesktop => deviceTier == DeviceTier.desktop;
  bool get isTV => deviceTier == DeviceTier.tv;

  /// Handheld devices (phone & large mobile) where bottom navigation & drawer apply
  bool get isHandheld => screenWidth < 768;

  /// Medium screens (tablet) where navigation rail applies
  bool get isRail => screenWidth >= 768 && screenWidth < 1024;

  /// Large screens (laptop, desktop, TV) where full sidebar or TV layout applies
  bool get isWide => screenWidth >= 1024;

  /// Responsive value resolver
  T responsiveValue<T>({
    required T mobile,
    T? largeMobile,
    T? tablet,
    T? laptop,
    T? desktop,
    T? tv,
  }) {
    switch (deviceTier) {
      case DeviceTier.mobile:
        return mobile;
      case DeviceTier.largeMobile:
        return largeMobile ?? mobile;
      case DeviceTier.tablet:
        return tablet ?? largeMobile ?? mobile;
      case DeviceTier.laptop:
        return laptop ?? tablet ?? largeMobile ?? mobile;
      case DeviceTier.desktop:
        return desktop ?? laptop ?? tablet ?? largeMobile ?? mobile;
      case DeviceTier.tv:
        return tv ?? desktop ?? laptop ?? tablet ?? largeMobile ?? mobile;
    }
  }

  /// Scale font sizes smoothly
  double responsiveFontSize(double baseSize) {
    if (isMobile) return (baseSize * 0.92).clamp(10.0, 36.0);
    if (isLargeMobile) return baseSize;
    if (isTablet) return baseSize;
    if (isLaptop) return baseSize;
    if (isDesktop) return (baseSize * 1.05);
    return (baseSize * 1.35); // Large TV readable font
  }

  /// Screen horizontal padding
  EdgeInsets get screenPadding {
    if (isMobile) return const EdgeInsets.symmetric(horizontal: 14, vertical: 12);
    if (isLargeMobile) return const EdgeInsets.symmetric(horizontal: 18, vertical: 16);
    if (isTablet) return const EdgeInsets.symmetric(horizontal: 20, vertical: 18);
    if (isLaptop) return const EdgeInsets.symmetric(horizontal: 24, vertical: 20);
    if (isDesktop) return const EdgeInsets.symmetric(horizontal: 32, vertical: 24);
    return const EdgeInsets.symmetric(horizontal: 48, vertical: 32); // TV spacious padding
  }
}
