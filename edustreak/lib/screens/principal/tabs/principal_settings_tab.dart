import 'package:flutter/material.dart';
import '../../../../models/school_model.dart';
import '../../../../models/user_model.dart';
import '../../../../services/auth_service.dart';
import '../../../../utils/edustreak_theme.dart';
import '../../../../utils/responsive_breakpoints.dart';
import '../../../../widgets/responsive/responsive_dialog.dart';

class PrincipalSettingsTab extends StatefulWidget {
  final SchoolModel school;
  final UserModel principal;
  final VoidCallback onLogout;

  const PrincipalSettingsTab({
    super.key,
    required this.school,
    required this.principal,
    required this.onLogout,
  });

  @override
  State<PrincipalSettingsTab> createState() => _PrincipalSettingsTabState();
}

class _PrincipalSettingsTabState extends State<PrincipalSettingsTab> {
  final _authService = AuthService();
  bool _emailAlerts = true;
  bool _attendanceAlerts = true;
  bool _aiInsightAlerts = true;

  @override
  Widget build(BuildContext context) {
    final isDesktop = context.isDesktop;
    final isTablet = context.isTablet;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 28 : (isTablet ? 20 : 16),
        vertical: 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── PRINCIPAL PROFILE CARD ────────────────────────────────────
          _buildProfileCard(isDesktop),

          const SizedBox(height: 24),

          // ─── SCHOOL CONFIGURATION CARD ─────────────────────────────────
          _buildSchoolConfigurationCard(),

          const SizedBox(height: 24),

          // ─── SECURITY & NOTIFICATIONS ──────────────────────────────────
          _buildSecurityAndNotificationsCard(),

          const SizedBox(height: 24),

          // ─── LOGOUT BUTTON ─────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: widget.onLogout,
              icon: const Icon(Icons.logout_rounded, color: EduStreakTheme.rosePink),
              label: const Text('Sign Out of Principal Portal', style: TextStyle(color: EduStreakTheme.rosePink, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: EduStreakTheme.rosePink),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildProfileCard(bool isDesktop) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: EduStreakTheme.studentDarkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: EduStreakTheme.studentDarkBorder, width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: EduStreakTheme.primaryViolet,
            child: Text(
              widget.principal.name.isNotEmpty ? widget.principal.name[0] : 'P',
              style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      widget.principal.name,
                      style: EduStreakTheme.fontHeading2(color: Colors.white, weight: FontWeight.w800),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: EduStreakTheme.primaryViolet.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'HEAD OF INSTITUTION',
                        style: EduStreakTheme.fontSmall(color: EduStreakTheme.neonCyan, weight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Assigned School: ${widget.school.name} (Code: ${widget.school.code})',
                  style: EduStreakTheme.fontBody(color: EduStreakTheme.neonCyan),
                ),
                Text(
                  'Email: ${widget.principal.email} • Phone: ${widget.school.contactPhone}',
                  style: EduStreakTheme.fontCaption(color: EduStreakTheme.studentDarkTextMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSchoolConfigurationCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: EduStreakTheme.studentDarkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: EduStreakTheme.studentDarkBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.settings_suggest_rounded, color: EduStreakTheme.neonCyan, size: 22),
              const SizedBox(width: 10),
              Text(
                'Institutional Configuration',
                style: EduStreakTheme.fontHeading3(color: Colors.white, weight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSettingRow('Active Academic Year', widget.school.academicYear),
          _buildSettingRow('Curriculum Framework', 'Andhra Pradesh State Board (SCERT)'),
          _buildSettingRow('Affiliation Standard', widget.school.affiliationNumber),
          _buildSettingRow('Daily Attendance Window', '8:45 AM - 9:30 AM (Mandatory)'),
          _buildSettingRow('Weekly Instruction Schedule', 'Monday to Saturday (6 Working Days)'),
        ],
      ),
    );
  }

  Widget _buildSecurityAndNotificationsCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: EduStreakTheme.studentDarkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: EduStreakTheme.studentDarkBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.security_rounded, color: EduStreakTheme.emeraldGreen, size: 22),
              const SizedBox(width: 10),
              Text(
                'Security & Administrative Alerts',
                style: EduStreakTheme.fontHeading3(color: Colors.white, weight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Email Daily Attendance Digest', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            subtitle: const Text('Receive 10:00 AM executive attendance report via email', style: TextStyle(color: EduStreakTheme.studentDarkTextMuted, fontSize: 12)),
            value: _emailAlerts,
            activeTrackColor: EduStreakTheme.primaryViolet,
            onChanged: (val) => setState(() => _emailAlerts = val),
          ),
          SwitchListTile(
            title: const Text('Low Class Attendance Push Notification', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            subtitle: const Text('Trigger immediate alert if any section attendance drops below 80%', style: TextStyle(color: EduStreakTheme.studentDarkTextMuted, fontSize: 12)),
            value: _attendanceAlerts,
            activeTrackColor: EduStreakTheme.primaryViolet,
            onChanged: (val) => setState(() => _attendanceAlerts = val),
          ),
          SwitchListTile(
            title: const Text('AI School Health & Critical Warnings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            subtitle: const Text('Instant detection of grading delays or sharp subject score drops', style: TextStyle(color: EduStreakTheme.studentDarkTextMuted, fontSize: 12)),
            value: _aiInsightAlerts,
            activeTrackColor: EduStreakTheme.primaryViolet,
            onChanged: (val) => setState(() => _aiInsightAlerts = val),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _showChangePasswordDialog,
            icon: const Icon(Icons.lock_reset_rounded, size: 18, color: Colors.white),
            label: const Text('Update Security Password', style: TextStyle(color: Colors.white)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: EduStreakTheme.studentDarkBorder),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: EduStreakTheme.fontCaption(color: EduStreakTheme.studentDarkTextMuted, weight: FontWeight.w500)),
          Text(value, style: EduStreakTheme.fontCaption(color: Colors.white, weight: FontWeight.w700)),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentPassController = TextEditingController();
    final newPassController = TextEditingController();

    showAdaptiveEduStreakModal(
      context: context,
      title: 'Change Security Password',
      icon: const Icon(Icons.lock_rounded, color: EduStreakTheme.neonCyan),
      isDark: true,
      builder: (ctx) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: currentPassController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Current Password',
                labelStyle: TextStyle(color: EduStreakTheme.studentDarkTextMuted),
                filled: true,
                fillColor: Color(0xFF14193E),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: newPassController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'New Password (min 6 characters)',
                labelStyle: TextStyle(color: EduStreakTheme.studentDarkTextMuted),
                filled: true,
                fillColor: Color(0xFF14193E),
              ),
            ),
          ],
        );
      },
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
        ),
        ElevatedButton(
          onPressed: () async {
            final curr = currentPassController.text.trim();
            final next = newPassController.text.trim();
            if (curr.isEmpty || next.length < 6) return;
            Navigator.pop(context);
            try {
              await _authService.changePassword(currentPassword: curr, newPassword: next);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password updated successfully!'), backgroundColor: EduStreakTheme.emeraldGreen),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}'), backgroundColor: EduStreakTheme.rosePink),
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: EduStreakTheme.primaryViolet),
          child: const Text('Save Password', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
