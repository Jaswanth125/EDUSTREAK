import 'package:flutter/material.dart';
import '../../../../models/school_model.dart';
import '../../../../models/user_model.dart';
import '../../../../services/principal_service.dart';
import '../../../../utils/edustreak_theme.dart';
import '../../../../utils/responsive_breakpoints.dart';

class PrincipalParentManagementTab extends StatefulWidget {
  final SchoolModel school;
  final VoidCallback onBroadcastToParents;

  const PrincipalParentManagementTab({
    super.key,
    required this.school,
    required this.onBroadcastToParents,
  });

  @override
  State<PrincipalParentManagementTab> createState() => _PrincipalParentManagementTabState();
}

class _PrincipalParentManagementTabState extends State<PrincipalParentManagementTab> {
  final _principalService = PrincipalService();
  String _searchQuery = '';
  int _selectedSubTab = 0; // 0: Parent Directory, 1: Pending Link Requests

  @override
  Widget build(BuildContext context) {
    final isDesktop = context.isDesktop;
    final isTablet = context.isTablet;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 28 : (isTablet ? 20 : 16),
        vertical: 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── TOP ACTION BANNER ──────────────────────────────────────────
          _buildTopBanner(isDesktop),

          const SizedBox(height: 18),

          // ─── SUB-SECTION TABS (DIRECTORY VS REQUESTS) ───────────────────
          _buildSubTabSelector(),

          const SizedBox(height: 16),

          // ─── TAB CONTENT ────────────────────────────────────────────────
          Expanded(
            child: _selectedSubTab == 0
                ? _buildParentDirectory(isDesktop, isTablet)
                : _buildPendingLinkRequests(),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBanner(bool isDesktop) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 620;

        final textBlock = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.family_restroom_rounded, color: EduStreakTheme.magentaPink, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Parent & Guardian Management',
                    style: EduStreakTheme.fontHeading2(color: Colors.white, weight: FontWeight.w800),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Verify student-parent relationships, authorize link claims, and coordinate institutional communications.',
              style: EduStreakTheme.fontCaption(color: EduStreakTheme.studentDarkTextMuted),
            ),
          ],
        );

        final broadcastBtn = ElevatedButton.icon(
          onPressed: widget.onBroadcastToParents,
          icon: const Icon(Icons.campaign_rounded, size: 16),
          label: const Text('Broadcast Notice'),
          style: ElevatedButton.styleFrom(
            backgroundColor: EduStreakTheme.primaryViolet,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );

        if (isNarrow) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: EduStreakTheme.studentDarkCard,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: EduStreakTheme.studentDarkBorder, width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                textBlock,
                const SizedBox(height: 12),
                SizedBox(width: double.infinity, child: broadcastBtn),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: EduStreakTheme.studentDarkCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: EduStreakTheme.studentDarkBorder, width: 1.2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: textBlock),
              const SizedBox(width: 12),
              broadcastBtn,
            ],
          ),
        );
      },
    );
  }

  Widget _buildSubTabSelector() {
    return Row(
      children: [
        _buildPillButton(0, 'Linked Parents Directory', Icons.people_outline_rounded),
        const SizedBox(width: 10),
        _buildPillButton(1, 'Pending Link Requests', Icons.mark_email_unread_outlined, badgeCount: 2),
      ],
    );
  }

  Widget _buildPillButton(int index, String label, IconData icon, {int? badgeCount}) {
    final isSelected = _selectedSubTab == index;
    return InkWell(
      onTap: () => setState(() => _selectedSubTab = index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected ? EduStreakTheme.activePillGradient : null,
          color: isSelected ? null : EduStreakTheme.studentDarkCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.transparent : EduStreakTheme.studentDarkBorder,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : EduStreakTheme.studentDarkTextMuted),
            const SizedBox(width: 8),
            Text(
              label,
              style: EduStreakTheme.fontCaption(
                color: isSelected ? Colors.white : EduStreakTheme.studentDarkTextMuted,
                weight: isSelected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
            if (badgeCount != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withValues(alpha: 0.25) : EduStreakTheme.magentaPink.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$badgeCount',
                  style: TextStyle(
                    color: isSelected ? Colors.white : EduStreakTheme.magentaPink,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildParentDirectory(bool isDesktop, bool isTablet) {
    return Column(
      children: [
        // Search Box
        TextField(
          onChanged: (val) => setState(() => _searchQuery = val),
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search parents by name, email, or student roll number...',
            hintStyle: const TextStyle(color: Colors.white38),
            prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 18),
            filled: true,
            fillColor: EduStreakTheme.studentDarkCard,
            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: EduStreakTheme.studentDarkBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: EduStreakTheme.studentDarkBorder),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Parents List Stream
        Expanded(
          child: StreamBuilder<List<UserModel>>(
            stream: _principalService.getLinkedParentsStream(
              widget.school.id,
              searchQuery: _searchQuery,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: EduStreakTheme.primaryViolet));
              }

              final parents = snapshot.data ?? [];

              if (parents.isEmpty) {
                return Center(
                  child: Text(
                    'No parent records found',
                    style: EduStreakTheme.fontHeading3(color: Colors.white54),
                  ),
                );
              }

              return ListView.builder(
                itemCount: parents.length,
                itemBuilder: (context, index) {
                  final parent = parents[index];
                  final studentCount = parent.childIds.isNotEmpty ? parent.childIds.length : (parent.childId != null ? 1 : 0);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: EduStreakTheme.studentDarkCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: EduStreakTheme.studentDarkBorder),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: EduStreakTheme.magentaPink.withValues(alpha: 0.2),
                          child: Text(
                            parent.name.isNotEmpty ? parent.name[0].toUpperCase() : 'P',
                            style: const TextStyle(color: EduStreakTheme.magentaPink, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                parent.name,
                                style: EduStreakTheme.fontLabel(color: Colors.white, weight: FontWeight.w700),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                parent.email,
                                style: EduStreakTheme.fontCaption(color: EduStreakTheme.studentDarkTextMuted),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: EduStreakTheme.primaryViolet.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: EduStreakTheme.primaryViolet.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            '$studentCount Student(s) Linked',
                            style: EduStreakTheme.fontCaption(color: EduStreakTheme.primaryVioletLight, weight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: EduStreakTheme.emeraldGreen.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Verified',
                            style: TextStyle(color: EduStreakTheme.emeraldGreen, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPendingLinkRequests() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _principalService.getPendingApprovalsStream(widget.school.id),
      builder: (context, snapshot) {
        final allApprovals = snapshot.data ?? [];
        final linkRequests = allApprovals.where((a) => a['type'] == 'parent_linking' && a['status'] == 'pending').toList();

        if (linkRequests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_outline_rounded, size: 48, color: EduStreakTheme.emeraldGreen),
                const SizedBox(height: 12),
                Text(
                  'All Parent Linking Requests Reviewed',
                  style: EduStreakTheme.fontHeading3(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  'No pending student-guardian verification requests.',
                  style: EduStreakTheme.fontCaption(color: EduStreakTheme.studentDarkTextMuted),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: linkRequests.length,
          itemBuilder: (context, index) {
            final req = linkRequests[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: EduStreakTheme.studentDarkCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: EduStreakTheme.amberGold.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        req['title'] ?? 'Parent Link Request',
                        style: EduStreakTheme.fontLabel(color: Colors.white, weight: FontWeight.w800),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: EduStreakTheme.amberGold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Awaiting Review',
                          style: EduStreakTheme.fontCaption(color: EduStreakTheme.amberGold, weight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    req['description'] ?? '',
                    style: EduStreakTheme.fontCaption(color: Colors.white70),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Requested by: ${req['requestedBy']}',
                    style: EduStreakTheme.fontCaption(color: EduStreakTheme.studentDarkTextMuted),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => _handleApproval(req['id'], false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: EduStreakTheme.rosePink,
                          side: const BorderSide(color: EduStreakTheme.rosePink),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Reject'),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () => _handleApproval(req['id'], true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: EduStreakTheme.emeraldGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Approve Link'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleApproval(String requestId, bool approve) async {
    await _principalService.resolveApprovalRequest(
      schoolId: widget.school.id,
      requestId: requestId,
      approved: approve,
      reviewerUid: 'prin_current',
      reviewerName: 'Principal',
      reason: approve ? 'Verified matching admission roster record' : 'Invalid guardian details',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(approve ? '✓ Parent link request approved!' : 'Parent link request rejected.'),
          backgroundColor: approve ? EduStreakTheme.emeraldGreen : EduStreakTheme.rosePink,
        ),
      );
    }
  }
}
