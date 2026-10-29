import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../models/task_model.dart';
import '../../services/task_service.dart';
import 'package:intl/intl.dart';

class TaskDetailScreen extends StatefulWidget {
  final String taskId;

  const TaskDetailScreen({super.key, required this.taskId});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final TaskService _taskService = TaskService();
  final TextEditingController _submissionController = TextEditingController();
  bool _isSubmitting = false;
  bool _controllerInitialized = false;

  @override
  void initState() {
    super.initState();
    // Listen to text changes to update button state
    _submissionController.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final currentUser = userProvider.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tasks')
          .doc(widget.taskId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(
            body: Center(child: Text('Task not found')),
          );
        }

        final task = TaskModel.fromMap(
          snapshot.data!.data() as Map<String, dynamic>
            ..['id'] = snapshot.data!.id,
        );

        final submissionStatus = task.submissions[currentUser.id] ?? 'pending';
        final marks = task.marks[currentUser.id];
        final feedback = task.feedback[currentUser.id];
        final submissionText = task.submissionTexts[currentUser.id] ?? '';
        final pointsAwarded = task.pointsAwarded[currentUser.id];

        // Initialize controller with existing submission text if available
        if (submissionText.isNotEmpty && !_controllerInitialized) {
          _submissionController.text = submissionText;
          _controllerInitialized = true;
        } else if (submissionText.isEmpty && !_controllerInitialized) {
          _controllerInitialized = true;
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(task.title),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Task Info Card
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
                        Text(
                          task.description,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Icon(Icons.person, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'Assigned by: ${task.assignedByName}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'Due: ${DateFormat('MMM dd, yyyy').format(task.dueDate)}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: DateTime.now().isAfter(task.dueDate)
                                        ? Colors.red
                                        : null,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.star, size: 16, color: Colors.orange),
                            const SizedBox(width: 4),
                            Text(
                              'Reward: ${task.xpReward} XP',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.grade, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'Max Marks: ${task.maxMarks}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Submission Status
                Card(
                  color: _getStatusColor(submissionStatus),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          _getStatusIcon(submissionStatus),
                          color: Colors.white,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Status: ${_getStatusText(submissionStatus)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Marks and Feedback
                if (marks != null) ...[
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Grade',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$marks / ${task.maxMarks}',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: _getGradeColor(marks, task.maxMarks),
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          if (pointsAwarded != null && pointsAwarded > 0) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.green[100],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star, color: Colors.green, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    '+$pointsAwarded Points Awarded',
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (feedback != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              'Feedback:',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(feedback),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],

                // Text Submission Section
                if (submissionStatus != 'graded' && submissionStatus != 'completed') ...[
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Submit Your Answer',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Enter your answer or proof of completion in the text box below',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _submissionController,
                            enabled: submissionStatus != 'graded' && submissionStatus != 'completed',
                            decoration: InputDecoration(
                              hintText: submissionStatus == 'submitted'
                                  ? 'Edit your answer and resubmit...'
                                  : 'Type your answer here...',
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.all(16),
                            ),
                            maxLines: 10,
                            minLines: 5,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // View Submitted Text
                if (submissionText.isNotEmpty && submissionStatus != 'pending') ...[
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Submission',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              submissionText,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // Submit Button - Show when task is not graded/completed
                if (submissionStatus != 'graded' && submissionStatus != 'completed') ...[
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (_isSubmitting || _submissionController.text.trim().isEmpty) 
                          ? null 
                          : () => _submitTask(context),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: (_isSubmitting || _submissionController.text.trim().isEmpty)
                            ? Colors.grey
                            : Theme.of(context).colorScheme.primary,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              submissionStatus == 'submitted' ? 'Resubmit Task' : 'Submit Task',
                              style: const TextStyle(fontSize: 16, color: Colors.white),
                            ),
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
      case 'completed':
      case 'graded':
        return Colors.green;
      case 'submitted':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'completed':
      case 'graded':
        return Icons.check_circle;
      case 'submitted':
        return Icons.upload;
      default:
        return Icons.pending;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'completed':
        return 'Completed';
      case 'graded':
        return 'Graded';
      case 'submitted':
        return 'Submitted (Waiting for grading)';
      default:
        return 'Pending';
    }
  }

  Color _getGradeColor(double marks, int maxMarks) {
    final percentage = marks / maxMarks;
    if (percentage >= 0.9) return Colors.green;
    if (percentage >= 0.7) return Colors.blue;
    if (percentage >= 0.5) return Colors.orange;
    return Colors.red;
  }

  @override
  void dispose() {
    _submissionController.dispose();
    super.dispose();
  }

  Future<void> _submitTask(BuildContext context) async {
    if (_submissionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your answer before submitting'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final currentUser = userProvider.currentUser;

      if (currentUser == null) return;

      await _taskService.submitTask(
        taskId: widget.taskId,
        studentId: currentUser.id,
        submissionText: _submissionController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Task submitted successfully! Teacher will review it soon.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        // Don't pop - let user see the updated status
        // Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting task: $e')),
        );
      }
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }
}

