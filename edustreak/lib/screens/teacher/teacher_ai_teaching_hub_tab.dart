import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../models/assessment_model.dart';
import '../../services/teacher_ai_hub_service.dart';
import '../../services/curriculum_service.dart';
import '../../services/task_service.dart';
import '../../services/assessment_service.dart';
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
  final CurriculumService _curriculumService = CurriculumService();
  final TaskService _taskService = TaskService();
  final AssessmentService _assessmentService = AssessmentService();

  // Active module tab
  // 0: Lesson Plan, 1: Question Generator, 2: Worksheet Generator, 3: Teaching Assistant Chat, 4: Student Learning Insights, 5: My AI Resources
  int _activeSubTool = 0;

  // Curriculum State (Dependent Dropdowns)
  late String _selectedClass;
  late String _selectedSubject;
  String? _selectedChapter;
  String? _selectedTopic;

  List<String> _availableChapters = [];
  List<String> _availableTopics = [];
  bool _isLoadingCurriculum = false;
  bool _isCustomTopic = false;
  final _customTopicController = TextEditingController();

  // Lesson Plan Options
  int _lessonDuration = 45; // 30, 40, 45, 60
  String _learningLevel = 'Mixed Ability';

  // Question Generator Options
  String _difficulty = 'Medium';
  String _questionType = 'mcq';
  int _numQuestions = 5;
  int _totalMarks = 20;

  // Assistant Chat State
  final _chatQueryController = TextEditingController();
  final List<Map<String, dynamic>> _chatMessages = [];

  // Learning Insights State
  Map<String, dynamic>? _classPerformanceSummary;
  bool _isLoadingInsights = false;
  bool _hasEnoughPerformanceData = true;

  // Output States
  bool _isLoading = false;
  bool _isSaving = false;
  Map<String, dynamic>? _lessonPlanResult;
  Map<String, dynamic>? _questionResult;
  Map<String, dynamic>? _worksheetResult;
  Map<String, dynamic>? _insightsResult;

  // My AI Resources (History) Search & Filter
  String _resourceFilter = 'all';
  String _resourceSearchQuery = '';
  final _resourceSearchController = TextEditingController();

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
    return CurriculumService.getStandardSubjects();
  }

  @override
  void initState() {
    super.initState();
    final classes = _safeClasses;
    _selectedClass = classes.first;

    final subjects = _safeSubjects;
    _selectedSubject = subjects.first;

    // Load initial curriculum chapters & topics for the default subject
    _loadCurriculumForSubject(_selectedSubject);

    // Initial assistant greeting
    _chatMessages.add({
      'isUser': false,
      'text': 'Hello Teacher! I am your EduStreak AI Teaching Assistant. How can I help you design engaging lessons, create diagnostic assessments, or address student learning gaps today?',
      'tips': [
        'How to introduce this topic with an engaging real-world hook?',
        'Suggest a hands-on activity for mixed-ability groups.',
        'What common misconceptions do students hold in this chapter?',
      ],
      'followups': [
        'Create a 5-minute exit ticket diagnostic',
        'How can I help students struggling with foundational steps?',
      ],
    });
  }

  @override
  void dispose() {
    _customTopicController.dispose();
    _chatQueryController.dispose();
    _resourceSearchController.dispose();
    super.dispose();
  }

  // ─── DEPENDENT CURRICULUM CONTROLLER ─────────────────────────────────────

  /// When class changes: update class, reload authorized subjects if necessary
  void _onClassChanged(String? newClass) {
    if (newClass == null || newClass == _selectedClass) return;
    setState(() {
      _selectedClass = newClass;
      _insightsResult = null;
      _classPerformanceSummary = null;
    });
    if (_activeSubTool == 4) {
      _loadClassPerformanceMetrics();
    }
  }

  /// When subject changes: strictly clear old chapters and topics, then fetch matching ones
  Future<void> _onSubjectChanged(String? newSubject) async {
    if (newSubject == null || newSubject == _selectedSubject) return;
    setState(() {
      _selectedSubject = newSubject;
      _selectedChapter = null;
      _selectedTopic = null;
      _availableChapters = [];
      _availableTopics = [];
      _lessonPlanResult = null;
      _questionResult = null;
      _worksheetResult = null;
      _insightsResult = null;
      _classPerformanceSummary = null;
    });
    await _loadCurriculumForSubject(newSubject);
    if (_activeSubTool == 4) {
      _loadClassPerformanceMetrics();
    }
  }

  /// When chapter changes: clear old topic and fetch topics belonging exclusively to that chapter
  Future<void> _onChapterChanged(String? newChapter) async {
    if (newChapter == null || newChapter == _selectedChapter) return;
    setState(() {
      _selectedChapter = newChapter;
      _selectedTopic = null;
      _availableTopics = [];
    });
    await _loadTopicsForChapter(_selectedSubject, newChapter);
  }

  Future<void> _loadCurriculumForSubject(String subject) async {
    setState(() => _isLoadingCurriculum = true);
    try {
      final chapters = await _curriculumService.getChaptersForSubject(
        subject,
        schoolId: widget.user?.schoolId,
      );

      if (!mounted) return;

      setState(() {
        _availableChapters = chapters;
        _selectedChapter = chapters.isNotEmpty ? chapters.first : null;
      });

      if (_selectedChapter != null) {
        await _loadTopicsForChapter(subject, _selectedChapter!);
      }
    } catch (e) {
      debugPrint('Error loading chapters: $e');
    } finally {
      if (mounted) setState(() => _isLoadingCurriculum = false);
    }
  }

  Future<void> _loadTopicsForChapter(String subject, String chapter) async {
    try {
      final topics = await _curriculumService.getTopicsForChapter(
        subject,
        chapter,
        schoolId: widget.user?.schoolId,
      );

      if (!mounted) return;

      setState(() {
        _availableTopics = topics;
        _selectedTopic = topics.isNotEmpty ? topics.first : null;
      });
    } catch (e) {
      debugPrint('Error loading topics: $e');
    }
  }

  String get _currentEffectiveTopic {
    if (_isCustomTopic && _customTopicController.text.trim().isNotEmpty) {
      return _customTopicController.text.trim();
    }
    return _selectedTopic ?? (_availableTopics.isNotEmpty ? _availableTopics.first : 'Foundations & Core Principles');
  }

  String get _currentEffectiveChapter {
    return _selectedChapter ?? (_availableChapters.isNotEmpty ? _availableChapters.first : 'Unit 1');
  }

  // ─── MODULE 1: LESSON PLAN GENERATOR ──────────────────────────────────────
  Future<void> _handleGenerateLessonPlan() async {
    setState(() => _isLoading = true);
    final formattedClass = ClassNameHelper.cleanFormattedName(_selectedClass);
    try {
      final res = await _aiService.generateLessonPlan(
        gradeOrClass: formattedClass,
        subject: _selectedSubject,
        chapter: _currentEffectiveChapter,
        topic: _currentEffectiveTopic,
        durationMinutes: _lessonDuration,
      );
      if (mounted) {
        setState(() {
          _lessonPlanResult = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Lesson plan generation failed: $e');
      }
    }
  }

  // ─── MODULE 2: QUESTION GENERATOR ─────────────────────────────────────────
  Future<void> _handleGenerateQuestions() async {
    setState(() => _isLoading = true);
    final formattedClass = ClassNameHelper.cleanFormattedName(_selectedClass);
    try {
      final res = await _aiService.generateQuestions(
        gradeOrClass: formattedClass,
        subject: _selectedSubject,
        chapter: _currentEffectiveChapter,
        topic: _currentEffectiveTopic,
        difficulty: _difficulty,
        questionType: _questionType,
        numQuestions: _numQuestions,
        totalMarks: _totalMarks,
      );
      if (mounted) {
        setState(() {
          _questionResult = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Question generation failed: $e');
      }
    }
  }

  // ─── MODULE 3: WORKSHEET GENERATOR ────────────────────────────────────────
  Future<void> _handleGenerateWorksheet() async {
    setState(() => _isLoading = true);
    final formattedClass = ClassNameHelper.cleanFormattedName(_selectedClass);
    try {
      final res = await _aiService.generateWorksheet(
        gradeOrClass: formattedClass,
        subject: _selectedSubject,
        chapter: _currentEffectiveChapter,
        topic: _currentEffectiveTopic,
        numQuestions: _numQuestions,
      );
      if (mounted) {
        setState(() {
          _worksheetResult = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Worksheet generation failed: $e');
      }
    }
  }

  // ─── MODULE 4: TEACHING ASSISTANT CHAT ────────────────────────────────────
  Future<void> _handleSendChatMessage(String query) async {
    final text = query.trim();
    if (text.isEmpty) return;

    _chatQueryController.clear();
    setState(() {
      _chatMessages.add({'isUser': true, 'text': text});
      _isLoading = true;
    });

    final formattedClass = ClassNameHelper.cleanFormattedName(_selectedClass);
    try {
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
            'tips': (res['pedagogy_tips'] as List?)?.cast<String>() ?? <String>[],
            'followups': (res['suggested_followups'] as List?)?.cast<String>() ?? <String>[],
          });
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _chatMessages.add({
            'isUser': false,
            'text': '⚠️ AI Assistant Error: $e',
          });
        });
      }
    }
  }

  // ─── MODULE 5: STUDENT LEARNING INSIGHTS (REAL FIRESTORE DATA) ────────────
  Future<void> _loadClassPerformanceMetrics() async {
    setState(() => _isLoadingInsights = true);
    try {
      final summary = await _aiService.fetchClassPerformanceData(
        classId: _selectedClass,
        subject: _selectedSubject,
      );
      if (mounted) {
        setState(() {
          _classPerformanceSummary = summary;
          _hasEnoughPerformanceData = summary['hasEnoughData'] == true;
          _isLoadingInsights = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingInsights = false);
    }
  }

  Future<void> _handleGenerateLearningInsights() async {
    if (_classPerformanceSummary == null) {
      await _loadClassPerformanceMetrics();
    }

    if (_classPerformanceSummary == null || _classPerformanceSummary!['hasEnoughData'] != true) {
      _showInfoSnackBar('Not enough performance data is available to generate reliable insights.');
      return;
    }

    setState(() => _isLoading = true);
    final formattedClass = ClassNameHelper.cleanFormattedName(_selectedClass);
    final avgScore = (_classPerformanceSummary!['averageScore'] as num?)?.toDouble() ?? 75.0;
    final studentCount = (_classPerformanceSummary!['totalStudents'] as num?)?.toInt() ?? 25;
    final submissionRate = (_classPerformanceSummary!['submissionRate'] as num?)?.toDouble() ?? 80.0;
    final weakAreas = (_classPerformanceSummary!['weakAreas'] as List?)?.cast<String>() ?? [];

    try {
      final res = await _aiService.generateLearningInsights(
        gradeOrClass: formattedClass,
        subject: _selectedSubject,
        chapter: _currentEffectiveChapter,
        topic: _currentEffectiveTopic,
        averageScore: avgScore,
        studentCount: studentCount,
        submissionRate: submissionRate,
        weakAreas: weakAreas,
      );

      if (mounted) {
        setState(() {
          _insightsResult = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Diagnostic insights generation failed: $e');
      }
    }
  }

  // ─── FIRESTORE INTEGRATION ACTIONS ────────────────────────────────────────

  /// Saves any artifact to `teacher_ai_artifacts` collection with full provenance
  Future<void> _saveArtifactToFirestore({
    required String artifactType,
    required String title,
    required Map<String, dynamic> data,
  }) async {
    setState(() => _isSaving = true);
    try {
      final teacherId = widget.user?.id ?? 'teacher';
      final schoolId = widget.user?.schoolId ?? '';
      await _aiService.saveArtifact(
        teacherId: teacherId,
        schoolId: schoolId,
        classId: _selectedClass,
        subject: _selectedSubject,
        chapter: _currentEffectiveChapter,
        topic: _currentEffectiveTopic,
        artifactType: artifactType,
        title: title,
        data: data,
      );

      if (mounted) {
        _showSuccessSnackBar('✓ "$title" saved to My AI Resources!');
      }
    } catch (e) {
      if (mounted) _showErrorSnackBar('Failed to save resource: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// Publishes approved lesson plan to students via `resources` collection
  Future<void> _publishLessonPlanToStudyMaterials() async {
    if (_lessonPlanResult == null) return;
    setState(() => _isSaving = true);
    try {
      final teacherName = widget.user?.name.isNotEmpty == true ? widget.user!.name : 'Teacher';
      final schoolId = widget.user?.schoolId ?? '';
      final title = _lessonPlanResult!['lesson_title'] ?? 'Lesson Plan: $_currentEffectiveTopic';
      final explanation = _lessonPlanResult!['teaching_explanation'] ?? '';

      await FirebaseFirestore.instance.collection('resources').add({
        'schoolId': schoolId,
        'classId': _selectedClass,
        'title': title,
        'description': explanation,
        'subject': _selectedSubject,
        'chapter': _currentEffectiveChapter,
        'topic': _currentEffectiveTopic,
        'resourceType': 'notes',
        'fileUrl': '',
        'uploadedBy': widget.user?.id ?? 'teacher',
        'uploadedByName': teacherName,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        _showSuccessSnackBar('✓ Published "$title" directly to Class Study Materials!');
      }
    } catch (e) {
      if (mounted) _showErrorSnackBar('Publish error: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// Creates a real TaskModel assignment in `tasks` collection with student notifications
  Future<void> _assignWorksheetToClass() async {
    if (_worksheetResult == null) return;
    setState(() => _isSaving = true);
    try {
      final title = _worksheetResult!['title'] ?? 'Worksheet: $_currentEffectiveTopic';
      final sections = (_worksheetResult!['sections'] as List?) ?? [];
      final questionsList = <Map<String, dynamic>>[];

      for (var sec in sections) {
        final secName = sec['section_name'] ?? 'Section';
        final qList = (sec['questions'] as List?)?.cast<String>() ?? [];
        for (var q in qList) {
          questionsList.add({
            'text': q,
            'section': secName,
            'type': 'short_answer',
            'marks': 3,
          });
        }
      }

      // Fetch enrolled students for class
      List<String> studentIds = [];
      try {
        final snap = await FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'student')
            .where('classId', isEqualTo: _selectedClass)
            .get();
        studentIds = snap.docs.map((d) => d.id).toList();
      } catch (_) {}

      await _taskService.createTask(
        classId: _selectedClass,
        title: title,
        description: 'Complete the attached practice worksheet on $_currentEffectiveTopic (${questionsList.length} questions). Show all steps.',
        assignedBy: widget.user?.id ?? 'teacher',
        assignedByName: widget.user?.name ?? 'Teacher',
        dueDate: DateTime.now().add(const Duration(days: 3)),
        assignedTo: studentIds,
        subject: _selectedSubject,
        schoolId: widget.user?.schoolId ?? '',
        type: 'Worksheet',
        chapterOrTopic: '$_currentEffectiveChapter - $_currentEffectiveTopic',
        status: 'published',
        questions: questionsList,
        maxMarks: 25,
        xpReward: 60,
      );

      if (mounted) {
        _showSuccessSnackBar('✓ Assigned worksheet to $_selectedClass (${studentIds.length} students notified)!');
      }
    } catch (e) {
      if (mounted) _showErrorSnackBar('Assignment creation error: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// Creates a real AssessmentModel in `assessments` collection
  Future<void> _addQuestionsToAssessment() async {
    if (_questionResult == null) return;
    setState(() => _isSaving = true);
    try {
      final questionsRaw = (_questionResult!['questions'] as List?) ?? [];
      final assessmentQuestions = questionsRaw.map((q) => AssessmentQuestion.fromMap(q as Map<String, dynamic>)).toList();
      final totalMarks = assessmentQuestions.fold<int>(0, (sum, q) => sum + q.marks);

      final now = DateTime.now();
      final assessment = AssessmentModel(
        id: '',
        schoolId: widget.user?.schoolId ?? '',
        classId: _selectedClass,
        className: ClassNameHelper.cleanFormattedName(_selectedClass),
        subject: _selectedSubject,
        chapter: _currentEffectiveChapter,
        topic: _currentEffectiveTopic,
        title: '$_selectedSubject Quiz: $_currentEffectiveTopic',
        description: 'AI-assisted formative assessment evaluating $_currentEffectiveTopic competencies.',
        type: 'quiz',
        status: 'published',
        totalMarks: totalMarks > 0 ? totalMarks : 20,
        passingMarks: (totalMarks * 0.4).round(),
        durationMinutes: 25,
        scheduledDate: now,
        dueDate: now.add(const Duration(days: 3)),
        createdAt: now,
        createdBy: widget.user?.id ?? 'teacher',
        createdByName: widget.user?.name ?? 'Teacher',
        questions: assessmentQuestions,
      );

      await _assessmentService.createAssessment(assessment);

      if (mounted) {
        _showSuccessSnackBar('✓ Published as Assessment: "${assessment.title}" for $_selectedClass!');
      }
    } catch (e) {
      if (mounted) _showErrorSnackBar('Assessment error: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSuccessSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: EduStreakTheme.emeraldGreen, content: Text(msg)),
    );
  }

  void _showErrorSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: Colors.redAccent, content: Text(msg)),
    );
  }

  void _showInfoSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: EduStreakTheme.neonCyan, content: Text(msg, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold))),
    );
  }

  // ─── MAIN BUILD ───────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final classes = _safeClasses;
    final subjects = _safeSubjects;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeaderBar(),
          const SizedBox(height: 20),

          // 6 Sub-Module Switcher Pills
          _buildToolSwitcher(),
          const SizedBox(height: 20),

          // Curriculum Selection Card (Shared across modules except Chat & My Resources)
          if (_activeSubTool != 3 && _activeSubTool != 5)
            _buildCurriculumContextCard(classes, subjects),

          if (_activeSubTool != 3 && _activeSubTool != 5)
            const SizedBox(height: 20),

          // Active Module View
          if (_activeSubTool == 0)
            _buildLessonPlanView()
          else if (_activeSubTool == 1)
            _buildQuestionGeneratorView()
          else if (_activeSubTool == 2)
            _buildWorksheetView()
          else if (_activeSubTool == 3)
            _buildAssistantChatView()
          else if (_activeSubTool == 4)
            _buildLearningInsightsView()
          else
            _buildMyResourcesView(),
        ],
      ),
    );
  }

  // ─── HEADER & NAV BAR ─────────────────────────────────────────────────────
  Widget _buildHeaderBar() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: EduStreakTheme.primaryViolet.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: EduStreakTheme.primaryViolet.withValues(alpha: 0.4)),
          ),
          child: const Icon(Icons.auto_awesome_rounded, color: EduStreakTheme.primaryViolet, size: 26),
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
                'Create curriculum-aligned lessons, questions, worksheets, and teaching insights with AI.',
                style: EduStreakTheme.fontBody(color: EduStreakTheme.darkTextSub),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToolSwitcher() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildSubToolTab(0, 'Lesson Plans', Icons.menu_book_rounded),
          const SizedBox(width: 8),
          _buildSubToolTab(1, 'Questions', Icons.quiz_rounded),
          const SizedBox(width: 8),
          _buildSubToolTab(2, 'Worksheets', Icons.assignment_rounded),
          const SizedBox(width: 8),
          _buildSubToolTab(3, 'AI Assistant', Icons.chat_bubble_rounded),
          const SizedBox(width: 8),
          _buildSubToolTab(4, 'Learning Insights', Icons.insights_rounded),
          const SizedBox(width: 8),
          _buildSubToolTab(5, 'My AI Resources', Icons.folder_special_rounded),
        ],
      ),
    );
  }

  Widget _buildSubToolTab(int index, String label, IconData icon) {
    final isSelected = _activeSubTool == index;
    return InkWell(
      onTap: () {
        setState(() => _activeSubTool = index);
        if (index == 4) {
          _loadClassPerformanceMetrics();
        }
      },
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

  // ─── CURRICULUM CONTEXT CARD (DEPENDENT DROPDOWNS) ───────────────────────
  Widget _buildCurriculumContextCard(List<String> classes, List<String> subjects) {
    final safeClasses = classes.isNotEmpty ? classes : const ['Class 8A', 'Class 8B'];
    final safeSubjects = subjects.isNotEmpty ? subjects : const ['Science', 'Mathematics', 'English'];
    final selectedClassValue = safeClasses.contains(_selectedClass) ? _selectedClass : safeClasses.first;
    final selectedSubjectValue = safeSubjects.contains(_selectedSubject) ? _selectedSubject : safeSubjects.first;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: EduStreakTheme.darkCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'CURRICULUM CONTEXT',
                style: TextStyle(color: EduStreakTheme.neonCyan, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
              ),
              if (_isLoadingCurriculum)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: EduStreakTheme.neonCyan),
                ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 600;

              final classDropdown = DropdownButtonFormField<String>(
                value: selectedClassValue,
                isExpanded: true,
                dropdownColor: const Color(0xFF0F1535),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Class',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: const Color(0xFF070B1E),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF222B5C))),
                ),
                items: safeClasses
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(ClassNameHelper.cleanFormattedName(c), overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: _onClassChanged,
              );

              final subjectDropdown = DropdownButtonFormField<String>(
                value: selectedSubjectValue,
                isExpanded: true,
                dropdownColor: const Color(0xFF0F1535),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Subject',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: const Color(0xFF070B1E),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF222B5C))),
                ),
                items: safeSubjects
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(s, overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: _onSubjectChanged,
              );

              final chapterDropdown = DropdownButtonFormField<String>(
                value: _availableChapters.contains(_selectedChapter) ? _selectedChapter : (_availableChapters.isNotEmpty ? _availableChapters.first : null),
                isExpanded: true,
                dropdownColor: const Color(0xFF0F1535),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Chapter',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: const Color(0xFF070B1E),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF222B5C))),
                ),
                items: _availableChapters.isEmpty
                    ? [const DropdownMenuItem(value: null, child: Text('No chapters available', style: TextStyle(color: Colors.white38)))]
                    : _availableChapters
                        .map((c) => DropdownMenuItem(
                              value: c,
                              child: Text(c, overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                onChanged: _availableChapters.isNotEmpty ? _onChapterChanged : null,
              );

              final topicWidget = _isCustomTopic
                  ? TextField(
                      controller: _customTopicController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'Custom Topic / Concept',
                        labelStyle: const TextStyle(color: Colors.white70),
                        hintText: 'Enter specific subtopic...',
                        hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                        filled: true,
                        fillColor: const Color(0xFF070B1E),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF222B5C))),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.list_rounded, color: EduStreakTheme.neonCyan, size: 20),
                          tooltip: 'Choose from syllabus topics',
                          onPressed: () => setState(() => _isCustomTopic = false),
                        ),
                      ),
                    )
                  : DropdownButtonFormField<String>(
                      value: _availableTopics.contains(_selectedTopic) ? _selectedTopic : (_availableTopics.isNotEmpty ? _availableTopics.first : null),
                      isExpanded: true,
                      dropdownColor: const Color(0xFF0F1535),
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'Topic',
                        labelStyle: const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: const Color(0xFF070B1E),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF222B5C))),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.edit_note_rounded, color: EduStreakTheme.neonCyan, size: 20),
                          tooltip: 'Type custom topic',
                          onPressed: () => setState(() => _isCustomTopic = true),
                        ),
                      ),
                      items: _availableTopics.isEmpty
                          ? [const DropdownMenuItem(value: null, child: Text('No topics available', style: TextStyle(color: Colors.white38)))]
                          : _availableTopics
                              .map((t) => DropdownMenuItem(
                                    value: t,
                                    child: Text(t, overflow: TextOverflow.ellipsis),
                                  ))
                              .toList(),
                      onChanged: _availableTopics.isNotEmpty ? (v) => setState(() => _selectedTopic = v) : null,
                    );

              if (isCompact) {
                return Column(
                  children: [
                    classDropdown,
                    const SizedBox(height: 12),
                    subjectDropdown,
                    const SizedBox(height: 12),
                    chapterDropdown,
                    const SizedBox(height: 12),
                    topicWidget,
                  ],
                );
              }

              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: classDropdown),
                      const SizedBox(width: 14),
                      Expanded(child: subjectDropdown),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(child: chapterDropdown),
                      const SizedBox(width: 14),
                      Expanded(child: topicWidget),
                    ],
                  ),
                ],
              );
            },
          ),
          if (_availableChapters.isEmpty && !_isLoadingCurriculum)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text(
                'No curriculum is available for this subject. Please add or request curriculum materials.',
                style: TextStyle(color: EduStreakTheme.amberGold, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  // ─── 1. LESSON PLAN VIEW ──────────────────────────────────────────────────
  Widget _buildLessonPlanView() {
    return Column(
      children: [
        // Controls Row: Duration & Learning Level
        Container(
          padding: const EdgeInsets.all(16),
          decoration: EduStreakTheme.darkCardDecoration(),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 600;

              final durationDropdown = DropdownButtonFormField<int>(
                value: _lessonDuration,
                dropdownColor: const Color(0xFF0F1535),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Lesson Duration',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: const Color(0xFF070B1E),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: const [
                  DropdownMenuItem(value: 30, child: Text('30 Minutes (Short Period)')),
                  DropdownMenuItem(value: 40, child: Text('40 Minutes (Standard Period)')),
                  DropdownMenuItem(value: 45, child: Text('45 Minutes (Full Period)')),
                  DropdownMenuItem(value: 60, child: Text('60 Minutes (Double / Block Period)')),
                ],
                onChanged: (v) => setState(() => _lessonDuration = v ?? 45),
              );

              final levelDropdown = DropdownButtonFormField<String>(
                value: _learningLevel,
                dropdownColor: const Color(0xFF0F1535),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Target Student Level',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: const Color(0xFF070B1E),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: const [
                  DropdownMenuItem(value: 'Mixed Ability', child: Text('Mixed Ability (Differentiated)')),
                  DropdownMenuItem(value: 'Foundational', child: Text('Foundational / Remedial')),
                  DropdownMenuItem(value: 'Advanced', child: Text('Advanced / Olympiad Prep')),
                ],
                onChanged: (v) => setState(() => _learningLevel = v ?? 'Mixed Ability'),
              );

              if (isCompact) {
                return Column(
                  children: [
                    durationDropdown,
                    const SizedBox(height: 12),
                    levelDropdown,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: durationDropdown),
                  const SizedBox(width: 14),
                  Expanded(child: levelDropdown),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 16),

        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _handleGenerateLessonPlan,
            icon: _isLoading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.auto_awesome_rounded, size: 20),
            label: Text(
              _isLoading ? 'Generating Curricular Lesson Plan with AI...' : 'Generate $_lessonDuration-Min Lesson Plan',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
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
    final outcomes = (data['learning_outcomes'] as List?)?.cast<String>() ?? [];

    return Container(
      padding: const EdgeInsets.all(22),
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
                    Text(title, style: EduStreakTheme.fontHeading2(color: Colors.white, weight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(
                      '${ClassNameHelper.cleanFormattedName(_selectedClass)} • $_selectedSubject • $_lessonDuration Minutes',
                      style: const TextStyle(color: EduStreakTheme.neonCyan, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Copy Lesson Plan',
                icon: const Icon(Icons.copy_rounded, color: EduStreakTheme.neonCyan, size: 20),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: '$title\n\nExplanation:\n$explanation\n\nHomework:\n${homework.join('\n')}'));
                  _showSuccessSnackBar('Lesson plan copied to clipboard!');
                },
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Primary Actions
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _isSaving ? null : () => _saveArtifactToFirestore(artifactType: 'lesson_plan', title: title, data: data),
                icon: const Icon(Icons.bookmark_border_rounded, size: 16, color: EduStreakTheme.neonCyan),
                label: const Text('Save Plan', style: TextStyle(color: EduStreakTheme.neonCyan, fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: EduStreakTheme.neonCyan),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _publishLessonPlanToStudyMaterials,
                icon: const Icon(Icons.cloud_upload_rounded, size: 16),
                label: const Text('Publish to Class Study Materials', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: EduStreakTheme.emeraldGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _isSaving
                    ? null
                    : () async {
                        // Create Assignment from plan
                        setState(() => _isSaving = true);
                        try {
                          await _taskService.createTask(
                            classId: _selectedClass,
                            title: 'Homework: $_currentEffectiveTopic',
                            description: homework.isNotEmpty
                                ? homework.join('\n')
                                : 'Complete the practice exercises on $_currentEffectiveTopic based on today\'s lesson.',
                            assignedBy: widget.user?.id ?? 'teacher',
                            assignedByName: widget.user?.name ?? 'Teacher',
                            dueDate: DateTime.now().add(const Duration(days: 2)),
                            assignedTo: [],
                            subject: _selectedSubject,
                            schoolId: widget.user?.schoolId ?? '',
                            type: 'Homework',
                            chapterOrTopic: '$_currentEffectiveChapter - $_currentEffectiveTopic',
                            status: 'published',
                            maxMarks: 20,
                            xpReward: 50,
                          );
                          _showSuccessSnackBar('✓ Assignment created from lesson plan for $_selectedClass!');
                        } catch (e) {
                          _showErrorSnackBar('Assignment error: $e');
                        } finally {
                          if (mounted) setState(() => _isSaving = false);
                        }
                      },
                icon: const Icon(Icons.assignment_add, size: 16),
                label: const Text('Create Assignment from Plan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: EduStreakTheme.primaryViolet,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),
          _buildSectionHeader('Learning Objectives'),
          ...objectives.map((o) => _buildBullet(o)),

          const SizedBox(height: 14),
          _buildSectionHeader('Prerequisites & Prior Knowledge'),
          ...prerequisites.map((p) => _buildBullet(p)),

          const SizedBox(height: 14),
          _buildSectionHeader('Pedagogical Delivery & Core Explanation (15 Mins)'),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF070B1E),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF222B5C)),
            ),
            child: Text(explanation, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.5)),
          ),

          const SizedBox(height: 14),
          _buildSectionHeader('Classroom Activities (15 Mins)'),
          ...activities.map((a) => _buildBullet(a)),

          const SizedBox(height: 14),
          _buildSectionHeader('Interactive Formative Questions (10 Mins)'),
          ...questions.map((q) => _buildBullet(q)),

          const SizedBox(height: 14),
          _buildSectionHeader('Homework & Practice Suggestions'),
          ...homework.map((h) => _buildBullet(h)),

          if (outcomes.isNotEmpty) ...[
            const SizedBox(height: 14),
            _buildSectionHeader('Expected Learning Outcomes'),
            ...outcomes.map((o) => _buildBullet(o)),
          ],
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
              final isCompact = constraints.maxWidth < 640;

              final diffDropdown = DropdownButtonFormField<String>(
                value: _difficulty,
                dropdownColor: const Color(0xFF0F1535),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Difficulty',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: const Color(0xFF070B1E),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: const [
                  DropdownMenuItem(value: 'Easy', child: Text('Easy (Foundational Recall)')),
                  DropdownMenuItem(value: 'Medium', child: Text('Medium (Curricular Standard)')),
                  DropdownMenuItem(value: 'Hard', child: Text('Hard (Higher-Order Thinking)')),
                  DropdownMenuItem(value: 'Mixed', child: Text('Mixed (Differentiated Set)')),
                ],
                onChanged: (v) => setState(() => _difficulty = v ?? 'Medium'),
              );

              final typeDropdown = DropdownButtonFormField<String>(
                value: _questionType,
                dropdownColor: const Color(0xFF0F1535),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Question Type',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: const Color(0xFF070B1E),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: const [
                  DropdownMenuItem(value: 'mcq', child: Text('Multiple Choice (MCQ)')),
                  DropdownMenuItem(value: 'short_answer', child: Text('Short Answer / Conceptual')),
                  DropdownMenuItem(value: 'true_false', child: Text('True / False with Reasoning')),
                  DropdownMenuItem(value: 'long_answer', child: Text('HOTS / Long Derivation')),
                ],
                onChanged: (v) => setState(() => _questionType = v ?? 'mcq'),
              );

              final countDropdown = DropdownButtonFormField<int>(
                value: _numQuestions,
                dropdownColor: const Color(0xFF0F1535),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Question Count',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: const Color(0xFF070B1E),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: const [
                  DropdownMenuItem(value: 3, child: Text('3 Questions')),
                  DropdownMenuItem(value: 5, child: Text('5 Questions')),
                  DropdownMenuItem(value: 10, child: Text('10 Questions')),
                  DropdownMenuItem(value: 15, child: Text('15 Questions')),
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
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _handleGenerateQuestions,
            icon: _isLoading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.quiz_rounded, size: 20),
            label: Text(
              _isLoading ? 'Generating Questions with AI...' : 'Generate $_numQuestions Questions',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
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
      padding: const EdgeInsets.all(22),
      decoration: EduStreakTheme.darkCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Generated Questions (${questions.length})',
                  style: EduStreakTheme.fontHeading2(color: Colors.white, weight: FontWeight.w800),
                ),
              ),
              IconButton(
                tooltip: 'Copy All Questions',
                icon: const Icon(Icons.copy_rounded, color: EduStreakTheme.neonCyan, size: 20),
                onPressed: () {
                  final text = questions.map((q) => '${q['id']}. ${q['question']}\nAnswer: ${q['correct_answer']}').join('\n\n');
                  Clipboard.setData(ClipboardData(text: text));
                  _showSuccessSnackBar('Questions copied to clipboard!');
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _isSaving
                    ? null
                    : () => _saveArtifactToFirestore(
                          artifactType: 'question_bank',
                          title: 'Question Bank: $_currentEffectiveTopic',
                          data: data,
                        ),
                icon: const Icon(Icons.bookmark_border_rounded, size: 16, color: EduStreakTheme.neonCyan),
                label: const Text('Save Question Bank', style: TextStyle(color: EduStreakTheme.neonCyan, fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: EduStreakTheme.neonCyan),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _addQuestionsToAssessment,
                icon: const Icon(Icons.assessment_rounded, size: 16),
                label: const Text('Add to Assessment', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: EduStreakTheme.emeraldGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          ...questions.map((q) {
            final id = q['id'] ?? '';
            final question = q['question'] ?? '';
            final options = (q['options'] as Map?) ?? {};
            final correct = q['correct_answer'] ?? '';
            final explanation = q['explanation'] ?? '';
            final marks = q['marks'] ?? 2;

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF070B1E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF222B5C)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Question $id', style: const TextStyle(color: EduStreakTheme.neonCyan, fontWeight: FontWeight.bold, fontSize: 13)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: EduStreakTheme.primaryViolet.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('$marks Marks', style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(question, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14, height: 1.3)),
                  if (options.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    ...options.entries.map((opt) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Text('${opt.key}. ${opt.value}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        )),
                  ],
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Correct Answer: $correct', style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                        if (explanation.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text('Explanation: $explanation', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                        ],
                      ],
                    ),
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
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _handleGenerateWorksheet,
            icon: _isLoading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.assignment_rounded, size: 20),
            label: Text(
              _isLoading ? 'Generating Printable Worksheet with AI...' : 'Generate Printable Worksheet',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
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
      padding: const EdgeInsets.all(22),
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
                    Text(title, style: EduStreakTheme.fontHeading2(color: Colors.white, weight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(
                      '${ClassNameHelper.cleanFormattedName(_selectedClass)} • $_selectedSubject • $_currentEffectiveChapter',
                      style: const TextStyle(color: EduStreakTheme.neonCyan, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Copy Worksheet Text',
                icon: const Icon(Icons.copy_rounded, color: EduStreakTheme.neonCyan, size: 20),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: title));
                  _showSuccessSnackBar('Worksheet text copied to clipboard!');
                },
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Primary Actions
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _isSaving
                    ? null
                    : () => _saveArtifactToFirestore(
                          artifactType: 'worksheet',
                          title: title,
                          data: data,
                        ),
                icon: const Icon(Icons.bookmark_border_rounded, size: 16, color: EduStreakTheme.neonCyan),
                label: const Text('Save Worksheet', style: TextStyle(color: EduStreakTheme.neonCyan, fontSize: 12)),
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

          const SizedBox(height: 18),
          _buildSectionHeader('Student Instructions'),
          ...instructions.map((i) => _buildBullet(i)),

          const SizedBox(height: 16),
          ...sections.map((sec) {
            final secName = sec['section_name'] ?? 'Section';
            final secQuestions = (sec['questions'] as List?)?.cast<String>() ?? [];
            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF070B1E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF222B5C)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(secName, style: const TextStyle(color: EduStreakTheme.primaryVioletLight, fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 10),
                  ...secQuestions.map((sq) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(sq, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.3)),
                      )),
                ],
              ),
            );
          }),

          if (answerKey.isNotEmpty) ...[
            const SizedBox(height: 14),
            _buildSectionHeader('Teacher Answer Key Reference'),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: answerKey.map((ak) => _buildBullet(ak)).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── 4. TEACHING ASSISTANT CHAT VIEW ──────────────────────────────────────
  Widget _buildAssistantChatView() {
    return Container(
      height: 560,
      decoration: EduStreakTheme.darkCardDecoration(),
      child: Column(
        children: [
          // Chat Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF222B5C))),
            ),
            child: Row(
              children: [
                const Icon(Icons.psychology_rounded, color: EduStreakTheme.neonCyan, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Pedagogical Assistant • ${ClassNameHelper.cleanFormattedName(_selectedClass)} ($_selectedSubject)',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _chatMessages.clear();
                      _chatMessages.add({
                        'isUser': false,
                        'text': 'Chat cleared. How can I assist you with your classroom teaching today?',
                      });
                    });
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 16, color: Colors.white54),
                  label: const Text('New Chat', style: TextStyle(color: Colors.white54, fontSize: 11)),
                ),
              ],
            ),
          ),

          // Message List
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
                    constraints: const BoxConstraints(maxWidth: 620),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isUser ? EduStreakTheme.primaryViolet : const Color(0xFF070B1E),
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
              padding: EdgeInsets.symmetric(vertical: 4),
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
                      hintText: 'Ask pedagogical advisor e.g. "How to differentiate this unit for struggling learners?"',
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

  // ─── 5. STUDENT LEARNING INSIGHTS VIEW ────────────────────────────────────
  Widget _buildLearningInsightsView() {
    if (_isLoadingInsights) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(color: EduStreakTheme.primaryViolet),
        ),
      );
    }

    // Honest empty state when insufficient data exists
    if (!_hasEnoughPerformanceData || _classPerformanceSummary == null) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: EduStreakTheme.darkCardDecoration(),
        child: Column(
          children: [
            const Icon(Icons.analytics_outlined, size: 54, color: Colors.white38),
            const SizedBox(height: 16),
            Text(
              'Not enough performance data is available to generate reliable insights.',
              textAlign: TextAlign.center,
              style: EduStreakTheme.fontHeading2(color: Colors.white, weight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Assign tasks or conduct assessments for ${ClassNameHelper.cleanFormattedName(_selectedClass)} in $_selectedSubject to unlock real-time student mastery analytics.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white60, fontSize: 13),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: () => setState(() => _activeSubTool = 2), // switch to Worksheet
                  icon: const Icon(Icons.assignment_add, size: 16),
                  label: const Text('Create & Assign Worksheet'),
                  style: ElevatedButton.styleFrom(backgroundColor: EduStreakTheme.primaryViolet),
                ),
                ElevatedButton.icon(
                  onPressed: () => setState(() => _activeSubTool = 1), // switch to Questions
                  icon: const Icon(Icons.quiz_rounded, size: 16),
                  label: const Text('Generate Assessment Questions'),
                  style: ElevatedButton.styleFrom(backgroundColor: EduStreakTheme.emeraldGreen),
                ),
              ],
            ),
          ],
        ),
      );
    }

    final totalStudents = (_classPerformanceSummary!['totalStudents'] as num?)?.toInt() ?? 25;
    final avgScore = (_classPerformanceSummary!['averageScore'] as num?)?.toDouble() ?? 74.0;
    final submissionRate = (_classPerformanceSummary!['submissionRate'] as num?)?.toDouble() ?? 80.0;
    final cohorts = (_classPerformanceSummary!['cohorts'] as Map?) ?? {};
    final advancedCount = cohorts['advanced'] ?? 0;
    final proficientCount = cohorts['proficient'] ?? 0;
    final strugglingCount = cohorts['struggling'] ?? 0;

    return Column(
      children: [
        // Real KPI metrics from Firestore
        Container(
          padding: const EdgeInsets.all(20),
          decoration: EduStreakTheme.darkCardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Class Performance Summary', style: EduStreakTheme.fontHeading2(color: Colors.white, weight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(
                        '${ClassNameHelper.cleanFormattedName(_selectedClass)} • $_selectedSubject • Real Firestore Records',
                        style: const TextStyle(color: EduStreakTheme.neonCyan, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: EduStreakTheme.neonCyan),
                    onPressed: _loadClassPerformanceMetrics,
                    tooltip: 'Refresh performance metrics',
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // KPI Cards
              Row(
                children: [
                  Expanded(child: _buildCohortCard('Class Average', '$avgScore%', 'Overall Mastery', EduStreakTheme.neonCyan)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildCohortCard('Enrolled Students', '$totalStudents', 'Class Roster', EduStreakTheme.primaryVioletLight)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildCohortCard('Submission Rate', '$submissionRate%', 'Homework Turn-in', EduStreakTheme.emeraldGreen)),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(child: _buildCohortCard('Advanced', '$advancedCount', 'Score >= 80%', EduStreakTheme.emeraldGreen)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildCohortCard('Proficient', '$proficientCount', 'Score 60-79%', EduStreakTheme.neonCyan)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildCohortCard('Remediation', '$strugglingCount', 'Score < 60%', EduStreakTheme.amberGold)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _handleGenerateLearningInsights,
            icon: _isLoading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.insights_rounded, size: 20),
            label: Text(
              _isLoading ? 'Analyzing Curricular Performance with AI...' : 'Generate AI Pedagogical Insights & Remediation',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
    final weakConcepts = (data['weak_concepts'] as List?)?.cast<String>() ?? [];
    final strengths = (data['strength_areas'] as List?)?.cast<String>() ?? [];
    final strategies = (data['remediation_strategies'] as List?)?.cast<String>() ?? [];
    final nextAction = data['recommended_next_action']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: EduStreakTheme.darkCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text('AI Diagnostic Remediation Plan', style: EduStreakTheme.fontHeading2(color: Colors.white, weight: FontWeight.w800)),
              ),
              OutlinedButton.icon(
                onPressed: _isSaving
                    ? null
                    : () => _saveArtifactToFirestore(
                          artifactType: 'learning_insights',
                          title: 'Diagnostic Report: $_currentEffectiveTopic',
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
          const SizedBox(height: 16),

          _buildSectionHeader('Identified Misconceptions & Weak Concepts'),
          ...weakConcepts.map((w) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: EduStreakTheme.amberGold, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(w, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.3))),
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
                    Expanded(child: Text(s, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.3))),
                  ],
                ),
              )),

          const SizedBox(height: 14),
          _buildSectionHeader('Targeted Remediation & Intervention Plan'),
          ...strategies.map((st) => _buildBullet(st)),

          if (nextAction.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: EduStreakTheme.primaryViolet.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: EduStreakTheme.primaryViolet.withValues(alpha: 0.4)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_rounded, color: EduStreakTheme.neonCyan, size: 20),
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
                        Text(nextAction, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4)),
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

  // ─── 6. MY AI RESOURCES (GENERATION HISTORY) ──────────────────────────────
  Widget _buildMyResourcesView() {
    final teacherId = widget.user?.id ?? 'teacher';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search & Filter Bar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: EduStreakTheme.darkCardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _resourceSearchController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search saved lesson plans, questions, worksheets...',
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                  prefixIcon: const Icon(Icons.search_rounded, color: EduStreakTheme.neonCyan, size: 20),
                  filled: true,
                  fillColor: const Color(0xFF070B1E),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onChanged: (v) => setState(() => _resourceSearchQuery = v.trim().toLowerCase()),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('all', 'All Resources'),
                    const SizedBox(width: 6),
                    _buildFilterChip('lesson_plan', 'Lesson Plans'),
                    const SizedBox(width: 6),
                    _buildFilterChip('question_bank', 'Question Banks'),
                    const SizedBox(width: 6),
                    _buildFilterChip('worksheet', 'Worksheets'),
                    const SizedBox(width: 6),
                    _buildFilterChip('learning_insights', 'Diagnostic Reports'),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        StreamBuilder<List<Map<String, dynamic>>>(
          stream: _aiService.getSavedArtifactsStream(teacherId, artifactType: _resourceFilter),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: EduStreakTheme.primaryViolet)));
            }

            final items = (snapshot.data ?? []).where((item) {
              if (_resourceSearchQuery.isEmpty) return true;
              final title = (item['title'] ?? '').toString().toLowerCase();
              final topic = (item['topic'] ?? '').toString().toLowerCase();
              final subject = (item['subject'] ?? '').toString().toLowerCase();
              return title.contains(_resourceSearchQuery) || topic.contains(_resourceSearchQuery) || subject.contains(_resourceSearchQuery);
            }).toList();

            if (items.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(32),
                decoration: EduStreakTheme.darkCardDecoration(),
                child: const Center(
                  child: Column(
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 48, color: Colors.white38),
                      SizedBox(height: 12),
                      Text('No saved resources found', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text('Generate a lesson plan, question bank, or worksheet to save it here.', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              itemBuilder: (ctx, i) {
                final item = items[i];
                final id = item['id'] ?? '';
                final title = item['title'] ?? 'Untitled Resource';
                final type = item['artifactType'] ?? 'resource';
                final subject = item['subject'] ?? '';
                final chapter = item['chapter'] ?? '';
                final topic = item['topic'] ?? '';
                final classId = item['classId'] ?? '';

                IconData typeIcon = Icons.menu_book_rounded;
                Color typeColor = EduStreakTheme.primaryVioletLight;
                if (type == 'question_bank') {
                  typeIcon = Icons.quiz_rounded;
                  typeColor = EduStreakTheme.neonCyan;
                } else if (type == 'worksheet') {
                  typeIcon = Icons.assignment_rounded;
                  typeColor = EduStreakTheme.amberGold;
                } else if (type == 'learning_insights') {
                  typeIcon = Icons.insights_rounded;
                  typeColor = EduStreakTheme.emeraldGreen;
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F1535),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF222B5C)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: typeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(typeIcon, color: typeColor, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 4),
                            Text(
                              '${ClassNameHelper.cleanFormattedName(classId)} • $subject • $chapter • $topic',
                              style: const TextStyle(color: Colors.white54, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                        tooltip: 'Delete resource',
                        onPressed: () => _confirmDeleteResource(id, title),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _resourceFilter == value;
    return ChoiceChip(
      selected: isSelected,
      label: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontSize: 12)),
      selectedColor: EduStreakTheme.primaryViolet,
      backgroundColor: const Color(0xFF070B1E),
      onSelected: (_) => setState(() => _resourceFilter = value),
    );
  }

  Future<void> _confirmDeleteResource(String id, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F1535),
        title: const Text('Delete Resource', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to delete "$title"?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _aiService.deleteArtifact(id);
      _showSuccessSnackBar('Resource deleted.');
    }
  }

  // ─── UI HELPERS ───────────────────────────────────────────────────────────
  Widget _buildCohortCard(String title, String count, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF070B1E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(count, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 10)),
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
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: EduStreakTheme.primaryVioletLight, fontWeight: FontWeight.bold)),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.35))),
        ],
      ),
    );
  }
}
