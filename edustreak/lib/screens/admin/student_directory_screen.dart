import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/school_model.dart';
import '../../services/school_service.dart';
import '../../services/audit_service.dart';
import '../../utils/edustreak_theme.dart';
import '../../widgets/responsive/responsive_dialog.dart';

class StudentDirectoryScreen extends StatefulWidget {
  const StudentDirectoryScreen({super.key});

  @override
  State<StudentDirectoryScreen> createState() => _StudentDirectoryScreenState();
}

class _StudentDirectoryScreenState extends State<StudentDirectoryScreen> {
  final _schoolService = SchoolService();
  final _auditService = AuditService();
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  String? _selectedSchoolId;
  String _selectedGrade = 'All';
  String _selectedStatus = 'All';
  String _searchQuery = '';

  List<SchoolModel> _schools = [];
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSchools();
  }

  Future<void> _loadSchools() async {
    try {
      final stream = _schoolService.getSchoolsStream();
      final list = await stream.first;
      if (mounted) {
        setState(() => _schools = list);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF070B1E),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Filter Bar
          _buildFilterBar(),

          const SizedBox(height: 18),

          // Students Roster Stream
          Expanded(child: _buildStudentListStream()),
        ],
      ),
    );
  }

  // ─── FILTER BAR ───────────────────────────────────────────────────────────
  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1535),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EduStreakTheme.cardBorder),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 650;
          final titleWidget = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Central Student Directory', style: EduStreakTheme.fontHeading3(color: Colors.white, weight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text('Cross-institutional student enrollment, performance metrics & transfer governance.', style: EduStreakTheme.fontCaption(color: EduStreakTheme.textMuted)),
            ],
          );

          final searchInput = SizedBox(
            width: isCompact ? double.infinity : 260,
            height: 40,
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search name or roll no...',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.white54, size: 18),
                filled: true,
                fillColor: const Color(0xFF141A42),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          );

          final topRow = isCompact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleWidget,
                    const SizedBox(height: 12),
                    searchInput,
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: titleWidget),
                    const SizedBox(width: 16),
                    searchInput,
                  ],
                );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              topRow,
              const SizedBox(height: 14),
              // Filter row
              Wrap(
                spacing: 16,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // School Filter
                  SizedBox(
                    width: isCompact ? double.infinity : 220,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141A42),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF26326E)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          value: _selectedSchoolId,
                          dropdownColor: const Color(0xFF141A42),
                          isExpanded: true,
                          hint: const Text('All Institutions', style: TextStyle(color: Colors.white70, fontSize: 12), overflow: TextOverflow.ellipsis),
                          icon: const Icon(Icons.arrow_drop_down, color: Colors.white54),
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          items: [
                            const DropdownMenuItem<String?>(value: null, child: Text('All Institutions', overflow: TextOverflow.ellipsis)),
                            ..._schools.map((s) => DropdownMenuItem<String?>(
                              value: s.id,
                              child: Text('${s.name} (${s.code})', overflow: TextOverflow.ellipsis),
                            )),
                          ],
                          onChanged: (val) => setState(() => _selectedSchoolId = val),
                        ),
                      ),
                    ),
                  ),

                  // Grade Filter
                  SizedBox(
                    width: isCompact ? double.infinity : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141A42),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF26326E)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedGrade,
                          dropdownColor: const Color(0xFF141A42),
                          isExpanded: isCompact,
                          icon: const Icon(Icons.arrow_drop_down, color: Colors.white54),
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          items: const [
                            DropdownMenuItem(value: 'All', child: Text('All Classes', overflow: TextOverflow.ellipsis)),
                            DropdownMenuItem(value: '6', child: Text('Class 6', overflow: TextOverflow.ellipsis)),
                            DropdownMenuItem(value: '7', child: Text('Class 7', overflow: TextOverflow.ellipsis)),
                            DropdownMenuItem(value: '8', child: Text('Class 8', overflow: TextOverflow.ellipsis)),
                            DropdownMenuItem(value: '9', child: Text('Class 9', overflow: TextOverflow.ellipsis)),
                            DropdownMenuItem(value: '10', child: Text('Class 10', overflow: TextOverflow.ellipsis)),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedGrade = val);
                          },
                        ),
                      ),
                    ),
                  ),

                  // Status Filter
                  SizedBox(
                    width: isCompact ? double.infinity : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141A42),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF26326E)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedStatus,
                          dropdownColor: const Color(0xFF141A42),
                          isExpanded: isCompact,
                          icon: const Icon(Icons.arrow_drop_down, color: Colors.white54),
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          items: const [
                            DropdownMenuItem(value: 'All', child: Text('All Statuses', overflow: TextOverflow.ellipsis)),
                            DropdownMenuItem(value: 'Active', child: Text('Active Only', overflow: TextOverflow.ellipsis)),
                            DropdownMenuItem(value: 'Inactive', child: Text('Suspended / Inactive', overflow: TextOverflow.ellipsis)),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedStatus = val);
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── STUDENT LIST STREAM ──────────────────────────────────────────────────
  Widget _buildStudentListStream() {
    try {
      Query<Map<String, dynamic>> query = _firestore.collection('users').where('role', isEqualTo: 'student');

      if (_selectedSchoolId != null) {
        query = query.where('schoolId', isEqualTo: _selectedSchoolId);
      }

    if (_selectedGrade != 'All') {
      query = query.where('grade', isEqualTo: _selectedGrade);
    }

    if (_selectedStatus == 'Active') {
      query = query.where('isActive', isEqualTo: true);
    } else if (_selectedStatus == 'Inactive') {
      query = query.where('isActive', isEqualTo: false);
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: EduStreakTheme.primaryViolet));
        }

        var docs = snapshot.data?.docs ?? [];

        // In-memory search filtering
        if (_searchQuery.isNotEmpty) {
          docs = docs.where((doc) {
            final data = doc.data();
            final name = (data['name'] ?? '').toString().toLowerCase();
            final roll = (data['rollNumber'] ?? data['rollNo'] ?? '').toString().toLowerCase();
            return name.contains(_searchQuery) || roll.contains(_searchQuery);
          }).toList();
        }

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.school_outlined, size: 52, color: Colors.white24),
                const SizedBox(height: 14),
                Text('No students matched your criteria.', style: EduStreakTheme.fontBody(color: Colors.white70)),
                const SizedBox(height: 8),
                Text('Import students via the CSV tool or adjust directory filters.', style: EduStreakTheme.fontCaption(color: EduStreakTheme.textMuted)),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.only(bottom: 96),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data();
            final studentId = doc.id;
            final studentName = data['name'] ?? 'Unnamed Student';
            final rollNo = data['rollNumber'] ?? data['rollNo'] ?? 'N/A';
            final schoolCode = data['schoolCode'] ?? 'AP';
            final grade = data['grade'] ?? '10';
            final section = data['section'] ?? 'A';
            final streak = (data['streak'] as num?)?.toInt() ?? 0;
            final xp = (data['xp'] as num?)?.toInt() ?? 0;
            final isActive = data['isActive'] ?? true;

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1535),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: EduStreakTheme.cardBorder),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: EduStreakTheme.primaryViolet.withValues(alpha: 0.2),
                    child: Text(
                      studentName.isNotEmpty ? studentName[0].toUpperCase() : 'S',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              studentName,
                              style: EduStreakTheme.fontLabel(color: Colors.white, weight: FontWeight.w700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isActive ? Colors.green.withValues(alpha: 0.15) : Colors.red.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: isActive ? Colors.green : Colors.redAccent),
                              ),
                              child: Text(
                                isActive ? 'ACTIVE' : 'SUSPENDED',
                                style: TextStyle(color: isActive ? Colors.greenAccent : Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Roll: $rollNo • Class $grade-$section • School: $schoolCode • Streak: $streak days • XP: $xp',
                          style: EduStreakTheme.fontCaption(color: EduStreakTheme.textMuted),
                        ),
                      ],
                    ),
                  ),

                  // Actions
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // View Profile
                      IconButton(
                        icon: const Icon(Icons.account_circle_outlined, color: EduStreakTheme.neonCyan, size: 20),
                        tooltip: 'View Profile',
                        onPressed: () => _showStudentProfileModal(studentId, data),
                      ),
                      // Transfer Student
                      IconButton(
                        icon: const Icon(Icons.swap_horiz_rounded, color: Colors.amberAccent, size: 20),
                        tooltip: 'Transfer Student',
                        onPressed: () => _showTransferStudentModal(studentId, data),
                      ),
                      // Status Toggle
                      IconButton(
                        icon: Icon(isActive ? Icons.block_rounded : Icons.check_circle_outline_rounded,
                            color: isActive ? Colors.redAccent : Colors.greenAccent, size: 20),
                        tooltip: isActive ? 'Deactivate Student' : 'Activate Student',
                        onPressed: () => _toggleStudentStatus(studentId, studentName, !isActive),
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
    } catch (_) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.school_outlined, size: 56, color: Colors.white24),
            const SizedBox(height: 12),
            Text('No student records found', style: EduStreakTheme.fontHeading3(color: Colors.white60)),
          ],
        ),
      );
    }
  }

  // ─── STUDENT OPERATIONS ───────────────────────────────────────────────────
  Future<void> _toggleStudentStatus(String studentId, String studentName, bool newActive) async {
    await _firestore.collection('users').doc(studentId).update({
      'isActive': newActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _auditService.logAction(
      action: newActive ? 'STUDENT_ACTIVATED' : 'STUDENT_SUSPENDED',
      targetType: 'student',
      targetId: studentId,
      details: {'studentName': studentName, 'newActive': newActive},
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Student $studentName ${newActive ? 'activated' : 'suspended'}.')),
      );
    }
  }

  void _showStudentProfileModal(String studentId, Map<String, dynamic> data) {
    showAdaptiveEduStreakModal(
      context: context,
      maxWidth: 500,
      title: 'Student Profile: ${data['name']}',
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileRow('Student UID', studentId),
            _buildProfileRow('Roll Number', '${data['rollNumber'] ?? data['rollNo'] ?? 'N/A'}'),
            _buildProfileRow('Class & Section', 'Class ${data['grade'] ?? '10'}-${data['section'] ?? 'A'}'),
            _buildProfileRow('School Code', '${data['schoolCode'] ?? 'N/A'}'),
            _buildProfileRow('Internal Email', '${data['email'] ?? 'N/A'}'),
            _buildProfileRow('Current Streak', '${data['streak'] ?? 0} days'),
            _buildProfileRow('Lifetime XP', '${data['xp'] ?? 0} XP'),
            _buildProfileRow('Level', 'Tier ${data['level'] ?? 1} Scholar'),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(backgroundColor: EduStreakTheme.primaryViolet),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: EduStreakTheme.fontCaption(color: EduStreakTheme.textMuted)),
          SelectableText(value, style: EduStreakTheme.fontBodySmall(color: Colors.white, weight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ─── TRANSFER STUDENT WORKFLOW ────────────────────────────────────────────
  void _showTransferStudentModal(String studentId, Map<String, dynamic> currentData) {
    String? destSchoolId;
    final destGradeCtrl = TextEditingController(text: '${currentData['grade'] ?? '10'}');
    final destSecCtrl = TextEditingController(text: '${currentData['section'] ?? 'A'}');
    final reasonCtrl = TextEditingController(text: 'Institutional transfer approved by Central Administration');

    showAdaptiveEduStreakModal(
      context: context,
      maxWidth: 520,
      title: 'Transfer Student: ${currentData['name']}',
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current School: ${currentData['schoolCode'] ?? 'N/A'} (Class ${currentData['grade']}-${currentData['section']})',
                  style: EduStreakTheme.fontBodySmall(color: EduStreakTheme.primaryVioletLight, weight: FontWeight.w700),
                ),
                const SizedBox(height: 14),
                // Destination School
                DropdownButtonFormField<String>(
                  value: destSchoolId,
                  dropdownColor: const Color(0xFF141A42),
                  decoration: const InputDecoration(labelText: 'Destination School'),
                  items: _schools
                      .where((s) => s.id != currentData['schoolId'])
                      .map((s) => DropdownMenuItem(value: s.id, child: Text('${s.name} (${s.code})')))
                      .toList(),
                  onChanged: (val) => setModalState(() => destSchoolId = val),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: destGradeCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'Target Class (e.g. 10)'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: destSecCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'Target Section (e.g. B)'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Transfer Reason / Order Number'),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: destSchoolId == null
                          ? null
                          : () async {
                              final destSchool = _schools.firstWhere((s) => s.id == destSchoolId);
                              final prevSchoolId = currentData['schoolId'];

                              // Execute Transfer
                              await _firestore.collection('users').doc(studentId).update({
                                'schoolId': destSchool.id,
                                'schoolCode': destSchool.code,
                                'grade': destGradeCtrl.text.trim(),
                                'section': destSecCtrl.text.trim().toUpperCase(),
                                'transferredAt': FieldValue.serverTimestamp(),
                              });

                              // Record transfer audit log
                              await _auditService.logAction(
                                action: 'STUDENT_TRANSFERRED',
                                targetType: 'student',
                                targetId: studentId,
                                details: {
                                  'studentName': currentData['name'],
                                  'fromSchool': currentData['schoolCode'],
                                  'toSchool': destSchool.code,
                                  'newClass': 'Class ${destGradeCtrl.text}-${destSecCtrl.text}',
                                  'reason': reasonCtrl.text.trim(),
                                },
                              );

                              // Update counts
                              if (prevSchoolId != null) {
                                try {
                                  await _firestore.collection('schools').doc(prevSchoolId).update({
                                    'totalStudents': FieldValue.increment(-1),
                                  });
                                } catch (_) {}
                              }
                              try {
                                await _firestore.collection('schools').doc(destSchool.id).update({
                                  'totalStudents': FieldValue.increment(1),
                                });
                              } catch (_) {}

                              if (ctx.mounted) Navigator.of(ctx).pop();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Successfully transferred ${currentData['name']} to ${destSchool.name}.')),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.amberAccent, foregroundColor: Colors.black87),
                      child: const Text('Execute Transfer', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
