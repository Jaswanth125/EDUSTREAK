import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../../../models/task_model.dart';
import '../../../models/user_model.dart';
import '../../../services/task_service.dart';
import '../../../services/curriculum_service.dart';
import '../../../utils/edustreak_theme.dart';
import '../../../utils/class_name_helper.dart';

class CreateAssignmentDialog extends StatefulWidget {
  final UserModel teacher;
  final TaskModel? existingTask; // If editing an existing task

  const CreateAssignmentDialog({
    super.key,
    required this.teacher,
    this.existingTask,
  });

  static Future<bool?> show(BuildContext context, UserModel teacher, {TaskModel? existingTask}) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => CreateAssignmentDialog(teacher: teacher, existingTask: existingTask),
    );
  }

  @override
  State<CreateAssignmentDialog> createState() => _CreateAssignmentDialogState();
}

class _CreateAssignmentDialogState extends State<CreateAssignmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _topicController = TextEditingController();
  final _maxMarksController = TextEditingController(text: '100');
  final _xpRewardController = TextEditingController(text: '50');

  String? _selectedClassId;
  String? _selectedSubject;
  String _selectedType = 'Homework';
  DateTime _dueDate = DateTime.now().add(const Duration(days: 3, hours: 4));
  TimeOfDay _dueTime = const TimeOfDay(hour: 23, minute: 59);

  bool _assignToAll = true;
  final List<String> _selectedStudentIds = [];
  List<UserModel> _classStudents = [];
  bool _isLoadingStudents = false;

  final List<Map<String, dynamic>> _questions = [];
  final List<PlatformFile> _pickedFiles = [];
  final List<String> _existingAttachmentUrls = [];
  final List<String> _existingAttachmentNames = [];

  final Map<String, String> _classDisplayNames = {};
  List<String> _availableTopics = [];
  bool _isLoadingTopics = false;
  bool _isSaving = false;

  static const List<String> _assignmentTypes = [
    'Homework',
    'Worksheet',
    'Reading Task',
    'Practice Assignment',
    'Project',
    'Quiz',
  ];

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    final t = widget.teacher;
    final List<String> teacherClasses = (t.classIds != null && t.classIds!.isNotEmpty)
        ? t.classIds!
        : (t.classId != null && t.classId!.isNotEmpty ? [t.classId!] : <String>[]);

    if (widget.existingTask != null) {
      final task = widget.existingTask!;
      _titleController.text = task.title;
      _descriptionController.text = task.description;
      _topicController.text = task.chapterOrTopic;
      _maxMarksController.text = task.maxMarks.toString();
      _xpRewardController.text = task.xpReward.toString();
      _selectedClassId = task.classId;
      _selectedSubject = task.subject;
      _selectedType = task.type.isNotEmpty ? task.type : 'Homework';
      _dueDate = task.dueDate;
      _dueTime = TimeOfDay(hour: task.dueDate.hour, minute: task.dueDate.minute);
      _questions.addAll(task.questions);
      _existingAttachmentUrls.addAll(task.attachmentUrls);
      _existingAttachmentNames.addAll(task.attachmentNames);
      _selectedStudentIds.addAll(task.assignedTo);
      _assignToAll = false;
    } else {
      if (teacherClasses.isNotEmpty) {
        _selectedClassId = teacherClasses.first;
      }
      if (t.assignedSubjects.isNotEmpty) {
        _selectedSubject = t.assignedSubjects.first;
      } else {
        _selectedSubject = 'Mathematics';
      }
    }

    _loadClassNames(teacherClasses);
    if (_selectedClassId != null) {
      _loadClassStudents(_selectedClassId!);
      _loadCurriculumTopics();
    }
  }

  Future<void> _loadClassNames(List<String> classIds) async {
    for (final id in classIds) {
      final name = await ClassNameHelper.getClassName(id, schoolId: widget.teacher.schoolId);
      if (mounted) {
        setState(() {
          _classDisplayNames[id] = name;
        });
      }
    }
  }

  Future<void> _loadClassStudents(String classId) async {
    setState(() => _isLoadingStudents = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'student')
          .where('classId', isEqualTo: classId)
          .get();

      final students = snap.docs.map((doc) => UserModel.fromMap(doc.data()..['id'] = doc.id)).toList();
      students.sort((a, b) => a.name.compareTo(b.name));

      if (mounted) {
        setState(() {
          _classStudents = students;
          _isLoadingStudents = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingStudents = false);
    }
  }

  Future<void> _loadCurriculumTopics() async {
    setState(() => _isLoadingTopics = true);
    try {
      final curriculumService = CurriculumService();
      final templates = await curriculumService.getTemplatesStream().first;
      final topics = <String>{};

      for (final tmpl in templates) {
        for (final subj in tmpl.standardSubjects) {
          if (_selectedSubject != null &&
              subj.name.toLowerCase().contains(_selectedSubject!.toLowerCase())) {
            for (final ch in subj.chapters) {
              topics.add(ch.title);
              for (final top in ch.topics) {
                topics.add('${ch.title} - ${top.title}');
              }
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _availableTopics = topics.take(15).toList();
          _isLoadingTopics = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingTopics = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _topicController.dispose();
    _maxMarksController.dispose();
    _xpRewardController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'docx', 'txt'],
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _pickedFiles.addAll(result.files);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File picker notice: $e'), backgroundColor: const Color(0xFF1E1035)),
        );
      }
    }
  }

  void _addQuestionDialog({Map<String, dynamic>? editQuestion, int? editIndex}) {
    final qTextCtrl = TextEditingController(text: editQuestion?['questionText'] ?? '');
    String qType = editQuestion?['questionType'] ?? 'short';
    final marksCtrl = TextEditingController(text: (editQuestion?['marks'] ?? 10).toString());

    final optACtrl = TextEditingController(text: (editQuestion?['options'] as List?)?.elementAtOrNull(0) ?? '');
    final optBCtrl = TextEditingController(text: (editQuestion?['options'] as List?)?.elementAtOrNull(1) ?? '');
    final optCCtrl = TextEditingController(text: (editQuestion?['options'] as List?)?.elementAtOrNull(2) ?? '');
    final optDCtrl = TextEditingController(text: (editQuestion?['options'] as List?)?.elementAtOrNull(3) ?? '');
    int correctOpt = editQuestion?['correctOptionIndex'] ?? 0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          backgroundColor: const Color(0xFF141A42),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF283168)),
          ),
          title: Text(
            editIndex != null ? 'Edit Question' : 'Add Question',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Question Type', style: TextStyle(color: EduStreakTheme.darkTextSub, fontSize: 12)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0C1030),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF283168)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: qType,
                        dropdownColor: const Color(0xFF141A42),
                        isExpanded: true,
                        style: const TextStyle(color: Colors.white),
                        items: const [
                          DropdownMenuItem(value: 'short', child: Text('Short Answer')),
                          DropdownMenuItem(value: 'descriptive', child: Text('Descriptive / Long Answer')),
                          DropdownMenuItem(value: 'mcq', child: Text('Multiple Choice (MCQ)')),
                        ],
                        onChanged: (val) => setDlgState(() => qType = val ?? 'short'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: qTextCtrl,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Question Statement *',
                      labelStyle: const TextStyle(color: EduStreakTheme.darkTextSub),
                      filled: true,
                      fillColor: const Color(0xFF0C1030),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF283168)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (qType == 'mcq') ...[
                    const Text('MCQ Options & Correct Answer', style: TextStyle(color: EduStreakTheme.darkTextSub, fontSize: 12)),
                    const SizedBox(height: 8),
                    _buildMcqOptionInput('A', optACtrl, 0, correctOpt, (idx) => setDlgState(() => correctOpt = idx)),
                    const SizedBox(height: 6),
                    _buildMcqOptionInput('B', optBCtrl, 1, correctOpt, (idx) => setDlgState(() => correctOpt = idx)),
                    const SizedBox(height: 6),
                    _buildMcqOptionInput('C', optCCtrl, 2, correctOpt, (idx) => setDlgState(() => correctOpt = idx)),
                    const SizedBox(height: 6),
                    _buildMcqOptionInput('D', optDCtrl, 3, correctOpt, (idx) => setDlgState(() => correctOpt = idx)),
                    const SizedBox(height: 14),
                  ],
                  TextField(
                    controller: marksCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Marks for this Question',
                      labelStyle: const TextStyle(color: EduStreakTheme.darkTextSub),
                      filled: true,
                      fillColor: const Color(0xFF0C1030),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF283168)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: EduStreakTheme.primaryViolet,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                final text = qTextCtrl.text.trim();
                if (text.isEmpty) return;
                final marks = int.tryParse(marksCtrl.text.trim()) ?? 10;
                final qData = <String, dynamic>{
                  'questionText': text,
                  'questionType': qType,
                  'marks': marks,
                };
                if (qType == 'mcq') {
                  qData['options'] = [
                    optACtrl.text.trim(),
                    optBCtrl.text.trim(),
                    optCCtrl.text.trim(),
                    optDCtrl.text.trim(),
                  ];
                  qData['correctOptionIndex'] = correctOpt;
                }

                setState(() {
                  if (editIndex != null) {
                    _questions[editIndex] = qData;
                  } else {
                    _questions.add(qData);
                  }
                  // Auto-recalculate max marks
                  final sumMarks = _questions.fold<int>(0, (acc, q) => acc + (q['marks'] as int? ?? 10));
                  if (sumMarks > 0) {
                    _maxMarksController.text = sumMarks.toString();
                  }
                });
                Navigator.pop(ctx);
              },
              child: Text(editIndex != null ? 'Update' : 'Add Question', style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMcqOptionInput(
    String letter,
    TextEditingController controller,
    int index,
    int currentCorrect,
    ValueChanged<int> onSelectCorrect,
  ) {
    final isCorrect = currentCorrect == index;
    return Row(
      children: [
        IconButton(
          tooltip: isCorrect ? 'Correct Answer' : 'Mark as Correct Answer',
          icon: Icon(
            isCorrect ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            color: isCorrect ? EduStreakTheme.emeraldGreen : Colors.white38,
            size: 20,
          ),
          onPressed: () => onSelectCorrect(index),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Option $letter',
              hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              filled: true,
              fillColor: const Color(0xFF0C1030),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: isCorrect ? EduStreakTheme.emeraldGreen : const Color(0xFF283168)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _submitAssignment({required bool isDraft}) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClassId == null || _selectedClassId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an authorized class'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final combinedDueDateTime = DateTime(
        _dueDate.year,
        _dueDate.month,
        _dueDate.day,
        _dueTime.hour,
        _dueTime.minute,
      );

      final maxMarks = int.tryParse(_maxMarksController.text.trim()) ?? 100;
      final xpReward = int.tryParse(_xpRewardController.text.trim()) ?? 50;

      // Determine recipients
      List<String> assignedStudentIds = [];
      if (_assignToAll) {
        if (_classStudents.isEmpty) {
          await _loadClassStudents(_selectedClassId!);
        }
        assignedStudentIds = _classStudents.map((s) => s.id).toList();
      } else {
        assignedStudentIds = _selectedStudentIds;
      }

      if (assignedStudentIds.isEmpty && !isDraft) {
        // Fallback: fetch student IDs directly
        final studentsSnap = await FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'student')
            .where('classId', isEqualTo: _selectedClassId)
            .get();
        assignedStudentIds = studentsSnap.docs.map((d) => d.id).toList();
      }

      // Handle attachments
      final taskService = TaskService();
      final attachmentUrls = List<String>.from(_existingAttachmentUrls);
      final attachmentNames = List<String>.from(_existingAttachmentNames);

      for (final pf in _pickedFiles) {
        if (pf.bytes != null) {
          try {
            final url = await taskService.uploadProofFileFromBytes(
              'assignment_${DateTime.now().millisecondsSinceEpoch}',
              widget.teacher.id,
              pf.bytes!,
              pf.name,
            );
            attachmentUrls.add(url);
            attachmentNames.add(pf.name);
          } catch (_) {
            attachmentUrls.add('attachment://${pf.name}');
            attachmentNames.add(pf.name);
          }
        }
      }

      if (widget.existingTask != null) {
        // Update existing task
        await taskService.updateTask(
          taskId: widget.existingTask!.id,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          subject: _selectedSubject ?? 'Mathematics',
          classId: _selectedClassId!,
          dueDate: combinedDueDateTime,
          maxMarks: maxMarks,
          xpReward: xpReward,
          type: _selectedType,
          chapterOrTopic: _topicController.text.trim(),
          status: isDraft ? 'draft' : 'published',
          questions: _questions,
          attachmentUrls: attachmentUrls,
          attachmentNames: attachmentNames,
          assignedTo: assignedStudentIds,
        );
      } else {
        // Create new task
        await taskService.createTask(
          classId: _selectedClassId!,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          assignedBy: widget.teacher.id,
          assignedByName: widget.teacher.name.isNotEmpty ? widget.teacher.name : 'Teacher',
          dueDate: combinedDueDateTime,
          assignedTo: assignedStudentIds,
          subject: _selectedSubject ?? 'Mathematics',
          schoolId: widget.teacher.schoolId ?? '',
          type: _selectedType,
          chapterOrTopic: _topicController.text.trim(),
          status: isDraft ? 'draft' : 'published',
          questions: _questions,
          attachmentUrls: attachmentUrls,
          attachmentNames: attachmentNames,
          maxMarks: maxMarks,
          xpReward: xpReward,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isDraft
                  ? '💾 Assignment saved as draft!'
                  : '🚀 Assignment published! ${assignedStudentIds.length} students notified.',
            ),
            backgroundColor: isDraft ? const Color(0xFF3B82F6) : EduStreakTheme.emeraldGreen,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving assignment: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.teacher;
    final List<String> authorizedClasses = (t.classIds != null && t.classIds!.isNotEmpty)
        ? t.classIds!
        : (t.classId != null && t.classId!.isNotEmpty ? [t.classId!] : <String>[]);

    final authorizedSubjects = t.assignedSubjects.isNotEmpty ? t.assignedSubjects : ['Mathematics', 'Science'];

    final screenWidth = MediaQuery.of(context).size.width;
    final isDialog = screenWidth > 700;

    return Dialog(
      backgroundColor: const Color(0xFF0C1030),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFF283168)),
      ),
      insetPadding: isDialog ? const EdgeInsets.symmetric(horizontal: 40, vertical: 30) : EdgeInsets.zero,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 780,
          maxHeight: MediaQuery.of(context).size.height * 0.92,
        ),
        child: Column(
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
                    child: const Icon(Icons.assignment_add, color: EduStreakTheme.primaryViolet, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.existingTask != null ? 'Edit Assignment' : 'Assign New Task',
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Configure learning tasks, questions, and due dates for your students.',
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

            // Form Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section 1: Class and Subject
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Select Class *', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF141A42),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFF283168)),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: authorizedClasses.contains(_selectedClassId) ? _selectedClassId : (authorizedClasses.isNotEmpty ? authorizedClasses.first : null),
                                      dropdownColor: const Color(0xFF141A42),
                                      isExpanded: true,
                                      style: const TextStyle(color: Colors.white, fontSize: 14),
                                      items: authorizedClasses.map((id) {
                                        final label = _classDisplayNames[id] ?? ClassNameHelper.formatClassNameSync(id);
                                        return DropdownMenuItem(value: id, child: Text(label));
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(() => _selectedClassId = val);
                                          _loadClassStudents(val);
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Select Subject *', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF141A42),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFF283168)),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: authorizedSubjects.contains(_selectedSubject) ? _selectedSubject : authorizedSubjects.first,
                                      dropdownColor: const Color(0xFF141A42),
                                      isExpanded: true,
                                      style: const TextStyle(color: Colors.white, fontSize: 14),
                                      items: authorizedSubjects.map((s) {
                                        return DropdownMenuItem(value: s, child: Text(s));
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(() => _selectedSubject = val);
                                          _loadCurriculumTopics();
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // Section 2: Assignment Title
                      const Text('Assignment Title *', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _titleController,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'e.g. Chapter 3: Linear Equations Practice Set',
                          hintStyle: const TextStyle(color: Colors.white30),
                          filled: true,
                          fillColor: const Color(0xFF141A42),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFF283168)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFF283168)),
                          ),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Please enter assignment title' : null,
                      ),

                      const SizedBox(height: 18),

                      // Section 3: Type & Topic Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Assignment Type', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF141A42),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFF283168)),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedType,
                                      dropdownColor: const Color(0xFF141A42),
                                      isExpanded: true,
                                      style: const TextStyle(color: Colors.white, fontSize: 14),
                                      items: _assignmentTypes.map((t) {
                                        return DropdownMenuItem(value: t, child: Text(t));
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null) setState(() => _selectedType = val);
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Curriculum Chapter / Topic', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 6),
                                Autocomplete<String>(
                                  initialValue: TextEditingValue(text: _topicController.text),
                                  optionsBuilder: (textEditingValue) {
                                    if (textEditingValue.text.isEmpty) {
                                      return _availableTopics;
                                    }
                                    return _availableTopics.where((t) =>
                                        t.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                                  },
                                  onSelected: (selection) => _topicController.text = selection,
                                  fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                                    controller.addListener(() {
                                      _topicController.text = controller.text;
                                    });
                                    return TextField(
                                      controller: controller,
                                      focusNode: focusNode,
                                      style: const TextStyle(color: Colors.white, fontSize: 14),
                                      decoration: InputDecoration(
                                        hintText: 'e.g. Rational Numbers',
                                        hintStyle: const TextStyle(color: Colors.white30),
                                        suffixIcon: _isLoadingTopics
                                            ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child: Padding(
                                                  padding: EdgeInsets.all(12),
                                                  child: CircularProgressIndicator(strokeWidth: 2, color: EduStreakTheme.primaryPurple),
                                                ),
                                              )
                                            : null,
                                        filled: true,
                                        fillColor: const Color(0xFF141A42),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: const BorderSide(color: Color(0xFF283168)),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: const BorderSide(color: Color(0xFF283168)),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // Section 4: Instructions / Description
                      const Text('Task Instructions & Guidelines *', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 4,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Enter clear instructions for students, required steps, formulas, or formatting rules...',
                          hintStyle: const TextStyle(color: Colors.white30),
                          filled: true,
                          fillColor: const Color(0xFF141A42),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFF283168)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFF283168)),
                          ),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Please enter task instructions' : null,
                      ),

                      const SizedBox(height: 18),

                      // Section 5: Due Date, Time, Max Marks, XP
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Due Date & Time *', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 6),
                                InkWell(
                                  borderRadius: BorderRadius.circular(10),
                                  onTap: () async {
                                    final pickedDate = await showDatePicker(
                                      context: context,
                                      initialDate: _dueDate,
                                      firstDate: DateTime.now(),
                                      lastDate: DateTime.now().add(const Duration(days: 365)),
                                      builder: (ctx, child) => Theme(
                                        data: Theme.of(ctx).copyWith(
                                          colorScheme: const ColorScheme.dark(
                                            primary: EduStreakTheme.primaryViolet,
                                            surface: Color(0xFF141A42),
                                          ),
                                        ),
                                        child: child!,
                                      ),
                                    );
                                    if (pickedDate != null) {
                                      final pickedTime = await showTimePicker(
                                        context: context,
                                        initialTime: _dueTime,
                                        builder: (ctx, child) => Theme(
                                          data: Theme.of(ctx).copyWith(
                                            colorScheme: const ColorScheme.dark(
                                              primary: EduStreakTheme.primaryViolet,
                                              surface: Color(0xFF141A42),
                                            ),
                                          ),
                                          child: child!,
                                        ),
                                      );
                                      setState(() {
                                        _dueDate = pickedDate;
                                        if (pickedTime != null) _dueTime = pickedTime;
                                      });
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF141A42),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: const Color(0xFF283168)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.event_rounded, color: EduStreakTheme.primaryViolet, size: 18),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            '${DateFormat('MMM dd, yyyy').format(_dueDate)} • ${_dueTime.format(context)}',
                                            style: const TextStyle(color: Colors.white, fontSize: 13),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Max Marks', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _maxMarksController,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(color: Colors.white, fontSize: 14),
                                  decoration: InputDecoration(
                                    prefixIcon: const Icon(Icons.grade_rounded, color: EduStreakTheme.neonCyan, size: 18),
                                    filled: true,
                                    fillColor: const Color(0xFF141A42),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(color: Color(0xFF283168)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(color: Color(0xFF283168)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('XP Reward', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _xpRewardController,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(color: Colors.white, fontSize: 14),
                                  decoration: InputDecoration(
                                    prefixIcon: const Icon(Icons.bolt_rounded, color: Color(0xFFF59E0B), size: 18),
                                    filled: true,
                                    fillColor: const Color(0xFF141A42),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(color: Color(0xFF283168)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(color: Color(0xFF283168)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 22),

                      // Section 6: Questions Builder
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.quiz_rounded, color: EduStreakTheme.primaryViolet, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Assignment Questions (${_questions.length})',
                                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1F2964),
                              foregroundColor: EduStreakTheme.neonCyan,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add Question', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            onPressed: () => _addQuestionDialog(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      if (_questions.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF141A42).withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF283168), style: BorderStyle.solid),
                          ),
                          child: const Center(
                            child: Text(
                              'Optional: Add specific questions (MCQs, short answer, descriptive) or leave empty if using overall instructions.',
                              style: TextStyle(color: Colors.white54, fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _questions.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, idx) {
                            final q = _questions[idx];
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF141A42),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFF283168)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: EduStreakTheme.primaryViolet.withValues(alpha: 0.3),
                                    child: Text('${idx + 1}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(q['questionText'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
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
                                                (q['questionType'] as String? ?? 'short').toUpperCase(),
                                                style: const TextStyle(color: EduStreakTheme.neonCyan, fontSize: 10, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text('${q['marks'] ?? 10} marks', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 16, color: Colors.white60),
                                    onPressed: () => _addQuestionDialog(editQuestion: q, editIndex: idx),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                                    onPressed: () {
                                      setState(() {
                                        _questions.removeAt(idx);
                                      });
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                      const SizedBox(height: 22),

                      // Section 7: Attachments
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.attach_file_rounded, color: EduStreakTheme.neonCyan, size: 20),
                              const SizedBox(width: 8),
                              const Text('Attachments & Documents', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1F2964),
                              foregroundColor: EduStreakTheme.neonCyan,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            icon: const Icon(Icons.upload_file, size: 16),
                            label: const Text('Attach File', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            onPressed: _pickFiles,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      if (_pickedFiles.isEmpty && _existingAttachmentNames.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF141A42).withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF283168)),
                          ),
                          child: const Center(
                            child: Text(
                              'Attach PDF worksheets, problem sheets, images, or reference reading materials.',
                              style: TextStyle(color: Colors.white54, fontSize: 12),
                            ),
                          ),
                        )
                      else ...[
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ..._existingAttachmentNames.map((name) => Chip(
                                  backgroundColor: const Color(0xFF141A42),
                                  side: const BorderSide(color: Color(0xFF283168)),
                                  avatar: const Icon(Icons.insert_drive_file, color: EduStreakTheme.neonCyan, size: 16),
                                  label: Text(name, style: const TextStyle(color: Colors.white, fontSize: 12)),
                                  onDeleted: () {
                                    setState(() {
                                      final idx = _existingAttachmentNames.indexOf(name);
                                      if (idx >= 0) {
                                        _existingAttachmentNames.removeAt(idx);
                                        _existingAttachmentUrls.removeAt(idx);
                                      }
                                    });
                                  },
                                )),
                            ..._pickedFiles.map((pf) => Chip(
                                  backgroundColor: const Color(0xFF1F2964),
                                  side: const BorderSide(color: EduStreakTheme.primaryViolet),
                                  avatar: const Icon(Icons.file_present, color: Colors.white, size: 16),
                                  label: Text(pf.name, style: const TextStyle(color: Colors.white, fontSize: 12)),
                                  onDeleted: () {
                                    setState(() {
                                      _pickedFiles.remove(pf);
                                    });
                                  },
                                )),
                          ],
                        ),
                      ],

                      const SizedBox(height: 22),

                      // Section 8: Recipients
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.people_alt_rounded, color: EduStreakTheme.emeraldGreen, size: 20),
                              const SizedBox(width: 8),
                              const Text('Assignment Recipients', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Row(
                            children: [
                              ChoiceChip(
                                label: const Text('Entire Class', style: TextStyle(fontSize: 12)),
                                selected: _assignToAll,
                                selectedColor: EduStreakTheme.primaryViolet,
                                backgroundColor: const Color(0xFF141A42),
                                onSelected: (val) => setState(() => _assignToAll = true),
                              ),
                              const SizedBox(width: 8),
                              ChoiceChip(
                                label: Text(
                                  _assignToAll
                                      ? 'Selected Students'
                                      : 'Selected Students (${_selectedStudentIds.length})',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                selected: !_assignToAll,
                                selectedColor: EduStreakTheme.primaryViolet,
                                backgroundColor: const Color(0xFF141A42),
                                onSelected: (val) => setState(() => _assignToAll = false),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      if (!_assignToAll) ...[
                        if (_isLoadingStudents)
                          const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()))
                        else if (_classStudents.isEmpty)
                          const Text('No students found in this class.', style: TextStyle(color: Colors.white54, fontSize: 12))
                        else
                          Container(
                            constraints: const BoxConstraints(maxHeight: 180),
                            decoration: BoxDecoration(
                              color: const Color(0xFF141A42),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFF283168)),
                            ),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: _classStudents.length,
                              itemBuilder: (context, idx) {
                                final s = _classStudents[idx];
                                final isSelected = _selectedStudentIds.contains(s.id);
                                return CheckboxListTile(
                                  title: Text(s.name, style: const TextStyle(color: Colors.white, fontSize: 13)),
                                  subtitle: Text(
                                    'Roll No: ${s.rollNumber ?? 'N/A'}',
                                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                                  ),
                                  value: isSelected,
                                  activeColor: EduStreakTheme.primaryViolet,
                                  onChanged: (val) {
                                    setState(() {
                                      if (val == true) {
                                        _selectedStudentIds.add(s.id);
                                      } else {
                                        _selectedStudentIds.remove(s.id);
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // Modal Footer Actions
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                color: Color(0xFF141A42),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                border: Border(top: BorderSide(color: Color(0xFF283168))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Color(0xFF333E80)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    icon: const Icon(Icons.save_outlined, size: 16),
                    label: const Text('Save Draft'),
                    onPressed: _isSaving ? null : () => _submitAssignment(isDraft: true),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: EduStreakTheme.primaryViolet,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    icon: _isSaving
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.rocket_launch_rounded, size: 16),
                    label: Text(
                      widget.existingTask != null ? 'Update & Publish' : 'Publish Assignment',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: _isSaving ? null : () => _submitAssignment(isDraft: false),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
