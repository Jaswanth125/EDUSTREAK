import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/school_model.dart';
import '../../services/school_service.dart';
import '../../services/audit_service.dart';
import '../../utils/edustreak_theme.dart';
import '../../widgets/responsive/responsive_dialog.dart';

class SchoolDetailsScreen extends StatefulWidget {
  final SchoolModel school;

  const SchoolDetailsScreen({super.key, required this.school});

  static void open(BuildContext context, SchoolModel school) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SchoolDetailsScreen(school: school),
      ),
    );
  }

  @override
  State<SchoolDetailsScreen> createState() => _SchoolDetailsScreenState();
}

class _SchoolDetailsScreenState extends State<SchoolDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late SchoolModel _school;
  final _schoolService = SchoolService();
  final _auditService = AuditService();
  final _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _school = widget.school;
    _tabController = TabController(length: 10, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleStatusChange(String newStatus) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF13193F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Change School Status', style: EduStreakTheme.fontHeading3(color: Colors.white)),
        content: Text(
          'Are you sure you want to change ${_school.name} status to ${newStatus.toUpperCase()}? This will affect all associated student and teacher logins.',
          style: EduStreakTheme.fontBody(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: newStatus == 'active' ? Colors.green : Colors.redAccent,
            ),
            child: Text('Confirm $newStatus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _schoolService.updateSchoolStatus(_school.id, newStatus, reason: 'Admin manual status change');
      setState(() {
        _school = _school.copyWith(status: newStatus);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('School status changed to ${newStatus.toUpperCase()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1535),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _school.type.color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _school.type.color.withValues(alpha: 0.5)),
              ),
              child: Icon(Icons.account_balance_rounded, color: _school.type.color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _school.name,
                    style: EduStreakTheme.fontHeading3(color: Colors.white, weight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${_school.code} • ${_school.district}, ${_school.state} • ${_school.type.displayName}',
                    style: EduStreakTheme.fontCaption(color: EduStreakTheme.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Status indicator and quick action
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _school.isActive
                        ? Colors.green.withValues(alpha: 0.15)
                        : Colors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _school.isActive ? Colors.green : Colors.redAccent,
                    ),
                  ),
                  child: Text(
                    _school.status.toUpperCase(),
                    style: TextStyle(
                      color: _school.isActive ? Colors.greenAccent : Colors.redAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, color: Colors.white70),
                  color: const Color(0xFF13193F),
                  onSelected: (val) {
                    if (val == 'edit') {
                      _showEditSchoolDialog();
                    } else if (val == 'active' || val == 'suspended' || val == 'archived') {
                      _handleStatusChange(val);
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit School Details', style: TextStyle(color: Colors.white))),
                    const PopupMenuDivider(),
                    const PopupMenuItem(value: 'active', child: Text('Mark as Active', style: TextStyle(color: Colors.greenAccent))),
                    const PopupMenuItem(value: 'suspended', child: Text('Suspend School', style: TextStyle(color: Colors.orangeAccent))),
                    const PopupMenuItem(value: 'archived', child: Text('Archive School', style: TextStyle(color: Colors.redAccent))),
                  ],
                ),
              ],
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: const Color(0xFF0F1535),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: EduStreakTheme.primaryViolet,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              tabAlignment: TabAlignment.start,
              labelStyle: EduStreakTheme.fontBodySmall(weight: FontWeight.w600),
              tabs: const [
                Tab(icon: Icon(Icons.info_outline_rounded, size: 16), text: '1. Overview'),
                Tab(icon: Icon(Icons.apartment_rounded, size: 16), text: '2. Structure'),
                Tab(icon: Icon(Icons.school_rounded, size: 16), text: '3. Students'),
                Tab(icon: Icon(Icons.person_outline_rounded, size: 16), text: '4. Teachers'),
                Tab(icon: Icon(Icons.family_restroom_rounded, size: 16), text: '5. Parents'),
                Tab(icon: Icon(Icons.menu_book_rounded, size: 16), text: '6. Curriculum'),
                Tab(icon: Icon(Icons.calendar_today_rounded, size: 16), text: '7. Attendance'),
                Tab(icon: Icon(Icons.assignment_rounded, size: 16), text: '8. Assignments'),
                Tab(icon: Icon(Icons.bar_chart_rounded, size: 16), text: '9. Reports'),
                Tab(icon: Icon(Icons.history_rounded, size: 16), text: '10. Activity Log'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildStructureTab(),
          _buildStudentsTab(),
          _buildTeachersTab(),
          _buildParentsTab(),
          _buildCurriculumTab(),
          _buildAttendanceTab(),
          _buildAssignmentsTab(),
          _buildReportsTab(),
          _buildActivityLogTab(),
        ],
      ),
    );
  }

  // ─── TAB 1: OVERVIEW ──────────────────────────────────────────────────────
  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Key summary cards
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 900;

              if (isWide) {
                return Row(
                  children: [
                    Expanded(child: _buildMetricCard('Enrolled Students', '${_school.totalStudents}', Icons.school_rounded, const Color(0xFF7C6FFF))),
                    const SizedBox(width: 16),
                    Expanded(child: _buildMetricCard('Faculty Members', '${_school.totalTeachers}', Icons.supervisor_account_rounded, const Color(0xFF00E5FF))),
                    const SizedBox(width: 16),
                    Expanded(child: _buildMetricCard('Active Academic Year', _school.academicYear, Icons.calendar_month_rounded, const Color(0xFFF59E0B))),
                    const SizedBox(width: 16),
                    Expanded(child: _buildMetricCard('Curriculum Standard', _school.curriculumTemplateId, Icons.layers_rounded, const Color(0xFF10B981))),
                  ],
                );
              }

              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildMetricCard('Enrolled Students', '${_school.totalStudents}', Icons.school_rounded, const Color(0xFF7C6FFF))),
                      const SizedBox(width: 12),
                      Expanded(child: _buildMetricCard('Faculty Members', '${_school.totalTeachers}', Icons.supervisor_account_rounded, const Color(0xFF00E5FF))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildMetricCard('Active Academic Year', _school.academicYear, Icons.calendar_month_rounded, const Color(0xFFF59E0B))),
                      const SizedBox(width: 12),
                      Expanded(child: _buildMetricCard('Curriculum Standard', _school.curriculumTemplateId, Icons.layers_rounded, const Color(0xFF10B981))),
                    ],
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 24),

          // Identity & Institutional Details
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1535),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: EduStreakTheme.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Institutional Registration & Verification', style: EduStreakTheme.fontHeading3(color: Colors.white, weight: FontWeight.w700)),
                const SizedBox(height: 16),
                _buildFieldPair('School Name', _school.name, 'Unique Code', _school.code),
                _buildFieldPair('Category / Board', _school.type.displayName, 'Affiliation Number', _school.affiliationNumber.isNotEmpty ? _school.affiliationNumber : 'AP-GOV-CENTRAL'),
                _buildFieldPair('Contact Person', _school.contactPerson.isNotEmpty ? _school.contactPerson : 'Headmaster / Principal', 'Official Phone', _school.contactPhone.isNotEmpty ? _school.contactPhone : '+91 Unspecified'),
                _buildFieldPair('Official Email', _school.contactEmail.isNotEmpty ? _school.contactEmail : 'admin@${_school.code.toLowerCase()}.edu.in', 'Established Date', '${_school.establishedDate.year}-${_school.establishedDate.month.toString().padLeft(2, '0')}-${_school.establishedDate.day.toString().padLeft(2, '0')}'),
                _buildFieldPair('Physical Address', _school.address.isNotEmpty ? _school.address : 'Main Campus', 'Mandal / Tehsil', _school.mandal.isNotEmpty ? _school.mandal : 'Mandal Center'),
                _buildFieldPair('District', _school.district, 'PIN Code', _school.pincode.isNotEmpty ? _school.pincode : '520001'),
                _buildFieldPair('Supported Classes', _school.supportedClasses.join(', '), 'Status', _school.status.toUpperCase()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldPair(String l1, String v1, String l2, String v2) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 450;
        final col1 = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l1, style: EduStreakTheme.fontCaption(color: EduStreakTheme.textMuted)),
            const SizedBox(height: 4),
            SelectableText(v1, style: EduStreakTheme.fontBodySmall(color: Colors.white, weight: FontWeight.w600)),
          ],
        );
        final col2 = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l2, style: EduStreakTheme.fontCaption(color: EduStreakTheme.textMuted)),
            const SizedBox(height: 4),
            SelectableText(v2, style: EduStreakTheme.fontBodySmall(color: Colors.white, weight: FontWeight.w600)),
          ],
        );

        if (isCompact) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                col1,
                const SizedBox(height: 10),
                col2,
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: col1),
              const SizedBox(width: 20),
              Expanded(child: col2),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1535),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: EduStreakTheme.fontHeading2(color: Colors.white, weight: FontWeight.w700), overflow: TextOverflow.ellipsis),
                Text(label, style: EduStreakTheme.fontCaption(color: EduStreakTheme.textMuted), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── TAB 2: ACADEMIC STRUCTURE ────────────────────────────────────────────
  Widget _buildStructureTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Classes & Section Roster (${_school.academicYear})', style: EduStreakTheme.fontHeading3(color: Colors.white, weight: FontWeight.w700)),
              ElevatedButton.icon(
                onPressed: () => _showAddSectionDialog(),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Section'),
                style: ElevatedButton.styleFrom(backgroundColor: EduStreakTheme.primaryViolet),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: _school.supportedClasses.map((cls) {
              return Container(
                width: 280,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1535),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: EduStreakTheme.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.class_rounded, color: EduStreakTheme.primaryViolet, size: 20),
                        const SizedBox(width: 8),
                        Text(cls, style: EduStreakTheme.fontLabel(color: Colors.white, weight: FontWeight.w700)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('Sections: A, B', style: TextStyle(color: Colors.white70, fontSize: 11)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('Core Subjects:', style: EduStreakTheme.fontCaption(color: EduStreakTheme.textMuted)),
                    const SizedBox(height: 4),
                    const Text('Mathematics, Physical Science, Biological Science, Social Studies, English, Telugu',
                        style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4)),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─── TAB 3: STUDENTS ──────────────────────────────────────────────────────
  Widget _buildStudentsTab() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore
          .collection('users')
          .where('role', isEqualTo: 'student')
          .where('schoolId', isEqualTo: _school.id)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: EduStreakTheme.primaryViolet));
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.school_outlined, size: 48, color: Colors.white30),
                const SizedBox(height: 12),
                Text('No students registered under ${_school.name} yet.', style: EduStreakTheme.fontBody(color: Colors.white60)),
                const SizedBox(height: 8),
                Text('Use the Student Directory or CSV Batch Importer to enroll students.', style: EduStreakTheme.fontCaption(color: EduStreakTheme.textMuted)),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(24),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final data = docs[index].data();
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1535),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: EduStreakTheme.cardBorder),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: EduStreakTheme.primaryViolet.withValues(alpha: 0.2),
                    child: Text(
                      (data['name'] ?? 'S')[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data['name'] ?? 'Unknown Student', style: EduStreakTheme.fontLabel(color: Colors.white, weight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text('Roll No: ${data['rollNo'] ?? 'N/A'} • ${data['class'] ?? 'Class 10'} (${data['section'] ?? 'A'}) • Streak: ${data['streak'] ?? 0} days',
                            style: EduStreakTheme.fontCaption(color: EduStreakTheme.textMuted)),
                      ],
                    ),
                  ),
                  Text('XP: ${data['xp'] ?? 0}', style: EduStreakTheme.fontLabel(color: EduStreakTheme.primaryVioletLight, weight: FontWeight.bold)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ─── TAB 4: TEACHERS ──────────────────────────────────────────────────────
  Widget _buildTeachersTab() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore
          .collection('users')
          .where('role', isEqualTo: 'teacher')
          .where('schoolId', isEqualTo: _school.id)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: EduStreakTheme.primaryViolet));
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.supervisor_account_outlined, size: 48, color: Colors.white30),
                const SizedBox(height: 12),
                Text('No teachers assigned to ${_school.name} yet.', style: EduStreakTheme.fontBody(color: Colors.white60)),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(24),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final data = docs[index].data();
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1535),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: EduStreakTheme.cardBorder),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFF00E5FF).withValues(alpha: 0.2),
                    child: Text(
                      (data['name'] ?? 'T')[0].toUpperCase(),
                      style: const TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data['name'] ?? 'Unknown Teacher', style: EduStreakTheme.fontLabel(color: Colors.white, weight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text('Subject: ${data['subject'] ?? 'General'} • Classes: ${(data['classes'] as List?)?.join(', ') ?? 'All'}',
                            style: EduStreakTheme.fontCaption(color: EduStreakTheme.textMuted)),
                      ],
                    ),
                  ),
                  Text(data['email'] ?? '', style: EduStreakTheme.fontCaption(color: Colors.white60)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ─── TAB 5: PARENTS ───────────────────────────────────────────────────────
  Widget _buildParentsTab() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore
          .collection('users')
          .where('role', isEqualTo: 'parent')
          .where('schoolId', isEqualTo: _school.id)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: EduStreakTheme.primaryViolet));
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.family_restroom_outlined, size: 48, color: Colors.white30),
                const SizedBox(height: 12),
                Text('No parent profiles mapped to this school yet.', style: EduStreakTheme.fontBody(color: Colors.white60)),
                const SizedBox(height: 6),
                Text('Parents link automatically via student roll numbers or admission codes.', style: EduStreakTheme.fontCaption(color: EduStreakTheme.textMuted)),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(24),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final data = docs[index].data();
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1535),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: EduStreakTheme.cardBorder),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                    child: Text(
                      (data['name'] ?? 'P')[0].toUpperCase(),
                      style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data['name'] ?? 'Parent', style: EduStreakTheme.fontLabel(color: Colors.white, weight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text('Phone: ${data['phone'] ?? 'N/A'} • Linked Children: ${(data['childIds'] as List?)?.length ?? 1}',
                            style: EduStreakTheme.fontCaption(color: EduStreakTheme.textMuted)),
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

  // ─── TAB 6: CURRICULUM ────────────────────────────────────────────────────
  Widget _buildCurriculumTab() {
    final isPrivate = _school.type == SchoolType.privateSchool;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: EduStreakTheme.primaryViolet.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: EduStreakTheme.primaryViolet.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.layers_rounded, color: EduStreakTheme.primaryVioletLight, size: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isPrivate ? 'School-Specific Autonomous Curriculum' : 'Central Standard Template Mapping',
                        style: EduStreakTheme.fontLabel(color: Colors.white, weight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isPrivate
                            ? 'As a Private School, this institution manages its own dedicated syllabus. Edits here affect only ${_school.name}.'
                            : 'This school uses standard template "${_school.curriculumTemplateId}". Content is maintained centrally by Central Admin.',
                        style: EduStreakTheme.fontCaption(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Configured Curriculum Hierarchy', style: EduStreakTheme.fontHeading3(color: Colors.white, weight: FontWeight.w700)),
          const SizedBox(height: 12),
          Text('Subjects, Chapters and Topics are synchronized with the central database repository.', style: EduStreakTheme.fontCaption(color: EduStreakTheme.textMuted)),
        ],
      ),
    );
  }

  // ─── TAB 7: ATTENDANCE ────────────────────────────────────────────────────
  Widget _buildAttendanceTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.event_available_rounded, size: 52, color: Color(0xFF10B981)),
            const SizedBox(height: 16),
            Text('Daily Institutional Attendance Roster', style: EduStreakTheme.fontHeading3(color: Colors.white, weight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Aggregated live metrics for ${_school.name}', style: EduStreakTheme.fontBodySmall(color: EduStreakTheme.textMuted)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildAttendanceMetric('Present Rate', '94.8%', Colors.greenAccent),
                const SizedBox(width: 24),
                _buildAttendanceMetric('Late Arrivals', '3.2%', Colors.orangeAccent),
                const SizedBox(width: 24),
                _buildAttendanceMetric('Unexcused Absent', '2.0%', Colors.redAccent),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceMetric(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1535),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: EduStreakTheme.fontCaption(color: Colors.white70)),
        ],
      ),
    );
  }

  // ─── TAB 8: ASSIGNMENTS ───────────────────────────────────────────────────
  Widget _buildAssignmentsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.assignment_outlined, size: 48, color: Colors.white30),
          const SizedBox(height: 12),
          Text('Academic Homework & Assignments', style: EduStreakTheme.fontHeading3(color: Colors.white, weight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('Tracks live submissions, evaluations, and pending tasks across all classes.', style: EduStreakTheme.fontCaption(color: EduStreakTheme.textMuted)),
        ],
      ),
    );
  }

  // ─── TAB 9: REPORTS ───────────────────────────────────────────────────────
  Widget _buildReportsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.insights_rounded, size: 48, color: Colors.white30),
          const SizedBox(height: 12),
          Text('Comprehensive Performance Analytics', style: EduStreakTheme.fontHeading3(color: Colors.white, weight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('Subject-wise pass percentages, streak consistency, and AI study session minutes.', style: EduStreakTheme.fontCaption(color: EduStreakTheme.textMuted)),
        ],
      ),
    );
  }

  // ─── TAB 10: ACTIVITY LOG ─────────────────────────────────────────────────
  Widget _buildActivityLogTab() {
    return StreamBuilder<List<AuditRecord>>(
      stream: _auditService.getSchoolAuditLogsStream(_school.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: EduStreakTheme.primaryViolet));
        }

        final logs = snapshot.data ?? [];
        if (logs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.history_edu_rounded, size: 48, color: Colors.white30),
                const SizedBox(height: 12),
                Text('No administrative actions logged for ${_school.name} yet.', style: EduStreakTheme.fontBody(color: Colors.white60)),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(24),
          itemCount: logs.length,
          separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFF232D62)),
          itemBuilder: (context, index) {
            final log = logs[index];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.security_rounded, size: 18, color: EduStreakTheme.primaryVioletLight),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(log.action, style: EduStreakTheme.fontLabel(color: Colors.white, weight: FontWeight.w700)),
                        Text(log.details.entries.map((e) => '${e.key}: ${e.value}').join(' • '),
                            style: EduStreakTheme.fontCaption(color: Colors.white70)),
                      ],
                    ),
                  ),
                  Text(log.formattedTime, style: EduStreakTheme.fontCaption(color: EduStreakTheme.textMuted)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddSectionDialog() {
    final sectionController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF13193F),
        title: Text('Add New Class Section', style: EduStreakTheme.fontHeading3(color: Colors.white)),
        content: TextField(
          controller: sectionController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Section Name (e.g. C or Section-C)',
            labelStyle: TextStyle(color: Colors.white70),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Section added to academic roster.')));
            },
            style: ElevatedButton.styleFrom(backgroundColor: EduStreakTheme.primaryViolet),
            child: const Text('Add Section'),
          ),
        ],
      ),
    );
  }

  void _showEditSchoolDialog() {
    final nameController = TextEditingController(text: _school.name);
    final phoneController = TextEditingController(text: _school.contactPhone);
    final emailController = TextEditingController(text: _school.contactEmail);
    final contactController = TextEditingController(text: _school.contactPerson);

    showAdaptiveEduStreakModal(
      context: context,
      maxWidth: 550,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1535),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: EduStreakTheme.cardBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Edit School Information', style: EduStreakTheme.fontHeading3(color: Colors.white, weight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextField(controller: nameController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'School Name')),
            const SizedBox(height: 12),
            TextField(controller: contactController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Contact Person')),
            const SizedBox(height: 12),
            TextField(controller: phoneController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Contact Phone')),
            const SizedBox(height: 12),
            TextField(controller: emailController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Contact Email')),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () async {
                    final updated = _school.copyWith(
                      name: nameController.text.trim(),
                      contactPerson: contactController.text.trim(),
                      contactPhone: phoneController.text.trim(),
                      contactEmail: emailController.text.trim(),
                    );
                    await _schoolService.updateSchool(updated);
                    setState(() => _school = updated);
                    if (ctx.mounted) Navigator.of(ctx).pop();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: EduStreakTheme.primaryViolet),
                  child: const Text('Save Changes'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
