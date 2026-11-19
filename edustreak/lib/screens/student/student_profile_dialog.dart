import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/user_provider.dart';
import '../../services/auth_service.dart';
import '../../services/store_service.dart';
import '../../models/user_model.dart';
import '../../models/store_item_model.dart';
import '../../utils/edustreak_theme.dart';

/// Comprehensive student profile dialog showing real-time academic records,
/// gamification status, avatar customizer, and account controls.
class StudentProfileDialog extends StatefulWidget {
  final UserModel user;

  const StudentProfileDialog({super.key, required this.user});

  static Future<void> show(BuildContext context, UserModel user) {
    return showDialog(
      context: context,
      builder: (context) => StudentProfileDialog(user: user),
    );
  }

  @override
  State<StudentProfileDialog> createState() => _StudentProfileDialogState();
}

class _StudentProfileDialogState extends State<StudentProfileDialog> {
  late final StoreService _storeService = StoreService();
  bool _isEditing = false;
  late TextEditingController _nameController;
  late TextEditingController _rollController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _rollController = TextEditingController(text: widget.user.rollNumber ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rollController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.user.id).update({
        'name': _nameController.text.trim(),
        if (_rollController.text.trim().isNotEmpty)
          'rollNumber': _rollController.text.trim(),
      });

      // Update provider user
      if (mounted) {
        final prov = Provider.of<UserProvider>(context, listen: false);
        await prov.fetchUser(widget.user.id);
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Profile updated successfully!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _logout() async {
    Navigator.pop(context);
    await AuthService().signOut();
    if (mounted) {
      Provider.of<UserProvider>(context, listen: false).clearUser();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).currentUser ?? widget.user;
    final spendable = user.spendablePoints;
    final currentAvatarId = user.currentAvatar ?? 'avatar_1';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 720),
        decoration: BoxDecoration(
          color: EduStreakTheme.studentDarkBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: EduStreakTheme.studentDarkBorder, width: 1.4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header Bar
            _buildDialogHeader(),
            const Divider(height: 1, color: EduStreakTheme.studentDarkBorder),

            // Content Scroll
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar & Main Student Info Card
                    _buildIdentityHeader(user, currentAvatarId),
                    const SizedBox(height: 18),

                    // Gamification Metrics Grid
                    _buildGamificationGrid(user, spendable),
                    const SizedBox(height: 20),

                    // Academic & Enrollment Info
                    _buildEnrollmentSection(user),
                    const SizedBox(height: 20),

                    // Avatar Customizer Strip
                    _buildAvatarSelector(user, currentAvatarId),
                  ],
                ),
              ),
            ),

            // Footer Actions
            const Divider(height: 1, color: EduStreakTheme.studentDarkBorder),
            _buildDialogFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: EduStreakTheme.primaryViolet.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_rounded, color: EduStreakTheme.primaryViolet, size: 20),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Student Profile',
              style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded, color: EduStreakTheme.studentDarkTextMuted, size: 20),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }

  Widget _buildIdentityHeader(UserModel user, String currentAvatarId) {
    final avatarItem = StoreItemModel.getDefaultItems().firstWhere(
      (i) => i.id == currentAvatarId,
      orElse: () => StoreItemModel.getDefaultItems().first,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EduStreakTheme.studentDarkCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: EduStreakTheme.studentDarkBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7950FF), Color(0xFF35C9FF)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7950FF).withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Text(avatarItem.icon, style: const TextStyle(fontSize: 30)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isEditing)
                  TextField(
                    controller: _nameController,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                    decoration: InputDecoration(
                      isDense: true,
                      labelText: 'Full Name',
                      labelStyle: const TextStyle(color: EduStreakTheme.primaryViolet, fontSize: 13),
                      filled: true,
                      fillColor: EduStreakTheme.studentDarkBg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  )
                else
                  Text(
                    user.name,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: const TextStyle(color: EduStreakTheme.studentDarkTextMuted, fontSize: 12.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: EduStreakTheme.primaryViolet.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'STUDENT • ${user.grade != null ? "CLASS ${user.grade}" : (user.classId ?? "ENROLLED")}${user.section != null ? " - SEC ${user.section}" : ""}',
                    style: const TextStyle(
                      color: Color(0xFFDDD2F9),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
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

  Widget _buildGamificationGrid(UserModel user, int spendable) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 400 ? 3 : 2;
        final items = [
          _buildStatCard('Current Level', 'Level ${user.level}', Icons.military_tech_rounded, const Color(0xFFFBBF24)),
          _buildStatCard('Lifetime XP', '${user.xp} XP', Icons.bolt_rounded, const Color(0xFF38BDF8)),
          _buildStatCard('Spendable Pts', '$spendable Pts', Icons.stars_rounded, const Color(0xFF10B981)),
          _buildStatCard('Active Streak', '${user.streakCount} Days', Icons.local_fire_department_rounded, const Color(0xFFF97316)),
          _buildStatCard('Best Streak', '${user.highestStreak} Days', Icons.emoji_events_rounded, const Color(0xFFA855F7)),
          _buildStatCard('Badges Earned', '${user.badges.length}', Icons.military_tech_outlined, const Color(0xFFEC4899)),
        ];

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            mainAxisExtent: 74,
          ),
          itemCount: items.length,
          itemBuilder: (ctx, idx) => items[idx],
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: EduStreakTheme.studentDarkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: EduStreakTheme.studentDarkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(color: EduStreakTheme.studentDarkTextMuted, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildEnrollmentSection(UserModel user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EduStreakTheme.studentDarkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EduStreakTheme.studentDarkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Academic & Institutional Details',
            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          _buildDetailRow('School Code:', user.schoolCode ?? user.schoolId ?? 'Not Assigned'),
          _buildDetailRow('Admission Number:', user.admissionNumber ?? user.id.substring(0, user.id.length > 8 ? 8 : user.id.length)),
          _buildDetailRow('Roll Number:', _isEditing ? null : (user.rollNumber ?? 'Not Assigned'),
              customWidget: _isEditing
                  ? ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 100),
                      child: TextField(
                        controller: _rollController,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          filled: true,
                          fillColor: EduStreakTheme.studentDarkBg,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    )
                  : null),
          _buildDetailRow('Academic Year:', user.academicYear ?? '2026-2027'),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value, {Widget? customWidget}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: const TextStyle(color: EduStreakTheme.studentDarkTextMuted, fontSize: 12.5),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: customWidget ??
                Text(
                  value ?? '',
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarSelector(UserModel user, String currentAvatarId) {
    final owned = <StoreItemModel>[];
    for (var def in StoreItemModel.getDefaultItems()) {
      if (def.id == 'avatar_1' || user.purchasedItems.contains(def.id)) {
        owned.add(def);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Equip Avatar',
          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: owned.map((item) {
              final isCurrent = currentAvatarId == item.id;
              return GestureDetector(
                onTap: () async {
                  if (!isCurrent) {
                    await _storeService.setCurrentAvatar(user.id, item.id);
                    if (mounted) {
                      final prov = Provider.of<UserProvider>(context, listen: false);
                      await prov.fetchUser(user.id);
                    }
                  }
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? const Color(0xFF10B981).withValues(alpha: 0.2)
                        : EduStreakTheme.studentDarkCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isCurrent ? const Color(0xFF10B981) : EduStreakTheme.studentDarkBorder,
                      width: isCurrent ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(item.icon, style: const TextStyle(fontSize: 28)),
                      const SizedBox(height: 4),
                      Text(
                        isCurrent ? 'Active' : item.name.split(' ').first,
                        style: TextStyle(
                          color: isCurrent ? const Color(0xFF34D399) : EduStreakTheme.studentDarkTextMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDialogFooter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 360;

          final signOutBtn = OutlinedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded, size: 16, color: Colors.redAccent),
            label: const Text('Sign Out', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.redAccent, width: 1.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          );

          final actionBtns = _isEditing
              ? [
                  TextButton(
                    onPressed: () => setState(() => _isEditing = false),
                    child: const Text('Cancel', style: TextStyle(color: EduStreakTheme.studentDarkTextMuted)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    child: const Text('Save Changes', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ]
              : [
                  ElevatedButton.icon(
                    onPressed: () => setState(() => _isEditing = true),
                    icon: const Icon(Icons.edit_rounded, size: 16),
                    label: const Text('Edit Info', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: EduStreakTheme.primaryViolet,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                  ),
                ];

          if (isNarrow) {
            return Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                signOutBtn,
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: actionBtns,
                ),
              ],
            );
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              signOutBtn,
              Row(
                mainAxisSize: MainAxisSize.min,
                children: actionBtns,
              ),
            ],
          );
        },
      ),
    );
  }
}
