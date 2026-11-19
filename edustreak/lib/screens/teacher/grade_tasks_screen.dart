import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/user_provider.dart';
import '../../models/task_model.dart';
import '../../services/task_service.dart';
import '../shared/skill_matrix_screen.dart';
import 'package:intl/intl.dart';

class GradeTasksScreen extends StatefulWidget {
  final bool showAppBar;
  const GradeTasksScreen({super.key, this.showAppBar = false});

  @override
  State<GradeTasksScreen> createState() => _GradeTasksScreenState();
}

class _GradeTasksScreenState extends State<GradeTasksScreen> {
  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final teacher = userProvider.currentUser;

    if (teacher == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final content = StreamBuilder<List<TaskModel>>(
      stream: TaskService().getTasksForTeacher(teacher.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Retry by rebuilding
                      setState(() {});
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            if (kDebugMode) {
              print('GradeTasksScreen: No tasks found for teacher ${teacher.id}');
            }
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.assignment, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No tasks assigned yet'),
                  const SizedBox(height: 8),
                  Text(
                    'Assign tasks to students from the "Assign" tab',
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  if (kDebugMode) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Teacher ID: ${teacher.id}',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                  ],
                ],
              ),
            );
          }

          final tasks = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              // Count submissions (both 'submitted' and 'graded' status)
              final submittedCount = task.submissions.values
                  .where((s) => s == 'submitted' || s == 'graded')
                  .length;
              final pendingGradingCount = task.submissions.values
                  .where((s) => s == 'submitted')
                  .length;
              final gradedCount = task.submissions.values
                  .where((s) => s == 'graded')
                  .length;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TaskGradingDetailScreen(taskId: task.id),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                task.title,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                            if (pendingGradingCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '$pendingGradingCount to grade',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: submittedCount > 0 ? Colors.blue[100] : Colors.grey[300],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '$submittedCount / ${task.assignedTo.length}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: submittedCount > 0 ? Colors.blue : Colors.grey[600],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          task.description,
                          style: Theme.of(context).textTheme.bodyMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'Due: ${DateFormat('MMM dd, yyyy').format(task.dueDate)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(width: 16),
                            const Icon(Icons.grade, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'Max: ${task.maxMarks}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: task.assignedTo.isEmpty ? 0 : gradedCount / task.assignedTo.length,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Graded: $gradedCount / ${task.assignedTo.length}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      );

    if (widget.showAppBar) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Grade Assignments'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => setState(() {}),
            ),
          ],
        ),
        body: content,
      );
    }
    return content;
  }
}

class TaskGradingDetailScreen extends StatefulWidget {
  final String taskId; // Changed to taskId for real-time updates

  const TaskGradingDetailScreen({super.key, required this.taskId});

  @override
  State<TaskGradingDetailScreen> createState() => _TaskGradingDetailScreenState();
}

class _TaskGradingDetailScreenState extends State<TaskGradingDetailScreen> {
  final TaskService _taskService = TaskService();
  final Map<String, TextEditingController> _markControllers = {};
  final Map<String, TextEditingController> _feedbackControllers = {};
  final Map<String, String> _selectedGrades = {}; // studentId -> letter grade (A, B, C)
  Map<String, String>? _studentNames; // Cache student names

  @override
  void initState() {
    super.initState();
    // Load student names asynchronously after getting task data
  }

  Future<void> _loadStudentNames(List<String> assignedTo) async {
    try {
      if (assignedTo.isEmpty) {
        setState(() {
          _studentNames = {};
        });
        return;
      }

      // Fetch student names in batches (whereIn has limit of 10)
      final studentNamesMap = <String, String>{};
      for (var i = 0; i < assignedTo.length; i += 10) {
        final batch = assignedTo.skip(i).take(10).toList();
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .where(FieldPath.documentId, whereIn: batch)
            .get();
        
        for (var doc in snapshot.docs) {
          studentNamesMap[doc.id] = doc.data()['name'] ?? 'Unknown';
        }
      }

      if (mounted) {
        setState(() {
          _studentNames = studentNamesMap;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading student names: $e');
      }
      if (mounted) {
        setState(() {
          _studentNames = {};
        });
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _markControllers.values) {
      controller.dispose();
    }
    for (var controller in _feedbackControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('tasks')
              .doc(widget.taskId)
              .snapshots(),
          builder: (context, taskSnapshot) {
            if (taskSnapshot.hasData && taskSnapshot.data!.exists) {
              final taskData = taskSnapshot.data!.data() as Map<String, dynamic>;
              return Text(taskData['title'] ?? 'Task');
            }
            return const Text('Task');
          },
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('tasks')
            .doc(widget.taskId)
            .snapshots(),
        builder: (context, taskSnapshot) {
          if (taskSnapshot.connectionState == ConnectionState.waiting && !taskSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!taskSnapshot.hasData || !taskSnapshot.data!.exists) {
            return const Center(child: Text('Task not found'));
          }

          final taskData = taskSnapshot.data!.data() as Map<String, dynamic>;
          final task = TaskModel.fromMap(taskData..['id'] = taskSnapshot.data!.id);

          // Load student names if not already loaded
          if (_studentNames == null && task.assignedTo.isNotEmpty) {
            _loadStudentNames(task.assignedTo);
          }

          // Initialize controllers if not already done
          for (var studentId in task.assignedTo) {
            if (!_markControllers.containsKey(studentId)) {
              _markControllers[studentId] = TextEditingController(
                text: task.marks[studentId]?.toString() ?? '',
              );
              _feedbackControllers[studentId] = TextEditingController(
                text: task.feedback[studentId] ?? '',
              );
            } else {
              // Update existing controllers if marks changed
              final currentMark = task.marks[studentId]?.toString() ?? '';
              if (_markControllers[studentId]!.text != currentMark) {
                _markControllers[studentId]!.text = currentMark;
              }
              final currentFeedback = task.feedback[studentId] ?? '';
              if (_feedbackControllers[studentId]!.text != currentFeedback) {
                _feedbackControllers[studentId]!.text = currentFeedback;
              }
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Task Info
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(task.description),
                        const SizedBox(height: 8),
                        Text(
                          'Due: ${DateFormat('MMM dd, yyyy').format(task.dueDate)}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          'Max Marks: ${task.maxMarks}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Student Submissions',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                // Student List - Show immediately, names will load in background
                _buildStudentList(task),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStudentList(TaskModel task) {
    final studentIds = task.assignedTo;
    if (studentIds.isEmpty) {
      return const Center(child: Text('No students assigned'));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: studentIds.length,
      itemBuilder: (context, index) {
        final studentId = studentIds[index];
        // Show student name if loaded, otherwise show "Loading..." or student ID
        final studentName = _studentNames?[studentId] ?? 'Loading...';
        final submissionStatus = task.submissions[studentId] ?? 'pending';
        final submissionText = task.submissionTexts[studentId] ?? '';
        final proofUrl = task.proofUrls[studentId]; // For backward compatibility
        final existingMark = task.marks[studentId];
        final pointsAwarded = task.pointsAwarded[studentId];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      if (_studentNames == null || _studentNames![studentId] == null)
                                        const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      else
                                        const SizedBox(width: 16),
                                      Expanded(
                                        child: Text(
                                          studentName,
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(submissionStatus),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _getStatusText(submissionStatus),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            // Show text submission (preferred)
                            if (submissionText.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(
                                'Submission:',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: Text(
                                  submissionText,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            ] else if (proofUrl != null) ...[
                              // Fallback to old proof URL (backward compatibility)
                              const SizedBox(height: 12),
                              Text(
                                'Proof:',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 4),
                              Image.network(
                                proofUrl,
                                height: 150,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Text('Unable to load image');
                                },
                              ),
                            ],
                            if (submissionStatus == 'submitted' || submissionStatus == 'graded') ...[
                              const SizedBox(height: 16),
                              // Grade Selection (Letter Grade)
                              Text(
                                'Grade Selection',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: _selectedGrades[studentId] ?? 
                                    (existingMark != null ? _getLetterGrade(existingMark, task.maxMarks) : null),
                                decoration: const InputDecoration(
                                  labelText: 'Letter Grade',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.grade),
                                ),
                                items: ['A', 'B', 'C', 'D', 'F']
                                    .map((grade) => DropdownMenuItem(
                                          value: grade,
                                          child: Text('Grade $grade'),
                                        ))
                                    .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedGrades[studentId] = value!;
                                    // Auto-fill marks based on grade
                                    final gradeToMarks = {
                                      'A': task.maxMarks * 0.9,
                                      'B': task.maxMarks * 0.8,
                                      'C': task.maxMarks * 0.7,
                                      'D': task.maxMarks * 0.6,
                                      'F': task.maxMarks * 0.5,
                                    };
                                    _markControllers[studentId]?.text = 
                                        gradeToMarks[value]!.toStringAsFixed(0);
                                  });
                                },
                              ),
                              const SizedBox(height: 12),
                              // Numeric Marks (can be edited)
                              TextField(
                                controller: _markControllers[studentId],
                                decoration: InputDecoration(
                                  labelText: 'Marks (Max: ${task.maxMarks})',
                                  border: const OutlineInputBorder(),
                                  prefixIcon: const Icon(Icons.numbers),
                                  helperText: 'You can override the auto-filled marks',
                                ),
                                keyboardType: TextInputType.number,
                              ),
                              const SizedBox(height: 12),
                              // Feedback
                              TextField(
                                controller: _feedbackControllers[studentId],
                                decoration: const InputDecoration(
                                  labelText: 'Feedback',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.feedback),
                                ),
                                maxLines: 3,
                              ),
                              // Show points that will be awarded
                              if (pointsAwarded != null) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.green[50],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.star, color: Colors.green, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Points Awarded: $pointsAwarded',
                                        style: const TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.check),
                                  onPressed: () => _gradeStudent(
                                    context,
                                    task,
                                    studentId,
                                    studentName,
                                  ),
                                  label: Text(existingMark != null ? 'Update Grade' : 'Submit Grade'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.hub_rounded, size: 16),
                                  label: const Text('View Skill Graph & Competencies', style: TextStyle(fontSize: 12)),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => SkillMatrixScreen(
                                          studentId: studentId,
                                          studentName: studentName,
                                          isTeacher: true,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ] else if (submissionStatus == 'pending') ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.orange[50],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.pending, color: Colors.orange),
                                    const SizedBox(width: 8),
                                    Text(
                                      'No submission yet',
                                      style: TextStyle(
                                        color: Colors.orange[900],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                );
  }


  Color _getStatusColor(String status) {
    switch (status) {
      case 'graded':
        return Colors.green;
      case 'submitted':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'graded':
        return 'Graded';
      case 'submitted':
        return 'Submitted';
      default:
        return 'Pending';
    }
  }

  String? _getLetterGrade(double marks, int maxMarks) {
    final percentage = marks / maxMarks;
    if (percentage >= 0.9) return 'A';
    if (percentage >= 0.8) return 'B';
    if (percentage >= 0.7) return 'C';
    if (percentage >= 0.6) return 'D';
    return 'F';
  }

  Future<void> _gradeStudent(
    BuildContext context,
    TaskModel task,
    String studentId,
    String studentName,
  ) async {
    final markText = _markControllers[studentId]?.text ?? '';
    final feedback = _feedbackControllers[studentId]?.text ?? '';
    final letterGrade = _selectedGrades[studentId];

    if (markText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter marks')),
      );
      return;
    }

    final marks = double.tryParse(markText);
    if (marks == null || marks < 0 || marks > task.maxMarks) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Marks must be between 0 and ${task.maxMarks}')),
      );
      return;
    }

    try {
      // Calculate points that will be awarded
      int pointsAwarded = 0;
      if (letterGrade != null) {
        final gradeToPoints = {'A': 10, 'B': 8, 'C': 5, 'D': 3, 'F': 0};
        pointsAwarded = gradeToPoints[letterGrade.toUpperCase()] ?? 0;
      } else {
        final percentage = marks / task.maxMarks;
        if (percentage >= 0.9) {
          pointsAwarded = 10;
        } else if (percentage >= 0.8) {
          pointsAwarded = 8;
        } else if (percentage >= 0.7) {
          pointsAwarded = 5;
        } else if (percentage >= 0.6) {
          pointsAwarded = 3;
        } else {
          pointsAwarded = 0;
        }
      }

      await _taskService.gradeTask(
        taskId: widget.taskId,
        studentId: studentId,
        marks: marks,
        feedback: feedback.isNotEmpty ? feedback : null,
        letterGrade: letterGrade,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Graded $studentName: $marks / ${task.maxMarks}${letterGrade != null ? ' (Grade $letterGrade)' : ''}\n'
              '🎉 Student earned $pointsAwarded points!',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error grading: $e')),
        );
      }
    }
  }
}

