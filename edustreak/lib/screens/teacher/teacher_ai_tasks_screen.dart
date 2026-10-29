import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../models/ai_task_model.dart';
import '../../services/ai_task_service.dart';
import '../../utils/theme.dart';

class TeacherAiTasksScreen extends StatefulWidget {
  const TeacherAiTasksScreen({super.key});

  @override
  State<TeacherAiTasksScreen> createState() => _TeacherAiTasksScreenState();
}

class _TeacherAiTasksScreenState extends State<TeacherAiTasksScreen> {
  final AiTaskService _aiTaskService = AiTaskService();
  String? _selectedClassId;

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final teacher = userProvider.currentUser;

    if (teacher == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final classIds = teacher.classIds ?? [];
    if (classIds.isNotEmpty && _selectedClassId == null) {
      _selectedClassId = classIds.first;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Tasks Review'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.primaryGradient,
          ),
        ),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Class Selector Header
          if (classIds.length > 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Colors.grey.shade100,
              child: Row(
                children: [
                  const Icon(Icons.filter_list, size: 20, color: Colors.grey),
                  const SizedBox(width: 8),
                  const Text('Class: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _selectedClassId,
                    underline: const SizedBox(),
                    items: classIds.map((cId) {
                      return DropdownMenuItem(
                        value: cId,
                        child: Text(cId),
                      );
                    }).toList(),
                    onChanged: (newVal) {
                      if (newVal != null) {
                        setState(() => _selectedClassId = newVal);
                      }
                    },
                  ),
                ],
              ),
            ),

          // Informational Trust & Safety banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.amber.shade50,
            child: Row(
              children: [
                Icon(Icons.shield_outlined, color: Colors.amber.shade800, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Trust & Safety: Students cannot see or take these tasks until you approve them.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.amber.shade900,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // List of pending tasks
          Expanded(
            child: StreamBuilder<List<AiTaskModel>>(
              stream: _selectedClassId != null
                  ? _aiTaskService.getPendingTasksForClass('default_school', _selectedClassId!)
                  : _aiTaskService.getAllPendingTasks('default_school'),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error loading tasks: ${snapshot.error}'),
                  );
                }

                final tasks = snapshot.data ?? [];
                if (tasks.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline, size: 64, color: Colors.green.shade400),
                          const SizedBox(height: 16),
                          const Text(
                            'All Caught Up!',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No pending AI-generated tasks to review for this class.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return _buildPendingTaskCard(context, task, teacher.id, teacher.name);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingTaskCard(
    BuildContext context,
    AiTaskModel task,
    String teacherId,
    String teacherName,
  ) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Subject, Topic & Target Student
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    task.subject.toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Text(
                    task.difficulty.toUpperCase(),
                    style: TextStyle(
                      color: Colors.orange.shade800,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Topic & Student context
            Text(
              task.topic,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            if (task.studentName.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Generated for: ${task.studentName}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ],
            const Divider(height: 20),

            // Question Text
            Text(
              task.question,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            // MCQ Options
            ...task.options.map((opt) {
              final isCorrect = opt.trim() == task.correctAnswer.trim();
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isCorrect ? Colors.green.shade50 : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isCorrect ? Colors.green.shade400 : Colors.grey.shade300,
                    width: isCorrect ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isCorrect ? Icons.check_circle : Icons.radio_button_unchecked,
                      size: 16,
                      color: isCorrect ? Colors.green.shade700 : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        opt,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isCorrect ? FontWeight.bold : FontWeight.normal,
                          color: isCorrect ? Colors.green.shade900 : Colors.black87,
                        ),
                      ),
                    ),
                    if (isCorrect)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Correct',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.green.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),

            if (task.explanation.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Explanation: ${task.explanation}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Action Buttons: Approve, Edit, Reject
            Row(
              children: [
                // Reject Button
                OutlinedButton.icon(
                  onPressed: () => _handleReject(context, task, teacherId),
                  icon: const Icon(Icons.close, size: 16, color: Colors.red),
                  label: const Text('Reject', style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(width: 8),

                // Edit Button
                OutlinedButton.icon(
                  onPressed: () => _handleEdit(context, task, teacherId, teacherName),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const Spacer(),

                // Approve Button
                ElevatedButton.icon(
                  onPressed: () => _handleApprove(context, task, teacherId, teacherName),
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleApprove(
    BuildContext context,
    AiTaskModel task,
    String teacherId,
    String teacherName,
  ) async {
    try {
      await _aiTaskService.approveTask(
        schoolId: task.schoolId,
        taskId: task.id,
        teacherId: teacherId,
        teacherName: teacherName,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task approved! Now available for student practice.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error approving task: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleReject(
    BuildContext context,
    AiTaskModel task,
    String teacherId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject AI Task?'),
        content: const Text('This task will be discarded and will not be shown to the student.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _aiTaskService.rejectTask(
        schoolId: task.schoolId,
        taskId: task.id,
        teacherId: teacherId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task rejected'), duration: Duration(seconds: 2)),
        );
      }
    }
  }

  Future<void> _handleEdit(
    BuildContext context,
    AiTaskModel task,
    String teacherId,
    String teacherName,
  ) async {
    final questionController = TextEditingController(text: task.question);
    final explanationController = TextEditingController(text: task.explanation);
    final optionControllers = task.options.map((opt) => TextEditingController(text: opt)).toList();
    int selectedCorrectIndex = task.options.indexOf(task.correctAnswer);
    if (selectedCorrectIndex < 0) selectedCorrectIndex = 0;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                top: 20,
                left: 16,
                right: 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Edit & Approve Task',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: questionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Question',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Options (select radio for correct answer):',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...List.generate(optionControllers.length, (idx) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Radio<int>(
                              value: idx,
                              groupValue: selectedCorrectIndex,
                              onChanged: (val) {
                                if (val != null) {
                                  setModalState(() => selectedCorrectIndex = val);
                                }
                              },
                            ),
                            Expanded(
                              child: TextField(
                                controller: optionControllers[idx],
                                decoration: InputDecoration(
                                  labelText: 'Option ${idx + 1}',
                                  border: const OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                    TextField(
                      controller: explanationController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Explanation (Optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () async {
                          final newQuestion = questionController.text.trim();
                          final newOptions = optionControllers.map((c) => c.text.trim()).toList();
                          final newCorrect = newOptions[selectedCorrectIndex];
                          final newExplanation = explanationController.text.trim();

                          if (newQuestion.isEmpty || newOptions.any((o) => o.isEmpty)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please fill out all options and question.')),
                            );
                            return;
                          }

                          Navigator.pop(ctx);
                          await _aiTaskService.editAndApproveTask(
                            schoolId: task.schoolId,
                            taskId: task.id,
                            teacherId: teacherId,
                            teacherName: teacherName,
                            question: newQuestion,
                            options: newOptions,
                            correctAnswer: newCorrect,
                            explanation: newExplanation,
                          );

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Task updated and approved!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                        child: const Text(
                          'Save & Approve',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
