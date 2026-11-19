import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../../utils/edustreak_theme.dart';
import '../../utils/class_name_helper.dart';
import '../../widgets/responsive/responsive_dialog.dart';

/// Modal dialog for Teacher profile, security settings (password change), and assigned academic details.
class TeacherProfileDialog extends StatefulWidget {
  final UserModel? user;

  const TeacherProfileDialog({super.key, this.user});

  static Future<void> show(BuildContext context, UserModel? user) {
    return showAdaptiveEduStreakModal<void>(
      context: context,
      maxWidth: 680,
      builder: (ctx) => TeacherProfileDialog(user: user),
    );
  }

  @override
  State<TeacherProfileDialog> createState() => _TeacherProfileDialogState();
}

class _TeacherProfileDialogState extends State<TeacherProfileDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _authService = AuthService();

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
    _tabController = TabController(length: 2, vsync: this);
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
        backgroundColor: const Color(0xFF0F1535),
        title: const Text('Confirm Logout', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to sign out of the Teacher Portal?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
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
    final teacherName = user?.name.isNotEmpty == true ? user!.name : 'Teacher';
    final initialLetter = teacherName.isNotEmpty ? teacherName[0].toUpperCase() : 'T';

    return Container(
      constraints: const BoxConstraints(maxHeight: 700),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1030),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF222B5C), width: 1.2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF222B5C), width: 1)),
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
                      colors: [Color(0xFF8774FF), Color(0xFF6C57FF)],
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
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              teacherName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: EduStreakTheme.emeraldGreen.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: EduStreakTheme.emeraldGreen.withValues(alpha: 0.4),
                              ),
                            ),
                            child: const Text(
                              'Faculty',
                              style: TextStyle(
                                color: EduStreakTheme.emeraldGreen,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user?.email ?? 'teacher@school.edustreak.internal',
                        style: const TextStyle(color: Colors.white54, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white54),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Tab Bar
          Container(
            color: const Color(0xFF090D26),
            child: TabBar(
              controller: _tabController,
              labelColor: EduStreakTheme.primaryViolet,
              unselectedLabelColor: Colors.white54,
              indicatorColor: EduStreakTheme.primaryViolet,
              indicatorWeight: 3,
              tabs: const [
                Tab(
                  icon: Icon(Icons.badge_rounded, size: 20),
                  text: 'Profile & Academics',
                ),
                Tab(
                  icon: Icon(Icons.security_rounded, size: 20),
                  text: 'Security & Password',
                ),
              ],
            ),
          ),

          // Tab Content
          Flexible(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(user),
                _buildSecurityTab(),
              ],
            ),
          ),

          // Footer / Logout
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFF070B1E),
              border: Border(top: BorderSide(color: Color(0xFF222B5C), width: 1)),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: _handleLogout,
                  icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 18),
                  label: const Text(
                    'Sign Out',
                    style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF222B5C),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Close', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(UserModel? user) {
    final assignedClasses = user?.classIds ?? (user?.classId != null ? [user!.classId!] : <String>[]);
    final assignedSubjects = user?.assignedSubjects ?? <String>[];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section 1: Official Institutional Identity
          const Text(
            'OFFICIAL IDENTITY',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1535),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF222B5C)),
            ),
            child: Column(
              children: [
                _buildDetailRow('Employee ID', user?.employeeId?.isNotEmpty == true ? user!.employeeId! : 'EMP-${user?.id.substring(0, 6).toUpperCase() ?? "001"}'),
                const Divider(color: Color(0xFF222B5C), height: 18),
                _buildDetailRow('School Code', user?.schoolCode ?? 'AP-VIZ-001'),
                const Divider(color: Color(0xFF222B5C), height: 18),
                _buildDetailRow('Official Email', user?.email ?? 'N/A'),
                const Divider(color: Color(0xFF222B5C), height: 18),
                _buildDetailRow('Account Status', user?.isActive != false ? 'Active & Verified' : 'Suspended', isBadge: true),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Section 2: Teaching Assignments
          const Text(
            'ACADEMIC ASSIGNMENTS',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1535),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF222B5C)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Assigned Classes',
                  style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                if (assignedClasses.isEmpty)
                  const Text('No classes currently assigned.', style: TextStyle(color: Colors.white38, fontSize: 13))
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: assignedClasses.map((cId) {
                      final name = ClassNameHelper.formatClassNameSync(cId, fallback: 'Class 8A');
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: EduStreakTheme.primaryViolet.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: EduStreakTheme.primaryViolet.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          name,
                          style: const TextStyle(
                            color: Color(0xFFB8A8FF),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                const Divider(color: Color(0xFF222B5C), height: 24),

                const Text(
                  'Assigned Subjects',
                  style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                if (assignedSubjects.isEmpty)
                  const Text('Mathematics, Science, English', style: TextStyle(color: Colors.white70, fontSize: 13))
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: assignedSubjects.map((sub) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: EduStreakTheme.neonCyan.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: EduStreakTheme.neonCyan.withValues(alpha: 0.35)),
                        ),
                        child: Text(
                          sub,
                          style: const TextStyle(
                            color: EduStreakTheme.neonCyan,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBadge = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        if (isBadge)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
            ),
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.greenAccent,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        else
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }

  Widget _buildSecurityTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'CHANGE ACCOUNT PASSWORD',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 16),

            if (_passwordSuccess != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _passwordSuccess!,
                        style: const TextStyle(color: Colors.greenAccent, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

            if (_passwordError != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _passwordError!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

            // Current Password
            TextFormField(
              controller: _currentPasswordController,
              obscureText: _obscureCurrent,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration(
                label: 'Current Password',
                prefixIcon: Icons.lock_outline_rounded,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureCurrent ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    color: Colors.white38,
                    size: 18,
                  ),
                  onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                ),
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'Enter current password' : null,
            ),
            const SizedBox(height: 16),

            // New Password
            TextFormField(
              controller: _newPasswordController,
              obscureText: _obscureNew,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration(
                label: 'New Password',
                prefixIcon: Icons.lock_rounded,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureNew ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    color: Colors.white38,
                    size: 18,
                  ),
                  onPressed: () => setState(() => _obscureNew = !_obscureNew),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Enter new password';
                if (v.length < 6) return 'Password must be at least 6 characters';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Confirm New Password
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirm,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration(
                label: 'Confirm New Password',
                prefixIcon: Icons.lock_rounded,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    color: Colors.white38,
                    size: 18,
                  ),
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'Confirm new password' : null,
            ),
            const SizedBox(height: 24),

            // Update Password Button
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: _isChangingPassword ? null : _handleChangePassword,
                icon: _isChangingPassword
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save_rounded, size: 18),
                label: Text(
                  _isChangingPassword ? 'Updating Password...' : 'Update Password',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: EduStreakTheme.primaryViolet,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
      prefixIcon: Icon(prefixIcon, color: EduStreakTheme.primaryViolet, size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFF0F1535),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF222B5C)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF222B5C)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: EduStreakTheme.primaryViolet, width: 1.5),
      ),
    );
  }
}
