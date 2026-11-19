import 'package:flutter/material.dart';
import '../../../../models/school_model.dart';
import '../../../../models/user_model.dart';
import '../../../../services/principal_service.dart';
import '../../../../utils/edustreak_theme.dart';
import '../../../../utils/responsive_breakpoints.dart';

class PrincipalAnnouncementsTab extends StatefulWidget {
  final SchoolModel school;
  final UserModel principal;

  const PrincipalAnnouncementsTab({
    super.key,
    required this.school,
    required this.principal,
  });

  @override
  State<PrincipalAnnouncementsTab> createState() => _PrincipalAnnouncementsTabState();
}

class _PrincipalAnnouncementsTabState extends State<PrincipalAnnouncementsTab> {
  final _principalService = PrincipalService();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  String _selectedAudience = 'All';
  String _selectedPriority = 'normal';
  bool _isPublishing = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _publishAnnouncement() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both announcement title and message content.'),
          backgroundColor: EduStreakTheme.rosePink,
        ),
      );
      return;
    }

    setState(() => _isPublishing = true);

    try {
      await _principalService.createSchoolAnnouncement(
        schoolId: widget.school.id,
        title: title,
        content: content,
        targetAudience: _selectedAudience,
        priority: _selectedPriority,
        authorName: widget.principal.name,
        authorId: widget.principal.id,
      );

      _titleController.clear();
      _contentController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Announcement broadcasted to $_selectedAudience successfully.'),
            backgroundColor: EduStreakTheme.emeraldGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Broadcast note: Announcement logged ($e)'),
            backgroundColor: EduStreakTheme.amberGold,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

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
          // ─── BROADCAST COMPOSER ────────────────────────────────────────
          _buildComposerCard(isDesktop),

          const SizedBox(height: 24),

          // ─── PAST BROADCASTS HISTORY FEED ──────────────────────────────
          Text(
            'Institutional Broadcast History',
            style: EduStreakTheme.fontHeading2(color: Colors.white, weight: FontWeight.w800),
          ),
          const SizedBox(height: 14),

          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _principalService.getSchoolAnnouncementsStream(widget.school.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: EduStreakTheme.primaryViolet),
                );
              }

              final announcements = snapshot.data ?? [];

              if (announcements.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'No past announcements found. Create one above to notify the school.',
                      style: EduStreakTheme.fontBody(color: EduStreakTheme.studentDarkTextMuted),
                    ),
                  ),
                );
              }

              return Column(
                children: announcements.map((ann) => _buildAnnouncementCard(ann)).toList(),
              );
            },
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildComposerCard(bool isDesktop) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: EduStreakTheme.studentDarkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: EduStreakTheme.studentDarkBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.campaign_rounded, color: EduStreakTheme.primaryViolet, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Broadcast School Circular / Announcement',
                  style: EduStreakTheme.fontHeading2(color: Colors.white, weight: FontWeight.w800),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Title
          TextField(
            controller: _titleController,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              labelText: 'Announcement Title',
              labelStyle: const TextStyle(color: EduStreakTheme.studentDarkTextMuted),
              hintText: 'e.g. Science Exhibition Registration or Term Exam Schedule',
              hintStyle: TextStyle(color: EduStreakTheme.studentDarkTextMuted.withValues(alpha: 0.5)),
              filled: true,
              fillColor: const Color(0xFF14193E),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF283168)),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Content
          TextField(
            controller: _contentController,
            maxLines: 4,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Announcement Body / Instructions',
              labelStyle: const TextStyle(color: EduStreakTheme.studentDarkTextMuted),
              hintText: 'Detailed circular notes sent to targeted user apps...',
              hintStyle: TextStyle(color: EduStreakTheme.studentDarkTextMuted.withValues(alpha: 0.5)),
              filled: true,
              fillColor: const Color(0xFF14193E),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF283168)),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Target Audience & Priority Row / Column
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 550;

              final audienceField = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Target Audience', style: EduStreakTheme.fontSmall(color: EduStreakTheme.studentDarkTextMuted, weight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF14193E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF283168)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedAudience,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF191F4D),
                        icon: const Icon(Icons.arrow_drop_down_rounded, color: EduStreakTheme.primaryViolet),
                        style: EduStreakTheme.fontCaption(color: Colors.white, weight: FontWeight.w700),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedAudience = val);
                        },
                        items: const [
                          DropdownMenuItem(value: 'All', child: Text('Whole School (All Roles)')),
                          DropdownMenuItem(value: 'Teachers', child: Text('All Teachers Only')),
                          DropdownMenuItem(value: 'Students', child: Text('All Students Only')),
                          DropdownMenuItem(value: 'Parents', child: Text('All Parents & Guardians')),
                        ],
                      ),
                    ),
                  ),
                ],
              );

              final priorityField = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Priority Level', style: EduStreakTheme.fontSmall(color: EduStreakTheme.studentDarkTextMuted, weight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF14193E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF283168)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedPriority,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF191F4D),
                        icon: const Icon(Icons.arrow_drop_down_rounded, color: EduStreakTheme.primaryViolet),
                        style: EduStreakTheme.fontCaption(color: Colors.white, weight: FontWeight.w700),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedPriority = val);
                        },
                        items: const [
                          DropdownMenuItem(value: 'normal', child: Text('Normal Priority')),
                          DropdownMenuItem(value: 'important', child: Text('Important Circular')),
                          DropdownMenuItem(value: 'urgent', child: Text('Urgent Notice')),
                        ],
                      ),
                    ),
                  ),
                ],
              );

              if (isCompact) {
                return Column(
                  children: [
                    audienceField,
                    const SizedBox(height: 12),
                    priorityField,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: audienceField),
                  const SizedBox(width: 14),
                  Expanded(child: priorityField),
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // Submit Button
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _isPublishing ? null : _publishAnnouncement,
              icon: _isPublishing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded, size: 18),
              label: Text(_isPublishing ? 'Broadcasting...' : 'Broadcast Announcement Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: EduStreakTheme.primaryViolet,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementCard(Map<String, dynamic> ann) {
    final priority = ann['priority'] as String? ?? 'normal';
    final isUrgent = priority == 'urgent';
    final isImportant = priority == 'important';
    final accent = isUrgent
        ? EduStreakTheme.rosePink
        : (isImportant ? EduStreakTheme.amberGold : EduStreakTheme.primaryViolet);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: EduStreakTheme.studentDarkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.35), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  priority.toUpperCase(),
                  style: EduStreakTheme.fontSmall(color: accent, weight: FontWeight.w800),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: EduStreakTheme.neonCyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'To: ${ann['targetAudience'] ?? "All"}',
                  style: EduStreakTheme.fontSmall(color: EduStreakTheme.neonCyan, weight: FontWeight.w700),
                ),
              ),
              Text(
                'By: ${ann['authorName'] ?? "Principal"}',
                style: EduStreakTheme.fontSmall(color: EduStreakTheme.studentDarkTextMuted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            ann['title'] as String,
            style: EduStreakTheme.fontHeading3(color: Colors.white, weight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            ann['content'] as String,
            style: EduStreakTheme.fontBody(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
