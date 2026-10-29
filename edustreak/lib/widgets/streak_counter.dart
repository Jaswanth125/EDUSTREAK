import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/theme.dart';

class StreakCounter extends StatelessWidget {
  final int streak;

  const StreakCounter({super.key, required this.streak});

  String _getMotivationalMessage() {
    if (streak == 0) return 'Start your streak today!';
    if (streak < 3) return 'Keep it up! 🔥';
    if (streak < 7) return 'You\'re on fire! 🔥🔥';
    if (streak < 14) return 'Consistency King/Queen! 👑';
    if (streak < 30) return 'Unstoppable! 💪';
    return 'Legendary! 🏆';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.darkCardGradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.streakColor.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: AppTheme.streakGlowShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: AppTheme.streakGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.streakColor.withOpacity(0.6),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    Icons.local_fire_department,
                    color: Colors.white,
                    size: 48,
                  )
                      .animate(onPlay: (controller) => controller.repeat())
                      .shimmer(
                        duration: 2000.ms,
                        color: AppTheme.streakGlow.withOpacity(0.8),
                        angle: 0.5,
                      )
                      .then()
                      .scale(
                        begin: const Offset(1.0, 1.0),
                        end: const Offset(1.1, 1.1),
                        duration: 1000.ms,
                        curve: Curves.easeInOut,
                      )
                      .then()
                      .scale(
                        begin: const Offset(1.1, 1.1),
                        end: const Offset(1.0, 1.0),
                        duration: 1000.ms,
                        curve: Curves.easeInOut,
                      ),
                ),
                const SizedBox(width: 16),
                Text(
                  '$streak',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.streakColor,
                        fontSize: 64,
                        shadows: [
                          Shadow(
                            color: AppTheme.streakColor.withOpacity(0.8),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                )
                    .animate()
                    .fadeIn(duration: 800.ms, curve: Curves.easeOut)
                    .scale(begin: const Offset(0.5, 0.5), duration: 800.ms, curve: Curves.elasticOut),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              streak == 1 ? 'Day Streak' : 'Days Streak',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
            )
                .animate()
                .fadeIn(delay: 200.ms, duration: 600.ms)
                .slideY(begin: 0.3, end: 0, duration: 600.ms),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                gradient: AppTheme.streakGradient,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.streakColor.withOpacity(0.5),
                    blurRadius: 16,
                    spreadRadius: 0,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Text(
                _getMotivationalMessage(),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 0.5,
                    ),
              ),
            )
                .animate()
                .fadeIn(delay: 400.ms, duration: 800.ms)
                .slideY(begin: 0.3, end: 0, duration: 800.ms, curve: Curves.easeOut)
                .shimmer(
                  delay: 1000.ms,
                  duration: 1500.ms,
                  color: Colors.white.withOpacity(0.3),
                ),
          ],
        ),
      ),
    );
  }
}

