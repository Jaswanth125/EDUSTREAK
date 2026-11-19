import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../models/user_model.dart';
import '../../utils/edustreak_theme.dart';
import '../../utils/class_name_helper.dart';
import '../shared/skill_matrix_screen.dart';

class StudentsListScreen extends StatefulWidget {
  final bool showAppBar;
  const StudentsListScreen({super.key, this.showAppBar = false});

  @override
  State<StudentsListScreen> createState() => _StudentsListScreenState();
}

class _StudentsListScreenState extends State<StudentsListScreen> {
  String? _selectedClassId;
  Map<String, String> _classNamesMap = {};
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadClassNames();
  }

  Future<void> _loadClassNames() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final teacher = userProvider.currentUser;
    if (teacher?.classIds == null || teacher!.classIds!.isEmpty) return;

    final resolved = await ClassNameHelper.getClassNames(
      teacher.classIds!,
      schoolId: teacher.schoolId,
    );

    if (mounted) {
      setState(() {
        _classNamesMap = resolved;
        if (_selectedClassId == null && teacher.classIds!.isNotEmpty) {
          _selectedClassId = teacher.classIds!.first;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final teacher = userProvider.currentUser;

    if (teacher?.classIds == null || teacher!.classIds!.isEmpty) {
      final empty = Container(
        padding: const EdgeInsets.all(40),
        alignment: Alignment.center,
        child: const Text('No classes assigned', style: TextStyle(color: Colors.white54)),
      );
      return widget.showAppBar ? Scaffold(body: empty) : empty;
    }

    _selectedClassId ??= teacher.classIds!.first;

    final bodyContent = SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: EduStreakTheme.neonCyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: EduStreakTheme.neonCyan.withValues(alpha: 0.4)),
                ),
                child: const Icon(Icons.insights_rounded, color: EduStreakTheme.neonCyan, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Student Insights & Performance',
                      style: EduStreakTheme.fontHeading1(color: Colors.white, weight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Track student skill mastery, attendance health, and personalized intervention needs.',
                      style: EduStreakTheme.fontBody(color: EduStreakTheme.darkTextSub),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Filters Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: EduStreakTheme.darkCardDecoration(),
            child: Row(
              children: [
                // Class Selector
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: teacher.classIds!.contains(_selectedClassId) ? _selectedClassId : teacher.classIds!.first,
                    dropdownColor: const Color(0xFF0F1535),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(labelText: 'Select Class', labelStyle: TextStyle(color: Colors.white70)),
                    onChanged: (val) => setState(() => _selectedClassId = val),
                    items: teacher.classIds!.map((classId) {
                      final name = _classNamesMap[classId] ??
                          ClassNameHelper.formatClassNameSync(classId, fallback: 'Class 8A');
                      return DropdownMenuItem(value: classId, child: Text(name));
                    }).toList(),
                  ),
                ),
                const SizedBox(width: 14),
                // Search Input
                Expanded(
                  flex: 3,
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search by student name or roll number...',
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                      prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Colors.white54),
                      filled: true,
                      fillColor: const Color(0xFF0F1535),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF222B5C))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF222B5C))),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Student List Stream
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('role', isEqualTo: 'student')
                .where('classId', isEqualTo: _selectedClassId)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: EduStreakTheme.primaryViolet),
                  ),
                );
              }

              final docs = snapshot.data?.docs ?? [];
              var students = docs.map((d) {
                final data = d.data() as Map<String, dynamic>;
                return UserModel.fromMap(data..['id'] = d.id);
              }).toList();

              if (_searchQuery.isNotEmpty) {
                students = students.where((s) => s.name.toLowerCase().contains(_searchQuery) || (s.rollNumber?.toLowerCase().contains(_searchQuery) ?? false)).toList();
              }

              if (students.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
                  decoration: EduStreakTheme.darkCardDecoration(),
                  child: Column(
                    children: [
                      const Icon(Icons.person_search_rounded, size: 48, color: EduStreakTheme.darkTextMuted),
                      const SizedBox(height: 12),
                      Text(
                        'No Students Found in this Class',
                        style: EduStreakTheme.fontHeading2(color: Colors.white, weight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Enrolled students for this cohort will appear here with performance analytics.',
                        style: EduStreakTheme.fontBody(color: EduStreakTheme.darkTextSub),
                      ),
                    ],
                  ),
                );
              }

              // Aggregate Metrics
              final highPerformers = students.where((s) => s.xp >= 1000).length;
              final needsSupport = students.where((s) => s.xp < 200).length;

              return Column(
                children: [
                  // Overview Cards
                  Row(
                    children: [
                      Expanded(child: _buildMetricCard('Total Students', '${students.length}', Colors.white)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildMetricCard('High Performers', '$highPerformers', Colors.greenAccent)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildMetricCard('Needs Support', '$needsSupport', Colors.orangeAccent)),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Student Cards
                  ...students.map((student) => _buildStudentInsightCard(context, student)),
                ],
              );
            },
          ),
        ],
      ),
    );

    if (widget.showAppBar) {
      return Scaffold(
        appBar: AppBar(title: const Text('Students List & Insights')),
        body: bodyContent,
      );
    }
    return bodyContent;
  }

  Widget _buildMetricCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: EduStreakTheme.darkCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildStudentInsightCard(BuildContext context, UserModel student) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: EduStreakTheme.darkCardDecoration(),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: EduStreakTheme.primaryViolet,
            child: Text(
              student.name.isNotEmpty ? student.name[0].toUpperCase() : 'S',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      student.name,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161C48),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('Level ${student.level}', style: const TextStyle(color: EduStreakTheme.neonCyan, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Roll No: ${student.rollNumber ?? "N/A"} • ${student.xp} Lifetime XP • ${student.badges.length} Badges',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => SkillMatrixScreen(studentId: student.id, studentName: student.name),
                ),
              );
            },
            icon: const Icon(Icons.analytics_outlined, size: 16),
            label: const Text('Skill Matrix', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              foregroundColor: EduStreakTheme.neonCyan,
              side: const BorderSide(color: EduStreakTheme.neonCyan),
            ),
          ),
        ],
      ),
    );
  }
}
