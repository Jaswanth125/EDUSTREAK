import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/gamification_service.dart';
import '../utils/theme.dart';

class XPProgressBar extends StatelessWidget {
  final int xp;
  final int level;

  const XPProgressBar({super.key, required this.xp, required this.level});

  String _getLevelTitle() {
    if (level < 5) return 'Bronze';
    if (level < 10) return 'Silver';
    if (level < 15) return 'Gold';
    if (level < 20) return 'Platinum';
    return 'Diamond';
  }

  Color _getLevelColor() {
    if (level < 5) return Colors.brown;
    if (level < 10) return Colors.grey;
    if (level < 15) return Colors.amber;
    if (level < 20) return Colors.blue;
    return Colors.purple;
  }

  @override
  Widget build(BuildContext context) {
    final gamificationService = GamificationService();
    final currentLevelXP = gamificationService.getXPForLevel(level);
    final nextLevelXP = gamificationService.getXPForLevel(level + 1);
    final xpForCurrentLevel = xp - currentLevelXP;
    final xpNeededForNextLevel = nextLevelXP - currentLevelXP;
    final progress = xpNeededForNextLevel > 0
        ? xpForCurrentLevel / xpNeededForNextLevel
        : 0.0;

    final levelColor = _getLevelColor();
    final levelTitle = _getLevelTitle();

    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.darkCardGradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: AppTheme.cardGlowShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Level $level',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                        )
                            .animate()
                            .fadeIn(duration: 600.ms)
                            .slideX(begin: -0.2, end: 0),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                levelColor.withOpacity(0.3),
                                levelColor.withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: levelColor.withOpacity(0.6),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: levelColor.withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: Text(
                            levelTitle,
                            style: TextStyle(
                              color: levelColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            gradient: AppTheme.accentGradient,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.star, size: 16, color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$xp XP',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppTheme.primaryGlowShadow,
                  ),
                  child: Text(
                    'Lv.$level',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 600.ms)
                    .scale(begin: const Offset(0.8, 0.8), duration: 600.ms),
              ],
            ),
            const SizedBox(height: 24),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  Container(
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppTheme.darkBorder.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  Container(
                    height: 20,
                    width: (MediaQuery.of(context).size.width - 80) * progress.clamp(0.0, 1.0),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.6),
                          blurRadius: 12,
                          spreadRadius: 0,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 400.ms, duration: 1000.ms)
                      .scaleX(begin: 0, end: 1, duration: 1000.ms, curve: Curves.easeOutCubic)
                      .shimmer(
                        delay: 1500.ms,
                        duration: 2000.ms,
                        color: AppTheme.primaryGlow.withOpacity(0.5),
                      ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$xpForCurrentLevel / $xpNeededForNextLevel XP',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textTertiary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                Text(
                  'Next: Level ${level + 1}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

