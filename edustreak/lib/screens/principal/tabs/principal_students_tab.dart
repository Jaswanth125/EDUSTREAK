import 'package:flutter/material.dart';
import '../../../../models/school_model.dart';
import '../../../../models/user_model.dart';
import '../../../../services/principal_service.dart';
import '../../../../services/school_registration_service.dart';
import '../../../../utils/edustreak_theme.dart';
import '../../../../utils/responsive_breakpoints.dart';
import '../../../../widgets/responsive/responsive_dialog.dart';
import '../csv_import_dialog.dart';

class PrincipalStudentsTab extends StatefulWidget {
  final SchoolModel school;

  const PrincipalStudentsTab({super.key, required this.school});

  @override
  State<PrincipalStudentsTab> createState() => _PrincipalStudentsTabState();
}

class _PrincipalStudentsTabState extends State<PrincipalStudentsTab> {
  final _principalService = PrincipalService();
  final _searchController = TextEditingController();

  String _selectedClassFilter = 'All Classes';
  String _selectedStatusFilter = 'All';
  String _searchQuery = '';

  final _classOptions = const [
    'All Classes',
    'Class 10-A',
    'Class 10-B',
    'Class 9-A',
    'Class 9-B',
    'Class 8-A',
    'Class 8-B',
    'Class 7-A',
    'Class 7-B',
    'Class 6-A',
    'Class 6-B',
  ];

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
          // ─── SEARCH & FILTER TOOLBAR ───────────────────────────────────
          _buildFilterToolbar(isDesktop),

          const SizedBox(height: 18),

          // ─── STUDENTS STREAM LIST / GRID ───────────────────────────────
          Expanded(
            child: StreamBuilder<List<UserModel>>(
              stream: _principalService.getStudentsStream(
                widget.school.id,
                classFilter: _selectedClassFilter,
                searchQuery: _searchQuery,
                statusFilter: _selectedStatusFilter,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: EduStreakTheme.primaryViolet),
                  );
                }

                final students = snapshot.data ?? [];

                if (students.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.school_outlined, size: 54, color: EduStreakTheme.studentDarkTextMuted),
                        const SizedBox(height: 12),
                        Text(
                          'No students found matching current filters',
                          style: EduStreakTheme.fontHeading3(color: Colors.white70),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Try clearing your search query or selecting "All Classes".',
                          style: EduStreakTheme.fontCaption(color: EduStreakTheme.studentDarkTextMuted),
                        ),
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
                    childAspectRatio: isDesktop ? 1.9 : (isTablet ? 1.7 : 2.1),
                  ),
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final student = students[index];
                    return _buildStudentCard(student);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterToolbar(bool isDesktop) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EduStreakTheme.studentDarkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EduStreakTheme.studentDarkBorder, width: 1.2),
      ),
      child: Column(
        children: [
          // Header with Import CSV button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Student Roster & Directory',
                  style: EduStreakTheme.fontHeading3(color: Colors.white, weight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => CsvImportDialog.show(context, school: widget.school, initialTab: 0),
                icon: const Icon(Icons.upload_file_rounded, size: 16),
                label: const Text('Import CSV'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: EduStreakTheme.primaryViolet,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 520;

              final searchField = TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search by student name, roll number, or email...',
                  hintStyle: TextStyle(color: EduStreakTheme.studentDarkTextMuted.withValues(alpha: 0.6)),
                  prefixIcon: const Icon(Icons.search_rounded, color: EduStreakTheme.primaryViolet),
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
              );

              final dropdownField = Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF14193E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF283168)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedClassFilter,
                    dropdownColor: const Color(0xFF191F4D),
                    icon: const Icon(Icons.arrow_drop_down_rounded, color: EduStreakTheme.primaryViolet),
                    style: EduStreakTheme.fontCaption(color: Colors.white, weight: FontWeight.w700),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedClassFilter = val);
                    },
                    items: _classOptions.map((c) {
                      return DropdownMenuItem<String>(
                        value: c,
                        child: Text(c),
                      );
                    }).toList(),
                  ),
                ),
              );

              if (isNarrow) {
                return Column(
                  children: [
                    searchField,
                    const SizedBox(height: 10),
                    SizedBox(width: double.infinity, child: dropdownField),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: searchField),
                  const SizedBox(width: 14),
                  dropdownField,
                ],
              );
            },
          ),
          const SizedBox(height: 12),

          // Status Filter Chips (Scrollable)
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
                const SizedBox(width: 8),
                _buildStatusChip('Top Performers'),
                const SizedBox(width: 8),
                _buildStatusChip('At-Risk'),
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

  Widget _buildStudentCard(UserModel student) {
    final isAtRisk = student.streakCount < 3 || student.xp < 250;
    final isTop = student.streakCount >= 7 || student.xp >= 400;

    return InkWell(
      onTap: () => _showStudentDetailsModal(student),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: EduStreakTheme.studentDarkCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isAtRisk
                ? EduStreakTheme.rosePink.withValues(alpha: 0.4)
                : EduStreakTheme.studentDarkBorder,
            width: 1.2,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Student Avatar with Streak badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: EduStreakTheme.primaryViolet.withValues(alpha: 0.25),
                  child: Text(
                    student.name.isNotEmpty ? student.name[0] : 'S',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Positioned(
                  bottom: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9800),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '🔥${student.streakCount}',
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),

            // Student Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          student.name,
                          style: EduStreakTheme.fontBody(color: Colors.white, weight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (student.status == 'not_registered' || !student.isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: EduStreakTheme.amberGold.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'UNREGISTERED',
                            style: EduStreakTheme.fontSmall(color: EduStreakTheme.amberGold, weight: FontWeight.w800),
                          ),
                        )
                      else if (student.status == 'suspended')
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: EduStreakTheme.rosePink.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'SUSPENDED',
                            style: EduStreakTheme.fontSmall(color: EduStreakTheme.rosePink, weight: FontWeight.w800),
                          ),
                        )
                      else if (isAtRisk)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: EduStreakTheme.rosePink.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'AT-RISK',
                            style: EduStreakTheme.fontSmall(color: EduStreakTheme.rosePink, weight: FontWeight.w800),
                          ),
                        )
                      else if (isTop)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: EduStreakTheme.emeraldGreen.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'TOP',
                            style: EduStreakTheme.fontSmall(color: EduStreakTheme.emeraldGreen, weight: FontWeight.w800),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Roll: ${student.rollNumber ?? "N/A"} • Class ${student.grade ?? "10"}-${student.section ?? "A"}',
                    style: EduStreakTheme.fontCaption(color: EduStreakTheme.studentDarkTextMuted),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        '⚡ ${student.xp} XP',
                        style: EduStreakTheme.fontSmall(color: EduStreakTheme.neonCyan, weight: FontWeight.w700),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Lvl ${student.level}',
                        style: EduStreakTheme.fontSmall(color: EduStreakTheme.amberGold, weight: FontWeight.w700),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white30, size: 14),
          ],
        ),
      ),
    );
  }

  void _showStudentDetailsModal(UserModel student) {
    showAdaptiveEduStreakModal(
      context: context,
      title: 'Student Dossier: ${student.name}',
      icon: const Icon(Icons.badge_rounded, color: EduStreakTheme.neonCyan),
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
                  backgroundColor: EduStreakTheme.primaryViolet,
                  child: Text(
                    student.name[0],
                    style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(student.name, style: EduStreakTheme.fontHeading2(color: Colors.white, weight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(
                        'Class ${student.grade ?? "10"}-${student.section ?? "A"} • Roll Number: ${student.rollNumber ?? "101"}',
                        style: EduStreakTheme.fontBody(color: EduStreakTheme.neonCyan),
                      ),
                      Text(
                        student.email,
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

            Text('Academic & Engagement Metrics', style: EduStreakTheme.fontHeading3(color: Colors.white, weight: FontWeight.w700)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _buildModalStatBox('Attendance Rate', '94.2%', EduStreakTheme.emeraldGreen)),
                const SizedBox(width: 8),
                Expanded(child: _buildModalStatBox('SA-1 Score', '86.5%', EduStreakTheme.primaryViolet)),
                const SizedBox(width: 8),
                Expanded(child: _buildModalStatBox('Daily Streak', '${student.streakCount} Days', const Color(0xFFFF9800))),
                const SizedBox(width: 8),
                Expanded(child: _buildModalStatBox('Earned XP', '${student.xp} XP', EduStreakTheme.neonCyan)),
              ],
            ),

            const SizedBox(height: 18),
            Text('Guardian & Contact Details', style: EduStreakTheme.fontHeading3(color: Colors.white, weight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Parent / Guardian: Ramesh Chen (Father)', style: EduStreakTheme.fontBody(color: Colors.white70)),
            Text('Phone: +91 94401 54321', style: EduStreakTheme.fontBody(color: Colors.white70)),
            Text('Address: D.No. 4-12, Kankipadu Village, Krishna Dist.', style: EduStreakTheme.fontBody(color: Colors.white70)),
            const SizedBox(height: 14),
            Row(
              children: [
                Text('Account Status: ', style: EduStreakTheme.fontSmall(color: Colors.white70, weight: FontWeight.w700)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: student.status == 'active'
                        ? EduStreakTheme.emeraldGreen.withValues(alpha: 0.2)
                        : (student.status == 'suspended'
                            ? EduStreakTheme.rosePink.withValues(alpha: 0.2)
                            : EduStreakTheme.amberGold.withValues(alpha: 0.2)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    student.status.toUpperCase(),
                    style: TextStyle(
                      color: student.status == 'active'
                          ? EduStreakTheme.emeraldGreen
                          : (student.status == 'suspended'
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
            final newStatus = student.status == 'suspended' ? 'active' : 'suspended';
            await SchoolRegistrationService().updateAccountStatus(
              entityId: student.id,
              newStatus: newStatus,
              role: 'student',
              schoolId: widget.school.id,
            );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Student status updated to $newStatus'),
                  backgroundColor: newStatus == 'active' ? EduStreakTheme.emeraldGreen : EduStreakTheme.rosePink,
                ),
              );
            }
          },
          icon: Icon(student.status == 'suspended' ? Icons.check_circle_outline : Icons.block_rounded, size: 16),
          label: Text(student.status == 'suspended' ? 'Reactivate' : 'Suspend Account'),
          style: OutlinedButton.styleFrom(
            foregroundColor: student.status == 'suspended' ? EduStreakTheme.emeraldGreen : EduStreakTheme.rosePink,
            side: BorderSide(color: student.status == 'suspended' ? EduStreakTheme.emeraldGreen : EduStreakTheme.rosePink),
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
                content: Text('Notification dispatched to parent of ${student.name}'),
                backgroundColor: EduStreakTheme.emeraldGreen,
              ),
            );
          },
          icon: const Icon(Icons.send_rounded, size: 16),
          label: const Text('Notify Parent'),
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
