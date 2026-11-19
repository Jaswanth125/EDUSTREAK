import 'package:flutter/material.dart';
import '../../../../models/school_model.dart';
import '../../../../models/user_model.dart';
import '../../../../services/principal_service.dart';
import '../../../../utils/edustreak_theme.dart';
import '../../../../utils/responsive_breakpoints.dart';

class PrincipalApprovalsTab extends StatefulWidget {
  final SchoolModel school;
  final UserModel principal;

  const PrincipalApprovalsTab({
    super.key,
    required this.school,
    required this.principal,
  });

  @override
  State<PrincipalApprovalsTab> createState() => _PrincipalApprovalsTabState();
}

class _PrincipalApprovalsTabState extends State<PrincipalApprovalsTab> {
  final _principalService = PrincipalService();
  String _typeFilter = 'All';
  String _statusFilter = 'Pending'; // 'Pending', 'Approved', 'All'
  String? _processingId;

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
          // ─── HEADER BANNER ──────────────────────────────────────────────
          _buildHeaderBanner(),

          const SizedBox(height: 18),

          // ─── STATUS & TYPE FILTER CHIPS ─────────────────────────────────
          _buildFiltersSection(),

          const SizedBox(height: 18),

          // ─── APPROVALS QUEUE HEADER ─────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _statusFilter == 'Pending'
                      ? 'Pending School Authorization Requests'
                      : (_statusFilter == 'Approved'
                          ? 'Approved & Audited Requests'
                          : 'All Authorization Requests'),
                  style: EduStreakTheme.fontHeading2(color: Colors.white, weight: FontWeight.w800),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _principalService.getPendingApprovalsStream(widget.school.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(color: EduStreakTheme.primaryViolet),
                  ),
                );
              }

              final allItems = snapshot.data ?? [];

              var list = allItems.where((a) {
                final status = a['status']?.toString().toLowerCase() ?? 'pending';
                if (_statusFilter == 'Pending') return status == 'pending';
                if (_statusFilter == 'Approved') return status == 'approved';
                return true;
              }).toList();

              if (_typeFilter != 'All') {
                list = list.where((a) {
                  final t = a['type']?.toString().toLowerCase() ?? '';
                  return t.contains(_typeFilter.toLowerCase().replaceAll(' ', '_'));
                }).toList();
              }

              if (list.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: EduStreakTheme.studentDarkCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: EduStreakTheme.studentDarkBorder),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.verified_rounded, size: 48, color: EduStreakTheme.emeraldGreen),
                      const SizedBox(height: 12),
                      Text(
                        _statusFilter == 'Pending'
                            ? 'Zero Pending Approval Requests'
                            : 'No Requests Found',
                        style: EduStreakTheme.fontHeading3(color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _statusFilter == 'Pending'
                            ? 'All institutional registration claims, attendance edits, and parent links are up to date.'
                            : 'No items matching current category and status filters.',
                        style: EduStreakTheme.fontCaption(color: EduStreakTheme.studentDarkTextMuted),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final req = list[index];
                  return _buildApprovalCard(req);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: EduStreakTheme.studentDarkCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: EduStreakTheme.studentDarkBorder, width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: EduStreakTheme.primaryViolet.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.approval_rounded, color: EduStreakTheme.primaryViolet, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Institutional Approvals & Compliance Hub',
                  style: EduStreakTheme.fontHeading2(color: Colors.white, weight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  'Authorise student records, attendance adjustments, and identity links with full audit compliance.',
                  style: EduStreakTheme.fontCaption(color: EduStreakTheme.studentDarkTextMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    final statusOptions = ['Pending', 'Approved', 'All'];
    final typeFilters = ['All', 'Registration Claim', 'Attendance Correction', 'Student Info Correction', 'Parent Linking'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status Row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Text(
                'Status: ',
                style: EduStreakTheme.fontSmall(color: EduStreakTheme.studentDarkTextMuted, weight: FontWeight.w700),
              ),
              const SizedBox(width: 8),
              ...statusOptions.map((st) {
                final isSelected = _statusFilter == st;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(st == 'Pending' ? 'Pending Sign-off' : (st == 'Approved' ? 'Approved History' : 'All Statuses')),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _statusFilter = st),
                    backgroundColor: EduStreakTheme.studentDarkCard,
                    selectedColor: EduStreakTheme.primaryViolet,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 12,
                    ),
                    side: BorderSide(
                      color: isSelected ? EduStreakTheme.primaryViolet : EduStreakTheme.studentDarkBorder,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Type Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Text(
                'Type: ',
                style: EduStreakTheme.fontSmall(color: EduStreakTheme.studentDarkTextMuted, weight: FontWeight.w700),
              ),
              const SizedBox(width: 8),
              ...typeFilters.map((f) {
                final isSelected = _typeFilter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(f),
                    selected: isSelected,
                    onSelected: (val) => setState(() => _typeFilter = f),
                    backgroundColor: EduStreakTheme.studentDarkCard,
                    selectedColor: EduStreakTheme.secondaryPurple,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 12,
                    ),
                    side: BorderSide(
                      color: isSelected ? EduStreakTheme.secondaryPurple : EduStreakTheme.studentDarkBorder,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildApprovalCard(Map<String, dynamic> req) {
    final status = req['status'] ?? 'pending';
    final isPending = status == 'pending';
    final isProcessing = _processingId == req['id'];

    Color typeColor;
    IconData typeIcon;
    final typeStr = req['type'] ?? '';

    if (typeStr.contains('attendance')) {
      typeColor = EduStreakTheme.amberGold;
      typeIcon = Icons.event_available_rounded;
    } else if (typeStr.contains('parent')) {
      typeColor = EduStreakTheme.magentaPink;
      typeIcon = Icons.family_restroom_rounded;
    } else if (typeStr.contains('registration')) {
      typeColor = EduStreakTheme.neonCyan;
      typeIcon = Icons.how_to_reg_rounded;
    } else {
      typeColor = EduStreakTheme.primaryVioletLight;
      typeIcon = Icons.edit_note_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: EduStreakTheme.studentDarkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPending ? typeColor.withValues(alpha: 0.35) : (status == 'approved' ? EduStreakTheme.emeraldGreen.withValues(alpha: 0.35) : EduStreakTheme.rosePink.withValues(alpha: 0.35)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 380;
              final statusBadge = Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isPending
                      ? EduStreakTheme.amberGold.withValues(alpha: 0.15)
                      : (status == 'approved' ? EduStreakTheme.emeraldGreen.withValues(alpha: 0.15) : EduStreakTheme.rosePink.withValues(alpha: 0.15)),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isPending
                        ? EduStreakTheme.amberGold.withValues(alpha: 0.3)
                        : (status == 'approved' ? EduStreakTheme.emeraldGreen.withValues(alpha: 0.3) : EduStreakTheme.rosePink.withValues(alpha: 0.3)),
                  ),
                ),
                child: Text(
                  isPending ? 'Pending Sign-off' : (status == 'approved' ? '✓ Approved' : '✗ Rejected'),
                  style: EduStreakTheme.fontCaption(
                    color: isPending
                        ? EduStreakTheme.amberGold
                        : (status == 'approved' ? EduStreakTheme.emeraldGreen : EduStreakTheme.rosePink),
                    weight: FontWeight.w700,
                  ),
                ),
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: typeColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(typeIcon, color: typeColor, size: 18),
                        ),
                        const SizedBox(width: 10),
                        statusBadge,
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      req['title'] ?? 'Authorization Request',
                      style: EduStreakTheme.fontLabel(color: Colors.white, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Requested by: ${req['requestedBy'] ?? 'Staff Member'}',
                      style: EduStreakTheme.fontCaption(color: EduStreakTheme.studentDarkTextMuted),
                    ),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(typeIcon, color: typeColor, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          req['title'] ?? 'Authorization Request',
                          style: EduStreakTheme.fontLabel(color: Colors.white, weight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Requested by: ${req['requestedBy'] ?? 'Staff Member'}',
                          style: EduStreakTheme.fontCaption(color: EduStreakTheme.studentDarkTextMuted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  statusBadge,
                ],
              );
            },
          ),

          const SizedBox(height: 12),

          Text(
            req['description'] ?? '',
            style: EduStreakTheme.fontCaption(color: Colors.white70),
          ),

          if (status == 'approved') ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: EduStreakTheme.emeraldGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: EduStreakTheme.emeraldGreen.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user_rounded, color: EduStreakTheme.emeraldGreen, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Authorized by ${req['reviewedByName'] ?? widget.principal.name} • Recorded in Audit Trail',
                      style: EduStreakTheme.fontSmall(color: EduStreakTheme.emeraldGreen, weight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (isPending) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: isProcessing ? null : () => _resolveRequest(req['id'], false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: EduStreakTheme.rosePink,
                    side: const BorderSide(color: EduStreakTheme.rosePink),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Reject Request'),
                ),
                ElevatedButton(
                  onPressed: isProcessing ? null : () => _resolveRequest(req['id'], true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EduStreakTheme.emeraldGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: isProcessing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Approve & Authorize'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _resolveRequest(String requestId, bool approve) async {
    setState(() => _processingId = requestId);

    try {
      await _principalService.resolveApprovalRequest(
        schoolId: widget.school.id,
        requestId: requestId,
        approved: approve,
        reviewerUid: widget.principal.id,
        reviewerName: widget.principal.name,
        reason: approve ? 'Authorized by Principal' : 'Rejected by Principal based on verification rules',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(approve ? '✓ Request approved and recorded to audit trail!' : 'Request rejected.'),
            backgroundColor: approve ? EduStreakTheme.emeraldGreen : EduStreakTheme.rosePink,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Note: $e'),
            backgroundColor: EduStreakTheme.amberGold,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _processingId = null);
      }
    }
  }
}
