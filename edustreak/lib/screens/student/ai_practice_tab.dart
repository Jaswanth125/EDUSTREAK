import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../models/ai_task_model.dart';
import '../../services/ai_task_service.dart';
import '../../utils/theme.dart';

class AiPracticeTab extends StatefulWidget {
  final String studentId;
  final String classId;

  const AiPracticeTab({
    super.key,
    required this.studentId,
    required this.classId,
  });

  @override
  State<AiPracticeTab> createState() => _AiPracticeTabState();
}

class _AiPracticeTabState extends State<AiPracticeTab> {
  final AiTaskService _aiTaskService = AiTaskService();
  bool _isGenerating = false;
  String? _focusSubject;
  String? _focusTopic;
  String? _focusReason;

  @override
  void initState() {
    super.initState();
    _loadWeakTopicFocus();
  }

  Future<void> _loadWeakTopicFocus() async {
    try {
      final diagnosis = await _aiTaskService.detectWeakTopic(widget.studentId);
      if (mounted) {
        setState(() {
          _focusSubject = diagnosis['subject'];
          _focusTopic = diagnosis['topic'];
          _focusReason = diagnosis['reason'];
        });
      }
    } catch (_) {
      // Non-blocking
    }
  }

  Future<void> _requestNewAiTask(String studentName) async {
    if (_isGenerating) return;

    setState(() => _isGenerating = true);

    try {
      final result = await _aiTaskService.generatePersonalizedTaskForStudent(
        studentId: widget.studentId,
        studentName: studentName,
        classId: widget.classId,
        schoolId: 'default_school',
        preferredSubject: _focusSubject,
        preferredTopic: _focusTopic,
      );

      if (!mounted) return;

      if (result.success) {
        if (result.isCached) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✨ ${result.message}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎯 New question generated! Sent to your teacher for review.'),
              backgroundColor: AppTheme.primaryColor,
              duration: Duration(seconds: 4),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: Colors.orange.shade800,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Couldn't generate right now, try later."),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final studentName = userProvider.currentUser?.name ?? 'Student';

    return RefreshIndicator(
      onRefresh: () async {
        await _loadWeakTopicFocus();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Adaptive Learning Focus Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withOpacity(0.85),
                  AppTheme.secondaryColor.withOpacity(0.85),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.auto_awesome, color: Colors.amber, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Adaptive AI Practice',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _focusTopic != null
                      ? 'Identified Weak Area: $_focusSubject — $_focusTopic'
                      : 'Analyzing your recent performance to tailor practice...',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_focusReason != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Basis: $_focusReason',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isGenerating ? null : () => _requestNewAiTask(studentName),
                    icon: _isGenerating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.bolt, color: Colors.amber),
                    label: Text(
                      _isGenerating ? 'Analyzing & Generating...' : 'Generate New Practice Question',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Approved Practice Tasks',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '+15 XP each',
                style: TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Approved tasks stream
          StreamBuilder<List<AiTaskModel>>(
            stream: _aiTaskService.getApprovedPracticeTasks(
              schoolId: 'default_school',
              studentId: widget.studentId,
              classId: widget.classId,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final tasks = snapshot.data ?? [];
              if (tasks.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                    child: Column(
                      children: [
                        Icon(Icons.quiz_outlined, size: 54, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text(
                          'No practice questions ready yet',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tap "Generate New Practice Question" above. Once your teacher approves it, it will appear here for practice and XP!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  final isCompleted = task.completedBy.contains(widget.studentId);
                  return _buildPracticeCard(task, isCompleted);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPracticeCard(AiTaskModel task, bool isCompleted) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Subject tag & status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${task.subject} • ${task.topic}',
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.check_circle, size: 12, color: Colors.green),
                        SizedBox(width: 4),
                        Text(
                          'Completed (+15 XP)',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Question
            Text(
              task.question,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            // Solve / Review button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openQuizDialog(task, isCompleted),
                icon: Icon(
                  isCompleted ? Icons.visibility : Icons.play_arrow,
                  size: 16,
                ),
                label: Text(isCompleted ? 'Review Solution' : 'Start Practice Quiz'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCompleted ? Colors.grey.shade100 : AppTheme.primaryColor,
                  foregroundColor: isCompleted ? Colors.black87 : Colors.white,
                  elevation: isCompleted ? 0 : 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openQuizDialog(AiTaskModel task, bool isAlreadyCompleted) {
    String? selectedOption;
    bool submitted = isAlreadyCompleted;
    bool? isCorrect;
    String explanation = task.explanation;
    int xpEarned = 0;

    // Check if previous answer exists
    final previousSubmission = task.studentAnswers[widget.studentId] as Map<String, dynamic>?;
    if (previousSubmission != null) {
      selectedOption = previousSubmission['selectedOption']?.toString();
      isCorrect = previousSubmission['isCorrect'] == true;
    }

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              title: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: AppTheme.primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${task.subject}: ${task.topic}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.question,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 14),

                    // Options
                    ...task.options.map((opt) {
                      final isSelected = selectedOption == opt;
                      Color? tileColor;
                      Color borderColor = Colors.grey.shade300;

                      if (submitted) {
                        final isThisCorrect = opt.trim() == task.correctAnswer.trim();
                        if (isThisCorrect) {
                          tileColor = Colors.green.shade50;
                          borderColor = Colors.green.shade400;
                        } else if (isSelected && !isThisCorrect) {
                          tileColor = Colors.red.shade50;
                          borderColor = Colors.red.shade400;
                        }
                      } else if (isSelected) {
                        tileColor = AppTheme.primaryColor.withOpacity(0.1);
                        borderColor = AppTheme.primaryColor;
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: tileColor ?? Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: borderColor, width: isSelected ? 1.5 : 1.0),
                        ),
                        child: RadioListTile<String>(
                          value: opt,
                          groupValue: selectedOption,
                          activeColor: AppTheme.primaryColor,
                          dense: true,
                          title: Text(
                            opt,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          onChanged: submitted
                              ? null
                              : (val) {
                                  setDialogState(() => selectedOption = val);
                                },
                        ),
                      );
                    }),

                    // Result & Explanation
                    if (submitted) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (isCorrect == true) ? Colors.green.shade50 : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: (isCorrect == true) ? Colors.green.shade200 : Colors.orange.shade200,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  (isCorrect == true) ? Icons.check_circle : Icons.info,
                                  color: (isCorrect == true) ? Colors.green : Colors.orange.shade800,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  (isCorrect == true) ? 'Great Job! Correct Answer' : 'Keep Trying!',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: (isCorrect == true) ? Colors.green.shade900 : Colors.orange.shade900,
                                  ),
                                ),
                                if (xpEarned > 0) ...[
                                  const Spacer(),
                                  Text(
                                    '+$xpEarned XP',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber),
                                  ),
                                ],
                              ],
                            ),
                            if (explanation.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                explanation,
                                style: const TextStyle(fontSize: 12, color: Colors.black87),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: Text(submitted ? 'Close' : 'Cancel'),
                ),
                if (!submitted)
                  ElevatedButton(
                    onPressed: selectedOption == null
                        ? null
                        : () async {
                            final result = await _aiTaskService.submitStudentAnswer(
                              schoolId: task.schoolId,
                              taskId: task.id,
                              studentId: widget.studentId,
                              selectedOption: selectedOption!,
                            );

                            setDialogState(() {
                              submitted = true;
                              isCorrect = result['isCorrect'] == true;
                              explanation = result['explanation']?.toString() ?? task.explanation;
                              xpEarned = (result['xpEarned'] as num?)?.toInt() ?? 0;
                            });

                            if (mounted && (result['xpEarned'] as int? ?? 0) > 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('🎉 Correct! Earned +${result['xpEarned']} XP!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Submit Answer'),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
