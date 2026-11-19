import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/school_model.dart';
import '../../services/school_service.dart';
import '../../utils/edustreak_theme.dart';
import '../../widgets/responsive/responsive_dialog.dart';

class PrincipalManagementScreen extends StatefulWidget {
  const PrincipalManagementScreen({super.key});

  @override
  State<PrincipalManagementScreen> createState() => _PrincipalManagementScreenState();
}

class _PrincipalManagementScreenState extends State<PrincipalManagementScreen> {
  final _schoolService = SchoolService();
  String _searchQuery = '';
  String _selectedStatusFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 600;

    return Container(
      color: const Color(0xFF070B1E),
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 24,
        vertical: isCompact ? 10 : 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── HEADER BAR & INVITE ACTION ─────────────────────────────────
          _buildHeaderBar(),

          SizedBox(height: isCompact ? 10 : 18),

          // ─── SEARCH & FILTER CHIPS ──────────────────────────────────────
          _buildFilterBar(),

          SizedBox(height: isCompact ? 10 : 18),

          // ─── LIVE PRINCIPALS STREAM ─────────────────────────────────────
          Expanded(
            child: StreamBuilder<List<UserModel>>(
              stream: _schoolService.getAllPrincipalsStream(
                searchQuery: _searchQuery,
                statusFilter: _selectedStatusFilter,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: EduStreakTheme.primaryViolet));
                }

                final principals = snapshot.data ?? [];

                if (principals.isEmpty) {
                  return Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.supervisor_account_outlined, size: 48, color: Colors.white24),
                          const SizedBox(height: 10),
                          Text(
                            'No Principal accounts matching criteria',
                            style: EduStreakTheme.fontHeading3(color: Colors.white60),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Invite or assign school leaders using the "Invite Principal" button above.',
                            style: EduStreakTheme.fontCaption(color: EduStreakTheme.darkTextMuted),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 850;
                    if (isWide) {
                      return GridView.builder(
                        padding: const EdgeInsets.only(bottom: 24),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 2.1,
                        ),
                        itemCount: principals.length,
                        itemBuilder: (context, index) => _buildPrincipalCard(principals[index]),
                      );
                    } else {
                      return ListView.builder(
                        padding: const EdgeInsets.only(bottom: 24),
                        itemCount: principals.length,
                        itemBuilder: (context, index) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildPrincipalCard(principals[index]),
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBar() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 600;

    return Container(
      padding: EdgeInsets.all(isCompact ? 12 : 18),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1535),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EduStreakTheme.cardBorder),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final titleCol = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.admin_panel_settings_rounded, color: EduStreakTheme.primaryViolet, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isCompact ? 'Principal Governance' : 'Principal Management & Governance',
                      style: EduStreakTheme.fontHeading3(color: Colors.white, weight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              if (!isCompact) ...[
                const SizedBox(height: 4),
                Text(
                  'Authorise, onboard, monitor, and transfer school leadership accounts across the state network.',
                  style: EduStreakTheme.fontCaption(color: EduStreakTheme.textMuted),
                ),
              ],
            ],
          );

          final inviteButton = ElevatedButton.icon(
            onPressed: _showInvitePrincipalDialog,
            icon: const Icon(Icons.person_add_rounded, size: 15),
            label: Text(isCompact ? 'Invite' : 'Invite Principal', style: const TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: EduStreakTheme.primaryViolet,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: isCompact ? 10 : 18, vertical: isCompact ? 8 : 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: titleCol),
              const SizedBox(width: 8),
              inviteButton,
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterBar() {
    final filters = ['All', 'Active', 'Invited', 'Suspended'];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 650;

        final searchBox = TextField(
          onChanged: (val) => setState(() => _searchQuery = val),
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search by Principal name, email, or school code...',
            hintStyle: const TextStyle(color: Colors.white38),
            prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 18),
            filled: true,
            fillColor: const Color(0xFF0F1535),
            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF232A5C)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF232A5C)),
            ),
          ),
        );

        final filterChips = SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: filters.map((f) {
              final isSelected = _selectedStatusFilter == f;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: FilterChip(
                  label: Text(f),
                  selected: isSelected,
                  onSelected: (val) => setState(() => _selectedStatusFilter = f),
                  backgroundColor: const Color(0xFF0F1535),
                  selectedColor: EduStreakTheme.primaryViolet,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.white60,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 12,
                  ),
                  side: BorderSide(
                    color: isSelected ? EduStreakTheme.primaryViolet : const Color(0xFF232A5C),
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            }).toList(),
          ),
        );

        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              searchBox,
              const SizedBox(height: 10),
              filterChips,
            ],
          );
        }

        return Row(
          children: [
            Expanded(flex: 3, child: searchBox),
            const SizedBox(width: 12),
            filterChips,
          ],
        );
      },
    );
  }

  Widget _buildPrincipalCard(UserModel principal) {
    final status = principal.status.toLowerCase();
    Color statusColor;
    String statusLabel;

    if (status == 'active' || (principal.isActive && status != 'invited' && status != 'suspended' && status != 'revoked')) {
      statusColor = EduStreakTheme.emeraldGreen;
      statusLabel = 'Active Leader';
    } else if (status == 'invited') {
      statusColor = EduStreakTheme.neonCyan;
      statusLabel = 'Invitation Sent';
    } else if (status == 'sending') {
      statusColor = EduStreakTheme.amberGold;
      statusLabel = 'Email Sending...';
    } else if (status == 'revoked') {
      statusColor = EduStreakTheme.rosePink;
      statusLabel = 'Invitation Revoked';
    } else if (status == 'failed') {
      statusColor = EduStreakTheme.rosePink;
      statusLabel = 'Delivery Failed';
    } else {
      statusColor = EduStreakTheme.rosePink;
      statusLabel = 'Suspended';
    }

    final isInvitedOrPending = status == 'invited' || status == 'sending' || status == 'failed';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1333),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF232A5C)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Row 1: Avatar, Name, Email, Status Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: EduStreakTheme.primaryViolet.withValues(alpha: 0.25),
                child: Text(
                  principal.name.isNotEmpty ? principal.name[0].toUpperCase() : 'P',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      principal.name,
                      style: EduStreakTheme.fontLabel(color: Colors.white, weight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      principal.email,
                      style: EduStreakTheme.fontCaption(color: EduStreakTheme.darkTextMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  statusLabel,
                  style: EduStreakTheme.fontCaption(color: statusColor, weight: FontWeight.w700),
                ),
              ),
            ],
          ),

          // Row 2: School Context Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF161C48),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_balance_rounded, size: 14, color: EduStreakTheme.neonCyan),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Assigned School: ${principal.schoolCode ?? 'Unassigned'} • ${principal.schoolId}',
                    style: EduStreakTheme.fontCaption(color: Colors.white70),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Row 3: Action Buttons
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 6,
            runSpacing: 4,
            children: [
              if (isInvitedOrPending) ...[
                TextButton.icon(
                  onPressed: () => _resendInvitation(principal),
                  icon: const Icon(Icons.mail_outline_rounded, size: 14),
                  label: const Text('Resend Invite', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: EduStreakTheme.amberGold,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _revokeInvitation(principal),
                  icon: const Icon(Icons.cancel_outlined, size: 14),
                  label: const Text('Revoke', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: EduStreakTheme.rosePink,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ],
              TextButton.icon(
                onPressed: () => _showTransferPrincipalDialog(principal),
                icon: const Icon(Icons.swap_horiz_rounded, size: 14),
                label: const Text('Transfer', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  foregroundColor: EduStreakTheme.neonCyan,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
              if (!isInvitedOrPending && status != 'revoked')
                TextButton.icon(
                  onPressed: () => _togglePrincipalStatus(principal),
                  icon: Icon(
                    status == 'suspended' ? Icons.check_circle_outline : Icons.block_rounded,
                    size: 14,
                  ),
                  label: Text(
                    status == 'suspended' ? 'Reactivate' : 'Suspend',
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: status == 'suspended' ? EduStreakTheme.emeraldGreen : EduStreakTheme.rosePink,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── INVITE PRINCIPAL DIALOG ──────────────────────────────────────────────
  void _showInvitePrincipalDialog() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    String? selectedSchoolId;
    String? selectedSchoolCode;
    bool isSubmitting = false;

    showAdaptiveEduStreakModal(
      context: context,
      isDark: true,
      title: 'Invite Principal & Assign School',
      icon: const Icon(Icons.person_add_rounded, color: EduStreakTheme.neonCyan),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Form(
            key: formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Principal Full Name',
                      hintText: 'e.g. Dr. Sudhir Sharma',
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Enter full name' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: emailController,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Official Email Address',
                      hintText: 'e.g. principal@apgov.edu.in',
                    ),
                    validator: (v) => v == null || !v.contains('@') ? 'Enter a valid email' : null,
                  ),
                  const SizedBox(height: 14),
                  StreamBuilder<List<SchoolModel>>(
                    stream: _schoolService.getSchoolsStream(),
                    builder: (context, snapshot) {
                      final schools = snapshot.data ?? [];
                      return DropdownButtonFormField<String>(
                        initialValue: selectedSchoolId,
                        dropdownColor: const Color(0xFF141A42),
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Assigned School',
                          hintText: 'Select school for this Principal',
                        ),
                        items: schools.map((s) {
                          return DropdownMenuItem(
                            value: s.id,
                            child: Text(
                              '${s.name} (${s.code})',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            final match = schools.firstWhere((s) => s.id == val);
                            setDialogState(() {
                              selectedSchoolId = val;
                              selectedSchoolCode = match.code;
                            });
                          }
                        },
                        validator: (v) => v == null || v.isEmpty ? 'Select an authorized school' : null,
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;
                                setDialogState(() => isSubmitting = true);
                                try {
                                  await _schoolService.createAndInvitePrincipal(
                                    name: nameController.text.trim(),
                                    email: emailController.text.trim(),
                                    schoolId: selectedSchoolId!,
                                    schoolCode: selectedSchoolCode ?? 'SCH',
                                  );
                                  if (ctx.mounted) Navigator.pop(ctx);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('✓ Principal invited and invitation email dispatched!'),
                                        backgroundColor: EduStreakTheme.emeraldGreen,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  setDialogState(() => isSubmitting = false);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error: ${e.toString().replaceFirst('Exception: ', '')}'),
                                        backgroundColor: EduStreakTheme.rosePink,
                                      ),
                                    );
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: EduStreakTheme.primaryViolet,
                        ),
                        child: isSubmitting
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Confirm & Send Invite'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── TRANSFER PRINCIPAL DIALOG ────────────────────────────────────────────
  void _showTransferPrincipalDialog(UserModel currentPrincipal) {
    final formKey = GlobalKey<FormState>();
    final newNameController = TextEditingController();
    final newEmailController = TextEditingController();
    final reasonController = TextEditingController();
    bool isSubmitting = false;

    showAdaptiveEduStreakModal(
      context: context,
      isDark: true,
      title: 'Transfer School Leadership',
      icon: const Icon(Icons.swap_horiz_rounded, color: EduStreakTheme.neonCyan),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Form(
            key: formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161C48),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Current Principal: ${currentPrincipal.name} (${currentPrincipal.email})\nSchool Code: ${currentPrincipal.schoolCode}',
                      style: EduStreakTheme.fontCaption(color: Colors.white70),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: newNameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Successor Principal Name'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Enter successor name' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: newEmailController,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Successor Official Email'),
                    validator: (v) => v == null || !v.contains('@') ? 'Enter valid email' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: reasonController,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Transfer Authorization Reason'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Enter transfer reason' : null,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;
                                setDialogState(() => isSubmitting = true);
                                try {
                                  // Create successor user UID
                                  final newPrincipal = await _schoolService.createAndInvitePrincipal(
                                    name: newNameController.text.trim(),
                                    email: newEmailController.text.trim(),
                                    schoolId: currentPrincipal.schoolId ?? '',
                                    schoolCode: currentPrincipal.schoolCode ?? 'SCH',
                                  );

                                  await _schoolService.transferSchoolPrincipal(
                                    schoolId: currentPrincipal.schoolId ?? '',
                                    newPrincipalUid: newPrincipal.id,
                                    newPrincipalName: newPrincipal.name,
                                    newPrincipalEmail: newPrincipal.email,
                                    reason: reasonController.text.trim(),
                                  );

                                  if (ctx.mounted) Navigator.pop(ctx);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('✓ Leadership transfer executed and logged to audit trail!'),
                                        backgroundColor: EduStreakTheme.emeraldGreen,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  setDialogState(() => isSubmitting = false);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error: $e'), backgroundColor: EduStreakTheme.rosePink),
                                    );
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(backgroundColor: EduStreakTheme.neonCyan, foregroundColor: Colors.black),
                        child: const Text('Execute Transfer'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _togglePrincipalStatus(UserModel principal) async {
    final newStatus = principal.status == 'suspended' ? 'active' : 'suspended';
    await _schoolService.updatePrincipalStatus(principal.id, newStatus, reason: 'Central Admin status action');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Principal status updated to ${newStatus.toUpperCase()}'),
          backgroundColor: newStatus == 'active' ? EduStreakTheme.emeraldGreen : EduStreakTheme.rosePink,
        ),
      );
    }
  }

  Future<void> _resendInvitation(UserModel principal) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: EduStreakTheme.primaryViolet),
      ),
    );
    try {
      final res = await _schoolService.resendPrincipalInvitation(principal);
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Official invitation dispatched to ${principal.email} via ${res.provider}!'),
            backgroundColor: EduStreakTheme.emeraldGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to resend: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: EduStreakTheme.rosePink,
          ),
        );
      }
    }
  }

  void _revokeInvitation(UserModel principal) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF12183A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Revoke Leadership Invitation', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to revoke the appointment invitation for ${principal.name} (${principal.email})?\n\nThe issued invitation code and security token will be immediately invalidated.',
          style: const TextStyle(color: Colors.white70, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: EduStreakTheme.rosePink,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _schoolService.revokePrincipalInvitation(principal, reason: 'Revoked by Central Administrator');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✓ Leadership invitation for ${principal.name} revoked'),
                      backgroundColor: EduStreakTheme.rosePink,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString().replaceFirst('Exception: ', '')}'),
                      backgroundColor: EduStreakTheme.rosePink,
                    ),
                  );
                }
              }
            },
            child: const Text('Confirm Revocation'),
          ),
        ],
      ),
    );
  }
}
