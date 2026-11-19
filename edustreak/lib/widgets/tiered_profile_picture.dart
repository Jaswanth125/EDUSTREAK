import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/tier_system.dart';
import '../utils/theme.dart';
import '../models/user_model.dart';
import '../services/store_service.dart';

/// Profile picture widget with tier-based borders
/// Shows avatar if available, otherwise shows initial
class TieredProfilePicture extends StatelessWidget {
  final UserModel user;
  final double size;
  final bool showTierBorder;

  const TieredProfilePicture({
    super.key,
    required this.user,
    this.size = 56.0,
    this.showTierBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final tier = TierSystem.getTier(user.xp);
    
    // Get avatar display
    Widget avatarWidget = _buildAvatarWidget(tier);
    
    if (showTierBorder) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: TierSystem.getTierGradient(tier),
          boxShadow: TierSystem.getTierGlowShadow(tier),
        ),
        padding: EdgeInsets.all(tier.borderWidth),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.darkSurfaceVariant,
          ),
          child: ClipOval(
            child: avatarWidget,
          ),
        ),
      );
    } else {
      return SizedBox(
        width: size,
        height: size,
        child: ClipOval(
          child: avatarWidget,
        ),
      );
    }
  }

  Widget _buildAvatarWidget(TierInfo tier) {
    // If user has a profile image URL, use it
    if (user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty) {
      if (user.profileImageUrl!.startsWith('http') || 
          user.profileImageUrl!.startsWith('https')) {
        return CachedNetworkImage(
          imageUrl: user.profileImageUrl!,
          fit: BoxFit.cover,
          placeholder: (context, url) => _buildPlaceholder(),
          errorWidget: (context, url, error) => _buildPlaceholder(),
        );
      }
    }
    
    // If user has currentAvatar, try to get avatar icon
    if (user.currentAvatar != null && user.currentAvatar!.isNotEmpty) {
      return StreamBuilder<List<Map<String, dynamic>>>(
        stream: StoreService().getAvatars(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final avatars = snapshot.data!;
            final avatar = avatars.firstWhere(
              (a) => (a['avatarId'] as String?) == user.currentAvatar,
              orElse: () => {},
            );
            
            if (avatar.isNotEmpty) {
              final icon = avatar['icon'] as String? ?? avatar['iconUrl'] as String? ?? '';
              if (icon.isNotEmpty) {
                if (icon.startsWith('http') || icon.startsWith('https')) {
                  return CachedNetworkImage(
                    imageUrl: icon,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => _buildPlaceholder(),
                    errorWidget: (context, url, error) => _buildPlaceholder(),
                  );
                } else {
                  // Emoji avatar
                  return Container(
                    color: AppTheme.darkSurfaceVariant,
                    child: Center(
                      child: Text(
                        icon,
                        style: TextStyle(fontSize: size * 0.6),
                      ),
                    ),
                  );
                }
              }
            }
          }
          return _buildPlaceholder();
        },
      );
    }
    
    // Default: show initial
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

