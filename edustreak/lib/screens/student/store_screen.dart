import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../models/store_item_model.dart';
import '../../services/store_service.dart';
import '../../services/badge_service.dart';
import '../../services/avatar_service.dart';
import '../../utils/theme.dart';
import '../../widgets/app_logo.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _refreshKey = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  void _refreshAvatars() {
    setState(() {
      _refreshKey++;
    });
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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: AppLogo(size: 28),
        ),
        leadingWidth: 64,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            boxShadow: AppTheme.primaryGlowShadow,
          ),
        ),
        foregroundColor: Colors.white,
        title: const Text('Points Store'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.face), text: 'Avatars'),
            Tab(icon: Icon(Icons.workspace_premium), text: 'Badges'),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(Icons.star, color: Colors.orange),
                const SizedBox(width: 4),
                Text(
                  '${currentUser.xp < 0 ? 0 : currentUser.xp}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildItemsTab(currentUser),
          _buildBadgesTab(currentUser),
        ],
      ),
    );
  }

  Widget _buildItemsTab(currentUser) {
    final avatarService = AvatarService();
    
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: StoreService().getAvatars(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.face, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No Avatars Available',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Initialize avatars to start redeeming them with points!',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        // Show loading
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Row(
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                  SizedBox(width: 16),
                                  Text('Initializing avatars...'),
                                ],
                              ),
                              duration: Duration(seconds: 30),
                            ),
                          );
                        }

                        await AvatarService.uploadAvatarsToFirestore();
                        
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✅ Avatars initialized successfully!'),
                              backgroundColor: Colors.green,
                              duration: Duration(seconds: 3),
                            ),
                          );
                          // Refresh the screen
                          setState(() {});
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          String errorMessage = 'Error initializing avatars';
                          
                          if (e.toString().contains('permission') || 
                              e.toString().contains('Permission')) {
                            errorMessage = 'Permission denied. Please contact admin to initialize avatars.';
                          } else if (e.toString().contains('assets')) {
                            errorMessage = 'Avatar data file not found. Please check app configuration.';
                          } else {
                            errorMessage = 'Error: ${e.toString()}';
                          }
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(errorMessage),
                              backgroundColor: Colors.red,
                              duration: const Duration(seconds: 5),
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.cloud_upload),
                    label: const Text('Initialize Avatars'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'This will upload 30 motivational avatars to the store.\nYou can redeem them with points!',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final avatars = snapshot.data!;
        
        // Get user's redeemed avatars
        return FutureBuilder<Map<String, bool>>(
          key: ValueKey('avatars_$_refreshKey'),
          future: avatarService.getUserAvatars(currentUser.id),
          builder: (context, userAvatarsSnapshot) {
            final userAvatars = userAvatarsSnapshot.data ?? {};
            // Ensure points are not negative (fix any data issues)
            final userPoints = currentUser.xp < 0 ? 0 : currentUser.xp;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 280,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 0.6,
                  ),
                  itemCount: avatars.length,
              itemBuilder: (context, index) {
                final avatar = avatars[index];
                final avatarId = avatar['avatarId'] as String? ?? '';
                final name = avatar['name'] as String? ?? 'Unknown';
                final description = avatar['description'] as String? ?? '';
                final price = (avatar['price'] as num?)?.toInt() ?? 0;
                final category = avatar['category'] as String? ?? '';
                final icon = avatar['icon'] as String? ?? '👤';
                final isRedeemed = userAvatars[avatarId] == true;
                final isCurrentAvatar = currentUser.currentAvatar == avatarId;
                final canAfford = userPoints >= price;

                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: isCurrentAvatar
                          ? Border.all(color: Colors.blue, width: 3)
                          : isRedeemed
                              ? Border.all(color: Colors.green, width: 2)
                              : null,
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: isRedeemed
                          ? () => _setAsAvatarFromRedeemed(context, avatarId)
                          : canAfford
                              ? () => _redeemAvatar(context, avatarId, name, price, userPoints)
                              : null,
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              // Avatar Icon
                              Container(
                                width: 65,
                                height: 65,
                                decoration: BoxDecoration(
                                  color: isCurrentAvatar
                                      ? Colors.blue[100]
                                      : isRedeemed
                                          ? Colors.green[100]
                                          : Colors.orange[100],
                                  borderRadius: BorderRadius.circular(32.5),
                                  border: isCurrentAvatar
                                      ? Border.all(color: Colors.blue, width: 3)
                                      : isRedeemed
                                          ? Border.all(color: Colors.green, width: 2)
                                          : null,
                                ),
                                child: Center(
                                  child: Text(
                                    icon,
                                    style: const TextStyle(
                                      fontSize: 36,
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              // Name
                              Text(
                                name,
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              // Description
                              Text(
                                description,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                      fontSize: 10,
                                    ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              // Category
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.purple[50],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  category,
                                  style: TextStyle(
                                    fontSize: 8,
                                    color: Colors.purple[700],
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(height: 6),
                              // Points Cost
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange[100],
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.star, size: 12, color: Colors.orange),
                                    const SizedBox(width: 2),
                                    Text(
                                      '$price',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 5),
                              // Action Button
                              if (isCurrentAvatar)
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.check, color: Colors.white, size: 12),
                                      SizedBox(width: 3),
                                      Text(
                                        'Active',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                )
                              else if (isRedeemed)
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    onPressed: () => _setAsAvatarFromRedeemed(context, avatarId),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.green,
                                      padding: const EdgeInsets.symmetric(vertical: 5),
                                      side: const BorderSide(color: Colors.green, width: 2),
                                      minimumSize: const Size(0, 30),
                                    ),
                                    child: const Text(
                                      'Set as Avatar',
                                      style: TextStyle(fontSize: 10),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                              else if (canAfford)
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () => _redeemAvatar(context, avatarId, name, price, userPoints),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      padding: const EdgeInsets.symmetric(vertical: 5),
                                      minimumSize: const Size(0, 30),
                                    ),
                                    child: const Text(
                                      'Redeem',
                                      style: TextStyle(fontSize: 10),
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.lock, size: 11),
                                      SizedBox(width: 3),
                                      Text(
                                        'Not enough points',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 9,
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
                      ),
                    ),
                  ),
                );
              },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBadgesTab(currentUser) {
    final badgeService = BadgeService();
    
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: StoreService().getBadges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.workspace_premium, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('No badges available'),
                const SizedBox(height: 8),
                const Text(
                  'Badges need to be uploaded by admin first.',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final badges = snapshot.data!;
        
        // Get user's redeemed badges
        return FutureBuilder<Map<String, bool>>(
          future: badgeService.getUserBadges(currentUser.id),
          builder: (context, userBadgesSnapshot) {
            final userBadges = userBadgesSnapshot.data ?? {};
            // Ensure points are not negative (fix any data issues)
            final userPoints = currentUser.xp < 0 ? 0 : currentUser.xp;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 280,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.68,
                  ),
                  itemCount: badges.length,
              itemBuilder: (context, index) {
                final badge = badges[index];
                final badgeId = badge['badgeId'] as String? ?? '';
                final name = badge['name'] as String? ?? 'Unknown';
                final description = badge['description'] as String? ?? '';
                final price = (badge['price'] as num?)?.toInt() ?? 0;
                final category = badge['category'] as String? ?? '';
                final isRedeemed = userBadges[badgeId] == true;
                final canAfford = userPoints >= price;

                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: isRedeemed
                          ? Border.all(color: Colors.green, width: 3)
                          : null,
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: isRedeemed
                          ? null
                          : canAfford
                              ? () => _redeemBadge(context, badgeId, name, price, userPoints)
                              : null,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            // Badge Icon
                            Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                color: isRedeemed
                                    ? Colors.green[100]
                                    : Colors.orange[100],
                                borderRadius: BorderRadius.circular(35),
                                border: isRedeemed
                                    ? Border.all(color: Colors.green, width: 3)
                                    : null,
                              ),
                              child: Center(
                                child: Icon(
                                  isRedeemed ? Icons.check_circle : Icons.workspace_premium,
                                  size: 40,
                                  color: isRedeemed ? Colors.green : Colors.orange,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Name
                            Flexible(
                              child: Text(
                                name,
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Description
                            Flexible(
                              child: Text(
                                description,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                      fontSize: 11,
                                    ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Category
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                category,
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Points Cost
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange[100],
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star, size: 14, color: Colors.orange),
                                  const SizedBox(width: 2),
                                  Text(
                                    '$price',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            // Action Button
                            if (isRedeemed)
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check, color: Colors.white, size: 14),
                                    SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        'Redeemed',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else if (canAfford)
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () => _redeemBadge(context, badgeId, name, price, userPoints),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                  ),
                                  child: const Text(
                                    'Redeem',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.lock, size: 12),
                                    SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        'Not enough points',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _redeemBadge(
    BuildContext context,
    String badgeId,
    String badgeName,
    int price,
    int currentPoints,
  ) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.currentUser;

    if (currentUser == null) return;

    // Ensure points are not negative
    final safePoints = currentPoints < 0 ? 0 : currentPoints;

    if (safePoints < price) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Insufficient points. Need $price, have $safePoints'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Redeem $badgeName?'),
        content: Text(
          'This will cost $price points. You will have ${safePoints - price} points remaining.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Redeem'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final badgeService = BadgeService();
      await badgeService.redeemBadge(currentUser.id, badgeId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$badgeName redeemed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh user data
        userProvider.loadUser(currentUser.id);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _purchaseItem(
    BuildContext context,
    StoreItemModel item,
    int currentPoints,
  ) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.currentUser;

    if (currentUser == null) return;

    if (currentPoints < item.pointsCost) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Insufficient points. Need ${item.pointsCost}, have $currentPoints'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Purchase ${item.name}?'),
        content: Text(
          'This will cost ${item.pointsCost} points. You will have ${currentPoints - item.pointsCost} points remaining.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Purchase'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await StoreService().purchaseItem(currentUser.id, item.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.name} purchased successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _setAsAvatar(BuildContext context, String itemId) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.currentUser;

    if (currentUser == null) return;

    try {
      await StoreService().setCurrentAvatar(currentUser.id, itemId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Avatar updated!'),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh user data
        userProvider.loadUser(currentUser.id);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _redeemAvatar(
    BuildContext context,
    String avatarId,
    String avatarName,
    int price,
    int currentPoints,
  ) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.currentUser;

    if (currentUser == null) return;

    // Ensure points are not negative
    final safePoints = currentPoints < 0 ? 0 : currentPoints;

    if (safePoints < price) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Insufficient points. Need $price, have $safePoints'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Redeem $avatarName?'),
        content: Text(
          'This will cost $price points. You will have ${safePoints - price} points remaining.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Redeem'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final avatarService = AvatarService();
      await avatarService.redeemAvatar(currentUser.id, avatarId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$avatarName redeemed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh user data and avatars
        await userProvider.loadUser(currentUser.id);
        if (mounted) {
          _refreshAvatars();
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _setAsAvatarFromRedeemed(BuildContext context, String avatarId) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.currentUser;

    if (currentUser == null) return;

    try {
      await StoreService().setCurrentAvatarFromRedeemed(currentUser.id, avatarId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Avatar updated!'),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh user data
        await userProvider.loadUser(currentUser.id);
        if (mounted) {
          _refreshAvatars();
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

