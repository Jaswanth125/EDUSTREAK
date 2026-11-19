import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../../providers/user_provider.dart';
import '../../models/task_model.dart';
import '../../services/task_service.dart';
import '../../utils/edustreak_theme.dart';

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
  String? _attachedFileName;
  PlatformFile? _pickedFile;

  @override
  void initState() {
    super.initState();
    _submissionController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _submissionController.dispose();
    super.dispose();
  }

  Future<void> _pickAttachment() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'docx', 'txt'],
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _pickedFile = result.files.first;
          _attachedFileName = _pickedFile!.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File picker notice: $e'),
            backgroundColor: const Color(0xFF1E1035),
          ),
        );
      }
    }
  }

  Future<void> _submitTask(BuildContext context, TaskModel task) async {
    final text = _submissionController.text.trim();
    if (text.isEmpty && _pickedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your answer or attach a file before submitting'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final currentUser = userProvider.currentUser;
      if (currentUser == null) return;

      String? proofUrl;
      if (_pickedFile != null && _pickedFile!.bytes != null) {
        try {
          proofUrl = await _taskService.uploadProofFileFromBytes(
            widget.taskId,
            currentUser.id,
            _pickedFile!.bytes!,
            _pickedFile!.name,
          );
        } catch (_) {
          // If storage is restricted in test environment, attach filename as proof note
          proofUrl = 'attachment://${_pickedFile!.name}';
        }
      }

      await _taskService.submitTask(
        taskId: widget.taskId,
        studentId: currentUser.id,
        submissionText: text.isNotEmpty ? text : 'Submitted via file attachment: ${_pickedFile?.name}',
        proofFileUrl: proofUrl,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Task submitted successfully! Teacher will review it soon.'),
            backgroundColor: Color(0xFF10B981),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting task: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final currentUser = userProvider.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        backgroundColor: EduStreakTheme.studentDarkBg,
        body: Center(child: CircularProgressIndicator(color: EduStreakTheme.primaryViolet)),
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
            backgroundColor: EduStreakTheme.studentDarkBg,
            body: Center(child: CircularProgressIndicator(color: EduStreakTheme.primaryViolet)),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            backgroundColor: EduStreakTheme.studentDarkBg,
            appBar: AppBar(
              backgroundColor: EduStreakTheme.studentDarkBg,
              foregroundColor: Colors.white,
              title: const Text('Homework Details'),
            ),
            body: const Center(
              child: Text('Task not found', style: TextStyle(color: Colors.white)),
            ),
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
        final proofUrl = task.proofUrls[currentUser.id];

        if (submissionText.isNotEmpty && !_controllerInitialized) {
          _submissionController.text = submissionText;
          _controllerInitialized = true;
        } else if (submissionText.isEmpty && !_controllerInitialized) {
          _controllerInitialized = true;
        }

        return Scaffold(
          backgroundColor: EduStreakTheme.studentDarkBg,
          appBar: AppBar(
            backgroundColor: EduStreakTheme.studentDarkBg,
            elevation: 0,
            foregroundColor: Colors.white,
            title: Text(
              task.title,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Task Info Header Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: EduStreakTheme.studentDarkCard,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: EduStreakTheme.studentDarkBorder, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: EduStreakTheme.primaryViolet.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              task.subject.isNotEmpty ? task.subject : 'General',
                              style: const TextStyle(
                                color: Color(0xFFC4B5FD),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFBBF24).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('⭐ ', style: TextStyle(fontSize: 11)),
                                Text(
                                  '${task.xpReward} XP',
                                  style: const TextStyle(
                                    color: Color(0xFFFBBF24),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        task.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        task.description,
                        style: const TextStyle(
                          color: EduStreakTheme.studentDarkTextMuted,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: EduStreakTheme.studentDarkBorder),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 20,
                        runSpacing: 8,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.person_rounded, size: 16, color: Color(0xFFC4B5FD)),
                              const SizedBox(width: 6),
                              Text(
                                'Teacher: ${task.assignedByName}',
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.calendar_today_rounded, size: 15, color: Color(0xFFFF6B35)),
                              const SizedBox(width: 6),
                              Text(
                                'Due: ${DateFormat('MMM dd, yyyy').format(task.dueDate)}',
                                style: TextStyle(
                                  color: DateTime.now().isAfter(task.dueDate) ? Colors.redAccent : Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.grade_rounded, size: 16, color: Color(0xFF10B981)),
                              const SizedBox(width: 6),
                              Text(
                                'Max Marks: ${task.maxMarks}',
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Questions section (if teacher added specific questions)
                if (task.questions.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: EduStreakTheme.studentDarkCard,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: EduStreakTheme.studentDarkBorder, width: 1.2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.quiz_rounded, color: EduStreakTheme.primaryViolet, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Assignment Questions (${task.questions.length})',
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        ...task.questions.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final q = entry.value;
                          final qText = q['questionText']?.toString() ?? '';
                          final qType = q['questionType']?.toString() ?? 'short';
                          final marks = q['marks'] ?? 10;
                          final options = (q['options'] as List<dynamic>?) ?? [];

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF140F2D),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: EduStreakTheme.studentDarkBorder),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 12,
                                      backgroundColor: EduStreakTheme.primaryViolet.withValues(alpha: 0.3),
                                      child: Text('${idx + 1}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(qText, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.white10,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  qType.toUpperCase(),
                                                  style: const TextStyle(color: EduStreakTheme.neonCyan, fontSize: 10, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text('$marks marks', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                if (qType == 'mcq' && options.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  ...options.asMap().entries.map((optEntry) {
                                    final optIdx = optEntry.key;
                                    final optText = optEntry.value?.toString() ?? '';
                                    final letter = String.fromCharCode(65 + optIdx);
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 20,
                                            height: 20,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(color: Colors.white38),
                                            ),
                                            child: Center(
                                              child: Text(letter, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(child: Text(optText, style: const TextStyle(color: Colors.white70, fontSize: 13))),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],

                // Attachments section (if teacher uploaded reference files)
                if (task.attachmentNames.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: EduStreakTheme.studentDarkCard,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: EduStreakTheme.studentDarkBorder, width: 1.2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.folder_open_rounded, color: EduStreakTheme.neonCyan, size: 20),
                            SizedBox(width: 8),
                            Text('Teacher Attachments & Resources', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          children: task.attachmentNames.map((name) {
                            return Chip(
                              backgroundColor: const Color(0xFF140F2D),
                              side: const BorderSide(color: EduStreakTheme.studentDarkBorder),
                              avatar: const Icon(Icons.file_present, color: EduStreakTheme.neonCyan, size: 16),
                              label: Text(name, style: const TextStyle(color: Colors.white, fontSize: 12)),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // 2. Submission Status Banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: _getStatusBgColor(submissionStatus),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _getStatusBorderColor(submissionStatus)),
                  ),
                  child: Row(
                    children: [
                      Icon(_getStatusIcon(submissionStatus), color: _getStatusTextColor(submissionStatus), size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Status: ${_getStatusText(submissionStatus)}',
                          style: TextStyle(
                            color: _getStatusTextColor(submissionStatus),
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 3. Marks & Feedback Card (if graded)
                if (marks != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: EduStreakTheme.studentDarkCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4), width: 1.2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Evaluated Grade',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              '$marks / ${task.maxMarks}',
                              style: TextStyle(
                                color: _getGradeColor(marks, task.maxMarks),
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            if (pointsAwarded != null && pointsAwarded > 0) ...[
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '+$pointsAwarded XP Awarded',
                                  style: const TextStyle(
                                    color: Color(0xFF10B981),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (feedback != null && feedback.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          const Text(
                            'Teacher Feedback:',
                            style: TextStyle(color: Color(0xFFC4B5FD), fontWeight: FontWeight.w700, fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            feedback,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

                // 4. Submission Workspace (if not graded)
                if (submissionStatus != 'graded' && submissionStatus != 'completed') ...[
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: EduStreakTheme.studentDarkCard,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: EduStreakTheme.studentDarkBorder, width: 1.2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your Submission',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Write your answers or attach documentation below:',
                          style: TextStyle(color: EduStreakTheme.studentDarkTextMuted, fontSize: 12),
                        ),
                        const SizedBox(height: 14),

                        // Text input
                        TextField(
                          controller: _submissionController,
                          maxLines: 8,
                          minLines: 4,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: submissionStatus == 'submitted'
                                ? 'Edit your written answers and resubmit...'
                                : 'Type your answer or solution steps here...',
                            hintStyle: const TextStyle(color: EduStreakTheme.studentDarkTextMuted, fontSize: 13),
                            filled: true,
                            fillColor: const Color(0xFF140F2D),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: EduStreakTheme.studentDarkBorder),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: EduStreakTheme.studentDarkBorder),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: EduStreakTheme.primaryViolet),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Attachment picker strip
                        Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed: _pickAttachment,
                              icon: const Icon(Icons.attach_file_rounded, size: 16, color: Color(0xFFC4B5FD)),
                              label: Text(
                                _attachedFileName != null ? 'Change Attachment' : 'Attach File / PDF',
                                style: const TextStyle(color: Color(0xFFC4B5FD), fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: EduStreakTheme.studentDarkBorder),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                            if (_attachedFileName != null) ...[
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _attachedFileName!,
                                  style: const TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close_rounded, size: 16, color: Colors.white54),
                                onPressed: () => setState(() {
                                  _pickedFile = null;
                                  _attachedFileName = null;
                                }),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : () => _submitTask(context, task),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7950FF),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 4,
                              shadowColor: const Color(0xFF7950FF).withValues(alpha: 0.5),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : Text(
                                    submissionStatus == 'submitted' ? 'Resubmit Homework' : 'Submit Homework (+25 XP)',
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // 5. Existing Submitted Content View
                if (submissionText.isNotEmpty && submissionStatus != 'pending') ...[
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: EduStreakTheme.studentDarkCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: EduStreakTheme.studentDarkBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your Submitted Solution',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          submissionText,
                          style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 13, height: 1.5),
                        ),
                        if (proofUrl != null && proofUrl.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.attachment_rounded, size: 16, color: Color(0xFFC4B5FD)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  proofUrl.replaceFirst('attachment://', ''),
                                  style: const TextStyle(color: Color(0xFFC4B5FD), fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
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

  Color _getStatusBgColor(String status) {
    switch (status) {
      case 'completed':
      case 'graded':
        return const Color(0xFF10B981).withValues(alpha: 0.15);
      case 'submitted':
        return const Color(0xFF00D4FF).withValues(alpha: 0.15);
      default:
        return const Color(0xFFFF6B35).withValues(alpha: 0.15);
    }
  }

  Color _getStatusBorderColor(String status) {
    switch (status) {
      case 'completed':
      case 'graded':
        return const Color(0xFF10B981).withValues(alpha: 0.4);
      case 'submitted':
        return const Color(0xFF00D4FF).withValues(alpha: 0.4);
      default:
        return const Color(0xFFFF6B35).withValues(alpha: 0.4);
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status) {
      case 'completed':
      case 'graded':
        return const Color(0xFF10B981);
      case 'submitted':
        return const Color(0xFF00D4FF);
      default:
        return const Color(0xFFFF6B35);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'completed':
      case 'graded':
        return Icons.check_circle_rounded;
      case 'submitted':
        return Icons.cloud_done_rounded;
      default:
        return Icons.hourglass_top_rounded;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'completed':
        return 'Completed';
      case 'graded':
        return 'Graded by Teacher';
      case 'submitted':
        return 'Submitted • Waiting for grading';
      default:
        return 'Pending Submission';
    }
  }

  Color _getGradeColor(double marks, int maxMarks) {
    final percentage = maxMarks > 0 ? (marks / maxMarks) : 0.0;
    if (percentage >= 0.8) return const Color(0xFF10B981);
    if (percentage >= 0.6) return const Color(0xFF00D4FF);
    if (percentage >= 0.4) return const Color(0xFFFBBF24);
    return Colors.redAccent;
  }
}
