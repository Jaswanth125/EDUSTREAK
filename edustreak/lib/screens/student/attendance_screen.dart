import 'package:flutter/material.dart';
import '../../utils/edustreak_theme.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../providers/user_provider.dart';
import '../../services/attendance_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/attendance_model.dart';

class StudentAttendanceScreen extends StatefulWidget {
  final bool showAppBar;
  const StudentAttendanceScreen({super.key, this.showAppBar = false});

  @override
  State<StudentAttendanceScreen> createState() => _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends State<StudentAttendanceScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  final AttendanceService _attendanceService = AttendanceService();
  Map<String, AttendanceRecord> _attendanceRecords = {};
  Map<String, dynamic> _monthlyStats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAttendanceData();
  }

  Future<void> _loadAttendanceData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final student = userProvider.currentUser;
    if (student == null) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    try {
      // Load current month's attendance
      await _loadMonthAttendance(student.id, _focusedDay);
    } catch (e) {
      debugPrint('Error loading attendance: $e');
      // Show error but don't block the UI
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading attendance: $e'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadMonthAttendance(String studentId, DateTime month) async {
    try {
      final startDate = DateTime(month.year, month.month, 1);
      final endDate = DateTime(month.year, month.month + 1, 0);

      // Load attendance records
      Map<String, AttendanceRecord> records = {};
      try {
        records = await _attendanceService.getStudentAttendanceRange(
          studentId,
          startDate,
          endDate,
        );
      } catch (e) {
        debugPrint('Error loading attendance records: $e');
        // Continue with empty records
      }

      // Load monthly stats
      Map<String, dynamic> stats = {};
      try {
        stats = await _attendanceService.getStudentMonthlyStats(
          studentId,
          month,
        );
      } catch (e) {
        debugPrint('Error loading monthly stats: $e');
        // Set default stats
        stats = {
          'totalDays': 0,
          'presentDays': 0,
          'absentDays': 0,
          'percentage': 0.0,
        };
      }

      if (mounted) {
        setState(() {
          _attendanceRecords = records;
          _monthlyStats = stats;
        });
      }
    } catch (e) {
      debugPrint('Error loading month attendance: $e');
      // Ensure we have default values
      if (mounted) {
        setState(() {
          _monthlyStats = {
            'totalDays': 0,
            'presentDays': 0,
            'absentDays': 0,
            'percentage': 0.0,
          };
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final student = userProvider.currentUser;

    if (student == null) {
      return const Scaffold(
        body: Center(child: Text('Student data not found')),
      );
    }

    final content = _isLoading
          ? const Center(child: CircularProgressIndicator(color: EduStreakTheme.primaryViolet))
          : RefreshIndicator(
              color: EduStreakTheme.primaryViolet,
              onRefresh: _loadAttendanceData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPageHeader(),
                    const SizedBox(height: 20),
                    _buildMonthlySummaryCard(student.id),
                    const SizedBox(height: 20),
                    _buildCalendarView(),
                    const SizedBox(height: 20),
                    _buildLegend(),
                    const SizedBox(height: 20),
                    _buildSelectedDayDetails(),
                  ],
                ),
              ),
            );

    if (widget.showAppBar) {
      return Scaffold(
        backgroundColor: EduStreakTheme.studentDarkBg,
        appBar: AppBar(
          title: const Text('My Attendance'),
          backgroundColor: EduStreakTheme.studentDarkHeader,
          foregroundColor: Colors.white,
        ),
        body: content,
      );
    }

    return Container(
      color: EduStreakTheme.studentDarkBg,
      child: content,
    );
  }

  Widget _buildPageHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 540;

        final titleSection = Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: EduStreakTheme.primaryViolet.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: EduStreakTheme.primaryViolet.withValues(alpha: 0.4),
                  width: 1.2,
                ),
              ),
              child: const Icon(Icons.calendar_month_rounded, color: EduStreakTheme.primaryViolet, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          'Attendance Tracker',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text('📅', style: TextStyle(fontSize: 18)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Track your daily presence, leaves, and maintain your 90%+ streak!',
                    style: TextStyle(
                      color: EduStreakTheme.studentDarkTextMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

        final actionBtn = OutlinedButton.icon(
          onPressed: _showCorrectionDialog,
          icon: const Icon(Icons.edit_calendar_rounded, size: 16, color: EduStreakTheme.primaryViolet),
          label: const Text('Correction Request', style: TextStyle(color: EduStreakTheme.primaryViolet, fontSize: 12, fontWeight: FontWeight.w700)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: EduStreakTheme.primaryViolet, width: 1.2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        );

        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleSection,
              const SizedBox(height: 12),
              actionBtn,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: titleSection),
            const SizedBox(width: 12),
            actionBtn,
          ],
        );
      },
    );
  }

  Future<void> _showCorrectionDialog() async {
    final user = Provider.of<UserProvider>(context, listen: false).currentUser;
    if (user == null) return;

    DateTime disputedDate = _selectedDay;
    String requestedStatus = 'present';
    final reasonController = TextEditingController();

    final submitted = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: EduStreakTheme.studentDarkCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.edit_calendar_rounded, color: EduStreakTheme.primaryViolet, size: 22),
              SizedBox(width: 10),
              Text('Attendance Correction', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Submit a correction request to your class teacher if your attendance was recorded incorrectly.',
                  style: TextStyle(color: EduStreakTheme.studentDarkTextMuted, fontSize: 13)),
              const SizedBox(height: 16),
              Text('Disputed Date: ${disputedDate.day}/${disputedDate.month}/${disputedDate.year}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 12),
              const Text('Claimed Status:', style: TextStyle(color: EduStreakTheme.studentDarkTextMuted, fontSize: 12)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: requestedStatus,
                dropdownColor: EduStreakTheme.studentDarkCard,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: EduStreakTheme.studentDarkBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: const [
                  DropdownMenuItem(value: 'present', child: Text('Present (Present in class)')),
                  DropdownMenuItem(value: 'leave', child: Text('Approved Leave (Sick/Permitted)')),
                ],
                onChanged: (val) {
                  if (val != null) setDlgState(() => requestedStatus = val);
                },
              ),
              const SizedBox(height: 12),
              const Text('Reason / Explanation:', style: TextStyle(color: EduStreakTheme.studentDarkTextMuted, fontSize: 12)),
              const SizedBox(height: 6),
              TextField(
                controller: reasonController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'e.g. Present for all periods; medical certificate submitted to teacher.',
                  hintStyle: const TextStyle(color: EduStreakTheme.studentDarkTextMuted, fontSize: 12),
                  filled: true,
                  fillColor: EduStreakTheme.studentDarkBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel', style: TextStyle(color: EduStreakTheme.studentDarkTextMuted)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: EduStreakTheme.primaryViolet,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Submit Request'),
            ),
          ],
        ),
      ),
    );

    if (submitted == true && mounted) {
      try {
        final docRef = FirebaseFirestore.instance.collection('attendance_corrections').doc();
        await docRef.set({
          'id': docRef.id,
          'studentId': user.id,
          'studentName': user.name,
          'schoolId': user.schoolId ?? 'default_school',
          'classId': user.classId ?? '',
          'date': Timestamp.fromDate(disputedDate),
          'requestedStatus': requestedStatus,
          'reason': reasonController.text.trim(),
          'status': 'pending',
          'createdAt': Timestamp.now(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('📬 Correction request submitted to class teacher.'),
              backgroundColor: Color(0xFF10B981),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to submit request: $e'), backgroundColor: Colors.redAccent),
          );
        }
      }
    }
  }

  Widget _buildMonthlySummaryCard(String studentId) {
    final totalDays = _monthlyStats['totalDays'] ?? 0;
    final presentDays = _monthlyStats['presentDays'] ?? 0;
    final absentDays = _monthlyStats['absentDays'] ?? 0;
    final percentage = _monthlyStats['percentage'] ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: EduStreakTheme.studentDarkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: EduStreakTheme.studentDarkBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'This Month\'s Attendance',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Present', presentDays, Colors.green),
              _buildStatItem('Absent', absentDays, Colors.red),
              _buildStatItem('Total', totalDays, Colors.blue),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 8,
          ),
          const SizedBox(height: 8),
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (percentage >= 90)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.star, color: Colors.amber, size: 20),
                  SizedBox(width: 4),
                  Text(
                    'Consistency Star!',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          if (percentage == 100)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.emoji_events, color: Colors.amber, size: 20),
                  SizedBox(width: 4),
                  Text(
                    'Attendance Hero!',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$value',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarView() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: EduStreakTheme.studentDarkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: EduStreakTheme.studentDarkBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TableCalendar<AttendanceRecord>(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.now(),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        calendarFormat: _calendarFormat,
        eventLoader: (day) {
          final dateKey = AttendanceService.getDateKey(day);
          final record = _attendanceRecords[dateKey];
          return record != null ? [record] : [];
        },
        startingDayOfWeek: StartingDayOfWeek.monday,
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          defaultTextStyle: const TextStyle(color: Colors.white),
          weekendTextStyle: const TextStyle(color: Color(0xFFC4B5FD)),
          selectedDecoration: const BoxDecoration(
            gradient: EduStreakTheme.activePillGradient,
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: const Color(0xFF7950FF).withValues(alpha: 0.35),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF7950FF), width: 1.2),
          ),
          markerDecoration: const BoxDecoration(
            color: Colors.transparent,
            shape: BoxShape.circle,
          ),
          markersMaxCount: 1,
          markerSize: 8,
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: true,
          titleCentered: true,
          titleTextStyle: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          formatButtonTextStyle: const TextStyle(color: Colors.white, fontSize: 12),
          formatButtonDecoration: BoxDecoration(
            color: EduStreakTheme.studentDarkCardSub,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: EduStreakTheme.studentDarkBorder),
          ),
          leftChevronIcon: const Icon(Icons.chevron_left, color: Colors.white),
          rightChevronIcon: const Icon(Icons.chevron_right, color: Colors.white),
        ),
        onDaySelected: (selectedDay, focusedDay) {
          if (!isSameDay(_selectedDay, selectedDay)) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          }
        },
        onFormatChanged: (format) {
          if (_calendarFormat != format) {
            setState(() {
              _calendarFormat = format;
            });
          }
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
          final userProvider = Provider.of<UserProvider>(context, listen: false);
          final student = userProvider.currentUser;
          if (student != null) {
            _loadMonthAttendance(student.id, focusedDay);
          }
        },
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, date, events) {
            if (events.isEmpty) return null;
            
            final record = events.first;
            return Positioned(
              bottom: 1,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: record.present ? Colors.green : Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
          defaultBuilder: (context, date, _) {
            final dateKey = AttendanceService.getDateKey(date);
            final record = _attendanceRecords[dateKey];
            
            if (record == null) return null;
            
            return Container(
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: record.present 
                    ? Colors.green.withOpacity(0.2)
                    : Colors.red.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${date.day}',
                  style: TextStyle(
                    color: record.present ? Colors.green.shade700 : Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          },
          selectedBuilder: (context, date, _) {
            return Container(
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${date.day}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildLegendItem(Icons.check_circle, 'Present', Colors.green),
          _buildLegendItem(Icons.cancel, 'Absent', Colors.red),
          _buildLegendItem(Icons.circle, 'Not Marked', Colors.grey),
        ],
      ),
    );
  }

  Widget _buildLegendItem(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedDayDetails() {
    final dateKey = AttendanceService.getDateKey(_selectedDay);
    final record = _attendanceRecords[dateKey];

    if (record == null) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(Icons.calendar_today, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              'No attendance marked for ${_formatDate(_selectedDay)}',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: record.present ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: record.present ? Colors.green : Colors.red,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            record.present ? Icons.check_circle : Icons.cancel,
            color: record.present ? Colors.green : Colors.red,
            size: 48,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.present ? 'Present' : 'Absent',
                  style: TextStyle(
                    color: record.present ? Colors.green.shade700 : Colors.red.shade700,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(_selectedDay),
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Marked at: ${_formatTime(record.timestamp)}',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

