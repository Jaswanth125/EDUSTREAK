import 'package:flutter/material.dart';
import '../utils/theme.dart';

/// XP Tier System for Profile Picture Borders
/// Similar to FreeFire and Google Play Games
class TierSystem {
  /// Get tier information based on total lifetime XP
  static TierInfo getTier(int totalXP) {
    if (totalXP >= 100000) {
      return TierInfo(
        name: 'Grandmaster',
        color: const Color(0xFFFFD700), // Gold
        glowColor: const Color(0xFFFFF700), // Bright gold
        borderWidth: 4.0,
        icon: '👑',
      );
    } else if (totalXP >= 75000) {
      return TierInfo(
        name: 'Legend',
        color: const Color(0xFF9B59B6), // Purple
        glowColor: const Color(0xFFBB8FCE), // Light purple
        borderWidth: 3.5,
        icon: '🌟',
      );
    } else if (totalXP >= 50000) {
      return TierInfo(
        name: 'Heroic',
        color: const Color(0xFFE74C3C), // Red
        glowColor: const Color(0xFFEC7063), // Light red
        borderWidth: 3.5,
        icon: '⚔️',
      );
    } else if (totalXP >= 30000) {
      return TierInfo(
        name: 'Elite',
        color: const Color(0xFF3498DB), // Blue
        glowColor: const Color(0xFF5DADE2), // Light blue
        borderWidth: 3.0,
        icon: '💎',
      );
    } else if (totalXP >= 15000) {
      return TierInfo(
        name: 'Platinum',
        color: const Color(0xFF95A5A6), // Silver-gray
        glowColor: const Color(0xFFBDC3C7), // Light gray
        borderWidth: 2.5,
        icon: '💠',
      );
    } else if (totalXP >= 7500) {
      return TierInfo(
        name: 'Gold',
        color: const Color(0xFFFFD700), // Gold
        glowColor: const Color(0xFFFFF700), // Bright gold
        borderWidth: 2.5,
        icon: '🥇',
      );
    } else if (totalXP >= 3000) {
      return TierInfo(
        name: 'Silver',
        color: const Color(0xFFC0C0C0), // Silver
        glowColor: const Color(0xFFE8E8E8), // Light silver
        borderWidth: 2.0,
        icon: '🥈',
      );
    } else {
      return TierInfo(
        name: 'Bronze',
        color: const Color(0xFFCD7F32), // Bronze
        glowColor: const Color(0xFFD4A574), // Light bronze
        borderWidth: 2.0,
        icon: '🥉',
      );
    }
  }

  /// Get tier gradient for borders
  static LinearGradient getTierGradient(TierInfo tier) {
    return LinearGradient(
      colors: [
        tier.color,
        tier.glowColor,
        tier.color,
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      stops: const [0.0, 0.5, 1.0],
    );
  }

  /// Get tier glow shadow
  static List<BoxShadow> getTierGlowShadow(TierInfo tier) {
    return [
      BoxShadow(
        color: tier.color.withOpacity(0.6),
        blurRadius: 12,
        spreadRadius: 2,
        offset: const Offset(0, 4),
      ),
      BoxShadow(
        color: tier.glowColor.withOpacity(0.4),
        blurRadius: 20,
        spreadRadius: -2,
        offset: const Offset(0, 8),
      ),
    ];
  }
}

class TierInfo {
  final String name;
  final Color color;
  final Color glowColor;
  final double borderWidth;
  final String icon;

  TierInfo({
    required this.name,
    required this.color,
    required this.glowColor,
    required this.borderWidth,
    required this.icon,
  });
}

