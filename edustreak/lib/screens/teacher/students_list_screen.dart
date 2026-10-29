import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/user_provider.dart';
import '../../models/user_model.dart';
import '../../services/attendance_service.dart';
import '../../utils/theme.dart';
import '../shared/skill_matrix_screen.dart';

class StudentsListScreen extends StatefulWidget {
  const StudentsListScreen({super.key});

  @override
  State<StudentsListScreen> createState() => _StudentsListScreenState();
}

class _StudentsListScreenState extends State<StudentsListScreen> {
  String? _selectedClassId;
  Map<String, String> _classNamesMap = {};

  @override
  void initState() {
    super.initState();
    _loadClassNames();
  }

  Future<void> _loadClassNames() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final teacher = userProvider.currentUser;
    
    if (teacher?.classIds == null || teacher!.classIds!.isEmpty) return;

    final Map<String, String> classNamesMap = {};
    for (final classId in teacher.classIds!) {
      try {
        final classDoc = await FirebaseFirestore.instance
            .collection('classes')
            .doc(classId)
            .get();
        if (classDoc.exists) {
          final data = classDoc.data();
          String className = data?['name'] ?? '';
          if (className.isEmpty) {
            final match = RegExp(r'(\d+)').firstMatch(classId);
            if (match != null) {
              className = 'Class ${match.group(1)}';
            } else {
              className = 'Class ${classId.substring(0, classId.length > 8 ? 8 : classId.length)}...';
            }
          }
          classNamesMap[classId] = className;
        } else {
          final match = RegExp(r'(\d+)').firstMatch(classId);
          final className = match != null ? 'Class ${match.group(1)}' : 'Class $classId';
          classNamesMap[classId] = className;
        }
      } catch (e) {
        classNamesMap[classId] = 'Class $classId';
      }
    }
    
    if (mounted) {
      setState(() {
        _classNamesMap = classNamesMap;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final teacher = userProvider.currentUser;

    if (teacher?.classIds == null || teacher!.classIds!.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('No classes assigned')),
      );
    }

    _selectedClassId ??= teacher.classIds!.first;

    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withAlpha((0.15 * 255).round()),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: DropdownButtonFormField<String>(
              value: _selectedClassId,
              dropdownColor: Colors.white,
              decoration: InputDecoration(
                labelText: 'Select Class',
                labelStyle: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w600,
                ),
                floatingLabelBehavior: FloatingLabelBehavior.never,
                filled: true,
                fillColor: Colors.white.withOpacity(0.12),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(
                    color: Colors.white.withOpacity(0.6),
                    width: 1.2,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(
                    color: Colors.white.withOpacity(0.6),
                    width: 1.2,
                  ),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(18)),
                  borderSide: BorderSide(
                    color: Colors.white,
                    width: 1.8,
                  ),
                ),
              ),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              iconEnabledColor: Colors.white,
              iconDisabledColor: Colors.white70,
              items: teacher.classIds!.map((classId) {
                final className = _classNamesMap[classId] ?? 'Class $classId';
                return DropdownMenuItem(
                  value: classId,
                  child: Text(
                    className,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedClassId = value);
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'student')
                  .where('classId', isEqualTo: _selectedClassId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  debugPrint('Error loading students: ${snapshot.error}');
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error: ${snapshot.error}'),
                        const SizedBox(height: 8),
                        const Text('Please check Firebase rules are deployed'),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.people_outline, size: 48, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          'No students found',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Class: ${_classNamesMap[_selectedClassId] ?? _selectedClassId}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Make sure students have classId set to: $_selectedClassId',
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                final students = snapshot.data!.docs.map((doc) {
                  return UserModel.fromMap(
                    doc.data() as Map<String, dynamic>..['id'] = doc.id,
                  );
                }).toList();
                
                // Sort by streak in memory (descending)
                students.sort((a, b) => b.streak.compareTo(a.streak));

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
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

  Widget _buildStudentCard(UserModel student) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          child: Text(student.name[0].toUpperCase()),
        ),
        title: Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🔥 ${student.streak} day streak'),
            Text('⭐ ${student.xp} XP • Level ${student.level}'),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FutureBuilder<Map<String, dynamic>>(
                  future: AttendanceService().getStudentMonthlyStats(
                    student.id,
                    DateTime.now(),
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }

                    final stats = snapshot.data ?? {};
                    final presentDays = stats['presentDays'] ?? 0;
                    final totalDays = stats['totalDays'] ?? 0;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Attendance (Last 30 days):',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text('Present: $presentDays / $totalDays days'),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: totalDays > 0 ? presentDays / totalDays : 0,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            presentDays / totalDays >= 0.8 ? Colors.green : Colors.orange,
                          ),
                        ),
                        if (totalDays > 0) ...[
                          const SizedBox(height: 16),
                          Text(
                            'Attendance Rate: ${((presentDays / totalDays) * 100).toStringAsFixed(1)}%',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: (presentDays / totalDays) >= 0.8 ? Colors.green : Colors.orange,
                                ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                // Skill Matrix Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SkillMatrixScreen(
                            studentId: student.id,
                            studentName: student.name,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.radar),
                    label: const Text('View Skill Matrix'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Revoke Streak Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showRevokeStreakDialog(context, student),
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    label: const Text(
                      'Revoke Streak',
                      style: TextStyle(color: Colors.red),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showRevokeStreakDialog(BuildContext context, UserModel student) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke Streak'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to revoke ${student.name}\'s streak?',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Current streak: ${student.streakCount} days'),
            const SizedBox(height: 16),
            const Text(
              'This action will reset the student\'s streak to 0. This should only be done if the streak was broken due to external conditions (e.g., illness, family emergency).',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Revoke Streak'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Show loading
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 16),
                Text('Revoking streak...'),
              ],
            ),
            duration: Duration(seconds: 30),
          ),
        );
      }

      // Reset streak to 0
      await FirebaseFirestore.instance.collection('users').doc(student.id).update({
        'streakCount': 0,
        'streak': 0, // Legacy field
        'lastLoginDate': null, // Reset last login date so streak can restart
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${student.name}\'s streak has been revoked.'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error revoking streak: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Widget _buildAttendanceChart(Map<String, String> attendance) {
    if (attendance.isEmpty) {
      return const Center(child: Text('No attendance data'));
    }

    final last7Days = List.generate(7, (index) {
      final date = DateTime.now().subtract(Duration(days: 6 - index));
      final dateKey = '${date.year}-${date.month}-${date.day}';
      return attendance[dateKey] == 'present' ? 1.0 : 0.0;
    });

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 1,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                final index = value.toInt();
                if (index >= 0 && index < days.length) {
                  return Text(days[index]);
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: last7Days.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value,
                color: entry.value == 1.0 ? Colors.green : Colors.red,
                width: 20,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

