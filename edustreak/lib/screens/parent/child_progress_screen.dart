import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../models/user_model.dart';
import '../../services/attendance_service.dart';
import '../../services/attendance_summary_service.dart';
import '../../widgets/streak_counter.dart';
import '../../widgets/xp_progress_bar.dart';
import '../../widgets/badge_display.dart';

class ChildProgressScreen extends StatefulWidget {
  const ChildProgressScreen({super.key});

  @override
  State<ChildProgressScreen> createState() => _ChildProgressScreenState();
}

class _ChildProgressScreenState extends State<ChildProgressScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  final AttendanceSummaryService _summaryService = AttendanceSummaryService();
  DateTime _selectedMonth = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final parent = userProvider.currentUser;

    if (parent?.childId == null) {
      return const Scaffold(
        body: Center(
          child: Text('No child linked to your account. Please contact admin.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Child Progress'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(parent!.childId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Child data not found'));
          }

          final childData = snapshot.data!.data() as Map<String, dynamic>;
          final child = UserModel.fromMap(childData..['id'] = snapshot.data!.id);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Child Info Card
                Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          child: Text(child.name[0].toUpperCase()),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                child.name,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              Text('Class: ${child.classId ?? "N/A"}'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Streak Counter
                StreakCounter(streak: child.streak),
                const SizedBox(height: 24),

                // XP Progress
                XPProgressBar(xp: child.xp, level: child.level),
                const SizedBox(height: 24),

                // Badges
                Text(
                  'Badges Earned',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                BadgeDisplay(userId: child.id, badges: child.badges),
                const SizedBox(height: 24),

                // Attendance Summary Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Attendance Summary',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _selectedMonth,
                          firstDate: DateTime(2020, 1, 1),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() {
                            _selectedMonth = date;
                          });
                        }
                      },
                      tooltip: 'Select Month',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${_getMonthName(_selectedMonth.month)} ${_selectedMonth.year}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                FutureBuilder<Map<String, dynamic>>(
                  future: _summaryService.getStudentMonthlySummary(
                    child.id,
                    child.classId ?? '',
                    _selectedMonth,
                  ),
                  builder: (context, summarySnapshot) {
                    if (summarySnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final summary = summarySnapshot.data ?? {};
                    final totalWorkingDays = summary['totalWorkingDays'] ?? 0;
                    final presentDays = summary['presentDays'] ?? 0;
                    final absentDays = summary['absentDays'] ?? 0;
                    final percentage = summary['percentage'] ?? 0.0;

                    return _buildAttendanceCard(
                      context,
                      totalWorkingDays,
                      presentDays,
                      absentDays,
                      percentage,
                      child.name,
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAttendanceCard(
    BuildContext context,
    int totalWorkingDays,
    int presentDays,
    int absentDays,
    double percentage,
    String childName,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.school,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Monthly Attendance',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_getMonthName(_selectedMonth.month)} ${_selectedMonth.year}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Main Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCircle('Present', presentDays, Colors.green.shade300, Colors.white),
                _buildStatCircle('Absent', absentDays, Colors.red.shade300, Colors.white),
                _buildStatCircle('Total', totalWorkingDays, Colors.blue.shade300, Colors.white),
              ],
            ),
            const SizedBox(height: 24),

            // Progress Bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Attendance Rate',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    minHeight: 10,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      percentage >= 90 ? Colors.green.shade300 : Colors.orange.shade300,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Motivational Message
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    _getMotivationalIcon(percentage),
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _getMotivationalMessage(childName, presentDays, totalWorkingDays, percentage),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Badge Indicators
            if (percentage >= 90)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Row(
                  children: [
                    Icon(
                      percentage == 100 ? Icons.emoji_events : Icons.star,
                      color: Colors.amber,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      percentage == 100
                          ? 'Attendance Hero Achievement Unlocked!'
                          : 'Consistency Star Achievement Unlocked!',
                      style: TextStyle(
                        color: Colors.amber.shade100,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCircle(String label, int value, Color color, Color textColor) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(0.3),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: Text(
              '$value',
              style: TextStyle(
                color: textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  IconData _getMotivationalIcon(double percentage) {
    if (percentage == 100) return Icons.emoji_events;
    if (percentage >= 90) return Icons.star;
    if (percentage >= 75) return Icons.thumb_up;
    return Icons.trending_up;
  }

  String _getMotivationalMessage(
    String childName,
    int presentDays,
    int totalWorkingDays,
    double percentage,
  ) {
    if (percentage == 100) {
      return '$childName attended all $totalWorkingDays classes this month. Outstanding commitment! 🎉';
    } else if (percentage >= 90) {
      return '$childName attended $presentDays out of $totalWorkingDays classes this month (${percentage.toStringAsFixed(1)}%). Excellent attendance! ⭐';
    } else if (percentage >= 75) {
      return '$childName attended $presentDays out of $totalWorkingDays classes this month (${percentage.toStringAsFixed(1)}%). Keep it up! 👍';
    } else {
      return '$childName attended $presentDays out of $totalWorkingDays classes this month (${percentage.toStringAsFixed(1)}%). Let\'s work on improving attendance! 📈';
    }
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }
}
