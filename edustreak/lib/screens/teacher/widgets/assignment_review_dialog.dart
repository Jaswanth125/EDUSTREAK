import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../models/task_model.dart';
import '../../../models/user_model.dart';
import '../../../services/task_service.dart';
import '../../../utils/edustreak_theme.dart';
import '../../../utils/class_name_helper.dart';

class AssignmentReviewDialog extends StatefulWidget {
  final String taskId;

  const AssignmentReviewDialog({super.key, required this.taskId});

  static Future<void> show(BuildContext context, String taskId) {
    return showDialog(
      context: context,
      builder: (ctx) => AssignmentReviewDialog(taskId: taskId),
    );
  }

  @override
  State<AssignmentReviewDialog> createState() => _AssignmentReviewDialogState();
}

class _AssignmentReviewDialogState extends State<AssignmentReviewDialog> {
  final TaskService _taskService = TaskService();
  final Map<String, TextEditingController> _markControllers = {};
  final Map<String, TextEditingController> _feedbackControllers = {};
  final Map<String, String> _selectedGrades = {};
  final Map<String, bool> _gradingInProgress = {};

  Map<String, UserModel> _studentProfiles = {};
  bool _isLoadingStudents = false;
  String _filterStatus = 'All'; // 'All', 'Submitted', 'Graded', 'Pending'

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final taskDoc = await FirebaseFirestore.instance.collection('tasks').doc(widget.taskId).get();
      if (!taskDoc.exists) return;

      final task = TaskModel.fromMap(taskDoc.data()!..['id'] = taskDoc.id);
      final assignedStudentIds = task.assignedTo;

      if (assignedStudentIds.isNotEmpty) {
        final Map<String, UserModel> profiles = {};
        for (var i = 0; i < assignedStudentIds.length; i += 10) {
          final chunk = assignedStudentIds.skip(i).take(10).toList();
          final snap = await FirebaseFirestore.instance
              .collection('users')
              .where(FieldPath.documentId, whereIn: chunk)
              .get();

          for (final doc in snap.docs) {
            profiles[doc.id] = UserModel.fromMap(doc.data()..['id'] = doc.id);
          }
        }

        if (mounted) {
          setState(() {
            _studentProfiles = profiles;
            _isLoadingStudents = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingStudents = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingStudents = false);
    }
  }

  @override
  void dispose() {
    for (final c in _markControllers.values) {
      c.dispose();
    }
    for (final c in _feedbackControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submitGrade(TaskModel task, String studentId) async {
    final markStr = _markControllers[studentId]?.text.trim() ?? '';
    final feedbackStr = _feedbackControllers[studentId]?.text.trim() ?? '';
    final letterGrade = _selectedGrades[studentId];

    if (markStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter marks before submitting grade'), backgroundColor: Colors.orange),
      );
      return;
    }

    final marks = double.tryParse(markStr);
    if (marks == null || marks < 0 || marks > task.maxMarks) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Marks must be between 0 and ${task.maxMarks}'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() => _gradingInProgress[studentId] = true);

    try {
      await _taskService.gradeTask(
        taskId: task.id,
        studentId: studentId,
        marks: marks,
        feedback: feedbackStr.isNotEmpty ? feedbackStr : null,
        letterGrade: letterGrade,
      );

      if (mounted) {
        final sName = _studentProfiles[studentId]?.name ?? 'Student';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Successfully graded $sName: $marks/${task.maxMarks}! XP and feedback published.'),
            backgroundColor: EduStreakTheme.emeraldGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving grade: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _gradingInProgress[studentId] = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0C1030),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFF283168)),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 900,
          maxHeight: MediaQuery.of(context).size.height * 0.92,
        ),
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('tasks').doc(widget.taskId).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
              return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()));
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                    const SizedBox(height: 12),
                    const Text('Assignment not found or has been deleted.', style: TextStyle(color: Colors.white)),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
                  ],
                ),
              );
            }

            final data = snapshot.data!.data() as Map<String, dynamic>;
            final task = TaskModel.fromMap(data..['id'] = snapshot.data!.id);

            // Compute statistics
            final totalAssigned = task.assignedTo.length;
            final submittedCount = task.submissions.values.where((s) => s == 'submitted').length;
            final gradedCount = task.submissions.values.where((s) => s == 'graded').length;
            final pendingCount = totalAssigned - (submittedCount + gradedCount);

            // Filter student list
            final filteredStudentIds = task.assignedTo.where((sId) {
              final status = task.submissions[sId] ?? 'pending';
              if (_filterStatus == 'Submitted') return status == 'submitted';
              if (_filterStatus == 'Graded') return status == 'graded';
              if (_filterStatus == 'Pending') return status != 'submitted' && status != 'graded';
              return true;
            }).toList();

            return Column(
              children: [
                // Modal Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  decoration: const BoxDecoration(
                    color: Color(0xFF141A42),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    border: Border(bottom: BorderSide(color: Color(0xFF283168))),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: EduStreakTheme.primaryViolet.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: EduStreakTheme.primaryViolet.withValues(alpha: 0.4)),
                        ),
                        child: const Icon(Icons.rate_review_rounded, color: EduStreakTheme.primaryViolet, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.title,
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${task.subject} • ${ClassNameHelper.formatClassNameSync(task.classId)} • Due: ${DateFormat('MMM dd, yyyy • hh:mm a').format(task.dueDate)}',
                              style: TextStyle(color: EduStreakTheme.darkTextSub, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white70),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                // Live Stats Banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  color: const Color(0xFF0F1535),
                  child: Row(
                    children: [
                      _buildStatPill('Total Enrolled', '$totalAssigned', Colors.white70),
                      const SizedBox(width: 10),
                      _buildStatPill('To Review', '$submittedCount', const Color(0xFFF59E0B)),
                      const SizedBox(width: 10),
                      _buildStatPill('Graded', '$gradedCount', EduStreakTheme.emeraldGreen),
                      const SizedBox(width: 10),
                      _buildStatPill('Pending Submission', '$pendingCount', Colors.white38),
                      const Spacer(),
                      // Filter Dropdown
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141A42),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF283168)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _filterStatus,
                            dropdownColor: const Color(0xFF141A42),
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                            items: const [
                              DropdownMenuItem(value: 'All', child: Text('Show: All Students')),
                              DropdownMenuItem(value: 'Submitted', child: Text('Show: Needs Review')),
                              DropdownMenuItem(value: 'Graded', child: Text('Show: Graded')),
                              DropdownMenuItem(value: 'Pending', child: Text('Show: Pending Work')),
                            ],
                            onChanged: (val) => setState(() => _filterStatus = val ?? 'All'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Content List
                Expanded(
                  child: _isLoadingStudents
                      ? const Center(child: CircularProgressIndicator(color: EduStreakTheme.primaryPurple))
                      : filteredStudentIds.isEmpty
                          ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.inbox_rounded, color: Colors.white24, size: 48),
                              const SizedBox(height: 12),
                              Text(
                                'No students match "$_filterStatus"',
                                style: const TextStyle(color: Colors.white54, fontSize: 14),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(24),
                          itemCount: filteredStudentIds.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 16),
                          itemBuilder: (context, idx) {
                            final sId = filteredStudentIds[idx];
                            final profile = _studentProfiles[sId];
                            final sName = profile?.name ?? 'Student ${sId.substring(0, sId.length > 5 ? 5 : sId.length)}';
                            final rollNo = profile?.rollNumber ?? 'N/A';
                            final status = task.submissions[sId] ?? 'pending';
                            final submissionText = task.submissionTexts[sId] ?? '';
                            final proofUrl = task.proofUrls[sId];
                            final existingMark = task.marks[sId];
                            final existingFeedback = task.feedback[sId];

                            // Initialize controllers
                            _markControllers.putIfAbsent(sId, () => TextEditingController(text: existingMark != null ? existingMark.toStringAsFixed(0) : ''));
                            _feedbackControllers.putIfAbsent(sId, () => TextEditingController(text: existingFeedback ?? ''));

                            final isGrading = _gradingInProgress[sId] == true;

                            return Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: const Color(0xFF141A42),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: status == 'submitted'
                                      ? const Color(0xFFF59E0B).withValues(alpha: 0.5)
                                      : (status == 'graded' ? EduStreakTheme.emeraldGreen.withValues(alpha: 0.4) : const Color(0xFF283168)),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Row 1: Student info & status badge
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 18,
                                        backgroundColor: EduStreakTheme.primaryViolet.withValues(alpha: 0.2),
                                        child: Text(
                                          sName.isNotEmpty ? sName[0].toUpperCase() : 'S',
                                          style: const TextStyle(color: EduStreakTheme.primaryViolet, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              sName,
                                              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                                            ),
                                            Text(
                                              'Roll No: $rollNo',
                                              style: const TextStyle(color: Colors.white54, fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ),
                                      _buildStatusBadge(status),
                                    ],
                                  ),

                                  // Row 2: Submitted Content
                                  if (status == 'submitted' || status == 'graded') ...[
                                    const SizedBox(height: 14),
                                    const Text('Student Submission:', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 6),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0C1030),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: const Color(0xFF283168)),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (submissionText.isNotEmpty)
                                            SelectableText(
                                              submissionText,
                                              style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
                                            )
                                          else
                                            const Text('No written text provided.', style: TextStyle(color: Colors.white38, fontSize: 12)),
                                          if (proofUrl != null && proofUrl.isNotEmpty) ...[
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                const Icon(Icons.attachment, color: EduStreakTheme.neonCyan, size: 16),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    'Attached: $proofUrl',
                                                    style: const TextStyle(color: EduStreakTheme.neonCyan, fontSize: 12),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 14),

                                    // Grading Controls
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Numeric Marks
                                        SizedBox(
                                          width: 140,
                                          child: TextField(
                                            controller: _markControllers[sId],
                                            keyboardType: TextInputType.number,
                                            style: const TextStyle(color: Colors.white, fontSize: 13),
                                            decoration: InputDecoration(
                                              labelText: 'Marks / ${task.maxMarks}',
                                              labelStyle: const TextStyle(color: Colors.white60, fontSize: 11),
                                              prefixIcon: const Icon(Icons.grade_rounded, size: 16, color: EduStreakTheme.neonCyan),
                                              filled: true,
                                              fillColor: const Color(0xFF0C1030),
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                                borderSide: const BorderSide(color: Color(0xFF283168)),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        // Feedback input
                                        Expanded(
                                          child: TextField(
                                            controller: _feedbackControllers[sId],
                                            style: const TextStyle(color: Colors.white, fontSize: 13),
                                            decoration: InputDecoration(
                                              hintText: 'Teacher feedback / guidance (e.g. Excellent work!)...',
                                              hintStyle: const TextStyle(color: Colors.white30, fontSize: 12),
                                              prefixIcon: const Icon(Icons.comment_outlined, size: 16, color: Colors.white38),
                                              filled: true,
                                              fillColor: const Color(0xFF0C1030),
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                                borderSide: const BorderSide(color: Color(0xFF283168)),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        // Submit Grade Button
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: status == 'graded' ? const Color(0xFF1F2964) : EduStreakTheme.emeraldGreen,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                          ),
                                          icon: isGrading
                                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                              : Icon(status == 'graded' ? Icons.update_rounded : Icons.check_circle_rounded, size: 16),
                                          label: Text(
                                            status == 'graded' ? 'Update Grade' : 'Publish Grade',
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                          ),
                                          onPressed: isGrading ? null : () => _submitGrade(task, sId),
                                        ),
                                      ],
                                    ),
                                  ] else ...[
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        const Icon(Icons.schedule_rounded, color: Colors.white38, size: 16),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Pending student submission (Due: ${DateFormat('MMM dd').format(task.dueDate)})',
                                          style: const TextStyle(color: Colors.white38, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                ),

                // Modal Footer
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  decoration: const BoxDecoration(
                    color: Color(0xFF141A42),
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                    border: Border(top: BorderSide(color: Color(0xFF283168))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF222B5C),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatPill(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF141A42),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF283168)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
          const SizedBox(width: 8),
          Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    String label;
    IconData icon;

    switch (status) {
      case 'graded':
        bg = EduStreakTheme.emeraldGreen.withValues(alpha: 0.18);
        fg = EduStreakTheme.emeraldGreen;
        label = 'Graded & Reviewed';
        icon = Icons.verified_rounded;
        break;
      case 'submitted':
        bg = const Color(0xFFF59E0B).withValues(alpha: 0.18);
        fg = const Color(0xFFF59E0B);
        label = 'Needs Review';
        icon = Icons.pending_actions_rounded;
        break;
      default:
        bg = Colors.white10;
        fg = Colors.white54;
        label = 'Pending Submission';
        icon = Icons.hourglass_empty_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
