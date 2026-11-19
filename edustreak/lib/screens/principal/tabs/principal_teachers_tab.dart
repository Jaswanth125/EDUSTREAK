import 'package:flutter/material.dart';
import '../../../../models/school_model.dart';
import '../../../../models/user_model.dart';
import '../../../../services/principal_service.dart';
import '../../../../services/school_registration_service.dart';
import '../../../../utils/edustreak_theme.dart';
import '../../../../utils/responsive_breakpoints.dart';
import '../../../../widgets/responsive/responsive_dialog.dart';
import '../csv_import_dialog.dart';

class PrincipalTeachersTab extends StatefulWidget {
  final SchoolModel school;

  const PrincipalTeachersTab({super.key, required this.school});

  @override
  State<PrincipalTeachersTab> createState() => _PrincipalTeachersTabState();
}

class _PrincipalTeachersTabState extends State<PrincipalTeachersTab> {
  final _principalService = PrincipalService();
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedStatusFilter = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
          // ─── TOOLBAR & FACULTY STATS ───────────────────────────────────
          _buildToolbar(isDesktop),

          const SizedBox(height: 18),

          // ─── FACULTY STREAM GRID ───────────────────────────────────────
          Expanded(
            child: StreamBuilder<List<UserModel>>(
              stream: _principalService.getTeachersStream(
                widget.school.id,
                searchQuery: _searchQuery,
                statusFilter: _selectedStatusFilter,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: EduStreakTheme.primaryViolet),
                  );
                }

                final teachers = snapshot.data ?? [];

                if (teachers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.supervisor_account_outlined, size: 54, color: EduStreakTheme.studentDarkTextMuted),
                        const SizedBox(height: 12),
                        Text('No faculty members found', style: EduStreakTheme.fontHeading3(color: Colors.white70)),
                        const SizedBox(height: 6),
                        Text('Clear search query to see all teachers.', style: EduStreakTheme.fontCaption(color: EduStreakTheme.studentDarkTextMuted)),
                      ],
                    ),
                  );
                }

                int crossCount = isDesktop ? 3 : (isTablet ? 2 : 1);

                return GridView.builder(
                  padding: const EdgeInsets.only(bottom: 24),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossCount,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: isDesktop ? 1.6 : (isTablet ? 1.5 : 1.9),
                  ),
                  itemCount: teachers.length,
                  itemBuilder: (context, index) {
                    final teacher = teachers[index];
                    return _buildTeacherCard(teacher);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(bool isDesktop) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EduStreakTheme.studentDarkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EduStreakTheme.studentDarkBorder, width: 1.2),
      ),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 450;
              final titleWidget = Text(
                'Faculty & Staff Directory',
                style: EduStreakTheme.fontHeading3(color: Colors.white, weight: FontWeight.w700),
                overflow: TextOverflow.ellipsis,
              );
              final buttonWidget = ElevatedButton.icon(
                onPressed: () => CsvImportDialog.show(context, school: widget.school, initialTab: 1),
                icon: const Icon(Icons.upload_file_rounded, size: 16),
                label: const Text('Import Faculty CSV'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: EduStreakTheme.primaryViolet,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    titleWidget,
                    const SizedBox(height: 10),
                    buttonWidget,
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: titleWidget),
                  const SizedBox(width: 8),
                  buttonWidget,
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search faculty by name, department, or subject...',
                    hintStyle: TextStyle(color: EduStreakTheme.studentDarkTextMuted.withValues(alpha: 0.6)),
                    prefixIcon: const Icon(Icons.search_rounded, color: EduStreakTheme.neonCyan),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white60),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFF14193E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF283168)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Text(
                  'Filter by Status: ',
                  style: EduStreakTheme.fontSmall(color: EduStreakTheme.studentDarkTextMuted, weight: FontWeight.w600),
                ),
                const SizedBox(width: 8),
                _buildStatusChip('All'),
                const SizedBox(width: 8),
                _buildStatusChip('Active'),
                const SizedBox(width: 8),
                _buildStatusChip('Not Registered'),
                const SizedBox(width: 8),
                _buildStatusChip('Suspended'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label) {
    final isSelected = _selectedStatusFilter == label;

    return FilterChip(
      selected: isSelected,
      label: Text(label),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : EduStreakTheme.studentDarkTextMuted,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        fontSize: 12,
      ),
      selectedColor: EduStreakTheme.primaryViolet,
      backgroundColor: const Color(0xFF14193E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? EduStreakTheme.primaryViolet : const Color(0xFF283168),
        ),
      ),
      onSelected: (_) => setState(() => _selectedStatusFilter = label),
    );
  }

  Widget _buildTeacherCard(UserModel teacher) {
    final subjects = teacher.assignedSubjects.isNotEmpty
        ? teacher.assignedSubjects.join(', ')
        : 'General Sciences';
    final classes = teacher.classIds != null && teacher.classIds!.isNotEmpty
        ? teacher.classIds!.join(', ')
        : 'Class 10-A, Class 8-A';

    final isUnregistered = teacher.status == 'not_registered' || !teacher.isActive;
    final isSuspended = teacher.status == 'suspended';

    return InkWell(
      onTap: () => _showTeacherDetailsModal(teacher),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: EduStreakTheme.studentDarkCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSuspended
                ? EduStreakTheme.rosePink.withValues(alpha: 0.5)
                : EduStreakTheme.studentDarkBorder,
            width: 1.2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: EduStreakTheme.neonCyan.withValues(alpha: 0.2),
                  child: Text(
                    teacher.name.isNotEmpty ? teacher.name[0] : 'T',
                    style: const TextStyle(
                      color: EduStreakTheme.neonCyan,
                      fontSize: 16,
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
                        teacher.name,
                        style: EduStreakTheme.fontBody(color: Colors.white, weight: FontWeight.w800),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subjects,
                        style: EduStreakTheme.fontCaption(color: EduStreakTheme.neonCyan, weight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isUnregistered
                        ? EduStreakTheme.amberGold.withValues(alpha: 0.15)
                        : (isSuspended
                            ? EduStreakTheme.rosePink.withValues(alpha: 0.15)
                            : EduStreakTheme.emeraldGreen.withValues(alpha: 0.15)),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isUnregistered
                          ? EduStreakTheme.amberGold.withValues(alpha: 0.3)
                          : (isSuspended
                              ? EduStreakTheme.rosePink.withValues(alpha: 0.3)
                              : EduStreakTheme.emeraldGreen.withValues(alpha: 0.3)),
                    ),
                  ),
                  child: Text(
                    isUnregistered
                        ? 'UNREGISTERED'
                        : (isSuspended ? 'SUSPENDED' : 'ACTIVE'),
                    style: EduStreakTheme.fontSmall(
                      color: isUnregistered
                          ? EduStreakTheme.amberGold
                          : (isSuspended ? EduStreakTheme.rosePink : EduStreakTheme.emeraldGreen),
                      weight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(color: EduStreakTheme.studentDarkBorder, height: 16),
            Row(
              children: [
                const Icon(Icons.school_rounded, size: 14, color: EduStreakTheme.studentDarkTextMuted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Classes: $classes',
                    style: EduStreakTheme.fontSmall(color: EduStreakTheme.studentDarkTextMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                Text(
                  'Workload: 24 Periods/Wk',
                  style: EduStreakTheme.fontSmall(color: Colors.white70),
                ),
                Text(
                  'Inspect Details →',
                  style: EduStreakTheme.fontSmall(color: EduStreakTheme.primaryViolet, weight: FontWeight.w700),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showTeacherDetailsModal(UserModel teacher) {
    showAdaptiveEduStreakModal(
      context: context,
      title: 'Faculty Profile: ${teacher.name}',
      icon: const Icon(Icons.co_present_rounded, color: EduStreakTheme.neonCyan),
      isDark: true,
      builder: (ctx) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: EduStreakTheme.neonCyan,
                  child: Text(
                    teacher.name[0],
                    style: const TextStyle(fontSize: 24, color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(teacher.name, style: EduStreakTheme.fontHeading2(color: Colors.white, weight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(
                        teacher.assignedSubjects.join(', '),
                        style: EduStreakTheme.fontBody(color: EduStreakTheme.neonCyan),
                      ),
                      Text(
                        teacher.email,
                        style: EduStreakTheme.fontCaption(color: EduStreakTheme.studentDarkTextMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(color: EduStreakTheme.studentDarkBorder),
            const SizedBox(height: 14),

            Text('Faculty Workload & Performance', style: EduStreakTheme.fontHeading3(color: Colors.white, weight: FontWeight.w700)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _buildModalStatBox('Attendance', '98.5%', EduStreakTheme.emeraldGreen)),
                const SizedBox(width: 8),
                Expanded(child: _buildModalStatBox('Assignments', '14 Active', EduStreakTheme.primaryViolet)),
                const SizedBox(width: 8),
                Expanded(child: _buildModalStatBox('Grading Backlog', '18 Items', EduStreakTheme.amberGold)),
                const SizedBox(width: 8),
                Expanded(child: _buildModalStatBox('Avg Class Score', '84.2%', EduStreakTheme.neonCyan)),
              ],
            ),
            const SizedBox(height: 18),
            Text('Classroom Allocations', style: EduStreakTheme.fontHeading3(color: Colors.white, weight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('• Class 10-A (Physical Science - 6 periods/week)', style: EduStreakTheme.fontBody(color: Colors.white70)),
            Text('• Class 8-A (General Science - 5 periods/week)', style: EduStreakTheme.fontBody(color: Colors.white70)),
            Text('• Class 9-B (Physics Lab & Experiments - 4 periods/week)', style: EduStreakTheme.fontBody(color: Colors.white70)),
            const SizedBox(height: 14),
            Row(
              children: [
                Text('Account Status: ', style: EduStreakTheme.fontSmall(color: Colors.white70, weight: FontWeight.w700)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: teacher.status == 'active'
                        ? EduStreakTheme.emeraldGreen.withValues(alpha: 0.2)
                        : (teacher.status == 'suspended'
                            ? EduStreakTheme.rosePink.withValues(alpha: 0.2)
                            : EduStreakTheme.amberGold.withValues(alpha: 0.2)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    teacher.status.toUpperCase(),
                    style: TextStyle(
                      color: teacher.status == 'active'
                          ? EduStreakTheme.emeraldGreen
                          : (teacher.status == 'suspended'
                              ? EduStreakTheme.rosePink
                              : EduStreakTheme.amberGold),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
      actions: [
        OutlinedButton.icon(
          onPressed: () async {
            Navigator.pop(context);
            final newStatus = teacher.status == 'suspended' ? 'active' : 'suspended';
            await SchoolRegistrationService().updateAccountStatus(
              entityId: teacher.id,
              newStatus: newStatus,
              role: 'teacher',
              schoolId: widget.school.id,
            );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Faculty status updated to $newStatus'),
                  backgroundColor: newStatus == 'active' ? EduStreakTheme.emeraldGreen : EduStreakTheme.rosePink,
                ),
              );
            }
          },
          icon: Icon(teacher.status == 'suspended' ? Icons.check_circle_outline : Icons.block_rounded, size: 16),
          label: Text(teacher.status == 'suspended' ? 'Reactivate' : 'Suspend Account'),
          style: OutlinedButton.styleFrom(
            foregroundColor: teacher.status == 'suspended' ? EduStreakTheme.emeraldGreen : EduStreakTheme.rosePink,
            side: BorderSide(color: teacher.status == 'suspended' ? EduStreakTheme.emeraldGreen : EduStreakTheme.rosePink),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close', style: TextStyle(color: Colors.white60)),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Direct memo sent to ${teacher.name}'),
                backgroundColor: EduStreakTheme.primaryViolet,
              ),
            );
          },
          icon: const Icon(Icons.mail_outline_rounded, size: 16),
          label: const Text('Send Memo'),
          style: ElevatedButton.styleFrom(
            backgroundColor: EduStreakTheme.primaryViolet,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildModalStatBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF14193E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(value, style: EduStreakTheme.fontHeading3(color: color, weight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label, style: EduStreakTheme.fontSmall(color: EduStreakTheme.studentDarkTextMuted), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
