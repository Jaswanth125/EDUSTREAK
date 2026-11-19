import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/theme_provider.dart';
import '../../services/auth_service.dart';
import '../../utils/edustreak_theme.dart';
import '../../widgets/responsive/responsive_dialog.dart';

/// Modal dialog / bottom sheet for Parent profile details, linked children switching,
/// security settings (password change), and app preferences.
class ParentProfileDialog extends StatefulWidget {
  final UserModel? user;
  final UserModel? selectedChild;
  final List<UserModel> children;
  final ValueChanged<UserModel>? onChildSelected;

  const ParentProfileDialog({
    super.key,
    this.user,
    this.selectedChild,
    this.children = const [],
    this.onChildSelected,
  });

  static Future<void> show(
    BuildContext context, {
    UserModel? user,
    UserModel? selectedChild,
    List<UserModel> children = const [],
    ValueChanged<UserModel>? onChildSelected,
  }) {
    return showAdaptiveEduStreakModal<void>(
      context: context,
      maxWidth: 620,
      builder: (ctx) => ParentProfileDialog(
        user: user,
        selectedChild: selectedChild,
        children: children,
        onChildSelected: onChildSelected,
      ),
    );
  }

  @override
  State<ParentProfileDialog> createState() => _ParentProfileDialogState();
}

class _ParentProfileDialogState extends State<ParentProfileDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  AuthService get _authService => AuthService();

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isChangingPassword = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  String? _passwordError;
  String? _passwordSuccess;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleChangePassword() async {
    if (!_formKey.currentState!.validate()) return;

    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() {
        _passwordError = 'New passwords do not match';
        _passwordSuccess = null;
      });
      return;
    }

    setState(() {
      _isChangingPassword = true;
      _passwordError = null;
      _passwordSuccess = null;
    });

    try {
      await _authService.changePassword(
        currentPassword: _currentPasswordController.text.trim(),
        newPassword: _newPasswordController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _isChangingPassword = false;
          _passwordSuccess = 'Password changed successfully!';
          _passwordError = null;
          _currentPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isChangingPassword = false;
          _passwordError = e.toString().replaceAll('Exception:', '').trim();
          _passwordSuccess = null;
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: EduStreakTheme.studentDarkSidebar,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Logout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          'Are you sure you want to sign out of the Parent Portal?',
          style: TextStyle(color: EduStreakTheme.studentDarkTextMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: EduStreakTheme.rosePink,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Logout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      Navigator.of(context).pop(); // Close profile dialog
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context, rootNavigator: true)
            .pushNamedAndRemoveUntil('/login', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final parentName = user?.name.isNotEmpty == true ? user!.name : 'Parent';
    final initialLetter = parentName.isNotEmpty ? parentName[0].toUpperCase() : 'P';

    return Container(
      constraints: const BoxConstraints(maxHeight: 680),
      decoration: BoxDecoration(
        color: EduStreakTheme.studentDarkSidebar,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: EduStreakTheme.studentDarkBorder, width: 1.2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: EduStreakTheme.studentDarkBorder, width: 1)),
            ),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [EduStreakTheme.primaryViolet, EduStreakTheme.secondaryPurple],
                    ),
                    border: Border.all(color: EduStreakTheme.primaryViolet, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      initialLetter,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        parentName,
                        style: EduStreakTheme.fontHeading2(color: Colors.white, weight: FontWeight.w800),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: EduStreakTheme.emeraldGreen.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: EduStreakTheme.emeraldGreen.withValues(alpha: 0.35)),
                          ),
                          child: const Text(
                            'Verified Parent Account',
                            style: TextStyle(
                              color: EduStreakTheme.emeraldGreen,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Close',
                ),
              ],
            ),
          ),

          // Tab Bar
          TabBar(
            controller: _tabController,
            indicatorColor: EduStreakTheme.primaryViolet,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: EduStreakTheme.studentDarkTextMuted,
            labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            tabs: const [
              Tab(icon: Icon(Icons.family_restroom_rounded, size: 18), text: 'Children'),
              Tab(icon: Icon(Icons.security_rounded, size: 18), text: 'Security'),
              Tab(icon: Icon(Icons.tune_rounded, size: 18), text: 'Settings'),
            ],
          ),

          // Tab Content
          Flexible(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildChildrenTab(),
                _buildSecurityTab(),
                _buildSettingsTab(),
              ],
            ),
          ),

          // Footer with Logout
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: EduStreakTheme.studentDarkBorder, width: 1)),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 8,
              children: [
                TextButton.icon(
                  onPressed: _handleLogout,
                  icon: const Icon(Icons.logout_rounded, color: EduStreakTheme.rosePink, size: 18),
                  label: const Text(
                    'Sign Out',
                    style: TextStyle(color: EduStreakTheme.rosePink, fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  'EduStreak v2.4 • Secured',
                  style: EduStreakTheme.fontCaption(color: EduStreakTheme.studentDarkTextMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChildrenTab() {
    final children = widget.children;
    final user = widget.user;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Parent Info
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: EduStreakTheme.studentDarkCardSub,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: EduStreakTheme.studentDarkBorder),
            ),
            child: Column(
              children: [
                _buildDetailRow('Email Address', user?.email ?? 'Not available'),
                const Divider(color: EduStreakTheme.studentDarkBorder, height: 16),
                _buildDetailRow('School Code', user?.schoolCode ?? (user?.schoolId ?? 'Registered Institution')),
                const Divider(color: EduStreakTheme.studentDarkBorder, height: 16),
                _buildDetailRow('Linked Children Count', '${children.length} Enrolled'),
              ],
            ),
          ),

          const SizedBox(height: 18),
          Text(
            'Linked Children',
            style: EduStreakTheme.fontHeading3(color: Colors.white, weight: FontWeight.w800),
          ),
          const SizedBox(height: 10),

          if (children.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'No children profiles currently mapped to this account.',
                  style: EduStreakTheme.fontCaption(color: EduStreakTheme.studentDarkTextMuted),
                ),
              ),
            )
          else
            ...children.map((c) {
              final isSelected = widget.selectedChild?.id == c.id;
              final childClass = '${c.grade != null ? "Class ${c.grade}" : (c.classId ?? "Enrolled")}${c.section != null ? " • Sec ${c.section}" : ""}';

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? EduStreakTheme.primaryViolet.withValues(alpha: 0.15)
                      : EduStreakTheme.studentDarkCardSub,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? EduStreakTheme.primaryViolet
                        : EduStreakTheme.studentDarkBorder,
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: EduStreakTheme.primaryViolet.withValues(alpha: 0.2),
                      child: Text(
                        c.name.isNotEmpty ? c.name[0].toUpperCase() : 'S',
                        style: const TextStyle(
                          color: EduStreakTheme.primaryViolet,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.name,
                            style: EduStreakTheme.fontLabel(color: Colors.white, weight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            childClass,
                            style: EduStreakTheme.fontCaption(color: EduStreakTheme.studentDarkTextMuted),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: EduStreakTheme.primaryViolet,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check, size: 12, color: Colors.white),
                            SizedBox(width: 4),
                            Text('Active', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )
                    else if (widget.onChildSelected != null)
                      OutlinedButton(
                        onPressed: () {
                          widget.onChildSelected!(c);
                          Navigator.of(context).pop();
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: EduStreakTheme.primaryViolet),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Select', style: TextStyle(color: EduStreakTheme.primaryViolet, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildSecurityTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Change Password',
              style: EduStreakTheme.fontHeading3(color: Colors.white, weight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'Update your parent portal password to keep your account secure.',
              style: EduStreakTheme.fontCaption(color: EduStreakTheme.studentDarkTextMuted),
            ),
            const SizedBox(height: 16),

            if (_passwordSuccess != null)
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: EduStreakTheme.emeraldGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: EduStreakTheme.emeraldGreen.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: EduStreakTheme.emeraldGreen, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _passwordSuccess!,
                        style: const TextStyle(color: EduStreakTheme.emeraldGreen, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),

            if (_passwordError != null)
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: EduStreakTheme.rosePink.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: EduStreakTheme.rosePink.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: EduStreakTheme.rosePink, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _passwordError!,
                        style: const TextStyle(color: EduStreakTheme.rosePink, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),

            _buildPasswordField(
              controller: _currentPasswordController,
              label: 'Current Password',
              obscure: _obscureCurrent,
              onToggleObscure: () => setState(() => _obscureCurrent = !_obscureCurrent),
            ),
            const SizedBox(height: 14),
            _buildPasswordField(
              controller: _newPasswordController,
              label: 'New Password (min 6 chars)',
              obscure: _obscureNew,
              onToggleObscure: () => setState(() => _obscureNew = !_obscureNew),
              validator: (v) => (v == null || v.length < 6) ? 'Must be at least 6 characters' : null,
            ),
            const SizedBox(height: 14),
            _buildPasswordField(
              controller: _confirmPasswordController,
              label: 'Confirm New Password',
              obscure: _obscureConfirm,
              onToggleObscure: () => setState(() => _obscureConfirm = !_obscureConfirm),
              validator: (v) => (v == null || v.isEmpty) ? 'Please confirm new password' : null,
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isChangingPassword ? null : _handleChangePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: EduStreakTheme.primaryViolet,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                child: _isChangingPassword
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Update Password',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTab() {
    ThemeProvider? themeProv;
    try {
      themeProv = Provider.of<ThemeProvider>(context, listen: true);
    } catch (_) {
      themeProv = null;
    }
    final isDark = themeProv?.isDarkMode ?? true;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'App Preferences',
            style: EduStreakTheme.fontHeading3(color: Colors.white, weight: FontWeight.w800),
          ),
          const SizedBox(height: 14),

          // Theme Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: EduStreakTheme.studentDarkCardSub,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: EduStreakTheme.studentDarkBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                        color: isDark ? const Color(0xFFFBBF24) : EduStreakTheme.primaryViolet,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Theme Mode',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              isDark ? 'EduStreak Dark Purple' : 'Light Clean Mode',
                              style: EduStreakTheme.fontCaption(color: EduStreakTheme.studentDarkTextMuted),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Switch(
                  value: isDark,
                  onChanged: (val) => themeProv?.toggleTheme(),
                  activeTrackColor: EduStreakTheme.primaryViolet,
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Notifications Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: EduStreakTheme.studentDarkCardSub,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: EduStreakTheme.studentDarkBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.notifications_active_rounded, color: EduStreakTheme.neonCyan, size: 22),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Push Notifications',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Attendance & homework alerts',
                              style: TextStyle(color: EduStreakTheme.studentDarkTextMuted, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Switch(
                  value: true,
                  onChanged: (_) {},
                  activeTrackColor: EduStreakTheme.primaryViolet,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: EduStreakTheme.fontCaption(color: EduStreakTheme.studentDarkTextMuted)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: EduStreakTheme.fontLabel(color: Colors.white, weight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggleObscure,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator ?? (v) => (v == null || v.isEmpty) ? 'Required' : null,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: EduStreakTheme.studentDarkTextMuted, fontSize: 13),
        filled: true,
        fillColor: EduStreakTheme.studentDarkCardSub,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: EduStreakTheme.studentDarkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: EduStreakTheme.studentDarkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: EduStreakTheme.primaryViolet, width: 1.5),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            color: EduStreakTheme.studentDarkTextMuted,
            size: 18,
          ),
          onPressed: onToggleObscure,
        ),
      ),
    );
  }
}
