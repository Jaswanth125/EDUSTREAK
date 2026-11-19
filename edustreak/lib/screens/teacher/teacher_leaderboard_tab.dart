import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../utils/edustreak_theme.dart';
import '../../utils/class_name_helper.dart';

class TeacherLeaderboardTab extends StatefulWidget {
  final UserModel? user;

  const TeacherLeaderboardTab({super.key, this.user});

  @override
  State<TeacherLeaderboardTab> createState() => _TeacherLeaderboardTabState();
}

class _TeacherLeaderboardTabState extends State<TeacherLeaderboardTab> {
  String? _selectedClassId;
  String _timeframe = 'All-time'; // 'All-time', 'Monthly', 'Weekly'
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    final classes = widget.user?.classIds ?? (widget.user?.classId != null ? [widget.user!.classId!] : <String>[]);
    if (classes.isNotEmpty) {
      _selectedClassId = classes.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final classes = widget.user?.classIds ?? (widget.user?.classId != null ? [widget.user!.classId!] : <String>[]);
    if (_selectedClassId == null && classes.isNotEmpty) {
      _selectedClassId = classes.first;
    }

    return SingleChildScrollView(
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
                  color: Colors.amber.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                ),
                child: const Icon(Icons.leaderboard_rounded, color: Colors.amber, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Class-Wise Leaderboard',
                      style: EduStreakTheme.fontHeading1(color: Colors.white, weight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Track student engagement, level progress and lifetime XP ranking for your classes.',
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
            child: Wrap(
              spacing: 16,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Class Selector
                if (classes.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Class: ', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F1535),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF222B5C)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: classes.contains(_selectedClassId) ? _selectedClassId : classes.first,
                            dropdownColor: const Color(0xFF0F1535),
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            onChanged: (val) => setState(() => _selectedClassId = val),
                            items: classes.map((c) {
                              final display = ClassNameHelper.formatClassNameSync(c, fallback: 'Class 8A');
                              return DropdownMenuItem(value: c, child: Text(display));
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),

                // Timeframe Selector
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Timeframe: ', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F1535),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF222B5C)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _timeframe,
                          dropdownColor: const Color(0xFF0F1535),
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          onChanged: (val) => setState(() => _timeframe = val ?? 'All-time'),
                          items: const [
                            DropdownMenuItem(value: 'All-time', child: Text('All-Time XP')),
                            DropdownMenuItem(value: 'Monthly', child: Text('This Month')),
                            DropdownMenuItem(value: 'Weekly', child: Text('This Week')),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Search Box
                SizedBox(
                  width: 200,
                  height: 38,
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search student...',
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                      prefixIcon: const Icon(Icons.search_rounded, size: 16, color: Colors.white54),
                      filled: true,
                      fillColor: const Color(0xFF0F1535),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
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
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Leaderboard List Stream
          if (_selectedClassId == null)
            Container(
              padding: const EdgeInsets.all(40),
              alignment: Alignment.center,
              child: const Text('No class selected', style: TextStyle(color: Colors.white54)),
            )
          else
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

                // Sort by lifetime XP descending
                students.sort((a, b) => b.xp.compareTo(a.xp));

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
                        const Icon(Icons.emoji_events_outlined, size: 48, color: EduStreakTheme.darkTextMuted),
                        const SizedBox(height: 12),
                        Text(
                          'No Students in this Class',
                          style: EduStreakTheme.fontHeading2(color: Colors.white, weight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Students enrolled in ${ClassNameHelper.formatClassNameSync(_selectedClassId!, fallback: 'Class 8A')} will appear here.',
                          style: EduStreakTheme.fontBody(color: EduStreakTheme.darkTextSub),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: List.generate(students.length, (index) {
                    final student = students[index];
                    final rank = index + 1;
                    return _buildRankRow(student, rank);
                  }),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildRankRow(UserModel student, int rank) {
    Color rankColor;
    Color rankBg;
    if (rank == 1) {
      rankColor = const Color(0xFFFFD700); // Gold
      rankBg = const Color(0x33FFD700);
    } else if (rank == 2) {
      rankColor = const Color(0xFFC0C0C0); // Silver
      rankBg = const Color(0x33C0C0C0);
    } else if (rank == 3) {
      rankColor = const Color(0xFFCD7F32); // Bronze
      rankBg = const Color(0x33CD7F32);
    } else {
      rankColor = Colors.white70;
      rankBg = const Color(0xFF161C48);
    }

    final initial = student.name.isNotEmpty ? student.name[0].toUpperCase() : 'S';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1535),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: rank <= 3 ? rankColor.withValues(alpha: 0.5) : const Color(0xFF222B5C),
          width: rank <= 3 ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // Rank Badge
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: rankBg,
              shape: BoxShape.circle,
              border: Border.all(color: rankColor.withValues(alpha: 0.6)),
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: TextStyle(
                  color: rankColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: EduStreakTheme.primaryViolet,
            child: Text(
              initial,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          const SizedBox(width: 14),

          // Name and Roll No
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  'Roll No: ${student.rollNumber ?? "N/A"} • Level ${student.level}',
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),

          // XP and Badges
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${student.xp} XP',
                style: const TextStyle(
                  color: EduStreakTheme.neonCyan,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.military_tech_rounded, size: 14, color: Colors.amber),
                  const SizedBox(width: 2),
                  Text(
                    '${student.badges.length} badges',
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
