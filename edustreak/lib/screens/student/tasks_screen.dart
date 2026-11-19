import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../models/task_model.dart';
import '../../services/task_service.dart';
import '../../utils/edustreak_theme.dart';
import '../../widgets/edustreak_illustrations.dart';
import 'task_detail_screen.dart';
import 'package:intl/intl.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final currentUser = userProvider.currentUser;

    if (currentUser == null) {
      return const Center(child: CircularProgressIndicator(color: EduStreakTheme.primaryViolet));
    }

    return Container(
      color: EduStreakTheme.studentDarkBg,
      child: StreamBuilder<List<TaskModel>>(
        stream: TaskService().getTasksForStudent(currentUser.id, classId: currentUser.classId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: EduStreakTheme.primaryViolet));
          }

          final tasks = snapshot.data ?? [];

          // Compute status counts
          int total = tasks.length;
          int pending = 0;
          int inProgress = 0;
          int submitted = 0;
          int graded = 0;

          for (final t in tasks) {
            final sub = t.submissions[currentUser.id];
            final hasGrade = t.marks[currentUser.id] != null;
            if (hasGrade) {
              graded++;
            } else if (sub == 'submitted') {
              submitted++;
            } else if (sub == 'in_progress') {
              inProgress++;
            } else {
              pending++;
            }
          }

          // Filter tasks
          final filteredTasks = tasks.where((t) {
            final sub = t.submissions[currentUser.id];
            final hasGrade = t.marks[currentUser.id] != null;
            if (_selectedFilter == 'All') return true;
            if (_selectedFilter == 'Assigned') return sub != 'submitted' && sub != 'in_progress' && !hasGrade;
            if (_selectedFilter == 'In Progress') return sub == 'in_progress';
            if (_selectedFilter == 'Submitted') return sub == 'submitted';
            if (_selectedFilter == 'Graded') return hasGrade;
            return true;
          }).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Page Header (Clipboard + My Homework + Subtitle)
                _buildHeader(),
                const SizedBox(height: 20),

                // 2. 4 Metric Status Cards in a Row
                _buildMetricsRow(total: total, pending: pending, submitted: submitted, graded: graded),
                const SizedBox(height: 20),

                // 3. Next Assignment Hero Card
                _buildNextAssignmentHero(tasks, currentUser.id),
                const SizedBox(height: 22),

                // 4. Filter Pills Row
                _buildFilterPills(total: total, pending: pending, inProgress: inProgress, submitted: submitted, graded: graded),
                const SizedBox(height: 18),

                // 5. Assignment Cards List
                if (filteredTasks.isEmpty && tasks.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: EduStreakTheme.studentDarkCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: EduStreakTheme.studentDarkBorder),
                    ),
                    child: Center(
                      child: Text(
                        'No assignments in "$_selectedFilter"',
                        style: const TextStyle(color: EduStreakTheme.studentDarkTextMuted, fontSize: 14),
                      ),
                    ),
                  ),
                ] else if (filteredTasks.isEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: EduStreakTheme.studentDarkCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: EduStreakTheme.studentDarkBorder),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.assignment_outlined, size: 48, color: EduStreakTheme.studentDarkTextMuted),
                          SizedBox(height: 12),
                          Text(
                            'No Homework Assigned Yet',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'When your teachers assign homework for your class, it will appear here in real time.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: EduStreakTheme.studentDarkTextMuted, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredTasks.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final task = filteredTasks[index];
                      return _buildTaskCard(task, currentUser.id);
                    },
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── PAGE HEADER ────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Row(
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
          child: const Icon(Icons.assignment_rounded, color: EduStreakTheme.primaryViolet, size: 22),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'My Homework',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                  SizedBox(width: 6),
                  Text('📋', style: TextStyle(fontSize: 18)),
                ],
              ),
              SizedBox(height: 2),
              Text(
                'Complete your tasks, earn XP and keep your learning streak alive!',
                style: TextStyle(
                  color: EduStreakTheme.studentDarkTextMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── 4 STATUS METRIC CARDS ───────────────────────────────────────────────
  Widget _buildMetricsRow({
    required int total,
    required int pending,
    required int submitted,
    required int graded,
  }) {
    final metrics = [
      {'val': '$total', 'label': 'Total Assignments', 'color': const Color(0xFF7950FF), 'icon': Icons.assignment_rounded},
      {'val': '$pending', 'label': 'Pending', 'color': const Color(0xFFFF6B35), 'icon': Icons.hourglass_top_rounded},
      {'val': '$submitted', 'label': 'Submitted', 'color': const Color(0xFF00D4FF), 'icon': Icons.cloud_upload_rounded},
      {'val': '$graded', 'label': 'Graded', 'color': const Color(0xFF10B981), 'icon': Icons.verified_rounded},
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final int crossAxisCount = width >= 800 ? 4 : (width >= 450 ? 2 : 2);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: metrics.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 74,
          ),
          itemBuilder: (context, index) {
            final m = metrics[index];
            final color = m['color'] as Color;
            final icon = m['icon'] as IconData;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: EduStreakTheme.studentDarkCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: EduStreakTheme.studentDarkBorder, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          m['val'] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          m['label'] as String,
                          style: const TextStyle(
                            color: EduStreakTheme.studentDarkTextMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
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

  // ─── NEXT ASSIGNMENT HERO CARD ───────────────────────────────────────────
  Widget _buildNextAssignmentHero(List<TaskModel> tasks, String studentId) {
    TaskModel? nextTask;
    for (final t in tasks) {
      if (t.submissions[studentId] != 'submitted' && t.marks[studentId] == null) {
        nextTask = t;
        break;
      }
    }

    if (nextTask == null) {
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
        child: Row(
          children: [
            const AkashStudentAvatar(size: 64),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded, size: 13, color: Color(0xFF10B981)),
                        SizedBox(width: 4),
                        Text(
                          'All Caught Up! 🎉',
                          style: TextStyle(
                            color: Color(0xFF10B981),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'No Pending Homework',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'Great job! You have submitted all assigned homework.',
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
        ),
      );
    }

    final title = nextTask.title;
    final desc = nextTask.description.isNotEmpty
        ? nextTask.description
        : 'Assigned by ${nextTask.assignedByName} • Complete and submit your solutions.';
    final dueDate = DateFormat('MMM dd, yyyy').format(nextTask.dueDate);
    final xp = nextTask.xpReward;

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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 520;
          return Row(
            children: [
              // Mascot on Left
              const AkashStudentAvatar(size: 68),
              const SizedBox(width: 16),

              // Middle Assignment Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Next Assignment Pill
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7950FF).withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.push_pin_rounded, size: 13, color: Color(0xFFC4B5FD)),
                              SizedBox(width: 4),
                              Text(
                                'Next Assignment',
                                style: TextStyle(
                                  color: Color(0xFFC4B5FD),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      desc,
                      style: const TextStyle(
                        color: EduStreakTheme.studentDarkTextMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 12,
                      children: [
                        Text(
                          '📅 Due: $dueDate',
                          style: const TextStyle(
                            color: Color(0xFFFF6B35),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '⭐ Reward: $xp XP',
                          style: const TextStyle(
                            color: Color(0xFFFBBF24),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => TaskDetailScreen(taskId: nextTask!.id)),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7950FF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        elevation: 4,
                        shadowColor: const Color(0xFF7950FF).withValues(alpha: 0.5),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Open Assignment'),
                          SizedBox(width: 6),
                          Icon(Icons.arrow_forward_rounded, size: 15),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 3D Books + Clipboard artwork on Right
              if (!isNarrow) ...[
                const SizedBox(width: 14),
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const RadialGradient(
                      colors: [Color(0xFF10B981), Color(0xFF7950FF), Colors.transparent],
                      stops: [0.15, 0.5, 1.0],
                    ),
                  ),
                  child: const Center(
                    child: Text('📚📋✅', style: TextStyle(fontSize: 28)),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  // ─── FILTER PILLS ROW ────────────────────────────────────────────────────
  Widget _buildFilterPills({
    required int total,
    required int pending,
    required int inProgress,
    required int submitted,
    required int graded,
  }) {
    final pills = [
      {'key': 'All', 'label': 'All ($total)'},
      {'key': 'Assigned', 'label': 'Assigned ($pending)'},
      {'key': 'In Progress', 'label': 'In Progress ($inProgress)'},
      {'key': 'Submitted', 'label': 'Submitted ($submitted)'},
      {'key': 'Graded', 'label': 'Graded ($graded)'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: pills.map((p) {
          final isSelected = _selectedFilter == p['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => setState(() => _selectedFilter = p['key'] as String),
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: isSelected ? EduStreakTheme.activePillGradient : null,
                  color: isSelected ? null : EduStreakTheme.studentDarkCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? const Color(0xFFA855F7) : EduStreakTheme.studentDarkBorder,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF7950FF).withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  p['label'] as String,
                  style: TextStyle(
                    color: isSelected ? Colors.white : EduStreakTheme.studentDarkTextMuted,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── ASSIGNMENT CARD ─────────────────────────────────────────────────────
  Widget _buildTaskCard(TaskModel task, String studentId) {
    final sub = task.submissions[studentId];
    final hasGrade = task.marks[studentId] != null;
    final isSubmitted = sub == 'submitted';

    String statusText = 'Assigned';
    Color statusColor = const Color(0xFF7950FF);
    if (hasGrade) {
      statusText = 'Graded (${task.marks[studentId]}/${task.maxMarks})';
      statusColor = const Color(0xFF10B981);
    } else if (isSubmitted) {
      statusText = 'Submitted';
      statusColor = const Color(0xFF00D4FF);
    } else if (sub == 'in_progress') {
      statusText = 'In Progress';
      statusColor = const Color(0xFFFF6B35);
    }

    final dueDateStr = DateFormat('MMM dd, yyyy').format(task.dueDate);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EduStreakTheme.studentDarkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EduStreakTheme.studentDarkBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF7950FF).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.menu_book_rounded, color: Color(0xFFC4B5FD), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  task.description,
                  style: const TextStyle(
                    color: EduStreakTheme.studentDarkTextMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 12,
                  children: [
                    Text(
                      '📅 Due: $dueDateStr',
                      style: const TextStyle(
                        color: Color(0xFFFF6B35),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '⭐ ${task.xpReward} XP',
                      style: const TextStyle(
                        color: Color(0xFFFBBF24),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => TaskDetailScreen(taskId: task.id)),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7950FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(hasGrade ? 'Review' : (isSubmitted ? 'View' : 'Start')),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_rounded, size: 14),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
