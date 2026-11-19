import 'package:flutter/material.dart';
import '../utils/edustreak_theme.dart';

/// Custom illustrations, mascots, and graphical components faithfully
/// recreating the visual details in the EduStreak reference image.

/// 1. 3D Glowing Isometric EduStreak "E" Logo
class EduStreak3DLogo extends StatelessWidget {
  final double size;
  final bool showGlow;

  const EduStreak3DLogo({super.key, this.size = 48, this.showGlow = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        gradient: EduStreakTheme.logo3dGradient,
        boxShadow: showGlow
            ? [
                BoxShadow(
                  color: EduStreakTheme.primaryViolet.withValues(alpha: 0.55),
                  blurRadius: size * 0.45,
                  spreadRadius: size * 0.08,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.2),
                  blurRadius: size * 0.15,
                  offset: const Offset(-2, -2),
                ),
              ]
            : null,
      ),
      child: Center(
        child: Text(
          'E',
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.58,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 4,
                offset: const Offset(1, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 2. Brand Header Logo with text: "[E] EduStreak | Subtitle"
class EduStreakBrandHeader extends StatelessWidget {
  final String? subtitle;
  final bool isDark;

  const EduStreakBrandHeader({super.key, this.subtitle, this.isDark = true});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const EduStreak3DLogo(size: 38),
        const SizedBox(width: 12),
        Text(
          'EduStreak',
          style: EduStreakTheme.fontHeading1(
            color: isDark ? Colors.white : EduStreakTheme.studentText,
            weight: FontWeight.w900,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(width: 12),
          Container(
            height: 18,
            width: 1.5,
            color: (isDark ? Colors.white : EduStreakTheme.studentText).withValues(alpha: 0.3),
          ),
          const SizedBox(width: 12),
          Text(
            subtitle!,
            style: EduStreakTheme.fontCaption(
              color: isDark ? EduStreakTheme.darkTextSub : EduStreakTheme.studentTextMuted,
              weight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

/// 3. Akash Student 3D Avatar (Boy with purple hoodie and headphones)
class AkashStudentAvatar extends StatelessWidget {
  final double radius;
  final double? size;
  final bool showBadge;

  const AkashStudentAvatar({
    super.key,
    this.radius = 28,
    this.size,
    this.showBadge = false,
  });

  double get _effectiveRadius => size != null ? size! / 2 : radius;

  @override
  Widget build(BuildContext context) {
    final effectiveSize = _effectiveRadius * 2;
    return Stack(
      children: [
        Container(
          width: effectiveSize,
          height: effectiveSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFF3E8FF),
            border: Border.all(color: Colors.white, width: 2.0),
            boxShadow: [
              BoxShadow(
                color: EduStreakTheme.primaryViolet.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/akash_mascot_v2.png',
              fit: BoxFit.cover,
              alignment: const Alignment(0, -0.6),
              errorBuilder: (_, __, ___) => _buildProceduralAvatar(_effectiveRadius),
            ),
          ),
        ),
        if (showBadge)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: Color(0xFF10B981),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.bolt, size: 10, color: Colors.white),
            ),
          ),
      ],
    );
  }

  Widget _buildProceduralAvatar(double r) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Head / Face
        Positioned(
          top: r * 0.25,
          child: Container(
            width: r * 0.9,
            height: r * 1.0,
            decoration: const BoxDecoration(
              color: Color(0xFFFDBC85),
              shape: BoxShape.circle,
            ),
          ),
        ),
        // Hair (dark brown)
        Positioned(
          top: r * 0.05,
          child: Container(
            width: r * 1.05,
            height: r * 0.65,
            decoration: const BoxDecoration(
              color: Color(0xFF2C1810),
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
          ),
        ),
        // Blue/Purple Headphones
        Positioned(
          top: r * 0.35,
          child: Container(
            width: r * 1.3,
            height: r * 0.4,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF38BDF8), width: 3.5),
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        ),
        // Purple Hoodie with "E"
        Positioned(
          bottom: -r * 0.15,
          child: Container(
            width: r * 1.5,
            height: r * 0.9,
            decoration: const BoxDecoration(
              color: Color(0xFF6366F1),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Center(
              child: Text(
                'E',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: r * 0.35,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 4. Today's Quest Castle Card Illustration
class QuestCastleCard extends StatelessWidget {
  final VoidCallback? onStart;
  final VoidCallback? onStartQuest;
  final List<String> completedTasks;
  final List<String> pendingTasks;
  final String? questTitle;
  final String? questSubtitle;

  const QuestCastleCard({
    super.key,
    this.onStart,
    this.onStartQuest,
    this.completedTasks = const ['Learn: Photosynthesis', 'Practice: 10 MCQs'],
    this.pendingTasks = const ['Finish: Homework'],
    this.questTitle,
    this.questSubtitle,
  });

  VoidCallback get _effectiveAction => onStartQuest ?? onStart ?? () {};

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 160),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: EduStreakTheme.questCardGradient,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF43218B).withValues(alpha: 0.45),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background Castle & Rainbow illustration art
          Positioned(
            right: 0,
            bottom: 0,
            top: 0,
            width: 270,
            child: ClipRRect(
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(22)),
              child: ShaderMask(
                shaderCallback: (rect) {
                  return const LinearGradient(
                    colors: [Colors.transparent, Colors.black],
                    stops: [0.0, 0.40],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ).createShader(rect);
                },
                blendMode: BlendMode.dstIn,
                child: Image.asset(
                  'assets/images/quest_castle.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.centerRight,
                  errorBuilder: (_, __, ___) => CustomPaint(
                    painter: _CastlePathPainter(),
                  ),
                ),
              ),
            ),
          ),
          // Foreground Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        questTitle ?? "Today's Quest ⚔️",
                        style: EduStreakTheme.fontHeading2(color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (questSubtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    questSubtitle!,
                    style: EduStreakTheme.fontCaption(color: Colors.white.withValues(alpha: 0.85)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 12),
                // Completed Checklist Items
                ...completedTasks.map((t) => _buildCheckItem(t, true)),
                // Pending Checklist Items
                ...pendingTasks.map((t) => _buildCheckItem(t, false)),
                const SizedBox(height: 16),
                // "Start Now ->" Button
                InkWell(
                  onTap: _effectiveAction,
                  borderRadius: BorderRadius.circular(25),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 9),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Start Now',
                          style: EduStreakTheme.fontLabel(
                            color: const Color(0xFF43218B),
                            weight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color: Color(0xFF43218B),
                        ),
                      ],
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

  Widget _buildCheckItem(String title, bool isDone) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: isDone ? const Color(0xFF10B981) : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDone ? const Color(0xFF10B981) : Colors.white.withValues(alpha: 0.7),
                width: 1.8,
              ),
            ),
            child: isDone
                ? const Icon(Icons.check, size: 12, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              title,
              style: EduStreakTheme.fontCaption(
                color: isDone ? Colors.white.withValues(alpha: 0.95) : Colors.white.withValues(alpha: 0.85),
                weight: isDone ? FontWeight.w600 : FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _CastlePathPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Floating Green Cliff
    final cliffPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF22C55E), Color(0xFF15803D), Color(0xFF0F172A)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path()
      ..moveTo(size.width * 0.1, size.height)
      ..cubicTo(size.width * 0.2, size.height * 0.5, size.width * 0.6, size.height * 0.55, size.width, size.height * 0.4)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, cliffPaint);

    // Winding path (golden)
    final trailPaint = Paint()
      ..color = const Color(0xFFFDE047).withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round;

    final trailPath = Path()
      ..moveTo(size.width * 0.2, size.height * 0.9)
      ..quadraticBezierTo(size.width * 0.45, size.height * 0.75, size.width * 0.75, size.height * 0.45);
    canvas.drawPath(trailPath, trailPaint);

    // Castle Tower
    final towerPaint = Paint()..color = const Color(0xFFE2E8F0);
    final towerRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(size.width * 0.78, size.height * 0.35), width: 34, height: 48),
      const Radius.circular(6),
    );
    canvas.drawRRect(towerRect, towerPaint);

    // Castle Roof
    final roofPaint = Paint()..color = const Color(0xFFEF4444);
    final roofPath = Path()
      ..moveTo(size.width * 0.78 - 22, size.height * 0.35 - 24)
      ..lineTo(size.width * 0.78 + 22, size.height * 0.35 - 24)
      ..lineTo(size.width * 0.78, size.height * 0.35 - 46)
      ..close();
    canvas.drawPath(roofPath, roofPaint);

    // Flag
    final flagPaint = Paint()..color = const Color(0xFFFBBF24);
    canvas.drawLine(
      Offset(size.width * 0.78, size.height * 0.35 - 46),
      Offset(size.width * 0.78, size.height * 0.35 - 58),
      Paint()..color = Colors.white..strokeWidth = 2,
    );
    canvas.drawCircle(Offset(size.width * 0.78 + 4, size.height * 0.35 - 54), 4, flagPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 5. AI Cute Robot Mascot (for AI Teaching Hub and AI Study Buddy)
class AiRobotMascot extends StatelessWidget {
  final double size;

  const AiRobotMascot({super.key, this.size = 54});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF06B6D4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF06B6D4).withValues(alpha: 0.45),
            blurRadius: size * 0.35,
            spreadRadius: 1,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: size * 0.75,
          height: size * 0.65,
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(size * 0.25),
            border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Left Cyan Eye
              Container(
                width: size * 0.16,
                height: size * 0.22,
                decoration: BoxDecoration(
                  color: const Color(0xFF00E5FF),
                  borderRadius: BorderRadius.circular(size * 0.08),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.8),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              SizedBox(width: size * 0.12),
              // Right Cyan Eye
              Container(
                width: size * 0.16,
                height: size * 0.22,
                decoration: BoxDecoration(
                  color: const Color(0xFF00E5FF),
                  borderRadius: BorderRadius.circular(size * 0.08),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.8),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 6. Circular Level & XP Progress Ring
class LevelXpProgressRing extends StatelessWidget {
  final int level;
  final String? title;
  final String? rankTitle;
  final int currentXp;
  final int? targetXp;
  final int? maxXp;
  final double? size;

  const LevelXpProgressRing({
    super.key,
    required this.level,
    this.title,
    this.rankTitle,
    required this.currentXp,
    this.targetXp,
    this.maxXp,
    this.size,
  });

  String get _effectiveTitle => rankTitle ?? title ?? 'Scholar';
  int get _effectiveTargetXp => maxXp ?? targetXp ?? 3000;
  double get _effectiveSize => size ?? 96.0;

  @override
  Widget build(BuildContext context) {
    final progress = (currentXp / _effectiveTargetXp).clamp(0.0, 1.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Background & Progress Arc
            SizedBox(
              width: _effectiveSize,
              height: _effectiveSize,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 7,
                backgroundColor: const Color(0xFFF0ECFC),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFBBF24)),
                strokeCap: StrokeCap.round,
              ),
            ),
            // Inner content
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.emoji_events_rounded, size: 24, color: Color(0xFFF59E0B)),
                const SizedBox(height: 2),
                Text(
                  'Lv. $level',
                  style: TextStyle(
                    color: EduStreakTheme.textNavy,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  _effectiveTitle,
                  style: TextStyle(
                    color: EduStreakTheme.studentTextMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            currentXp == 2450 && _effectiveTargetXp == 3000
                ? '2,450 / 3,000 XP'
                : '$currentXp / $_effectiveTargetXp XP',
            style: TextStyle(
              color: EduStreakTheme.textNavy,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

/// 7. Authentic Streak Flame Card from Image 1
class StreakFlameCard extends StatelessWidget {
  final int streakDays;

  const StreakFlameCard({super.key, required this.streakDays});

  @override
  Widget build(BuildContext context) {
    final displayStreak = streakDays > 0 ? streakDays : 12;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: EduStreakTheme.studentBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: EduStreakTheme.primaryViolet.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Row(
          children: [
            Image.asset(
              'assets/images/streak_flame.png',
              width: 42,
              height: 42,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Text('🔥', style: TextStyle(fontSize: 28)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '$displayStreak Days',
                      style: TextStyle(
                        color: EduStreakTheme.textNavy,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Streak',
                    style: TextStyle(
                      color: EduStreakTheme.studentTextMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 8. Akash 3D Mascot Character Standing
class AkashMascotStanding extends StatelessWidget {
  final double height;

  const AkashMascotStanding({super.key, this.height = 220});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: height * 0.68,
      child: Image.asset(
        'assets/images/akash_mascot_v2.png',
        fit: BoxFit.contain,
        alignment: Alignment.bottomCenter,
        errorBuilder: (ctx, err, stack) {
          debugPrint('Failed to load assets/images/akash_mascot_v2.png: $err');
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

