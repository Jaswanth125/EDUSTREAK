import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/user_provider.dart';
import '../../models/task_model.dart';
import '../../models/user_model.dart';
import '../../services/task_service.dart';
import '../../utils/edustreak_theme.dart';
import '../../utils/class_name_helper.dart';
import 'widgets/create_assignment_dialog.dart';
import 'widgets/assignment_review_dialog.dart';

class TeacherAssignmentsScreen extends StatefulWidget {
  final bool showAppBar;
  const TeacherAssignmentsScreen({super.key, this.showAppBar = false});

  @override
  State<TeacherAssignmentsScreen> createState() => _TeacherAssignmentsScreenState();
}

class _TeacherAssignmentsScreenState extends State<TeacherAssignmentsScreen> {
  final TaskService _taskService = TaskService();

  String _searchQuery = '';
  String _selectedClassFilter = 'All';
  String _selectedSubjectFilter = 'All';
  String _selectedStatusFilter = 'All'; // 'All', 'Active', 'Pending Review', 'Completed', 'Drafts'
  String _selectedDueDateFilter = 'All Dates'; // 'All Dates', 'Due Today', 'Due This Week', 'Overdue'

  final Map<String, String> _classDisplayNames = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadClassNames();
    });
  }

  Future<void> _loadClassNames() async {
    final user = Provider.of<UserProvider>(context, listen: false).currentUser;
    if (user == null) return;

    final classIds = (user.classIds != null && user.classIds!.isNotEmpty)
        ? user.classIds!
        : (user.classId != null && user.classId!.isNotEmpty ? [user.classId!] : <String>[]);

    for (final id in classIds) {
      final name = await ClassNameHelper.getClassName(id, schoolId: user.schoolId);
      if (mounted) {
        setState(() {
          _classDisplayNames[id] = name;
        });
      }
    }
  }

  void _openCreateAssignmentDialog({TaskModel? taskToEdit}) async {
    final user = Provider.of<UserProvider>(context, listen: false).currentUser;
    if (user == null) return;

    final result = await CreateAssignmentDialog.show(context, user, existingTask: taskToEdit);
    if (result == true) {
      setState(() {});
    }
  }

  void _openReviewDialog(String taskId) {
    AssignmentReviewDialog.show(context, taskId);
  }

  Future<void> _confirmDeleteTask(TaskModel task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141A42),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF283168)),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 24),
            SizedBox(width: 10),
            Text('Delete Assignment?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${task.title}"? This will permanently remove the assignment and all associated student submissions.',
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _taskService.deleteTask(task.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Assignment deleted successfully'), backgroundColor: Colors.redAccent),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting assignment: $e'), backgroundColor: Colors.redAccent),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final teacher = userProvider.currentUser;

    if (teacher == null) {
      return const Center(child: CircularProgressIndicator(color: EduStreakTheme.primaryViolet));
    }

    final authorizedClassIds = (teacher.classIds != null && teacher.classIds!.isNotEmpty)
        ? teacher.classIds!
        : (teacher.classId != null && teacher.classId!.isNotEmpty ? [teacher.classId!] : <String>[]);

    final authorizedSubjects = teacher.assignedSubjects.isNotEmpty ? teacher.assignedSubjects : ['Mathematics'];

    final content = StreamBuilder<List<TaskModel>>(
      stream: _taskService.getTasksForTeacher(teacher.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: EduStreakTheme.primaryViolet));
        }

        final tasks = snapshot.data ?? [];

        // 1. Compute Live Firestore Metrics
        int totalAssignments = tasks.length;
        int activeAssignments = 0;
        int pendingSubmissions = 0;
        int reviewedSubmissions = 0;
        final now = DateTime.now();

        for (final t in tasks) {
          if (t.status != 'archived' && t.dueDate.isAfter(now)) {
            activeAssignments++;
          }
          for (final sub in t.submissions.values) {
            if (sub == 'submitted') {
              pendingSubmissions++;
            } else if (sub == 'graded') {
              reviewedSubmissions++;
            }
          }
        }

        // 2. Filter Tasks
        final filteredTasks = tasks.where((t) {
          // Search query filter
          if (_searchQuery.isNotEmpty) {
            final query = _searchQuery.toLowerCase();
            final matchesTitle = t.title.toLowerCase().contains(query);
            final matchesDesc = t.description.toLowerCase().contains(query);
            final matchesSubject = t.subject.toLowerCase().contains(query);
            if (!matchesTitle && !matchesDesc && !matchesSubject) return false;
          }

          // Class filter
          if (_selectedClassFilter != 'All' && t.classId != _selectedClassFilter) {
            return false;
          }

          // Subject filter
          if (_selectedSubjectFilter != 'All' && t.subject != _selectedSubjectFilter) {
            return false;
          }

          // Status filter
          if (_selectedStatusFilter == 'Active') {
            if (t.status == 'archived' || t.dueDate.isBefore(now)) return false;
          } else if (_selectedStatusFilter == 'Pending Review') {
            final hasPending = t.submissions.values.any((s) => s == 'submitted');
            if (!hasPending) return false;
          } else if (_selectedStatusFilter == 'Completed') {
            final allGraded = t.assignedTo.isNotEmpty &&
                t.assignedTo.every((sId) => t.submissions[sId] == 'graded');
            if (!allGraded) return false;
          } else if (_selectedStatusFilter == 'Drafts') {
            if (t.status != 'draft') return false;
          }

          // Due date filter
          if (_selectedDueDateFilter == 'Due Today') {
            final isToday = t.dueDate.year == now.year &&
                t.dueDate.month == now.month &&
                t.dueDate.day == now.day;
            if (!isToday) return false;
          } else if (_selectedDueDateFilter == 'Due This Week') {
            final diff = t.dueDate.difference(now).inDays;
            if (diff < 0 || diff > 7) return false;
          } else if (_selectedDueDateFilter == 'Overdue') {
            if (t.dueDate.isAfter(now)) return false;
          }

          return true;
        }).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // A. Header Row (Always visible Assign Task button)
              _buildHeader(teacher),

              const SizedBox(height: 22),

              // B. 4 Live Statistics Cards
              _buildStatisticsRow(
                total: totalAssignments,
                active: activeAssignments,
                pending: pendingSubmissions,
                reviewed: reviewedSubmissions,
              ),

              const SizedBox(height: 24),

              // C. Filter Controls
              _buildFiltersBar(authorizedClassIds, authorizedSubjects),

              const SizedBox(height: 20),

              // D. Assignments List or Empty State
              if (tasks.isEmpty)
                _buildEmptyState(
                  isFiltered: false,
                  onCreate: () => _openCreateAssignmentDialog(),
                )
              else if (filteredTasks.isEmpty)
                _buildEmptyState(
                  isFiltered: true,
                  onCreate: () => _openCreateAssignmentDialog(),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredTasks.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, idx) {
                    final task = filteredTasks[idx];
                    return _buildAssignmentCard(task, teacher);
                  },
                ),
            ],
          ),
        );
      },
    );

    if (widget.showAppBar) {
      return Scaffold(
        backgroundColor: const Color(0xFF070B1E),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0C1030),
          title: const Text('Assignments', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          elevation: 0,
        ),
        body: content,
      );
    }

    return Container(
      color: const Color(0xFF070B1E),
      child: content,
    );
  }

  // ─── A. HEADER ─────────────────────────────────────────────────────────────
  Widget _buildHeader(UserModel teacher) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 650;

        final titleColumn = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8774FF), Color(0xFF6C57FF)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6C57FF).withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.assignment_turned_in_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Assignments',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'Create, manage and track student learning tasks.',
                      style: TextStyle(color: EduStreakTheme.darkTextSub, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ],
        );

        final assignButton = Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF8774FF), Color(0xFF6C57FF)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6C57FF).withValues(alpha: 0.4),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.add_rounded, size: 20, color: Colors.white),
            label: const Text(
              'Assign New Task',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.3),
            ),
            onPressed: () => _openCreateAssignmentDialog(),
          ),
        );

        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              titleColumn,
              const SizedBox(height: 16),
              assignButton,
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: titleColumn),
            assignButton,
          ],
        );
      },
    );
  }

  // ─── B. 4 LIVE STATISTICS CARDS ───────────────────────────────────────────
  Widget _buildStatisticsRow({
    required int total,
    required int active,
    required int pending,
    required int reviewed,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final int crossAxisCount = width > 950 ? 4 : (width > 550 ? 2 : 1);

        final items = [
          _buildStatCard(
            label: 'Total Assignments',
            value: '$total',
            subtitle: 'Tasks across all classes',
            icon: Icons.layers_rounded,
            iconColor: EduStreakTheme.primaryViolet,
            bgColor: const Color(0xFF141A42),
          ),
          _buildStatCard(
            label: 'Active Assignments',
            value: '$active',
            subtitle: 'Currently open for students',
            icon: Icons.timer_outlined,
            iconColor: EduStreakTheme.neonCyan,
            bgColor: const Color(0xFF141A42),
          ),
          _buildStatCard(
            label: 'Pending Submissions',
            value: '$pending',
            subtitle: 'Awaiting your review & grade',
            icon: Icons.pending_actions_rounded,
            iconColor: const Color(0xFFF59E0B),
            bgColor: const Color(0xFF141A42),
            highlight: pending > 0,
          ),
          _buildStatCard(
            label: 'Reviewed Submissions',
            value: '$reviewed',
            subtitle: 'Graded & XP awarded',
            icon: Icons.verified_rounded,
            iconColor: EduStreakTheme.emeraldGreen,
            bgColor: const Color(0xFF141A42),
          ),
        ];

        if (crossAxisCount == 4) {
          return Row(
            children: items.map((card) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: card))).toList(),
          );
        }

        if (crossAxisCount == 2) {
          return Column(
            children: [
              Row(children: [Expanded(child: items[0]), const SizedBox(width: 12), Expanded(child: items[1])]),
              const SizedBox(height: 12),
              Row(children: [Expanded(child: items[2]), const SizedBox(width: 12), Expanded(child: items[3])]),
            ],
          );
        }

        return Column(
          children: items.map((card) => Padding(padding: const EdgeInsets.only(bottom: 12), child: card)).toList(),
        );
      },
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    bool highlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlight ? iconColor.withValues(alpha: 0.6) : const Color(0xFF222B5C),
          width: highlight ? 1.5 : 1,
        ),
        boxShadow: highlight
            ? [
                BoxShadow(
                  color: iconColor.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(color: EduStreakTheme.darkTextSub, fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ─── C. FILTER CONTROLS ──────────────────────────────────────────────────
  Widget _buildFiltersBar(List<String> classIds, List<String> subjects) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141A42),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF222B5C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search & Quick Dropdowns Row
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 800;

              final searchField = TextField(
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search by title, subject, or description...',
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                  prefixIcon: const Icon(Icons.search_rounded, color: Colors.white38, size: 18),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, color: Colors.white54, size: 16),
                          onPressed: () => setState(() => _searchQuery = ''),
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFF0C1030),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF283168)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF283168)),
                  ),
                ),
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
              );

              final classDropdown = Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0C1030),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF283168)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedClassFilter,
                    dropdownColor: const Color(0xFF141A42),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    items: [
                      const DropdownMenuItem(value: 'All', child: Text('All Classes')),
                      ...classIds.map((id) {
                        final label = _classDisplayNames[id] ?? ClassNameHelper.formatClassNameSync(id);
                        return DropdownMenuItem(value: id, child: Text(label));
                      }),
                    ],
                    onChanged: (val) => setState(() => _selectedClassFilter = val ?? 'All'),
                  ),
                ),
              );

              final subjectDropdown = Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0C1030),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF283168)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedSubjectFilter,
                    dropdownColor: const Color(0xFF141A42),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    items: [
                      const DropdownMenuItem(value: 'All', child: Text('All Subjects')),
                      ...subjects.map((s) => DropdownMenuItem(value: s, child: Text(s))),
                    ],
                    onChanged: (val) => setState(() => _selectedSubjectFilter = val ?? 'All'),
                  ),
                ),
              );

              final dueDateDropdown = Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0C1030),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF283168)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedDueDateFilter,
                    dropdownColor: const Color(0xFF141A42),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    items: const [
                      DropdownMenuItem(value: 'All Dates', child: Text('All Dates')),
                      DropdownMenuItem(value: 'Due Today', child: Text('Due Today')),
                      DropdownMenuItem(value: 'Due This Week', child: Text('Due This Week')),
                      DropdownMenuItem(value: 'Overdue', child: Text('Overdue')),
                    ],
                    onChanged: (val) => setState(() => _selectedDueDateFilter = val ?? 'All Dates'),
                  ),
                ),
              );

              if (isNarrow) {
                return Column(
                  children: [
                    searchField,
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: classDropdown),
                        const SizedBox(width: 8),
                        Expanded(child: subjectDropdown),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(width: double.infinity, child: dueDateDropdown),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(flex: 3, child: searchField),
                  const SizedBox(width: 12),
                  classDropdown,
                  const SizedBox(width: 12),
                  subjectDropdown,
                  const SizedBox(width: 12),
                  dueDateDropdown,
                ],
              );
            },
          ),

          const SizedBox(height: 12),

          // Status Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Text('Status: ', style: TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(width: 6),
                ...['All', 'Active', 'Pending Review', 'Completed', 'Drafts'].map((st) {
                  final isSelected = _selectedStatusFilter == st;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(st, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.white70)),
                      selected: isSelected,
                      selectedColor: EduStreakTheme.primaryViolet,
                      backgroundColor: const Color(0xFF0C1030),
                      side: BorderSide(color: isSelected ? EduStreakTheme.primaryViolet : const Color(0xFF283168)),
                      onSelected: (val) => setState(() => _selectedStatusFilter = st),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── D. ASSIGNMENT CARD ───────────────────────────────────────────────────
  Widget _buildAssignmentCard(TaskModel task, UserModel teacher) {
    final now = DateTime.now();
    final isOverdue = task.dueDate.isBefore(now);
    final daysLeft = task.dueDate.difference(now).inDays;

    final totalAssigned = task.assignedTo.length;
    final submittedCount = task.submissions.values.where((s) => s == 'submitted').length;
    final gradedCount = task.submissions.values.where((s) => s == 'graded').length;
    final totalCompleted = submittedCount + gradedCount;
    final progress = totalAssigned > 0 ? (totalCompleted / totalAssigned).clamp(0.0, 1.0) : 0.0;

    final className = _classDisplayNames[task.classId] ?? ClassNameHelper.formatClassNameSync(task.classId);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF141A42),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: submittedCount > 0 ? const Color(0xFFF59E0B).withValues(alpha: 0.5) : const Color(0xFF222B5C),
          width: submittedCount > 0 ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header Row: Subject, Type, Status Pill, More Options
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Subject Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: EduStreakTheme.primaryViolet.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: EduStreakTheme.primaryViolet.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.book_outlined, size: 13, color: Color(0xFFB8A8FF)),
                    const SizedBox(width: 5),
                    Text(
                      task.subject.isNotEmpty ? task.subject : 'General',
                      style: const TextStyle(color: Color(0xFFB8A8FF), fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Type Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF06B6D4).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF06B6D4).withValues(alpha: 0.35)),
                ),
                child: Text(
                  task.type,
                  style: const TextStyle(color: Color(0xFF06B6D4), fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),

              // Class Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  className,
                  style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),

              const Spacer(),

              // Status Badge
              if (task.status == 'draft')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('DRAFT', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                )
              else if (submittedCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFF59E0B)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.circle, color: Color(0xFFF59E0B), size: 7),
                      const SizedBox(width: 6),
                      Text(
                        '$submittedCount Needs Review',
                        style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                )
              else if (isOverdue)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.redAccent),
                  ),
                  child: const Text('Closed / Overdue', style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                ),

              // Overflow Menu
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: Colors.white60, size: 20),
                color: const Color(0xFF141A42),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Color(0xFF283168))),
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 16, color: Colors.white70), SizedBox(width: 10), Text('Edit Task', style: TextStyle(color: Colors.white, fontSize: 13))])),
                  const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 16, color: Colors.redAccent), SizedBox(width: 10), Text('Delete Task', style: TextStyle(color: Colors.redAccent, fontSize: 13))])),
                ],
                onSelected: (val) {
                  if (val == 'edit') _openCreateAssignmentDialog(taskToEdit: task);
                  if (val == 'delete') _confirmDeleteTask(task);
                },
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Title & Description
          Text(
            task.title,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (task.chapterOrTopic.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Topic: ${task.chapterOrTopic}',
              style: const TextStyle(color: EduStreakTheme.neonCyan, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            task.description,
            style: TextStyle(color: EduStreakTheme.darkTextSub, fontSize: 13, height: 1.4),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 14),

          // Metadata Chips (Due date, Max Marks, Questions, Attachments)
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _buildMetaPill(
                icon: Icons.calendar_today_rounded,
                label: 'Due: ${DateFormat('MMM dd, yyyy • hh:mm a').format(task.dueDate)}',
                color: isOverdue ? Colors.redAccent : (daysLeft <= 1 ? const Color(0xFFF59E0B) : Colors.white70),
              ),
              _buildMetaPill(
                icon: Icons.grade_rounded,
                label: 'Max: ${task.maxMarks} pts',
                color: Colors.white70,
              ),
              _buildMetaPill(
                icon: Icons.bolt_rounded,
                label: '+${task.xpReward} XP',
                color: const Color(0xFFF59E0B),
              ),
              if (task.questions.isNotEmpty)
                _buildMetaPill(
                  icon: Icons.quiz_outlined,
                  label: '${task.questions.length} Questions',
                  color: const Color(0xFF06B6D4),
                ),
              if (task.attachmentNames.isNotEmpty)
                _buildMetaPill(
                  icon: Icons.attach_file_rounded,
                  label: '${task.attachmentNames.length} Files',
                  color: Colors.white70,
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Submissions Progress Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Submissions: $totalCompleted of $totalAssigned students',
                style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(color: EduStreakTheme.neonCyan, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: const Color(0xFF0C1030),
              valueColor: AlwaysStoppedAnimation<Color>(
                submittedCount > 0 ? const Color(0xFFF59E0B) : EduStreakTheme.emeraldGreen,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Action Buttons Bar
          Row(
            children: [
              // Review Submissions Primary Button
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8774FF), Color(0xFF6C57FF)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.rate_review_rounded, size: 16),
                    label: Text(
                      submittedCount > 0
                          ? 'Review Submissions ($submittedCount to Grade)'
                          : 'View Submissions & Grades ($totalCompleted/$totalAssigned)',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => _openReviewDialog(task.id),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Edit Button
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: const BorderSide(color: Color(0xFF283168)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edit'),
                onPressed: () => _openCreateAssignmentDialog(taskToEdit: task),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetaPill({required IconData icon, required String label, required Color color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(color: color, fontSize: 12)),
      ],
    );
  }

  // ─── E. EMPTY STATE ────────────────────────────────────────────────────────
  Widget _buildEmptyState({required bool isFiltered, required VoidCallback onCreate}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: const Color(0xFF141A42),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF222B5C)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: EduStreakTheme.primaryViolet.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.assignment_outlined,
              size: 48,
              color: EduStreakTheme.primaryViolet,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            isFiltered ? 'No matching assignments found' : 'No assignments yet',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isFiltered
                ? 'Try adjusting your class, subject, or status filters above.'
                : 'Create your first assignment and help your students keep learning.',
            style: TextStyle(color: EduStreakTheme.darkTextSub, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8774FF), Color(0xFF6C57FF)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6C57FF).withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text(
                'Create First Assignment',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              onPressed: onCreate,
            ),
          ),
        ],
      ),
    );
  }
}
