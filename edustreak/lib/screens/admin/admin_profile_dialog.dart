import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../services/audit_service.dart';
import '../../models/user_model.dart';
import '../../utils/edustreak_theme.dart';
import '../../widgets/responsive/responsive_dialog.dart';

/// Modal dialog for Central Admin profile, security settings (password change), and audit trail inspection.
class AdminProfileDialog extends StatefulWidget {
  final UserModel? user;

  const AdminProfileDialog({super.key, this.user});

  static Future<void> show(BuildContext context, UserModel? user) {
    return showAdaptiveEduStreakModal<void>(
      context: context,
      maxWidth: 680,
      builder: (ctx) => AdminProfileDialog(user: user),
    );
  }

  @override
  State<AdminProfileDialog> createState() => _AdminProfileDialogState();
}

class _AdminProfileDialogState extends State<AdminProfileDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _authService = AuthService();
  final _auditService = AuditService();

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
          _passwordSuccess = 'Password successfully updated and logged to audit trail.';
          _currentPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _passwordError = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isChangingPassword = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = widget.user;
    final fbUser = FirebaseAuth.instance.currentUser;
    final displayName = currentUser?.name.isNotEmpty == true
        ? currentUser!.name
        : (fbUser?.displayName ?? 'Central Administrator');
    final email = currentUser?.email.isNotEmpty == true
        ? currentUser!.email
        : (fbUser?.email ?? 'admin@edustreak.com');

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F1535),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: EduStreakTheme.cardBorder, width: 1.5),
        boxShadow: EduStreakTheme.violetGlow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 20, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: EduStreakTheme.primaryViolet.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: EduStreakTheme.primaryViolet.withValues(alpha: 0.5)),
                  ),
                  child: const Icon(Icons.shield_rounded, color: EduStreakTheme.primaryVioletLight, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Central Administrator Security & Profile',
                        style: EduStreakTheme.fontHeading3(color: Colors.white, weight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Master Governance & Audit Center',
                        style: EduStreakTheme.fontLabel(color: EduStreakTheme.textMuted),
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

          // Tabs
          TabBar(
            controller: _tabController,
            indicatorColor: EduStreakTheme.primaryViolet,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            labelStyle: EduStreakTheme.fontBody(weight: FontWeight.w600),
            tabs: const [
              Tab(icon: Icon(Icons.person_rounded, size: 18), text: 'Profile Info'),
              Tab(icon: Icon(Icons.lock_reset_rounded, size: 18), text: 'Change Password'),
              Tab(icon: Icon(Icons.receipt_long_rounded, size: 18), text: 'Audit Trail'),
            ],
          ),

          const Divider(height: 1, color: Color(0xFF232D62)),

          // Tab views
          SizedBox(
            height: 420,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildProfileTab(displayName, email, fbUser),
                _buildChangePasswordTab(),
                _buildAuditTrailTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── TAB 1: PROFILE INFO ──────────────────────────────────────────────────
  Widget _buildProfileTab(String name, String email, User? fbUser) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: EduStreakTheme.primaryViolet.withValues(alpha: 0.3),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'A',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: EduStreakTheme.fontHeading2(color: Colors.white, weight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(email, style: EduStreakTheme.fontBody(color: EduStreakTheme.textMuted)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: EduStreakTheme.primaryViolet.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: EduStreakTheme.primaryViolet),
                      ),
                      child: Text(
                        'ROLE: CENTRAL_ADMIN (PLATFORM_WIDE)',
                        style: EduStreakTheme.fontCaption(
                          color: EduStreakTheme.primaryVioletLight,
                          weight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: Color(0xFF232D62)),
          const SizedBox(height: 16),
          Text('Session & Identity Details', style: EduStreakTheme.fontLabel(color: Colors.white70, weight: FontWeight.w700)),
          const SizedBox(height: 12),
          _buildInfoRow('Firebase UID', fbUser?.uid ?? 'N/A'),
          _buildInfoRow('Security Level', 'Tier 0 – Root Multi-School Governance'),
          _buildInfoRow('Email Verified', fbUser?.emailVerified == true ? 'Yes (Verified)' : 'Standard Authentication'),
          _buildInfoRow('Current Session Scope', 'Full Access (AP Govt, CBSE, Private)'),
          _buildInfoRow('Creation Timestamp', fbUser?.metadata.creationTime?.toIso8601String() ?? 'N/A'),
          _buildInfoRow('Last Sign-in', fbUser?.metadata.lastSignInTime?.toIso8601String() ?? 'Active Now'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 170,
            child: Text(label, style: EduStreakTheme.fontBodySmall(color: EduStreakTheme.textMuted)),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: EduStreakTheme.fontBodySmall(color: Colors.white, weight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // ─── TAB 2: CHANGE PASSWORD ───────────────────────────────────────────────
  Widget _buildChangePasswordTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Update Master Admin Credentials',
              style: EduStreakTheme.fontHeading3(color: Colors.white, weight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              'Changes require current password re-authentication and are logged directly to the immutable platform audit trail.',
              style: EduStreakTheme.fontCaption(color: EduStreakTheme.textMuted),
            ),
            const SizedBox(height: 16),

            if (_passwordError != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.redAccent),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(_passwordError!, style: EduStreakTheme.fontBodySmall(color: Colors.white)),
                    ),
                  ],
                ),
              ),

            if (_passwordSuccess != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.greenAccent),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, color: Colors.greenAccent, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(_passwordSuccess!, style: EduStreakTheme.fontBodySmall(color: Colors.white)),
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
                suffix: IconButton(
                  icon: Icon(_obscureCurrent ? Icons.visibility_off : Icons.visibility, color: Colors.white54, size: 20),
                  onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                ),
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'Current password is required' : null,
            ),
            const SizedBox(height: 14),

            // New Password
            TextFormField(
              controller: _newPasswordController,
              obscureText: _obscureNew,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration(
                label: 'New Password (min 6 characters)',
                prefixIcon: Icons.vpn_key_rounded,
                suffix: IconButton(
                  icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility, color: Colors.white54, size: 20),
                  onPressed: () => setState(() => _obscureNew = !_obscureNew),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'New password is required';
                if (v.length < 6) return 'Password must be at least 6 characters';
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Confirm New Password
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirm,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration(
                label: 'Confirm New Password',
                prefixIcon: Icons.check_rounded,
                suffix: IconButton(
                  icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility, color: Colors.white54, size: 20),
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'Please confirm your new password' : null,
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: _isChangingPassword ? null : _handleChangePassword,
                icon: _isChangingPassword
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.security_update_good_rounded, size: 20),
                label: Text(_isChangingPassword ? 'Re-authenticating & Updating...' : 'Commit Password Change'),
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

  // ─── TAB 3: AUDIT TRAIL ───────────────────────────────────────────────────
  Widget _buildAuditTrailTab() {
    return StreamBuilder<List<AuditRecord>>(
      stream: _auditService.getRecentAuditLogsStream(limit: 25),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: EduStreakTheme.primaryViolet));
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Failed to load audit trail: ${snapshot.error}',
                style: EduStreakTheme.fontBodySmall(color: Colors.redAccent),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final logs = snapshot.data ?? [];
        if (logs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shield_outlined, size: 44, color: Colors.white30),
                const SizedBox(height: 12),
                Text('No audit records logged yet.', style: EduStreakTheme.fontBody(color: Colors.white60)),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: logs.length,
          separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFF232D62)),
          itemBuilder: (context, index) {
            final log = logs[index];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: EduStreakTheme.primaryViolet.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(_getIconForAction(log.action), size: 16, color: EduStreakTheme.primaryVioletLight),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              log.action,
                              style: EduStreakTheme.fontLabel(color: Colors.white, weight: FontWeight.w700),
                            ),
                            const Spacer(),
                            Text(
                              log.formattedTime,
                              style: EduStreakTheme.fontCaption(color: EduStreakTheme.textMuted),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${log.targetType}: ${log.targetId}',
                          style: EduStreakTheme.fontCaption(color: EduStreakTheme.primaryVioletLight),
                        ),
                        if (log.details.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            log.details.entries.map((e) => '${e.key}: ${e.value}').join(' • '),
                            style: EduStreakTheme.fontCaption(color: Colors.white60),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  IconData _getIconForAction(String action) {
    if (action.contains('PASSWORD')) return Icons.password_rounded;
    if (action.contains('SIGN_IN')) return Icons.login_rounded;
    if (action.contains('SCHOOL')) return Icons.account_balance_rounded;
    if (action.contains('TRANSFER')) return Icons.swap_horiz_rounded;
    if (action.contains('CURRICULUM')) return Icons.layers_rounded;
    if (action.contains('IMPORT')) return Icons.upload_file_rounded;
    return Icons.verified_user_rounded;
  }

  InputDecoration _inputDecoration({required String label, required IconData prefixIcon, Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      prefixIcon: Icon(prefixIcon, color: EduStreakTheme.primaryVioletLight, size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFF161C48),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF283272)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: EduStreakTheme.primaryViolet, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
