import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../models/user_model.dart';
import '../../models/task_model.dart';
import '../../models/assessment_model.dart';
import '../../services/attendance_summary_service.dart';
import '../../services/task_service.dart';
import '../../services/assessment_service.dart';
import '../../widgets/streak_counter.dart';
import '../../widgets/xp_progress_bar.dart';
import '../../widgets/badge_display.dart';
import '../shared/skill_matrix_screen.dart';

class ChildProgressScreen extends StatefulWidget {
  const ChildProgressScreen({super.key});

  @override
  State<ChildProgressScreen> createState() => _ChildProgressScreenState();
}

class _ChildProgressScreenState extends State<ChildProgressScreen> {
  final AttendanceSummaryService _summaryService = AttendanceSummaryService();
  DateTime _selectedMonth = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final parent = userProvider.currentUser;
    final childId = parent?.childId ?? (parent?.childIds.isNotEmpty == true ? parent!.childIds.first : null);

    if (childId == null) {
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
            .doc(childId)
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

                const SizedBox(height: 32),

                // ── Homework & Assignments (Learning Diligence) ──
                _buildHomeworkSection(child.id),

                const SizedBox(height: 32),

                // ── Formal Assessments & Exam Results (Tested Mastery) ──
                _buildAssessmentsSection(child.id, child.classId ?? ''),

                const SizedBox(height: 32),

                // ── 6-Axis Competency Skill Matrix ──
                _buildSkillMatrixSection(child.id, child.name),
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

  // ─── HOMEWORK & ASSIGNMENTS SECTION ──────────────────────────────────────
  Widget _buildHomeworkSection(String childId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Homework & Assignments',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Icon(Icons.assignment_turned_in_rounded, color: Color(0xFF10B981)),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<TaskModel>>(
          stream: TaskService().getTasksForStudent(childId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
            }

            final tasks = snapshot.data ?? [];
            final total = tasks.length;
            int completed = 0;
            int pending = 0;
            int overdue = 0;
            final now = DateTime.now();

            for (final t in tasks) {
              final sub = t.submissions[childId];
              final hasGrade = t.marks[childId] != null;
              if (sub == 'submitted' || sub == 'completed' || hasGrade) {
                completed++;
              } else if (now.isAfter(t.dueDate)) {
                overdue++;
              } else {
                pending++;
              }
            }

            final completionRate = total > 0 ? ((completed / total) * 100).round() : 0;

            return Column(
              children: [
                // KPI Cards Row
                Row(
                  children: [
                    Expanded(child: _buildParentMetricCard('Completed', '$completed', '$completionRate% of assigned', const Color(0xFF10B981))),
                    const SizedBox(width: 8),
                    Expanded(child: _buildParentMetricCard('Pending', '$pending', 'Action required', const Color(0xFF06B6D4))),
                    const SizedBox(width: 8),
                    Expanded(child: _buildParentMetricCard('Overdue', '$overdue', 'Needs attention', Colors.redAccent)),
                  ],
                ),
                const SizedBox(height: 12),

                // Recent Tasks List
                if (tasks.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No homework assignments recorded.', style: TextStyle(color: Colors.grey)),
                  )
                else
                  ...tasks.take(4).map((t) {
                    final sub = t.submissions[childId];
                    final mark = t.marks[childId];
                    final isDone = sub == 'submitted' || sub == 'completed' || mark != null;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isDone ? const Color(0xFF10B981).withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                          child: Icon(
                            isDone ? Icons.check_circle_outline : Icons.pending_outlined,
                            color: isDone ? const Color(0xFF10B981) : Colors.orange,
                            size: 20,
                          ),
                        ),
                        title: Text(t.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text('${t.subject} • Due: ${t.dueDate.day}/${t.dueDate.month}'),
                        trailing: mark != null
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text('Grade: $mark/100', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                              )
                            : Text(isDone ? 'Submitted' : 'Pending', style: TextStyle(color: isDone ? Colors.green : Colors.orange, fontSize: 12)),
                      ),
                    );
                  }).toList(),
              ],
            );
          },
        ),
      ],
    );
  }

  // ─── FORMAL ASSESSMENTS & EXAMS SECTION ──────────────────────────────────
  Widget _buildAssessmentsSection(String childId, String classId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Examinations & Test Scores',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Icon(Icons.quiz_rounded, color: Color(0xFF06B6D4)),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<AssessmentModel>>(
          stream: AssessmentService().getAssessmentsForStudent(studentId: childId, classId: classId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
            }

            final assessments = snapshot.data ?? [];
            final evaluatedList = assessments.where((a) => a.scores.containsKey(childId)).toList();

            double scoreTotalPct = 0.0;
            for (final a in evaluatedList) {
              final s = a.scores[childId] ?? 0.0;
              if (a.totalMarks > 0) {
                scoreTotalPct += (s / a.totalMarks) * 100.0;
              }
            }
            final avgScore = evaluatedList.isNotEmpty ? (scoreTotalPct / evaluatedList.length).round() : 0;

            return Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _buildParentMetricCard('Total Tests', '${assessments.length}', 'Conducted', const Color(0xFF6C57FF))),
                    const SizedBox(width: 8),
                    Expanded(child: _buildParentMetricCard('Completed', '${evaluatedList.length}', 'Evaluated', const Color(0xFF06B6D4))),
                    const SizedBox(width: 8),
                    Expanded(child: _buildParentMetricCard('Avg Score', evaluatedList.isNotEmpty ? '$avgScore%' : 'N/A', 'Mastery', const Color(0xFF10B981))),
                  ],
                ),
                const SizedBox(height: 12),

                if (assessments.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No formal assessments recorded yet.', style: TextStyle(color: Colors.grey)),
                  )
                else
                  ...assessments.take(4).map((a) {
                    final hasScore = a.scores.containsKey(childId);
                    final score = a.scores[childId];
                    final feedback = a.feedback[childId];
                    final pct = hasScore && a.totalMarks > 0 ? (((score ?? 0) / a.totalMarks) * 100).round() : 0;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    a.title,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (hasScore)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981).withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${score?.toStringAsFixed(0)}/${a.totalMarks} ($pct%)',
                                      style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                  )
                                else
                                  const Text('Pending Attempt', style: TextStyle(color: Colors.orange, fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('${a.subject} • ${a.type.replaceAll('_', ' ').toUpperCase()} • Duration: ${a.durationMinutes} mins',
                                style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            if (feedback != null && feedback.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text('Teacher Feedback: "$feedback"',
                                  style: const TextStyle(color: Colors.teal, fontStyle: FontStyle.italic, fontSize: 12)),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
              ],
            );
          },
        ),
      ],
    );
  }

  // ─── 6-AXIS SKILL MATRIX SECTION ─────────────────────────────────────────
  Widget _buildSkillMatrixSection(String childId, String childName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Skill Intelligence Matrix',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Icon(Icons.radar_rounded, color: Color(0xFFA855F7)),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Authentic multi-dimensional competency analysis based on homework, test performance, and conceptual understanding.',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          clipBehavior: Clip.antiAlias,
          height: 620,
          child: SkillMatrixScreen(
            studentId: childId,
            studentName: childName,
            showAppBar: false,
          ),
        ),
      ],
    );
  }

  Widget _buildParentMetricCard(String label, String value, String subtitle, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 10), overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
