import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/assessment_model.dart';
import '../../models/user_model.dart';
import '../../services/assessment_service.dart';
import '../../services/teacher_ai_hub_service.dart';
import '../../utils/edustreak_theme.dart';
import '../../utils/class_name_helper.dart';

class TeacherAssessmentsTab extends StatefulWidget {
  final UserModel? user;
  final Stream<List<AssessmentModel>>? assessmentsStream;

  const TeacherAssessmentsTab({super.key, this.user, this.assessmentsStream});

  @override
  State<TeacherAssessmentsTab> createState() => _TeacherAssessmentsTabState();
}

class _TeacherAssessmentsTabState extends State<TeacherAssessmentsTab> {
  final AssessmentService _assessmentService = AssessmentService();
  final TeacherAiHubService _aiService = TeacherAiHubService();

  String _selectedClassFilter = 'All';
  String _selectedTypeFilter = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final teacherId = widget.user?.id ?? '';
    final classes = _safeClasses;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── 1. HEADER SECTION ──────────────────────────────────────────
          _buildHeader(),

          const SizedBox(height: 20),

          // ─── 2. LIVE ASSESSMENTS STREAM & METRICS ───────────────────────
          StreamBuilder<List<AssessmentModel>>(
            stream: widget.assessmentsStream ??
                _assessmentService.getAssessmentsStream(
                  teacherId: teacherId,
                  classId: _selectedClassFilter == 'All' ? null : _selectedClassFilter,
                ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: EduStreakTheme.primaryViolet),
                  ),
                );
              }

              final allAssessments = snapshot.data ?? [];

              // Calculate Metrics
              final total = allAssessments.length;
              final published = allAssessments.where((a) => a.status == 'published').length;
              final drafts = allAssessments.where((a) => a.status == 'draft').length;
              final completed = allAssessments.where((a) => a.status == 'closed' || (a.submissions.isNotEmpty && a.scores.length == a.submissions.length)).length;

              // Filter by type and search query
              final filtered = allAssessments.where((a) {
                if (_selectedTypeFilter != 'All' && a.type.toLowerCase() != _selectedTypeFilter.toLowerCase()) {
                  return false;
                }
                if (_searchQuery.isNotEmpty) {
                  final query = _searchQuery.toLowerCase();
                  final titleMatch = a.title.toLowerCase().contains(query);
                  final subjectMatch = a.subject.toLowerCase().contains(query);
                  final topicMatch = a.topic.toLowerCase().contains(query);
                  final chapterMatch = a.chapter.toLowerCase().contains(query);
                  return titleMatch || subjectMatch || topicMatch || chapterMatch;
                }
                return true;
              }).toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // KPI Cards
                  _buildMetricCards(total: total, published: published, drafts: drafts, completed: completed),

                  const SizedBox(height: 20),

                  // Search & Filters
                  _buildSearchAndFilters(classes),

                  const SizedBox(height: 20),

                  // Assessments List
                  if (filtered.isEmpty)
                    _buildEmptyState()
                  else
                    ...filtered.map((assessment) => _buildAssessmentCard(assessment)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ─── HEADER ───────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 620;

        final titleRow = Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: EduStreakTheme.neonCyan.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: EduStreakTheme.neonCyan.withValues(alpha: 0.35)),
              ),
              child: const Icon(Icons.quiz_rounded, color: EduStreakTheme.neonCyan, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Assessments & Tests',
                    style: EduStreakTheme.fontHeading1(color: Colors.white, weight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Create, schedule, evaluate, and track student syllabus mastery.',
                    style: EduStreakTheme.fontBody(color: EduStreakTheme.darkTextSub),
                  ),
                ],
              ),
            ),
          ],
        );

        final createBtn = ElevatedButton.icon(
          onPressed: _openCreateAssessmentModal,
          icon: const Icon(Icons.add_task_rounded, size: 18),
          label: const Text('Create Assessment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          style: ElevatedButton.styleFrom(
            backgroundColor: EduStreakTheme.primaryViolet,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );

        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleRow,
              const SizedBox(height: 14),
              createBtn,
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: titleRow),
            const SizedBox(width: 14),
            createBtn,
          ],
        );
      },
    );
  }

  // ─── KPI METRIC CARDS ─────────────────────────────────────────────────────
  Widget _buildMetricCards({
    required int total,
    required int published,
    required int drafts,
    required int completed,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 650;
        final cards = [
          _buildKpiCard('Total Assessments', total.toString(), Icons.folder_open_rounded, EduStreakTheme.neonCyan),
          _buildKpiCard('Published & Active', published.toString(), Icons.check_circle_outline_rounded, EduStreakTheme.emeraldGreen),
          _buildKpiCard('Drafts in Progress', drafts.toString(), Icons.edit_note_rounded, EduStreakTheme.amberGold),
          _buildKpiCard('Evaluated / Done', completed.toString(), Icons.verified_rounded, EduStreakTheme.primaryVioletLight),
        ];

        if (isNarrow) {
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: cards.map((c) => SizedBox(width: (constraints.maxWidth - 12) / 2, child: c)).toList(),
          );
        }

        return Row(
          children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 5), child: c))).toList(),
        );
      },
    );
  }

  Widget _buildKpiCard(String title, String count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1535),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count,
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                ),
                Text(
                  title,
                  style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── SEARCH & FILTER CONTROLS ─────────────────────────────────────────────
  Widget _buildSearchAndFilters(List<String> classes) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 680;

        final searchBar = TextField(
          controller: _searchController,
          onChanged: (v) => setState(() => _searchQuery = v.trim()),
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Search assessments by title, topic, or subject...',
            hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
            prefixIcon: const Icon(Icons.search_rounded, color: Colors.white54, size: 18),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, color: Colors.white54, size: 16),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            filled: true,
            fillColor: const Color(0xFF0F1535),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF222B5C))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF222B5C))),
          ),
        );

        final classDropdown = Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1535),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF222B5C)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedClassFilter,
              dropdownColor: const Color(0xFF0F1535),
              style: const TextStyle(color: Colors.white, fontSize: 13),
              icon: const Icon(Icons.arrow_drop_down_rounded, color: Colors.white70),
              items: ['All', ...classes].map((c) {
                final display = c == 'All' ? 'All Classes' : ClassNameHelper.formatClassNameSync(c, fallback: 'Class 8A');
                return DropdownMenuItem(value: c, child: Text(display));
              }).toList(),
              onChanged: (v) => setState(() => _selectedClassFilter = v ?? 'All'),
            ),
          ),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isCompact) ...[
              searchBar,
              const SizedBox(height: 10),
              classDropdown,
            ] else ...[
              Row(
                children: [
                  Expanded(child: searchBar),
                  const SizedBox(width: 12),
                  classDropdown,
                ],
              ),
            ],
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTypeFilterChip('All'),
                  const SizedBox(width: 8),
                  _buildTypeFilterChip('Quiz'),
                  const SizedBox(width: 8),
                  _buildTypeFilterChip('Unit_Test', label: 'Unit Test'),
                  const SizedBox(width: 8),
                  _buildTypeFilterChip('Practice_Test', label: 'Practice Test'),
                  const SizedBox(width: 8),
                  _buildTypeFilterChip('Chapter_Test', label: 'Chapter Test'),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTypeFilterChip(String key, {String? label}) {
    final isSelected = _selectedTypeFilter.toLowerCase() == key.toLowerCase();
    final displayText = label ?? key;

    return InkWell(
      onTap: () => setState(() => _selectedTypeFilter = key),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? EduStreakTheme.primaryViolet : const Color(0xFF0F1535),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? EduStreakTheme.primaryVioletLight : const Color(0xFF222B5C),
          ),
        ),
        child: Text(
          displayText,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ─── ASSESSMENT CARD ──────────────────────────────────────────────────────
  Widget _buildAssessmentCard(AssessmentModel a) {
    final isDraft = a.status == 'draft';
    final typeBadgeColor = _getTypeBadgeColor(a.type);
    final questionsCount = a.questions.length;
    final submittedCount = a.submissions.length;
    final evaluatedCount = a.scores.length;
    final dueDateFormatted = DateFormat('MMM d, y • h:mm a').format(a.dueDate);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1535),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF222B5C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Badges & Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: typeBadgeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: typeBadgeColor.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      a.type.replaceAll('_', ' ').toUpperCase(),
                      style: TextStyle(color: typeBadgeColor, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDraft ? Colors.amber.withValues(alpha: 0.15) : EduStreakTheme.emeraldGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isDraft ? Colors.amber.withValues(alpha: 0.4) : EduStreakTheme.emeraldGreen.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      isDraft ? 'DRAFT' : 'PUBLISHED',
                      style: TextStyle(
                        color: isDraft ? Colors.amberAccent : EduStreakTheme.emeraldGreen,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: Colors.white60, size: 18),
                color: const Color(0xFF0F1535),
                onSelected: (val) {
                  if (val == 'publish') {
                    _assessmentService.publishAssessment(a.id);
                  } else if (val == 'delete') {
                    _confirmDeleteAssessment(a);
                  }
                },
                itemBuilder: (ctx) => [
                  if (isDraft)
                    const PopupMenuItem(value: 'publish', child: Text('Publish Assessment', style: TextStyle(color: Colors.greenAccent, fontSize: 13))),
                  const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.redAccent, fontSize: 13))),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Title & Description
          Text(
            a.title,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
          ),
          if (a.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              a.description,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          const SizedBox(height: 12),

          // Metadata Chips (Class, Subject, Duration, Marks)
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _buildMetaPill(Icons.school_rounded, ClassNameHelper.formatClassNameSync(a.classId, fallback: 'Class 8A')),
              _buildMetaPill(Icons.menu_book_rounded, a.subject),
              _buildMetaPill(Icons.timer_outlined, '${a.durationMinutes} mins'),
              _buildMetaPill(Icons.stars_rounded, '${a.totalMarks} Marks'),
              _buildMetaPill(Icons.format_list_numbered_rounded, '$questionsCount Questions'),
            ],
          ),

          const SizedBox(height: 14),

          // Progress & Due Date Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Due: $dueDateFormatted',
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                'Submissions: $submittedCount ($evaluatedCount Graded)',
                style: const TextStyle(color: EduStreakTheme.neonCyan, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Action Buttons
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: () => _openGradingModal(a),
                icon: const Icon(Icons.rate_review_rounded, size: 15),
                label: const Text('Submissions & Grading', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: EduStreakTheme.primaryViolet,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              if (isDraft)
                OutlinedButton.icon(
                  onPressed: () => _assessmentService.publishAssessment(a.id),
                  icon: const Icon(Icons.send_rounded, size: 15, color: EduStreakTheme.emeraldGreen),
                  label: const Text('Publish Now', style: TextStyle(color: EduStreakTheme.emeraldGreen, fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: EduStreakTheme.emeraldGreen),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetaPill(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.white54),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Color _getTypeBadgeColor(String type) {
    switch (type.toLowerCase()) {
      case 'quiz':
        return EduStreakTheme.neonCyan;
      case 'unit_test':
        return EduStreakTheme.primaryVioletLight;
      case 'practice_test':
        return EduStreakTheme.emeraldGreen;
      case 'chapter_test':
        return EduStreakTheme.amberGold;
      default:
        return const Color(0xFFC4B5FD);
    }
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1535),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF222B5C)),
      ),
      child: Column(
        children: [
          const Icon(Icons.assignment_turned_in_rounded, size: 48, color: Colors.white30),
          const SizedBox(height: 12),
          const Text(
            'No assessments match your current filter.',
            style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          const Text(
            'Create a new quiz or unit test with 1-click AI generation.',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _openCreateAssessmentModal,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Create Assessment Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: EduStreakTheme.primaryViolet,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  // ─── MODAL: CREATE ASSESSMENT WORKFLOW ────────────────────────────────────
  Future<void> _openCreateAssessmentModal() async {
    final classes = _safeClasses;
    final subjects = _safeSubjects;

    final titleController = TextEditingController();
    final descController = TextEditingController();
    final chapterController = TextEditingController(text: 'Cell Biology');
    final topicController = TextEditingController(text: 'Cell Division');
    final marksController = TextEditingController(text: '25');
    final durationController = TextEditingController(text: '45');

    String selectedClass = classes.first;
    String selectedSubject = subjects.first;
    String selectedType = 'quiz';
    DateTime dueDate = DateTime.now().add(const Duration(days: 3));

    final List<AssessmentQuestion> questions = [];
    bool isGeneratingAi = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0C1030),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) {
          return DraggableScrollableSheet(
            initialChildSize: 0.88,
            maxChildSize: 0.95,
            minChildSize: 0.6,
            expand: false,
            builder: (_, scrollController) => Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: ListView(
                controller: scrollController,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Create New Assessment',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white54),
                        onPressed: () => Navigator.pop(modalCtx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Metadata Form
                  TextField(
                    controller: titleController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(labelText: 'Assessment Title (e.g. Unit Test 1: Cell Biology)'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(labelText: 'Instructions / Description'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedClass,
                          dropdownColor: const Color(0xFF0F1535),
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: const InputDecoration(labelText: 'Target Class'),
                          items: classes
                              .map((c) => DropdownMenuItem(value: c, child: Text(ClassNameHelper.formatClassNameSync(c, fallback: 'Class 8A'))))
                              .toList(),
                          onChanged: (v) => setModalState(() => selectedClass = v ?? selectedClass),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedSubject,
                          dropdownColor: const Color(0xFF0F1535),
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: const InputDecoration(labelText: 'Subject'),
                          items: subjects.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                          onChanged: (v) => setModalState(() => selectedSubject = v ?? selectedSubject),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedType,
                          dropdownColor: const Color(0xFF0F1535),
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: const InputDecoration(labelText: 'Assessment Type'),
                          items: const [
                            DropdownMenuItem(value: 'quiz', child: Text('Quick Quiz')),
                            DropdownMenuItem(value: 'unit_test', child: Text('Unit Test')),
                            DropdownMenuItem(value: 'practice_test', child: Text('Practice Test')),
                            DropdownMenuItem(value: 'chapter_test', child: Text('Chapter Test')),
                          ],
                          onChanged: (v) => setModalState(() => selectedType = v ?? 'quiz'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: marksController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: const InputDecoration(labelText: 'Total Marks'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: durationController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: const InputDecoration(labelText: 'Duration (Mins)'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Questions Builder Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Questions (${questions.length})',
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      ElevatedButton.icon(
                        onPressed: isGeneratingAi
                            ? null
                            : () async {
                                setModalState(() => isGeneratingAi = true);
                                try {
                                  final formattedClass = ClassNameHelper.formatClassNameSync(selectedClass, fallback: 'Class 8A');
                                  final res = await _aiService.generateQuestions(
                                    gradeOrClass: formattedClass,
                                    subject: selectedSubject,
                                    chapter: chapterController.text.trim().isNotEmpty ? chapterController.text.trim() : 'Unit 1',
                                    topic: topicController.text.trim().isNotEmpty ? topicController.text.trim() : 'Core Concept',
                                    numQuestions: 5,
                                  );

                                  final rawQs = (res['questions'] as List?) ?? [];
                                  final newQs = rawQs.map((q) => AssessmentQuestion.fromMap(Map<String, dynamic>.from(q as Map))).toList();

                                  setModalState(() {
                                    questions.addAll(newQs);
                                    isGeneratingAi = false;
                                  });
                                } catch (_) {
                                  setModalState(() => isGeneratingAi = false);
                                }
                              },
                        icon: isGeneratingAi
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.auto_awesome_rounded, size: 14),
                        label: Text(isGeneratingAi ? 'Generating...' : 'AI Generate 5 Questions', style: const TextStyle(fontSize: 11)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: EduStreakTheme.neonCyan.withValues(alpha: 0.2),
                          foregroundColor: EduStreakTheme.neonCyan,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  if (questions.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F1535),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF222B5C)),
                      ),
                      child: const Text('No questions added yet. Use AI Generate or create manually.', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    )
                  else
                    ...questions.asMap().entries.map((entry) {
                      final i = entry.key;
                      final q = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F1535),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF222B5C)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Q${i + 1}.', style: const TextStyle(color: EduStreakTheme.neonCyan, fontWeight: FontWeight.bold, fontSize: 12)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(q.question, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                                  if (q.options.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text('Options: ${q.options.values.join(" • ")}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                                    ),
                                  Text('Key: ${q.correctAnswer} (${q.marks} Marks)', style: const TextStyle(color: Colors.greenAccent, fontSize: 11)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 16),
                              onPressed: () => setModalState(() => questions.removeAt(i)),
                            ),
                          ],
                        ),
                      );
                    }),

                  const SizedBox(height: 24),

                  // Actions: Save Draft vs Publish
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final finalTitle = titleController.text.trim().isNotEmpty ? titleController.text.trim() : 'Quiz on ${topicController.text.trim()}';
                            final assessment = AssessmentModel(
                              id: '',
                              classId: selectedClass,
                              subject: selectedSubject,
                              chapter: chapterController.text.trim(),
                              topic: topicController.text.trim(),
                              title: finalTitle,
                              description: descController.text.trim(),
                              type: selectedType,
                              status: 'draft',
                              totalMarks: int.tryParse(marksController.text.trim()) ?? 25,
                              durationMinutes: int.tryParse(durationController.text.trim()) ?? 45,
                              scheduledDate: DateTime.now(),
                              dueDate: dueDate,
                              createdAt: DateTime.now(),
                              createdBy: widget.user?.id ?? '',
                              createdByName: widget.user?.name ?? 'Teacher',
                              questions: questions,
                            );
                            await _assessmentService.createAssessment(assessment);
                            Navigator.pop(modalCtx);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✓ Assessment saved as draft!')));
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: EduStreakTheme.neonCyan),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Save Draft', style: TextStyle(color: EduStreakTheme.neonCyan, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final finalTitle = titleController.text.trim().isNotEmpty ? titleController.text.trim() : 'Quiz on ${topicController.text.trim()}';
                            final assessment = AssessmentModel(
                              id: '',
                              classId: selectedClass,
                              subject: selectedSubject,
                              chapter: chapterController.text.trim(),
                              topic: topicController.text.trim(),
                              title: finalTitle,
                              description: descController.text.trim(),
                              type: selectedType,
                              status: 'published',
                              totalMarks: int.tryParse(marksController.text.trim()) ?? 25,
                              durationMinutes: int.tryParse(durationController.text.trim()) ?? 45,
                              scheduledDate: DateTime.now(),
                              dueDate: dueDate,
                              createdAt: DateTime.now(),
                              createdBy: widget.user?.id ?? '',
                              createdByName: widget.user?.name ?? 'Teacher',
                              questions: questions,
                            );
                            await _assessmentService.createAssessment(assessment);
                            Navigator.pop(modalCtx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(backgroundColor: EduStreakTheme.emeraldGreen, content: Text('✓ Assessment successfully published to class!')),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: EduStreakTheme.primaryViolet,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Publish Immediately', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── MODAL: STUDENT SUBMISSIONS & GRADING ─────────────────────────────────
  Future<void> _openGradingModal(AssessmentModel assessment) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0C1030),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.6,
        expand: false,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(assessment.title, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                        Text('Submissions Evaluation • Max: ${assessment.totalMarks} Marks', style: const TextStyle(color: EduStreakTheme.neonCyan, fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white54),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Roster Stream for Class
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .where('classId', isEqualTo: assessment.classId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final students = snapshot.data?.docs ?? [];
                    if (students.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(30),
                        alignment: Alignment.center,
                        child: const Text('No students currently enrolled in this class.', style: TextStyle(color: Colors.white54)),
                      );
                    }

                    return ListView.builder(
                      controller: scrollController,
                      itemCount: students.length,
                      itemBuilder: (context, i) {
                        final sData = students[i].data() as Map<String, dynamic>;
                        final sId = students[i].id;
                        final sName = sData['name'] ?? 'Student ${i + 1}';
                        final sRoll = sData['rollNumber'] ?? (i + 1).toString();
                        final isSubmitted = assessment.submissions.containsKey(sId);
                        final currentScore = assessment.scores[sId];
                        final feedback = assessment.feedback[sId] ?? '';

                        final scoreController = TextEditingController(
                          text: currentScore != null ? currentScore.toStringAsFixed(0) : '',
                        );
                        final feedbackController = TextEditingController(text: feedback);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F1535),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: currentScore != null
                                  ? EduStreakTheme.emeraldGreen.withValues(alpha: 0.4)
                                  : (isSubmitted ? EduStreakTheme.neonCyan.withValues(alpha: 0.4) : const Color(0xFF222B5C)),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 14,
                                        backgroundColor: EduStreakTheme.primaryViolet,
                                        child: Text(sName[0].toUpperCase(), style: const TextStyle(fontSize: 11, color: Colors.white)),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(sName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                      const SizedBox(width: 6),
                                      Text('(#$sRoll)', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: currentScore != null
                                          ? EduStreakTheme.emeraldGreen.withValues(alpha: 0.15)
                                          : (isSubmitted ? EduStreakTheme.neonCyan.withValues(alpha: 0.15) : Colors.white10),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      currentScore != null ? 'GRADED: ${currentScore.toStringAsFixed(0)}/${assessment.totalMarks}' : (isSubmitted ? 'SUBMITTED' : 'PENDING'),
                                      style: TextStyle(
                                        color: currentScore != null ? EduStreakTheme.emeraldGreen : (isSubmitted ? EduStreakTheme.neonCyan : Colors.white54),
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  SizedBox(
                                    width: 90,
                                    height: 38,
                                    child: TextField(
                                      controller: scoreController,
                                      keyboardType: TextInputType.number,
                                      style: const TextStyle(color: Colors.white, fontSize: 12),
                                      decoration: InputDecoration(
                                        labelText: 'Score / ${assessment.totalMarks}',
                                        labelStyle: const TextStyle(fontSize: 10),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: SizedBox(
                                      height: 38,
                                      child: TextField(
                                        controller: feedbackController,
                                        style: const TextStyle(color: Colors.white, fontSize: 12),
                                        decoration: const InputDecoration(
                                          hintText: 'Feedback / Rubric Notes...',
                                          hintStyle: TextStyle(color: Colors.white38, fontSize: 11),
                                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: () async {
                                      final score = double.tryParse(scoreController.text.trim()) ?? 0.0;
                                      await _assessmentService.gradeStudentSubmission(
                                        assessmentId: assessment.id,
                                        studentId: sId,
                                        score: score,
                                        feedback: feedbackController.text.trim(),
                                      );
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('✓ Grade saved for $sName!')),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: EduStreakTheme.primaryViolet,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    ),
                                    child: const Text('Save', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteAssessment(AssessmentModel a) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F1535),
        title: const Text('Delete Assessment?', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to delete "${a.title}"? This cannot be undone.', style: const TextStyle(color: Colors.white70)),
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
      await _assessmentService.deleteAssessment(a.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Assessment deleted.')));
      }
    }
  }
}
