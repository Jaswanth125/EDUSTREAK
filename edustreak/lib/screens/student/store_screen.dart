import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../models/user_model.dart';
import '../../models/store_item_model.dart';
import '../../services/store_service.dart';
import '../../utils/edustreak_theme.dart';

/// Genuine Avatar & Badge Redemption Store and Inventory.
/// Enforces strict separation between Spendable XP and Lifetime XP:
/// purchases deduct spendable points, never lowering lifetime XP or level.
class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final StoreService _storeService = StoreService();
  String _storeFilter = 'All';
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final currentUser = userProvider.currentUser;

    if (currentUser == null) {
      return const Center(
        child: CircularProgressIndicator(color: EduStreakTheme.primaryViolet),
      );
    }

    final spendableBalance = currentUser.spendablePoints;

    return Container(
      color: EduStreakTheme.studentDarkBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Balance Card (Fixed at top)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                _buildBalanceCard(currentUser, spendableBalance),
                const SizedBox(height: 16),
                _buildTabBar(),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Tab Views (Store / Inventory)
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildStoreTab(currentUser, spendableBalance),
                _buildInventoryTab(currentUser),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── PAGE HEADER ────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFF10B981).withValues(alpha: 0.4),
              width: 1.2,
            ),
          ),
          child: const Icon(Icons.storefront_rounded, color: Color(0xFF10B981), size: 22),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Avatar & Badge Store 🛍️',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 2),
              Text(
                'Redeem exclusive avatars, frames, and badges with your earned points!',
                style: TextStyle(
                  color: EduStreakTheme.studentDarkTextMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── SPENDABLE XP & LIFETIME BALANCE CARD ───────────────────────────────
  Widget _buildBalanceCard(UserModel user, int spendableBalance) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1F1247), Color(0xFF120C2E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: EduStreakTheme.primaryViolet.withValues(alpha: 0.4),
          width: 1.2,
        ),
      ),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 400;

              final spendableWidget = Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBBF24).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.stars_rounded, color: Color(0xFFFBBF24), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Spendable Balance',
                          style: TextStyle(
                            color: EduStreakTheme.studentDarkTextMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '$spendableBalance Pts',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              );

              final lifetimeWidget = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Level ${user.level} Scholar',
                    style: const TextStyle(
                      color: Color(0xFF35C9FF),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${user.xp} Lifetime XP',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              );

              if (isCompact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    spendableWidget,
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: Color(0x20FFFFFF)),
                    const SizedBox(height: 12),
                    lifetimeWidget,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: spendableWidget),
                  Container(width: 1, height: 36, color: Colors.white.withValues(alpha: 0.12)),
                  const SizedBox(width: 16),
                  Expanded(child: lifetimeWidget),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.shield_outlined, size: 14, color: Color(0xFF10B981)),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Purchases only deduct Spendable Points. Your Lifetime XP and Level never decrease.',
                    style: TextStyle(
                      color: EduStreakTheme.studentDarkTextMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
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

  // ─── TAB BAR ────────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: EduStreakTheme.studentDarkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: EduStreakTheme.studentDarkBorder),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: EduStreakTheme.primaryViolet,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: EduStreakTheme.studentDarkTextMuted,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        tabs: const [
          Tab(text: 'Store Items'),
          Tab(text: 'My Inventory'),
        ],
      ),
    );
  }

  // ─── TAB 1: STORE TAB ───────────────────────────────────────────────────
  Widget _buildStoreTab(UserModel user, int spendableBalance) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStoreFilterPills(),
          const SizedBox(height: 14),
          StreamBuilder<List<StoreItemModel>>(
            stream: _storeService.getStoreItems(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: EduStreakTheme.primaryViolet),
                  ),
                );
              }

              final items = snapshot.data ?? StoreItemModel.getDefaultItems();
              final filtered = items.where((i) {
                if (_storeFilter == 'All') return true;
                if (_storeFilter == 'Avatars') return i.type == 'avatar';
                if (_storeFilter == 'Badges') return i.type == 'badge';
                return true;
              }).toList();

              if (filtered.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('No store items available in this category.',
                        style: TextStyle(color: EduStreakTheme.studentDarkTextMuted)),
                  ),
                );
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth > 900
                      ? 3
                      : (constraints.maxWidth > 550 ? 2 : 1);
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisExtent: 205,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      final isOwned = user.purchasedItems.contains(item.id);
                      final isEquipped = user.currentAvatar == item.id;
                      final canAfford = spendableBalance >= item.pointsCost;

                      return _buildStoreItemCard(
                        item: item,
                        user: user,
                        isOwned: isOwned,
                        isEquipped: isEquipped,
                        canAfford: canAfford,
                        spendableBalance: spendableBalance,
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStoreFilterPills() {
    final filters = ['All', 'Avatars', 'Badges'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final isSelected = _storeFilter == f;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(f),
              selected: isSelected,
              onSelected: (_) => setState(() => _storeFilter = f),
              backgroundColor: EduStreakTheme.studentDarkCard,
              selectedColor: EduStreakTheme.primaryViolet,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : EduStreakTheme.studentDarkTextMuted,
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
              side: BorderSide(
                color: isSelected ? EduStreakTheme.primaryViolet : EduStreakTheme.studentDarkBorder,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStoreItemCard({
    required StoreItemModel item,
    required UserModel user,
    required bool isOwned,
    required bool isEquipped,
    required bool canAfford,
    required int spendableBalance,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EduStreakTheme.studentDarkCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isEquipped
              ? const Color(0xFF10B981)
              : (isOwned
                  ? EduStreakTheme.primaryViolet.withValues(alpha: 0.5)
                  : EduStreakTheme.studentDarkBorder),
          width: isEquipped ? 1.6 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: EduStreakTheme.primaryViolet.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(item.icon, style: const TextStyle(fontSize: 26)),
                ),
              ),
              const Spacer(),
              if (isEquipped)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('Equipped',
                      style: TextStyle(color: Color(0xFF34D399), fontSize: 11, fontWeight: FontWeight.w700)),
                )
              else if (isOwned)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: EduStreakTheme.primaryViolet.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('Owned',
                      style: TextStyle(color: Color(0xFFDDD2F9), fontSize: 11, fontWeight: FontWeight.w700)),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBBF24).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFBBF24).withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.stars_rounded, size: 14, color: Color(0xFFFBBF24)),
                      const SizedBox(width: 4),
                      Text(
                        '${item.pointsCost} Pts',
                        style: const TextStyle(
                          color: Color(0xFFFBBF24),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
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
                item.name,
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                item.description,
                style: const TextStyle(color: EduStreakTheme.studentDarkTextMuted, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          SizedBox(
            width: double.infinity,
            child: isEquipped
                ? OutlinedButton(
                    onPressed: null,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF10B981),
                      side: const BorderSide(color: Color(0xFF10B981)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: const Text('Active Avatar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  )
                : (isOwned
                    ? ElevatedButton(
                        onPressed: _isProcessing ? null : () => _handleEquip(user.id, item.id),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: EduStreakTheme.primaryViolet,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: const Text('Equip Avatar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      )
                    : ElevatedButton(
                        onPressed: (!canAfford || _isProcessing)
                            ? null
                            : () => _showPurchaseDialog(user.id, item, spendableBalance),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.white.withValues(alpha: 0.08),
                          disabledForegroundColor: EduStreakTheme.studentDarkTextMuted,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: Text(
                          canAfford ? 'Redeem Item' : 'Need ${item.pointsCost - spendableBalance} Pts',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      )),
          ),
        ],
      ),
    );
  }

  // ─── TAB 2: INVENTORY TAB ───────────────────────────────────────────────
  Widget _buildInventoryTab(UserModel user) {
    final purchased = user.purchasedItems;
    final defaultAvatars = StoreItemModel.getDefaultItems();

    // Collect all owned items: default avatar_1 + purchased items
    final ownedItems = <StoreItemModel>[];
    for (var def in defaultAvatars) {
      if (def.id == 'avatar_1' || purchased.contains(def.id)) {
        ownedItems.add(def);
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Unlocked Avatars & Badges',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Select any avatar from your collection to equip it on your profile across EduStreak.',
            style: TextStyle(color: EduStreakTheme.studentDarkTextMuted, fontSize: 13),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 800 ? 3 : (constraints.maxWidth > 500 ? 2 : 1);
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisExtent: 185,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                ),
                itemCount: ownedItems.length,
                itemBuilder: (context, index) {
                  final item = ownedItems[index];
                  final isEquipped = (user.currentAvatar == item.id) ||
                      (user.currentAvatar == null && item.id == 'avatar_1');

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: EduStreakTheme.studentDarkCard,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isEquipped ? const Color(0xFF10B981) : EduStreakTheme.studentDarkBorder,
                        width: isEquipped ? 1.8 : 1.2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(item.icon, style: const TextStyle(fontSize: 32)),
                            const Spacer(),
                            if (isEquipped)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_circle_rounded, color: Color(0xFF34D399), size: 14),
                                    SizedBox(width: 4),
                                    Text('Equipped',
                                        style: TextStyle(
                                            color: Color(0xFF34D399), fontSize: 11, fontWeight: FontWeight.w700)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.name,
                                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text(item.description,
                                style: const TextStyle(color: EduStreakTheme.studentDarkTextMuted, fontSize: 12)),
                          ],
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: (isEquipped || _isProcessing)
                                ? null
                                : () => _handleEquip(user.id, item.id),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isEquipped
                                  ? const Color(0xFF10B981).withValues(alpha: 0.2)
                                  : EduStreakTheme.primaryViolet,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.white.withValues(alpha: 0.05),
                              disabledForegroundColor: const Color(0xFF34D399),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            child: Text(
                              isEquipped ? 'Active Avatar' : 'Equip Avatar',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // ─── ACTIONS: EQUIP & PURCHASE ──────────────────────────────────────────
  Future<void> _handleEquip(String userId, String itemId) async {
    setState(() => _isProcessing = true);
    try {
      await _storeService.setCurrentAvatar(userId, itemId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✨ Avatar equipped successfully!'),
            backgroundColor: Color(0xFF10B981),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to equip: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _showPurchaseDialog(String userId, StoreItemModel item, int balance) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: EduStreakTheme.studentDarkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Text(item.icon, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Redeem ${item.name}',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.description,
              style: const TextStyle(color: EduStreakTheme.studentDarkTextMuted, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Item Cost:', style: TextStyle(color: EduStreakTheme.studentDarkTextMuted, fontSize: 13)),
                      Text('${item.pointsCost} Pts', style: const TextStyle(color: Color(0xFFFBBF24), fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Current Balance:', style: TextStyle(color: EduStreakTheme.studentDarkTextMuted, fontSize: 13)),
                      Text('$balance Pts', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const Divider(color: Colors.white12, height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Remaining Balance:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                      Text('${balance - item.pointsCost} Pts', style: const TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.w800)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: EduStreakTheme.studentDarkTextMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Confirm Purchase'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isProcessing = true);
      try {
        await _storeService.purchaseItem(userId, item.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🎉 Successfully redeemed ${item.name}!'),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Purchase failed: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
    }
  }
}
