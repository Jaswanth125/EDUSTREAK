import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/user_provider.dart';
import '../../models/user_model.dart';
import '../../models/badge_model.dart';
import '../../models/xp_transaction_model.dart';
import '../../services/gamification_service.dart';
import '../../utils/edustreak_theme.dart';

/// Screen displaying student achievements, unlocked badges, and level milestone progression.
/// Zero mock data: 100% bound to authenticated student's true records.
class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  String _selectedFilter = 'All';
  final GamificationService _gamificationService = GamificationService();

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final currentUser = userProvider.currentUser;

    if (currentUser == null) {
      return const Center(
        child: CircularProgressIndicator(color: EduStreakTheme.primaryViolet),
      );
    }

    final level = currentUser.level > 0 ? currentUser.level : 1;
    final xp = currentUser.xp;
    final currentLevelBaseXp = _gamificationService.getXPForLevel(level - 1);
    final nextLevelTargetXp = _gamificationService.getXPForLevel(level);
    final xpInCurrentLevel = (xp - currentLevelBaseXp).clamp(0, nextLevelTargetXp);
    final xpNeededForNext = (nextLevelTargetXp - currentLevelBaseXp);
    final progress = xpNeededForNext > 0
        ? (xpInCurrentLevel / xpNeededForNext).clamp(0.0, 1.0)
        : 1.0;

    return Container(
      color: EduStreakTheme.studentDarkBg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header
            _buildHeader(currentUser),
            const SizedBox(height: 20),

            // Hero Card: Current Level Scholar Progression
            _buildScholarHeroCard(level, xp, nextLevelTargetXp, progress),
            const SizedBox(height: 22),

            // Filter Pills
            _buildFilterPills(),
            const SizedBox(height: 18),

            // Badges Grid with Real Status
            _buildBadgesGrid(currentUser),
          ],
        ),
      ),
    );
  }

  // ─── PAGE HEADER WITH XP HISTORY ACTION ─────────────────────────────────
  Widget _buildHeader(UserModel user) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 500;
        final titleSection = Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: EduStreakTheme.primaryViolet.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: EduStreakTheme.primaryViolet.withValues(alpha: 0.4),
                  width: 1.2,
                ),
              ),
              child: const Icon(Icons.emoji_events_rounded, color: EduStreakTheme.primaryViolet, size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'My Achievements',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                      SizedBox(width: 6),
                      Text('🏆', style: TextStyle(fontSize: 18)),
                    ],
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Unlock trophies, badges and level up by completing lessons and tasks!',
                    style: TextStyle(
                      color: EduStreakTheme.studentDarkTextMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

        final xpHistoryBtn = OutlinedButton.icon(
          onPressed: () => _showXpHistoryDialog(user),
          icon: const Icon(Icons.history_rounded, size: 16, color: Color(0xFFFBBF24)),
          label: const Text(
            'XP History',
            style: TextStyle(color: Color(0xFFFBBF24), fontSize: 12, fontWeight: FontWeight.w700),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: const Color(0xFFFBBF24).withValues(alpha: 0.6)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          ),
        );

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleSection,
              const SizedBox(height: 12),
              xpHistoryBtn,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: titleSection),
            const SizedBox(width: 12),
            xpHistoryBtn,
          ],
        );
      },
    );
  }

  void _showXpHistoryDialog(UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        decoration: BoxDecoration(
          color: EduStreakTheme.studentDarkBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: EduStreakTheme.studentDarkBorder, width: 1.2),
        ),
        child: Column(
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: EduStreakTheme.studentDarkTextMuted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBBF24).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.bolt_rounded, color: Color(0xFFFBBF24), size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'XP Transaction History',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        Text(
                          'Every earned and spent point is permanently recorded',
                          style: TextStyle(color: EduStreakTheme.studentDarkTextMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: EduStreakTheme.studentDarkTextMuted),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: EduStreakTheme.studentDarkBorder),
            Expanded(
              child: StreamBuilder<List<XpTransactionModel>>(
                stream: _gamificationService.getXPTransactions(user.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: EduStreakTheme.primaryViolet),
                    );
                  }

                  final transactions = snapshot.data ?? [];
                  if (transactions.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.receipt_long_rounded, size: 48, color: EduStreakTheme.studentDarkTextMuted),
                            SizedBox(height: 12),
                            Text(
                              'No XP transactions yet',
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Complete homework and practice challenges to start earning XP!',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: EduStreakTheme.studentDarkTextMuted, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: transactions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final tx = transactions[index];
                      final isEarn = tx.type == 'earn' || tx.amount > 0;
                      final sign = isEarn ? '+' : '';
                      final amountColor = isEarn ? const Color(0xFF10B981) : const Color(0xFFA855F7);
                      final icon = isEarn ? Icons.bolt_rounded : Icons.shopping_bag_rounded;

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: EduStreakTheme.studentDarkCard,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: EduStreakTheme.studentDarkBorder),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: amountColor.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(icon, color: amountColor, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tx.reason,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13.5),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    DateFormat('MMM dd, yyyy • hh:mm a').format(tx.timestamp),
                                    style: const TextStyle(color: EduStreakTheme.studentDarkTextMuted, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '$sign${tx.amount} XP',
                                  style: TextStyle(
                                    color: amountColor,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15,
                                  ),
                                ),
                                Text(
                                  'Balance: ${tx.balanceAfter}',
                                  style: const TextStyle(color: EduStreakTheme.studentDarkTextMuted, fontSize: 11),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── HERO CARD: LEVEL PROGRESSION ───────────────────────────────────────
  Widget _buildScholarHeroCard(int level, int xp, int targetXp, double progress) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF281358),
            Color(0xFF19103C),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: EduStreakTheme.primaryViolet.withValues(alpha: 0.4),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: EduStreakTheme.primaryViolet.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7950FF), Color(0xFF9E7BFF)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7950FF).withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(Icons.stars_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Level $level Scholar',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$xp Lifetime XP • Next level at $targetXp XP',
                      style: const TextStyle(
                        color: EduStreakTheme.studentDarkTextMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.5)),
                ),
                child: Text(
                  '${(progress * 100).toInt()}%',
                  style: const TextStyle(
                    color: Color(0xFF34D399),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: const Color(0xFF140E36),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF35C9FF)),
            ),
          ),
        ],
      ),
    );
  }

  // ─── FILTER PILLS ───────────────────────────────────────────────────────
  Widget _buildFilterPills() {
    final filters = ['All', 'Streaks', 'Tasks', 'Level', 'Academic'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final isSelected = _selectedFilter == f;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(f),
              selected: isSelected,
              onSelected: (_) => setState(() => _selectedFilter = f),
              backgroundColor: EduStreakTheme.studentDarkCard,
              selectedColor: EduStreakTheme.primaryViolet,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : EduStreakTheme.studentDarkTextMuted,
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
              side: BorderSide(
                color: isSelected
                    ? EduStreakTheme.primaryViolet
                    : EduStreakTheme.studentDarkBorder,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── BADGES GRID ────────────────────────────────────────────────────────
  Widget _buildBadgesGrid(UserModel user) {
    final allBadges = BadgeModel.getDefaultBadges();
    final userBadgeIds = user.badges;

    final filtered = allBadges.where((b) {
      if (_selectedFilter == 'All') return true;
      if (_selectedFilter == 'Streaks') return b.category == 'streak';
      if (_selectedFilter == 'Tasks') return b.category == 'task';
      if (_selectedFilter == 'Level') return b.category == 'level';
      if (_selectedFilter == 'Academic') return b.category == 'academic' || b.category == 'quiz';
      return true;
    }).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 800 ? 3 : (constraints.maxWidth > 500 ? 2 : 1);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 1.45,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
          ),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final badge = filtered[index];
            final isUnlocked = userBadgeIds.contains(badge.id);
            return _buildBadgeCard(badge, isUnlocked);
          },
        );
      },
    );
  }

  Widget _buildBadgeCard(BadgeModel badge, bool isUnlocked) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnlocked
            ? EduStreakTheme.studentDarkCard
            : EduStreakTheme.studentDarkCard.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isUnlocked
              ? EduStreakTheme.primaryViolet.withValues(alpha: 0.5)
              : EduStreakTheme.studentDarkBorder,
          width: 1.2,
        ),
        boxShadow: isUnlocked
            ? [
                BoxShadow(
                  color: EduStreakTheme.primaryViolet.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isUnlocked
                      ? EduStreakTheme.primaryViolet.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    badge.icon,
                    style: TextStyle(
                      fontSize: 22,
                      color: isUnlocked ? null : Colors.grey,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isUnlocked
                      ? const Color(0xFF10B981).withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isUnlocked ? Icons.check_circle_rounded : Icons.lock_outline_rounded,
                      size: 13,
                      color: isUnlocked ? const Color(0xFF34D399) : EduStreakTheme.studentDarkTextMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isUnlocked ? 'Unlocked' : 'Locked',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isUnlocked ? const Color(0xFF34D399) : EduStreakTheme.studentDarkTextMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                badge.name,
                style: TextStyle(
                  color: isUnlocked ? Colors.white : EduStreakTheme.studentDarkTextMuted,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(
                badge.description,
                style: const TextStyle(
                  color: EduStreakTheme.studentDarkTextMuted,
                  fontSize: 12,
                  height: 1.25,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.bolt_rounded, size: 14, color: Color(0xFFFBBF24)),
              const SizedBox(width: 3),
              Text(
                '+${badge.xpReward} XP',
                style: const TextStyle(
                  color: Color(0xFFFBBF24),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
