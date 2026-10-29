import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/badge_model.dart';
import '../services/store_service.dart';
import '../utils/theme.dart';

class BadgeDisplay extends StatelessWidget {
  final String userId;
  final List<String>? badges; // Optional - for backward compatibility

  const BadgeDisplay({super.key, required this.userId, this.badges});

  @override
  Widget build(BuildContext context) {
    // Use StreamBuilder to get real-time badge updates from Firestore
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
      builder: (context, userSnapshot) {
        List<String> userBadges = [];
        List<String> redeemedAvatars = [];
        
        if (userSnapshot.hasData && userSnapshot.data!.exists) {
          final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
          final badgesData = userData?['badges'];
          
          // Get earned badges (from achievements)
          if (badgesData != null) {
            if (badgesData is List) {
              // Badges stored as List<String>
              userBadges = List<String>.from(badgesData);
            } else if (badgesData is Map) {
              // Badges stored as Map<String, bool> (legacy format)
              final badgesMap = Map<String, dynamic>.from(badgesData);
              userBadges = badgesMap.entries
                  .where((entry) => entry.value == true)
                  .map((entry) => entry.key)
                  .toList();
            }
          }
          
          // Get redeemed avatars
          final avatarsData = userData?['redeemedAvatars'];
          if (avatarsData != null) {
            if (avatarsData is List) {
              redeemedAvatars = List<String>.from(avatarsData);
            } else if (avatarsData is Map) {
              final avatarsMap = Map<String, dynamic>.from(avatarsData);
              redeemedAvatars = avatarsMap.entries
                  .where((entry) => entry.value == true)
                  .map((entry) => entry.key)
                  .toList();
            }
          }
        } else if (badges != null) {
          // Fallback to provided badges list for backward compatibility
          userBadges = badges!;
        }

        // Get default badges (earned through achievements)
        final defaultBadges = BadgeModel.getDefaultBadges();
        final earnedDefaultBadges = defaultBadges.where((b) => userBadges.contains(b.id)).toList();

        // Get store badges and redeemed store badges
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: StoreService().getBadges(),
          builder: (context, storeBadgesSnapshot) {
            List<Map<String, dynamic>> redeemedStoreBadges = [];
            
            if (storeBadgesSnapshot.hasData) {
              final storeBadges = storeBadgesSnapshot.data!;
              // Filter to only show redeemed store badges
              redeemedStoreBadges = storeBadges.where((badge) {
                final badgeId = badge['badgeId'] as String? ?? '';
                return userBadges.contains(badgeId);
              }).toList();
            }

            // Get redeemed avatars from store
            return StreamBuilder<List<Map<String, dynamic>>>(
              stream: StoreService().getAvatars(),
              builder: (context, avatarsSnapshot) {
                List<Map<String, dynamic>> redeemedStoreAvatars = [];
                
                if (avatarsSnapshot.hasData) {
                  final storeAvatars = avatarsSnapshot.data!;
                  // Filter to only show redeemed avatars
                  redeemedStoreAvatars = storeAvatars.where((avatar) {
                    final avatarId = avatar['avatarId'] as String? ?? '';
                    return redeemedAvatars.contains(avatarId);
                  }).toList();
                }

                final allEarnedBadges = earnedDefaultBadges.length + redeemedStoreBadges.length;
                final allRedeemedItems = allEarnedBadges + redeemedStoreAvatars.length;

                if (allRedeemedItems == 0) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        'No badges or avatars yet.\nComplete tasks and challenges to earn badges!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.textTertiary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Earned Achievement Badges
                    if (earnedDefaultBadges.isNotEmpty) ...[
                      Text(
                        'Achievement Badges (${earnedDefaultBadges.length})',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 140,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: earnedDefaultBadges.length,
                          itemBuilder: (context, index) {
                            final badge = earnedDefaultBadges[index];
                            return _buildBadgeCard(context, badge, true);
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    // Redeemed Store Badges
                    if (redeemedStoreBadges.isNotEmpty) ...[
                      Text(
                        'Redeemed Badges (${redeemedStoreBadges.length})',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 140,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: redeemedStoreBadges.length,
                          itemBuilder: (context, index) {
                            final badge = redeemedStoreBadges[index];
                            return _buildStoreBadgeCard(context, badge, true);
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    // Redeemed Avatars
                    if (redeemedStoreAvatars.isNotEmpty) ...[
                      Text(
                        'Redeemed Avatars (${redeemedStoreAvatars.length})',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 140,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: redeemedStoreAvatars.length,
                          itemBuilder: (context, index) {
                            final avatar = redeemedStoreAvatars[index];
                            return _buildAvatarCard(context, avatar, true);
                          },
                        ),
                      ),
                    ],
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildBadgeCard(BuildContext context, BadgeModel badge, bool earned) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      child: Container(
        decoration: BoxDecoration(
          gradient: earned 
              ? AppTheme.darkCardGradient 
              : LinearGradient(
                  colors: [
                    AppTheme.darkSurfaceVariant.withOpacity(0.3),
                    AppTheme.darkSurfaceVariant.withOpacity(0.1),
                  ],
                ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: earned 
                ? AppTheme.primaryColor.withOpacity(0.4)
                : AppTheme.darkBorder.withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: earned 
              ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: 0,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: earned 
                      ? AppTheme.primaryGradient 
                      : null,
                  shape: BoxShape.circle,
                  color: earned ? null : AppTheme.darkBorder.withOpacity(0.2),
                ),
                child: Text(
                  badge.icon,
                  style: TextStyle(
                    fontSize: 40,
                    color: earned ? null : AppTheme.textTertiary,
                  ),
                )
                    .animate(target: earned ? 1 : 0)
                    .shimmer(
                      duration: 2000.ms,
                      color: AppTheme.primaryGlow.withOpacity(0.6),
                    )
                    .then()
                    .scale(
                      begin: const Offset(1.0, 1.0),
                      end: const Offset(1.1, 1.1),
                      duration: 800.ms,
                      curve: Curves.easeInOut,
                    )
                    .then()
                    .scale(
                      begin: const Offset(1.1, 1.1),
                      end: const Offset(1.0, 1.0),
                      duration: 800.ms,
                      curve: Curves.easeInOut,
                    ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: Text(
                  badge.name,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: earned ? AppTheme.textPrimary : AppTheme.textTertiary,
                        letterSpacing: 0.3,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoreBadgeCard(BuildContext context, Map<String, dynamic> badge, bool earned) {
    final name = badge['name'] as String? ?? 'Unknown Badge';
    final icon = badge['iconUrl'] as String? ?? badge['icon'] as String? ?? '🏆';
    final description = badge['description'] as String? ?? '';
    
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      child: Container(
        decoration: BoxDecoration(
          gradient: earned 
              ? AppTheme.darkCardGradient 
              : LinearGradient(
                  colors: [
                    AppTheme.darkSurfaceVariant.withOpacity(0.3),
                    AppTheme.darkSurfaceVariant.withOpacity(0.1),
                  ],
                ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: earned 
                ? AppTheme.accentColor.withOpacity(0.4)
                : AppTheme.darkBorder.withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: earned 
              ? [
                  BoxShadow(
                    color: AppTheme.accentColor.withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: 0,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: earned 
                      ? AppTheme.accentGradient 
                      : null,
                  shape: BoxShape.circle,
                  color: earned ? null : AppTheme.darkBorder.withOpacity(0.2),
                ),
                child: icon.startsWith('http') || icon.startsWith('https')
                    ? Icon(
                        Icons.workspace_premium, 
                        size: 40, 
                        color: earned ? Colors.white : AppTheme.textTertiary,
                      )
                    : Text(
                        icon,
                        style: TextStyle(
                          fontSize: 40,
                          color: earned ? null : AppTheme.textTertiary,
                        ),
                      )
                        .animate(target: earned ? 1 : 0)
                        .shimmer(
                          duration: 2000.ms,
                          color: AppTheme.accentGlow.withOpacity(0.6),
                        ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: Text(
                  name,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: earned ? AppTheme.textPrimary : AppTheme.textTertiary,
                        letterSpacing: 0.3,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarCard(BuildContext context, Map<String, dynamic> avatar, bool earned) {
    final name = avatar['name'] as String? ?? 'Unknown Avatar';
    final icon = avatar['icon'] as String? ?? avatar['iconUrl'] as String? ?? '👤';
    
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      child: Container(
        decoration: BoxDecoration(
          gradient: earned 
              ? AppTheme.darkCardGradient 
              : LinearGradient(
                  colors: [
                    AppTheme.darkSurfaceVariant.withOpacity(0.3),
                    AppTheme.darkSurfaceVariant.withOpacity(0.1),
                  ],
                ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: earned 
                ? AppTheme.secondaryColor.withOpacity(0.4)
                : AppTheme.darkBorder.withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: earned 
              ? [
                  BoxShadow(
                    color: AppTheme.secondaryColor.withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: 0,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: earned 
                      ? AppTheme.primaryGradient 
                      : null,
                  shape: BoxShape.circle,
                  color: earned ? null : AppTheme.darkBorder.withOpacity(0.2),
                ),
                child: icon.startsWith('http') || icon.startsWith('https')
                    ? Icon(
                        Icons.person, 
                        size: 40, 
                        color: earned ? Colors.white : AppTheme.textTertiary,
                      )
                    : Text(
                        icon,
                        style: TextStyle(
                          fontSize: 40,
                          color: earned ? null : AppTheme.textTertiary,
                        ),
                      )
                        .animate(target: earned ? 1 : 0)
                        .shimmer(
                          duration: 2000.ms,
                          color: AppTheme.secondaryGlow.withOpacity(0.6),
                        ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: Text(
                  name,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: earned ? AppTheme.textPrimary : AppTheme.textTertiary,
                        letterSpacing: 0.3,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

