import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/user_provider.dart';
import '../../models/user_model.dart';
import '../../services/attendance_service.dart';
import '../../utils/edustreak_theme.dart';
import '../../utils/class_name_helper.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  String? _selectedClassId;
  DateTime _selectedDate = DateTime.now();
  final AttendanceService _attendanceService = AttendanceService();

  Map<String, String> _attendanceStatus = {}; // studentId -> 'present', 'absent', 'late'
  bool _isMarked = false;
  bool _isLoading = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<UserProvider>(context, listen: false).currentUser;
      final classes = user?.classIds ?? (user?.classId != null ? [user!.classId!] : <String>[]);
      if (classes.isNotEmpty) {
        setState(() => _selectedClassId = classes.first);
        _loadAttendance();
      }
    });
  }

  Future<void> _loadAttendance() async {
    if (_selectedClassId == null) return;
    setState(() => _isLoading = true);

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final isMarked = await _attendanceService.isAttendanceMarked(
        _selectedClassId!,
        dateStr,
      );
      final recordMap = await _attendanceService.getClassAttendanceForDate(
        _selectedClassId!,
        dateStr,
      );

      if (recordMap.isNotEmpty) {
        final Map<String, String> statusMap = {};
        for (final entry in recordMap.entries) {
          statusMap[entry.key] = entry.value.present ? 'present' : 'absent';
        }
        setState(() {
          _attendanceStatus = statusMap;
          _isMarked = isMarked;
          _isLoading = false;
        });
      } else {
        setState(() {
          _attendanceStatus = {};
          _isMarked = isMarked;
          _isLoading = false;
        });
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _markAllPresent(List<UserModel> students) {
    final Map<String, String> updated = {};
    for (final s in students) {
      updated[s.id] = 'present';
    }
    setState(() => _attendanceStatus = updated);
  }

  Future<void> _saveAttendance(List<UserModel> students) async {
    if (_selectedClassId == null || students.isEmpty) return;
    setState(() => _isSubmitting = true);

    final teacher = Provider.of<UserProvider>(context, listen: false).currentUser;
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    final Map<String, bool> studentAttendance = {};
    for (final s in students) {
      final status = _attendanceStatus[s.id] ?? 'present';
      studentAttendance[s.id] = (status == 'present');
    }

    try {
      await _attendanceService.markClassAttendance(
        classId: _selectedClassId!,
        dateKey: dateStr,
        studentAttendance: studentAttendance,
        markedBy: teacher?.id ?? 'teacher',
        allowUpdate: true,
      );
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _isMarked = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Attendance saved and synchronized successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving attendance: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).currentUser;
    final classes = user?.classIds ?? (user?.classId != null ? [user!.classId!] : <String>[]);

    if (classes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        alignment: Alignment.center,
        child: const Text('No classes assigned to take attendance.', style: TextStyle(color: Colors.white54)),
      );
    }

    _selectedClassId ??= classes.first;
    final formattedDate = DateFormat('EEEE, d MMMM yyyy').format(_selectedDate);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 560;

              final titleBlock = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Class Attendance Register',
                    style: EduStreakTheme.fontHeading1(color: Colors.white, weight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Mark and sync student daily attendance in real time with Student & Principal Portals.',
                    style: EduStreakTheme.fontBody(color: EduStreakTheme.darkTextSub),
                  ),
                ],
              );

              final recordedBadge = _isMarked
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 16),
                          SizedBox(width: 6),
                          Text('Recorded', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                    )
                  : const SizedBox.shrink();

              if (isCompact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleBlock,
                    if (_isMarked) ...[
                      const SizedBox(height: 10),
                      recordedBadge,
                    ],
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: titleBlock),
                  if (_isMarked) ...[
                    const SizedBox(width: 14),
                    recordedBadge,
                  ],
                ],
              );
            },
          ),

          const SizedBox(height: 20),

          // Date & Class Controls Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: EduStreakTheme.darkCardDecoration(),
            child: Wrap(
              spacing: 16,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Class Selector
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
                          onChanged: (v) {
                            setState(() => _selectedClassId = v);
                            _loadAttendance();
                          },
                          items: classes.map((c) {
                            final name = ClassNameHelper.formatClassNameSync(c, fallback: 'Class 8A');
                            return DropdownMenuItem(value: c, child: Text(name));
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),

                // Date Picker Button
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2025),
                      lastDate: DateTime.now().add(const Duration(days: 1)),
                      builder: (ctx, child) => Theme(
                        data: ThemeData.dark().copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: EduStreakTheme.primaryViolet,
                            surface: Color(0xFF0F1535),
                          ),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) {
                      setState(() => _selectedDate = picked);
                      _loadAttendance();
                    }
                  },
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F1535),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF222B5C)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_month_rounded, size: 16, color: EduStreakTheme.neonCyan),
                        const SizedBox(width: 8),
                        Text(formattedDate, style: const TextStyle(color: Colors.white, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Students Roster Stream & Marking
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('role', isEqualTo: 'student')
                .where('classId', isEqualTo: _selectedClassId)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting || _isLoading) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: EduStreakTheme.primaryViolet),
                  ),
                );
              }

              final docs = snapshot.data?.docs ?? [];
              final students = docs.map((d) {
                final data = d.data() as Map<String, dynamic>;
                return UserModel.fromMap(data..['id'] = d.id);
              }).toList();

              // Sort by roll number or name
              students.sort((a, b) => (a.rollNumber ?? a.name).compareTo(b.rollNumber ?? b.name));

              if (students.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(40),
                  alignment: Alignment.center,
                  decoration: EduStreakTheme.darkCardDecoration(),
                  child: const Text('No students enrolled in this class.', style: TextStyle(color: Colors.white54)),
                );
              }

              // Compute Summary Metrics
              int presentCount = 0;
              int absentCount = 0;
              int lateCount = 0;

              for (final s in students) {
                final status = _attendanceStatus[s.id] ?? 'present';
                if (status == 'present') presentCount++;
                if (status == 'absent') absentCount++;
                if (status == 'late') lateCount++;
              }

              final pct = students.isNotEmpty ? ((presentCount / students.length) * 100).round() : 100;

              return Column(
                children: [
                  // Attendance Summary Cards
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: EduStreakTheme.darkCardDecoration(),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMetricChip('Total Students', '${students.length}', Colors.white),
                        _buildMetricChip('Present', '$presentCount', Colors.greenAccent),
                        _buildMetricChip('Absent', '$absentCount', Colors.redAccent),
                        _buildMetricChip('Late', '$lateCount', Colors.orangeAccent),
                        _buildMetricChip('Attendance Rate', '$pct%', EduStreakTheme.neonCyan),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Actions row: Mark All Present + Save Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _markAllPresent(students),
                        icon: const Icon(Icons.select_all_rounded, size: 16),
                        label: const Text('Mark All Present'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: EduStreakTheme.neonCyan,
                          side: const BorderSide(color: EduStreakTheme.neonCyan),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : () => _saveAttendance(students),
                        icon: _isSubmitting
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.cloud_upload_rounded, size: 18),
                        label: Text(_isSubmitting ? 'Saving...' : 'Save & Submit Attendance', style: const TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(backgroundColor: EduStreakTheme.primaryViolet),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Student Roster
                  ...students.map((student) {
                    final status = _attendanceStatus[student.id] ?? 'present';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F1535),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF222B5C)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: EduStreakTheme.primaryViolet,
                            child: Text(
                              student.name.isNotEmpty ? student.name[0].toUpperCase() : 'S',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(student.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                Text('Roll No: ${student.rollNumber ?? "N/A"}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                              ],
                            ),
                          ),
                          // Present / Absent / Late Toggles
                          _buildStatusSelector(student.id, status),
                        ],
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSelector(String studentId, String currentStatus) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildStatusButton(studentId, 'present', 'P', Colors.greenAccent, currentStatus == 'present'),
        const SizedBox(width: 6),
        _buildStatusButton(studentId, 'absent', 'A', Colors.redAccent, currentStatus == 'absent'),
        const SizedBox(width: 6),
        _buildStatusButton(studentId, 'late', 'L', Colors.orangeAccent, currentStatus == 'late'),
      ],
    );
  }

  Widget _buildStatusButton(String studentId, String statusValue, String label, Color color, bool isSelected) {
    return InkWell(
      onTap: () {
        setState(() {
          _attendanceStatus[studentId] = statusValue;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.25) : const Color(0xFF161C48),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : const Color(0xFF222B5C),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? color : Colors.white54,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricChip(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 18)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
      ],
    );
  }
}
