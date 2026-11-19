import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../services/teacher_ai_hub_service.dart';
import '../../utils/edustreak_theme.dart';
import '../../utils/class_name_helper.dart';

class TeacherAiTeachingHubTab extends StatefulWidget {
  final UserModel? user;

  const TeacherAiTeachingHubTab({super.key, this.user});

  @override
  State<TeacherAiTeachingHubTab> createState() => _TeacherAiTeachingHubTabState();
}

class _TeacherAiTeachingHubTabState extends State<TeacherAiTeachingHubTab> {
  final TeacherAiHubService _aiService = TeacherAiHubService();
  int _activeSubTool = 0; // 0: Lesson Plan, 1: Questions, 2: Worksheet, 3: Assistant Chat, 4: Student Insights

  // Form controls
  late String _selectedClass;
  late String _selectedSubject;
  final _chapterController = TextEditingController(text: 'Cell Structure and Functions');
  final _topicController = TextEditingController(text: 'Plant and Animal Cells');
  final _chatQueryController = TextEditingController();

  // Tool specific options
  String _difficulty = 'Medium';
  String _questionType = 'mcq';
  int _numQuestions = 5;

  // Output states
  bool _isLoading = false;
  bool _isSaving = false;
  Map<String, dynamic>? _lessonPlanResult;
  Map<String, dynamic>? _questionResult;
  Map<String, dynamic>? _worksheetResult;
  Map<String, dynamic>? _insightsResult;
  final List<Map<String, dynamic>> _chatMessages = [];

  List<String> get _safeClasses {
    final raw = widget.user?.classIds;
    if (raw != null && raw.isNotEmpty) return raw;
    final single = widget.user?.classId;
    if (single != null && single.isNotEmpty) return [single];
    return const ['Class 8A', 'Class 8B'];
  }

  List<String> get _safeSubjects {
    final raw = widget.user?.assignedSubjects;
    if (raw != null && raw.isNotEmpty) return raw;
    return const ['Science', 'Mathematics', 'English'];
  }

  @override
  void initState() {
    super.initState();
    final classes = _safeClasses;
    _selectedClass = classes.first;

    final subjects = _safeSubjects;
    _selectedSubject = subjects.first;

    // Seed initial assistant greeting
    _chatMessages.add({
      'isUser': false,
      'text': 'Hello Teacher! I am your AI Teaching Assistant. How can I assist you with your curriculum, classroom pedagogy, or student differentiation today?',
      'tips': [
        'Try asking: "How should I introduce this topic tomorrow?"',
        'Ask: "What classroom activity works best for mixed-ability groups?"',
      ],
    });
  }

  @override
  void dispose() {
    _chapterController.dispose();
    _topicController.dispose();
    _chatQueryController.dispose();
    super.dispose();
  }

  Future<void> _handleGenerateLessonPlan() async {
    setState(() => _isLoading = true);
    final formattedClass = ClassNameHelper.formatClassNameSync(_selectedClass, fallback: 'Class 8A');
    final res = await _aiService.generateLessonPlan(
      gradeOrClass: formattedClass,
      subject: _selectedSubject,
      chapter: _chapterController.text.trim().isNotEmpty ? _chapterController.text.trim() : 'Unit 1',
      topic: _topicController.text.trim().isNotEmpty ? _topicController.text.trim() : 'Core Concept',
    );
    if (mounted) {
      setState(() {
        _lessonPlanResult = res;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleGenerateQuestions() async {
    setState(() => _isLoading = true);
    final formattedClass = ClassNameHelper.formatClassNameSync(_selectedClass, fallback: 'Class 8A');
    final res = await _aiService.generateQuestions(
      gradeOrClass: formattedClass,
      subject: _selectedSubject,
      chapter: _chapterController.text.trim().isNotEmpty ? _chapterController.text.trim() : 'Unit 1',
      topic: _topicController.text.trim().isNotEmpty ? _topicController.text.trim() : 'Core Concept',
      difficulty: _difficulty,
      questionType: _questionType,
      numQuestions: _numQuestions,
    );
    if (mounted) {
      setState(() {
        _questionResult = res;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleGenerateWorksheet() async {
    setState(() => _isLoading = true);
    final formattedClass = ClassNameHelper.formatClassNameSync(_selectedClass, fallback: 'Class 8A');
    final res = await _aiService.generateWorksheet(
      gradeOrClass: formattedClass,
      subject: _selectedSubject,
      chapter: _chapterController.text.trim().isNotEmpty ? _chapterController.text.trim() : 'Unit 1',
      topic: _topicController.text.trim().isNotEmpty ? _topicController.text.trim() : 'Core Concept',
    );
    if (mounted) {
      setState(() {
        _worksheetResult = res;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleGenerateLearningInsights() async {
    setState(() => _isLoading = true);
    final formattedClass = ClassNameHelper.formatClassNameSync(_selectedClass, fallback: 'Class 8A');
    final res = await _aiService.generateLearningInsights(
      gradeOrClass: formattedClass,
      subject: _selectedSubject,
      topic: _topicController.text.trim().isNotEmpty ? _topicController.text.trim() : 'Core Curriculum Topic',
    );
    if (mounted) {
      setState(() {
        _insightsResult = res;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSendChatMessage(String query) async {
    final text = query.trim();
    if (text.isEmpty) return;

    _chatQueryController.clear();
    setState(() {
      _chatMessages.add({'isUser': true, 'text': text});
      _isLoading = true;
    });

    final formattedClass = ClassNameHelper.formatClassNameSync(_selectedClass, fallback: 'Class 8A');
    final res = await _aiService.askAssistant(
      question: text,
      gradeOrClass: formattedClass,
      subject: _selectedSubject,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        _chatMessages.add({
          'isUser': false,
          'text': res['answer'] ?? 'Here is my pedagogical guidance for your classroom.',
          'tips': res['pedagogy_tips'] ?? <String>[],
          'followups': res['suggested_followups'] ?? <String>[],
        });
      });
    }
  }

  // ─── FIRESTORE DRAFT & PUBLISH ACTIONS ─────────────────────────────────────
  Future<void> _saveDraft({
    required String artifactType,
    required String title,
    required Map<String, dynamic> data,
  }) async {
    setState(() => _isSaving = true);
    try {
      final teacherId = widget.user?.id ?? 'teacher';
      final schoolId = widget.user?.schoolId ?? '';
      await FirebaseFirestore.instance.collection('teacher_ai_artifacts').add({
        'teacherId': teacherId,
        'schoolId': schoolId,
        'classId': _selectedClass,
        'subject': _selectedSubject,
        'chapter': _chapterController.text.trim(),
        'topic': _topicController.text.trim(),
        'artifactType': artifactType,
        'title': title,
        'content': data,
        'status': 'draft',
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: EduStreakTheme.emeraldGreen,
            content: Text('✓ $title successfully saved to drafts!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text('Error saving draft: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _publishLessonPlanToResources() async {
    if (_lessonPlanResult == null) return;
    setState(() => _isSaving = true);
    try {
      final teacherName = widget.user?.name.isNotEmpty == true ? widget.user!.name : 'Teacher';
      final schoolId = widget.user?.schoolId ?? '';
      final title = _lessonPlanResult!['lesson_title'] ?? 'Lesson Plan: ${_topicController.text.trim()}';
      final explanation = _lessonPlanResult!['teaching_explanation'] ?? '';

      await FirebaseFirestore.instance.collection('resources').add({
        'schoolId': schoolId,
        'classId': _selectedClass,
        'title': title,
        'description': explanation,
        'subject': _selectedSubject,
        'chapter': _chapterController.text.trim(),
        'topic': _topicController.text.trim(),
        'resourceType': 'notes',
        'fileUrl': '',
        'uploadedBy': widget.user?.id ?? 'teacher',
        'uploadedByName': teacherName,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: EduStreakTheme.emeraldGreen,
            content: Text('✓ Published "$title" directly to Class Study Materials!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.redAccent, content: Text('Publish error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _assignWorksheetToClass() async {
    if (_worksheetResult == null) return;
    setState(() => _isSaving = true);
    try {
      final teacherName = widget.user?.name.isNotEmpty == true ? widget.user!.name : 'Teacher';
      final title = _worksheetResult!['title'] ?? 'Worksheet: ${_topicController.text.trim()}';
      final sections = (_worksheetResult!['sections'] as List?) ?? [];
      final questionsCount = sections.fold<int>(0, (acc, s) => acc + ((s['questions'] as List?)?.length ?? 0));

      await FirebaseFirestore.instance.collection('tasks').add({
        'classId': _selectedClass,
        'title': title,
        'description': 'Complete the attached AI-generated practice worksheet on ${_topicController.text.trim()} ($questionsCount questions).',
        'subject': _selectedSubject,
        'assignedBy': widget.user?.id ?? 'teacher',
        'assignedByName': teacherName,
        'dueDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 3))),
        'createdAt': FieldValue.serverTimestamp(),
        'assignedTo': [],
        'maxMarks': 25,
        'xpReward': 60,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: EduStreakTheme.neonCyan,
            content: Text('✓ Assigned worksheet to $_selectedClass students (due in 3 days)!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.redAccent, content: Text('Assignment error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final classes = _safeClasses;
    final subjects = _safeSubjects;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: EduStreakTheme.primaryViolet.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: EduStreakTheme.primaryViolet.withValues(alpha: 0.4)),
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: EduStreakTheme.primaryViolet, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Teaching Hub',
                      style: EduStreakTheme.fontHeading1(color: Colors.white, weight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Curriculum-aligned lesson plans, question sets, worksheets, insights & pedagogy assistance.',
                      style: EduStreakTheme.fontBody(color: EduStreakTheme.darkTextSub),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Sub-tool switcher pills (All 5 Sub-Modules)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildSubToolTab(0, 'Lesson Plan Generator', Icons.menu_book_rounded),
                const SizedBox(width: 8),
                _buildSubToolTab(1, 'Question Generator', Icons.quiz_rounded),
                const SizedBox(width: 8),
                _buildSubToolTab(2, 'Worksheet Generator', Icons.assignment_rounded),
                const SizedBox(width: 8),
                _buildSubToolTab(3, 'Teaching Assistant Chat', Icons.chat_bubble_rounded),
                const SizedBox(width: 8),
                _buildSubToolTab(4, 'Student Learning Insights', Icons.insights_rounded),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Curricular Context Card (Shared across tools except Chat)
          if (_activeSubTool != 3) _buildContextCard(classes, subjects),

          const SizedBox(height: 20),

          // Active Tool Body
          if (_activeSubTool == 0)
            _buildLessonPlanView()
          else if (_activeSubTool == 1)
            _buildQuestionGeneratorView()
          else if (_activeSubTool == 2)
            _buildWorksheetView()
          else if (_activeSubTool == 3)
            _buildAssistantChatView()
          else
            _buildLearningInsightsView(),
        ],
      ),
    );
  }

  Widget _buildSubToolTab(int index, String label, IconData icon) {
    final isSelected = _activeSubTool == index;
    return InkWell(
      onTap: () => setState(() => _activeSubTool = index),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? EduStreakTheme.primaryViolet : const Color(0xFF0F1535),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? EduStreakTheme.primaryVioletLight : const Color(0xFF222B5C),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.white70),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContextCard(List<String> classes, List<String> subjects) {
    final safeClasses = classes.isNotEmpty ? classes : const ['Class 8A', 'Class 8B'];
    final safeSubjects = subjects.isNotEmpty ? subjects : const ['Science', 'Mathematics', 'English'];
    final selectedClassValue = safeClasses.contains(_selectedClass) ? _selectedClass : safeClasses.first;
    final selectedSubjectValue = safeSubjects.contains(_selectedSubject) ? _selectedSubject : safeSubjects.first;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: EduStreakTheme.darkCardDecoration(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 480;

          final classDropdown = DropdownButtonFormField<String>(
            value: selectedClassValue,
            isExpanded: true,
            dropdownColor: const Color(0xFF0F1535),
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: const InputDecoration(labelText: 'Class', labelStyle: TextStyle(color: Colors.white70)),
            items: safeClasses
                .map((c) => DropdownMenuItem(
                      value: c,
                      child: Text(
                        ClassNameHelper.formatClassNameSync(c, fallback: 'Class 8A'),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _selectedClass = v ?? _selectedClass),
          );

          final subjectDropdown = DropdownButtonFormField<String>(
            value: selectedSubjectValue,
            isExpanded: true,
            dropdownColor: const Color(0xFF0F1535),
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: const InputDecoration(labelText: 'Subject', labelStyle: TextStyle(color: Colors.white70)),
            items: safeSubjects
                .map((s) => DropdownMenuItem(
                      value: s,
                      child: Text(s, overflow: TextOverflow.ellipsis),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _selectedSubject = v ?? _selectedSubject),
          );

          final chapterField = TextField(
            controller: _chapterController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: const InputDecoration(labelText: 'Chapter', labelStyle: TextStyle(color: Colors.white70)),
          );

          final topicField = TextField(
            controller: _topicController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: const InputDecoration(labelText: 'Topic', labelStyle: TextStyle(color: Colors.white70)),
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'CURRICULUM CONTEXT',
                style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1),
              ),
              const SizedBox(height: 12),
              if (isCompact) ...[
                classDropdown,
                const SizedBox(height: 12),
                subjectDropdown,
                const SizedBox(height: 12),
                chapterField,
                const SizedBox(height: 12),
                topicField,
              ] else ...[
                Row(
                  children: [
                    Expanded(child: classDropdown),
                    const SizedBox(width: 14),
                    Expanded(child: subjectDropdown),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: chapterField),
                    const SizedBox(width: 14),
                    Expanded(child: topicField),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  // ─── 1. LESSON PLAN VIEW ──────────────────────────────────────────────────
  Widget _buildLessonPlanView() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _handleGenerateLessonPlan,
            icon: _isLoading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.auto_awesome_rounded, size: 18),
            label: Text(_isLoading ? 'Generating Curricular Lesson Plan...' : 'Generate 45-Min Lesson Plan', style: const TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: EduStreakTheme.primaryViolet,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 20),

        if (_lessonPlanResult != null) _buildLessonPlanResultCard(_lessonPlanResult!),
      ],
    );
  }

  Widget _buildLessonPlanResultCard(Map<String, dynamic> data) {
    final title = data['lesson_title'] ?? 'Lesson Plan';
    final objectives = (data['objectives'] as List?)?.cast<String>() ?? [];
    final prerequisites = (data['prerequisites'] as List?)?.cast<String>() ?? [];
    final explanation = data['teaching_explanation']?.toString() ?? '';
    final activities = (data['classroom_activities'] as List?)?.cast<String>() ?? [];
    final questions = (data['interactive_questions'] as List?)?.cast<String>() ?? [];
    final homework = (data['homework_suggestions'] as List?)?.cast<String>() ?? [];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: EduStreakTheme.darkCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: EduStreakTheme.fontHeading2(color: Colors.white, weight: FontWeight.w800),
                ),
              ),
              IconButton(
                tooltip: 'Copy Lesson Plan',
                icon: const Icon(Icons.copy_rounded, color: EduStreakTheme.neonCyan, size: 20),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: '$title\n\nExplanation:\n$explanation'));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Lesson plan copied to clipboard!')),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Actions: Save Draft & Publish to Study Materials
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _isSaving ? null : () => _saveDraft(artifactType: 'lesson_plan', title: title, data: data),
                icon: const Icon(Icons.bookmark_border_rounded, size: 16, color: EduStreakTheme.neonCyan),
                label: const Text('Save as Draft', style: TextStyle(color: EduStreakTheme.neonCyan, fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: EduStreakTheme.neonCyan),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _publishLessonPlanToResources,
                icon: const Icon(Icons.cloud_upload_rounded, size: 16),
                label: const Text('Publish to Class Study Materials', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: EduStreakTheme.emeraldGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          _buildSectionHeader('Learning Objectives'),
          ...objectives.map((o) => _buildBullet(o)),

          const SizedBox(height: 14),
          _buildSectionHeader('Prerequisites'),
          ...prerequisites.map((p) => _buildBullet(p)),

          const SizedBox(height: 14),
          _buildSectionHeader('Instructional Explanation (15 Mins)'),
          Text(explanation, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5)),

          const SizedBox(height: 14),
          _buildSectionHeader('Classroom Activities'),
          ...activities.map((a) => _buildBullet(a)),

          const SizedBox(height: 14),
          _buildSectionHeader('Interactive Formative Questions'),
          ...questions.map((q) => _buildBullet(q)),

          const SizedBox(height: 14),
          _buildSectionHeader('Homework & Practice Suggestions'),
          ...homework.map((h) => _buildBullet(h)),
        ],
      ),
    );
  }

  // ─── 2. QUESTION GENERATOR VIEW ───────────────────────────────────────────
  Widget _buildQuestionGeneratorView() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: EduStreakTheme.darkCardDecoration(),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 540;

              final diffDropdown = DropdownButtonFormField<String>(
                value: _difficulty,
                isExpanded: true,
                dropdownColor: const Color(0xFF0F1535),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: const InputDecoration(labelText: 'Difficulty', labelStyle: TextStyle(color: Colors.white70)),
                items: const [
                  DropdownMenuItem(value: 'Easy', child: Text('Easy (Foundational)')),
                  DropdownMenuItem(value: 'Medium', child: Text('Medium (Standard)')),
                  DropdownMenuItem(value: 'Hard', child: Text('Hard (Higher Order)')),
                ],
                onChanged: (v) => setState(() => _difficulty = v ?? 'Medium'),
              );

              final typeDropdown = DropdownButtonFormField<String>(
                value: _questionType,
                isExpanded: true,
                dropdownColor: const Color(0xFF0F1535),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: const InputDecoration(labelText: 'Type', labelStyle: TextStyle(color: Colors.white70)),
                items: const [
                  DropdownMenuItem(value: 'mcq', child: Text('Multiple Choice (MCQ)')),
                  DropdownMenuItem(value: 'short_answer', child: Text('Short Answer')),
                ],
                onChanged: (v) => setState(() => _questionType = v ?? 'mcq'),
              );

              final countDropdown = DropdownButtonFormField<int>(
                value: _numQuestions,
                isExpanded: true,
                dropdownColor: const Color(0xFF0F1535),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: const InputDecoration(labelText: 'Count', labelStyle: TextStyle(color: Colors.white70)),
                items: const [
                  DropdownMenuItem(value: 3, child: Text('3 Questions')),
                  DropdownMenuItem(value: 5, child: Text('5 Questions')),
                  DropdownMenuItem(value: 10, child: Text('10 Questions')),
                ],
                onChanged: (v) => setState(() => _numQuestions = v ?? 5),
              );

              if (isCompact) {
                return Column(
                  children: [
                    diffDropdown,
                    const SizedBox(height: 12),
                    typeDropdown,
                    const SizedBox(height: 12),
                    countDropdown,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: diffDropdown),
                  const SizedBox(width: 14),
                  Expanded(child: typeDropdown),
                  const SizedBox(width: 14),
                  Expanded(child: countDropdown),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _handleGenerateQuestions,
            icon: _isLoading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.quiz_rounded, size: 18),
            label: Text(_isLoading ? 'Generating Questions...' : 'Generate Questions', style: const TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: EduStreakTheme.primaryViolet,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 20),

        if (_questionResult != null) _buildQuestionsResultCard(_questionResult!),
      ],
    );
  }

  Widget _buildQuestionsResultCard(Map<String, dynamic> data) {
    final questions = (data['questions'] as List?) ?? [];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: EduStreakTheme.darkCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text('Generated Questions (${questions.length})', style: EduStreakTheme.fontHeading2(color: Colors.white, weight: FontWeight.w800)),
              ),
              OutlinedButton.icon(
                onPressed: _isSaving
                    ? null
                    : () => _saveDraft(
                          artifactType: 'questions',
                          title: 'Question Bank: ${_topicController.text.trim()}',
                          data: data,
                        ),
                icon: const Icon(Icons.bookmark_border_rounded, size: 16, color: EduStreakTheme.neonCyan),
                label: const Text('Save Draft', style: TextStyle(color: EduStreakTheme.neonCyan, fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: EduStreakTheme.neonCyan),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...questions.map((q) {
            final id = q['id'] ?? '';
            final question = q['question'] ?? '';
            final options = (q['options'] as Map?) ?? {};
            final correct = q['correct_answer'] ?? '';
            final marks = q['marks'] ?? 2;

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1535),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF222B5C)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Q$id.', style: const TextStyle(color: EduStreakTheme.neonCyan, fontWeight: FontWeight.bold, fontSize: 13)),
                      Text('$marks Marks', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(question, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                  if (options.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ...options.entries.map((opt) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text('${opt.key}. ${opt.value}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        )),
                  ],
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('Correct Answer / Key: $correct', style: const TextStyle(color: Colors.greenAccent, fontSize: 12)),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─── 3. WORKSHEET VIEW ────────────────────────────────────────────────────
  Widget _buildWorksheetView() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _handleGenerateWorksheet,
            icon: _isLoading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.assignment_rounded, size: 18),
            label: Text(_isLoading ? 'Generating Printable Worksheet...' : 'Generate Printable Worksheet', style: const TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: EduStreakTheme.primaryViolet,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 20),

        if (_worksheetResult != null) _buildWorksheetResultCard(_worksheetResult!),
      ],
    );
  }

  Widget _buildWorksheetResultCard(Map<String, dynamic> data) {
    final title = data['title'] ?? 'Classroom Worksheet';
    final instructions = (data['instructions'] as List?)?.cast<String>() ?? [];
    final sections = (data['sections'] as List?) ?? [];
    final answerKey = (data['answer_key'] as List?)?.cast<String>() ?? [];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: EduStreakTheme.darkCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(title, style: EduStreakTheme.fontHeading2(color: Colors.white, weight: FontWeight.w800)),
              ),
              IconButton(
                tooltip: 'Copy Worksheet Text',
                icon: const Icon(Icons.copy_rounded, color: EduStreakTheme.neonCyan, size: 20),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: title));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Worksheet text copied!')));
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Action Buttons: Save Draft & Assign to Class
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _isSaving ? null : () => _saveDraft(artifactType: 'worksheet', title: title, data: data),
                icon: const Icon(Icons.bookmark_border_rounded, size: 16, color: EduStreakTheme.neonCyan),
                label: const Text('Save as Draft', style: TextStyle(color: EduStreakTheme.neonCyan, fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: EduStreakTheme.neonCyan),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _assignWorksheetToClass,
                icon: const Icon(Icons.assignment_turned_in_rounded, size: 16),
                label: const Text('Assign Worksheet to Class', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: EduStreakTheme.primaryViolet,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          _buildSectionHeader('Instructions'),
          ...instructions.map((i) => _buildBullet(i)),

          const SizedBox(height: 16),
          ...sections.map((sec) {
            final secName = sec['section_name'] ?? 'Section';
            final secQuestions = (sec['questions'] as List?)?.cast<String>() ?? [];
            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1535),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF222B5C)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(secName, style: const TextStyle(color: EduStreakTheme.primaryVioletLight, fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  ...secQuestions.map((sq) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text('• $sq', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      )),
                ],
              ),
            );
          }),

          const SizedBox(height: 14),
          _buildSectionHeader('Answer Key Reference'),
          ...answerKey.map((ak) => _buildBullet(ak)),
        ],
      ),
    );
  }

  // ─── 4. TEACHING ASSISTANT CHAT VIEW ──────────────────────────────────────
  Widget _buildAssistantChatView() {
    return Container(
      height: 520,
      decoration: EduStreakTheme.darkCardDecoration(),
      child: Column(
        children: [
          // Chat message list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _chatMessages.length,
              itemBuilder: (ctx, i) {
                final msg = _chatMessages[i];
                final isUser = msg['isUser'] == true;
                final text = msg['text'] ?? '';
                final tips = (msg['tips'] as List?)?.cast<String>() ?? [];
                final followups = (msg['followups'] as List?)?.cast<String>() ?? [];

                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    constraints: const BoxConstraints(maxWidth: 580),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isUser ? EduStreakTheme.primaryViolet : const Color(0xFF0F1535),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isUser ? EduStreakTheme.primaryVioletLight : const Color(0xFF222B5C),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(text, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4)),
                        if (tips.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          const Text('Pedagogy Micro-Tips:', style: TextStyle(color: EduStreakTheme.neonCyan, fontSize: 11, fontWeight: FontWeight.bold)),
                          ...tips.map((t) => Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text('• $t', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                              )),
                        ],
                        if (followups.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: followups.map((f) => ActionChip(
                                  backgroundColor: const Color(0xFF161C48),
                                  label: Text(f, style: const TextStyle(color: EduStreakTheme.neonCyan, fontSize: 10)),
                                  onPressed: () => _handleSendChatMessage(f),
                                )).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: LinearProgressIndicator(color: EduStreakTheme.primaryViolet, backgroundColor: Color(0xFF0F1535)),
            ),

          // Input field
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFF222B5C))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatQueryController,
                    onSubmitted: _handleSendChatMessage,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'Ask pedagogy advisor e.g. "How to differentiate this unit for struggling students?"',
                      hintStyle: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send_rounded, color: EduStreakTheme.primaryViolet),
                  onPressed: () => _handleSendChatMessage(_chatQueryController.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── 5. STUDENT LEARNING INSIGHTS VIEW (MODULE 5) ─────────────────────────
  Widget _buildLearningInsightsView() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _handleGenerateLearningInsights,
            icon: _isLoading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.insights_rounded, size: 18),
            label: Text(
              _isLoading ? 'Analyzing Student Mastery Diagnostics...' : 'Generate Student Learning Insights',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: EduStreakTheme.primaryViolet,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 20),

        if (_insightsResult != null) _buildLearningInsightsResultCard(_insightsResult!),
      ],
    );
  }

  Widget _buildLearningInsightsResultCard(Map<String, dynamic> data) {
    final totalStudents = data['total_students'] ?? 28;
    final cohorts = (data['cohorts'] as Map?) ?? {};
    final advancedCount = cohorts['advanced'] ?? 7;
    final proficientCount = cohorts['proficient'] ?? 17;
    final strugglingCount = cohorts['struggling'] ?? 4;
    final weakConcepts = (data['weak_concepts'] as List?)?.cast<String>() ?? [];
    final strengths = (data['strength_areas'] as List?)?.cast<String>() ?? [];
    final strategies = (data['remediation_strategies'] as List?)?.cast<String>() ?? [];
    final nextAction = data['recommended_next_action']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: EduStreakTheme.darkCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Curricular Diagnostic Report',
                      style: EduStreakTheme.fontHeading2(color: Colors.white, weight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$_selectedClass • $_selectedSubject • ${_topicController.text.trim()} • $totalStudents Students',
                      style: const TextStyle(color: EduStreakTheme.neonCyan, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: _isSaving
                    ? null
                    : () => _saveDraft(
                          artifactType: 'learning_insights',
                          title: 'Diagnostic Insights: ${_topicController.text.trim()}',
                          data: data,
                        ),
                icon: const Icon(Icons.bookmark_border_rounded, size: 16, color: EduStreakTheme.neonCyan),
                label: const Text('Save Report', style: TextStyle(color: EduStreakTheme.neonCyan, fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: EduStreakTheme.neonCyan),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // 3 Cohort KPI Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 600;
              final cards = [
                _buildCohortCard('Advanced Mastery', '$advancedCount Students', '> 80% Score', EduStreakTheme.emeraldGreen),
                _buildCohortCard('Proficient Growth', '$proficientCount Students', '60-80% Score', EduStreakTheme.neonCyan),
                _buildCohortCard('Remediation Needed', '$strugglingCount Students', '< 60% Score', EduStreakTheme.amberGold),
              ];

              if (isNarrow) {
                return Column(
                  children: cards.map((c) => Padding(padding: const EdgeInsets.only(bottom: 10), child: c)).toList(),
                );
              }

              return Row(
                children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: c))).toList(),
              );
            },
          ),

          const SizedBox(height: 18),
          _buildSectionHeader('Identified Misconceptions & Weak Concepts'),
          ...weakConcepts.map((w) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: EduStreakTheme.amberGold, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(w, style: const TextStyle(color: Colors.white70, fontSize: 13))),
                  ],
                ),
              )),

          const SizedBox(height: 14),
          _buildSectionHeader('Demonstrated Strengths'),
          ...strengths.map((s) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, color: EduStreakTheme.emeraldGreen, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(s, style: const TextStyle(color: Colors.white70, fontSize: 13))),
                  ],
                ),
              )),

          const SizedBox(height: 14),
          _buildSectionHeader('Targeted Remediation & Intervention Plan'),
          ...strategies.map((st) => _buildBullet(st)),

          if (nextAction.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: EduStreakTheme.primaryViolet.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: EduStreakTheme.primaryViolet.withValues(alpha: 0.4)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_rounded, color: EduStreakTheme.neonCyan, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AI RECOMMENDED NEXT PEDAGOGICAL ACTION',
                          style: TextStyle(color: EduStreakTheme.neonCyan, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(nextAction, style: const TextStyle(color: Colors.white, fontSize: 12.5, height: 1.4)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCohortCard(String title, String count, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1535),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(count, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(color: EduStreakTheme.neonCyan, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
      ),
    );
  }

  Widget _buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: EduStreakTheme.primaryVioletLight, fontWeight: FontWeight.bold)),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.3))),
        ],
      ),
    );
  }
}
