import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../models/user_model.dart';
import '../../utils/edustreak_theme.dart';
import '../../utils/class_name_helper.dart';

class ClassManagementScreen extends StatefulWidget {
  const ClassManagementScreen({super.key});

  @override
  State<ClassManagementScreen> createState() => _ClassManagementScreenState();
}

class _ClassManagementScreenState extends State<ClassManagementScreen> {
  String _searchQuery = '';
  String _selectedSection = 'All';

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final teacher = userProvider.currentUser;

    if (teacher == null) {
      return const Center(
        child: CircularProgressIndicator(color: EduStreakTheme.primaryViolet),
      );
    }

    final teacherClassIds = teacher.classIds ?? (teacher.classId != null ? [teacher.classId!] : <String>[]);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 600;

              final badge = Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: EduStreakTheme.primaryViolet.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: EduStreakTheme.primaryViolet.withValues(alpha: 0.4)),
                ),
                child: Text(
                  '${teacherClassIds.length} Assigned Classes',
                  style: const TextStyle(
                    color: Color(0xFFB8A8FF),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              );

              if (isCompact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'My Classes & Cohorts',
                            style: EduStreakTheme.fontHeading2(
                              color: Colors.white,
                              weight: FontWeight.w800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        badge,
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Manage curriculum delivery, student directories, and performance for your assigned classes.',
                      style: EduStreakTheme.fontBody(color: EduStreakTheme.darkTextSub),
                    ),
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'My Classes & Cohorts',
                          style: EduStreakTheme.fontHeading1(
                            color: Colors.white,
                            weight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Manage curriculum delivery, student directories, and performance for your assigned classes.',
                          style: EduStreakTheme.fontBody(color: EduStreakTheme.darkTextSub),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  badge,
                ],
              );
            },
          ),

          const SizedBox(height: 20),

          // Filters Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: EduStreakTheme.darkCardDecoration(),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search by class name, grade or section...',
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                      prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Colors.white54),
                      filled: true,
                      fillColor: const Color(0xFF0F1535),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF222B5C)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF222B5C)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F1535),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF222B5C)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedSection,
                      dropdownColor: const Color(0xFF0F1535),
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      onChanged: (v) => setState(() => _selectedSection = v ?? 'All'),
                      items: const [
                        DropdownMenuItem(value: 'All', child: Text('All Sections')),
                        DropdownMenuItem(value: 'A', child: Text('Section A')),
                        DropdownMenuItem(value: 'B', child: Text('Section B')),
                        DropdownMenuItem(value: 'C', child: Text('Section C')),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          // Classes Stream
          StreamBuilder<QuerySnapshot>(
            stream: (teacher.schoolId != null && teacher.schoolId!.isNotEmpty)
                ? FirebaseFirestore.instance
                    .collection('schools')
                    .doc(teacher.schoolId)
                    .collection('classes')
                    .snapshots()
                : FirebaseFirestore.instance.collection('classes').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: EduStreakTheme.primaryViolet),
                  ),
                );
              }

              // Fallback to top-level classes if sub-collection has no items
              final docs = snapshot.data?.docs ?? [];
              
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('classes').snapshots(),
                builder: (ctx, fallbackSnapshot) {
                  final combinedDocs = [...docs, ...(fallbackSnapshot.data?.docs ?? [])];
                  final seenIds = <String>{};
                  final uniqueDocs = <QueryDocumentSnapshot>[];
                  for (final d in combinedDocs) {
                    if (!seenIds.contains(d.id)) {
                      seenIds.add(d.id);
                      uniqueDocs.add(d);
                    }
                  }

                  // If teacher has class IDs that aren't represented in Firestore documents,
                  // create synthesized representations so the teacher still sees their assigned classes!
                  final List<Map<String, dynamic>> displayClasses = [];

                  for (final doc in uniqueDocs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final id = doc.id;
                    final isAssigned = teacherClassIds.contains(id);
                    if (!isAssigned) continue; // Teachers only see their authorized classes

                    final name = ClassNameHelper.formatClassNameSync(
                      data['name']?.toString() ?? id,
                      fallback: 'Class 8A',
                    );

                    displayClasses.add({
                      'id': id,
                      'name': name,
                      'grade': data['grade'] ?? '8',
                      'section': data['section'] ?? 'A',
                      'academicYear': data['academicYear'] ?? '2026-2027',
                      'subject': (teacher.assignedSubjects.isNotEmpty) ? teacher.assignedSubjects.first : 'General',
                    });
                  }

                  // Add any teacherClassIds not in Firestore
                  for (final tId in teacherClassIds) {
                    if (!seenIds.contains(tId)) {
                      final name = ClassNameHelper.formatClassNameSync(tId, fallback: 'Class 8A');
                      displayClasses.add({
                        'id': tId,
                        'name': name,
                        'grade': '8',
                        'section': 'A',
                        'academicYear': '2026-2027',
                        'subject': (teacher.assignedSubjects.isNotEmpty) ? teacher.assignedSubjects.first : 'General',
                      });
                    }
                  }

                  // Filter by search & section
                  final filtered = displayClasses.where((c) {
                    final name = c['name'].toString().toLowerCase();
                    final section = c['section'].toString().toUpperCase();
                    if (_selectedSection != 'All' && section != _selectedSection) {
                      return false;
                    }
                    if (_searchQuery.isNotEmpty && !name.contains(_searchQuery)) {
                      return false;
                    }
                    return true;
                  }).toList();

                  if (filtered.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
                      decoration: EduStreakTheme.darkCardDecoration(),
                      child: Column(
                        children: [
                          const Icon(Icons.groups_outlined, size: 48, color: EduStreakTheme.darkTextMuted),
                          const SizedBox(height: 12),
                          Text(
                            'No Assigned Classes Found',
                            style: EduStreakTheme.fontHeading2(color: Colors.white, weight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Your school administrator has not assigned active classes to your profile yet.',
                            style: EduStreakTheme.fontBody(color: EduStreakTheme.darkTextSub),
                          ),
                        ],
                      ),
                    );
                  }

                  return LayoutBuilder(
                    builder: (ctx, constraints) {
                      final isWide = constraints.maxWidth > 900;
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isWide ? 2 : 1,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          mainAxisExtent: 210,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          return _buildClassCard(context, filtered[index], teacher);
                        },
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildClassCard(BuildContext context, Map<String, dynamic> classInfo, UserModel teacher) {
    final classId = classInfo['id'] as String;
    final className = classInfo['name'] as String;
    final subject = classInfo['subject'] as String;
    final academicYear = classInfo['academicYear'] as String;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: EduStreakTheme.darkCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top Row: Class Name + Year Chip
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: EduStreakTheme.primaryViolet.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: EduStreakTheme.primaryViolet.withValues(alpha: 0.4)),
                      ),
                      child: const Icon(Icons.school_rounded, color: EduStreakTheme.primaryVioletLight, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            className,
                            style: EduStreakTheme.fontLabel(color: Colors.white, weight: FontWeight.w800),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '$subject • $academicYear',
                            style: EduStreakTheme.fontCaption(color: EduStreakTheme.darkTextMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: EduStreakTheme.emeraldGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: EduStreakTheme.emeraldGreen.withValues(alpha: 0.4)),
                ),
                child: const Text(
                  'Assigned',
                  style: TextStyle(color: EduStreakTheme.emeraldGreen, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),

          // Middle Row: Real Student Count & Metrics
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('role', isEqualTo: 'student')
                .where('classId', isEqualTo: classId)
                .snapshots(),
            builder: (context, studentSnap) {
              final studentCount = studentSnap.data?.docs.length ?? 0;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1535),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF222B5C)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCol('Enrolled', '$studentCount Students'),
                    Container(width: 1, height: 24, color: const Color(0xFF222B5C)),
                    _buildStatCol('Attendance', '94% Avg'),
                    Container(width: 1, height: 24, color: const Color(0xFF222B5C)),
                    _buildStatCol('Homework', 'Active'),
                  ],
                ),
              );
            },
          ),

          // Bottom Action: View Details Button
          SizedBox(
            width: double.infinity,
            height: 38,
            child: OutlinedButton.icon(
              onPressed: () => _openClassDetails(context, classId, className, subject),
              icon: const Icon(Icons.visibility_rounded, size: 16),
              label: const Text('View Class Details & Directory', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              style: OutlinedButton.styleFrom(
                foregroundColor: EduStreakTheme.neonCyan,
                side: const BorderSide(color: EduStreakTheme.neonCyan),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCol(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 1),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
      ],
    );
  }

  void _openClassDetails(BuildContext context, String classId, String className, String subject) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ClassDetailsSheet(classId: classId, className: className, subject: subject),
    );
  }
}

class _ClassDetailsSheet extends StatelessWidget {
  final String classId;
  final String className;
  final String subject;

  const _ClassDetailsSheet({
    required this.classId,
    required this.className,
    required this.subject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF0C1030),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(className, style: EduStreakTheme.fontHeading1(color: Colors.white, weight: FontWeight.w800)),
                    Text('Subject: $subject • Student Directory & Roster', style: EduStreakTheme.fontCaption(color: EduStreakTheme.darkTextMuted)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white54),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          const Divider(color: Color(0xFF222B5C)),

          // Student Directory List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'student')
                  .where('classId', isEqualTo: classId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: EduStreakTheme.primaryViolet));
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(
                    child: Text('No students currently enrolled in this class.', style: TextStyle(color: Colors.white54)),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: docs.length,
                  itemBuilder: (ctx, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    final student = UserModel.fromMap(data..['id'] = docs[i].id);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F1535),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF222B5C)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: EduStreakTheme.primaryViolet,
                            child: Text(
                              student.name.isNotEmpty ? student.name[0].toUpperCase() : 'S',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(student.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                Text('Roll No: ${student.rollNumber ?? "N/A"} • ${student.email}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: EduStreakTheme.neonCyan.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('${student.xp} XP', style: const TextStyle(color: EduStreakTheme.neonCyan, fontWeight: FontWeight.bold, fontSize: 12)),
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
      ),
    );
  }
}
