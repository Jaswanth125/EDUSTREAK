import 'package:flutter/material.dart';
import '../../models/curriculum_model.dart';
import '../../models/school_model.dart';
import '../../services/curriculum_service.dart';
import '../../services/school_service.dart';
import '../../utils/edustreak_theme.dart';
import '../../widgets/responsive/responsive_dialog.dart';

class CurriculumBuilderScreen extends StatefulWidget {
  const CurriculumBuilderScreen({super.key});

  @override
  State<CurriculumBuilderScreen> createState() => _CurriculumBuilderScreenState();
}

class _CurriculumBuilderScreenState extends State<CurriculumBuilderScreen> {
  final _curriculumService = CurriculumService();
  final _schoolService = SchoolService();

  String _selectedBoard = 'AP_STATE_GOVT'; // AP_STATE_GOVT, CBSE_CENTRAL, or PRIVATE_CUSTOM
  String? _selectedPrivateSchoolId;

  SubjectCurriculumModel? _selectedSubject;
  ChapterModel? _selectedChapter;

  List<SchoolModel> _privateSchools = [];

  @override
  void initState() {
    super.initState();
    _fetchPrivateSchools();
  }

  Future<void> _fetchPrivateSchools() async {
    final stream = _schoolService.getSchoolsStream(categoryFilter: 'Private');
    final first = await stream.first;
    if (mounted) {
      setState(() {
        _privateSchools = first;
        if (_privateSchools.isNotEmpty) {
          _selectedPrivateSchoolId = _privateSchools.first.id;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF070B1E),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Bar: Title & Scope Selector
          _buildScopeSelector(),

          const SizedBox(height: 20),

          // 3-Pane Curriculum Explorer (Subjects -> Chapters -> Topics)
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 900;
                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Pane 1: Subjects
                      Expanded(flex: 3, child: _buildSubjectsPane()),
                      const SizedBox(width: 16),
                      // Pane 2: Chapters
                      Expanded(flex: 4, child: _buildChaptersPane()),
                      const SizedBox(width: 16),
                      // Pane 3: Topics & Materials
                      Expanded(flex: 4, child: _buildTopicsPane()),
                    ],
                  );
                } else {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 96),
                    child: Column(
                      children: [
                        SizedBox(height: 340, child: _buildSubjectsPane()),
                        const SizedBox(height: 16),
                        SizedBox(height: 340, child: _buildChaptersPane()),
                        const SizedBox(height: 16),
                        SizedBox(height: 380, child: _buildTopicsPane()),
                      ],
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─── SCOPE SELECTOR (AP GOVT vs CBSE vs PRIVATE) ──────────────────────────
  Widget _buildScopeSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1535),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EduStreakTheme.cardBorder),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 12,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Curriculum Governance & Syllabus Architecture',
                style: EduStreakTheme.fontHeading3(color: Colors.white, weight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'Manage standardized SCERT/NCERT frameworks or school-specific autonomous curricula.',
                style: EduStreakTheme.fontCaption(color: EduStreakTheme.textMuted),
              ),
            ],
          ),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Segmented Scope Pill
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF141A42),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF26326E)),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildScopeButton('AP State Govt', 'AP_STATE_GOVT', Icons.account_balance_rounded),
                      _buildScopeButton('CBSE Central', 'CBSE_CENTRAL', Icons.school_rounded),
                      _buildScopeButton('Private Schools', 'PRIVATE_CUSTOM', Icons.apartment_rounded),
                    ],
                  ),
                ),

                if (_selectedBoard == 'PRIVATE_CUSTOM' && _privateSchools.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141A42),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: EduStreakTheme.primaryViolet),
                    ),
                    child: DropdownButton<String>(
                      value: _selectedPrivateSchoolId ?? _privateSchools.first.id,
                      dropdownColor: const Color(0xFF141A42),
                      underline: const SizedBox(),
                      icon: const Icon(Icons.arrow_drop_down_rounded, color: Colors.white),
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                      items: _privateSchools.map((s) {
                        return DropdownMenuItem(
                          value: s.id,
                          child: Text(s.name, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedPrivateSchoolId = val;
                            _selectedSubject = null;
                            _selectedChapter = null;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScopeButton(String label, String value, IconData icon) {
    final isSelected = _selectedBoard == value;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedBoard = value;
          _selectedSubject = null;
          _selectedChapter = null;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? EduStreakTheme.primaryViolet : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.white60),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── PANE 1: SUBJECTS ─────────────────────────────────────────────────────
  Widget _buildSubjectsPane() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1535),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EduStreakTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.menu_book_rounded, color: EduStreakTheme.primaryVioletLight, size: 18),
                  const SizedBox(width: 8),
                  Text('1. Subjects', style: EduStreakTheme.fontHeading3(color: Colors.white, weight: FontWeight.w700)),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded, color: EduStreakTheme.neonCyan, size: 22),
                tooltip: 'Add Subject',
                onPressed: _showAddSubjectDialog,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFF222B5C)),
          const SizedBox(height: 12),
          Expanded(
            child: _selectedBoard == 'PRIVATE_CUSTOM' && _selectedPrivateSchoolId != null
                ? StreamBuilder<List<SubjectCurriculumModel>>(
                    stream: _curriculumService.getPrivateSchoolCurriculumStream(_selectedPrivateSchoolId!),
                    builder: (context, snapshot) {
                      final subjects = snapshot.data ?? [];
                      return _renderSubjectList(subjects);
                    },
                  )
                : StreamBuilder<CurriculumTemplateModel?>(
                    stream: _curriculumService.getTemplate(_selectedBoard).asStream(),
                    builder: (context, snapshot) {
                      final subjects = snapshot.data?.standardSubjects ?? [];
                      return _renderSubjectList(subjects);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _renderSubjectList(List<SubjectCurriculumModel> subjects) {
    if (subjects.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_stories_outlined, size: 38, color: Colors.white24),
            const SizedBox(height: 8),
            Text('No subjects configured', style: EduStreakTheme.fontCaption(color: Colors.white60)),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _showAddSubjectDialog,
              style: OutlinedButton.styleFrom(foregroundColor: EduStreakTheme.neonCyan),
              child: const Text('Add First Subject'),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: subjects.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final subj = subjects[index];
        final isSelected = _selectedSubject?.id == subj.id;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedSubject = subj;
                _selectedChapter = subj.chapters.isNotEmpty ? subj.chapters.first : null;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? EduStreakTheme.primaryViolet.withValues(alpha: 0.2) : const Color(0xFF141A42),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? EduStreakTheme.primaryViolet : const Color(0xFF222B5C),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Color(subj.colorValue),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(subj.name, style: EduStreakTheme.fontLabel(color: Colors.white, weight: FontWeight.w700)),
                        Text('${subj.code} • ${subj.chapters.length} Chapters', style: EduStreakTheme.fontCaption(color: EduStreakTheme.textMuted)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Colors.white38, size: 18),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── PANE 2: CHAPTERS ─────────────────────────────────────────────────────
  Widget _buildChaptersPane() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1535),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EduStreakTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.format_list_numbered_rounded, color: EduStreakTheme.neonCyan, size: 18),
                  const SizedBox(width: 8),
                  Text('2. Chapters', style: EduStreakTheme.fontHeading3(color: Colors.white, weight: FontWeight.w700)),
                ],
              ),
              if (_selectedSubject != null)
                IconButton(
                  icon: const Icon(Icons.add_circle_outline_rounded, color: EduStreakTheme.neonCyan, size: 22),
                  tooltip: 'Add Chapter to ${_selectedSubject!.name}',
                  onPressed: _showAddChapterDialog,
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFF222B5C)),
          const SizedBox(height: 12),
          Expanded(
            child: _selectedSubject == null
                ? Center(
                    child: Text(
                      'Select a Subject from the left pane to view its chapters.',
                      style: EduStreakTheme.fontCaption(color: Colors.white54),
                      textAlign: TextAlign.center,
                    ),
                  )
                : _selectedSubject!.chapters.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.list_alt_rounded, size: 36, color: Colors.white24),
                            const SizedBox(height: 8),
                            Text('No chapters in ${_selectedSubject!.name}', style: EduStreakTheme.fontCaption(color: Colors.white60)),
                            const SizedBox(height: 8),
                            OutlinedButton(
                              onPressed: _showAddChapterDialog,
                              child: const Text('Add Chapter 1'),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: _selectedSubject!.chapters.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final ch = _selectedSubject!.chapters[index];
                          final isSelected = _selectedChapter?.id == ch.id;

                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                setState(() => _selectedChapter = ch);
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isSelected ? EduStreakTheme.primaryViolet.withValues(alpha: 0.2) : const Color(0xFF141A42),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? EduStreakTheme.primaryViolet : const Color(0xFF222B5C),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 14,
                                      backgroundColor: EduStreakTheme.primaryViolet.withValues(alpha: 0.3),
                                      child: Text(
                                        '${ch.chapterNumber}',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(ch.title, style: EduStreakTheme.fontLabel(color: Colors.white, weight: FontWeight.w700)),
                                          Text('${ch.topics.length} Topics', style: EduStreakTheme.fontCaption(color: EduStreakTheme.textMuted)),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right_rounded, color: Colors.white38, size: 18),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  // ─── PANE 3: TOPICS & MATERIALS ───────────────────────────────────────────
  Widget _buildTopicsPane() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1535),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EduStreakTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.topic_rounded, color: Color(0xFF10B981), size: 18),
                  const SizedBox(width: 8),
                  Text('3. Topics & Materials', style: EduStreakTheme.fontHeading3(color: Colors.white, weight: FontWeight.w700)),
                ],
              ),
              if (_selectedChapter != null)
                IconButton(
                  icon: const Icon(Icons.add_circle_outline_rounded, color: EduStreakTheme.neonCyan, size: 22),
                  tooltip: 'Add Topic to ${_selectedChapter!.title}',
                  onPressed: _showAddTopicDialog,
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFF222B5C)),
          const SizedBox(height: 12),
          Expanded(
            child: _selectedChapter == null
                ? Center(
                    child: Text(
                      'Select a Chapter in the middle pane to view its topics.',
                      style: EduStreakTheme.fontCaption(color: Colors.white54),
                      textAlign: TextAlign.center,
                    ),
                  )
                : _selectedChapter!.topics.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.assignment_turned_in_outlined, size: 36, color: Colors.white24),
                            const SizedBox(height: 8),
                            Text('No topics configured in Chapter ${_selectedChapter!.chapterNumber}', style: EduStreakTheme.fontCaption(color: Colors.white60)),
                            const SizedBox(height: 8),
                            OutlinedButton(
                              onPressed: _showAddTopicDialog,
                              child: const Text('Add Topic'),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: _selectedChapter!.topics.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final topic = _selectedChapter!.topics[index];

                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF141A42),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF222B5C)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_outline_rounded, size: 18, color: Color(0xFF10B981)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(topic.title, style: EduStreakTheme.fontLabel(color: Colors.white, weight: FontWeight.w700)),
                                      Text('Duration: ~${topic.estimatedMinutes} mins • Order: ${topic.order}',
                                          style: EduStreakTheme.fontCaption(color: EduStreakTheme.textMuted)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: EduStreakTheme.primaryViolet.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text('AI Synced', style: TextStyle(color: EduStreakTheme.primaryVioletLight, fontSize: 11)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  // ─── DIALOGS ──────────────────────────────────────────────────────────────
  void _showAddSubjectDialog() {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();

    showAdaptiveEduStreakModal(
      context: context,
      maxWidth: 480,
      title: 'Add New Subject',
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Subject Name (e.g. Physics)')),
            const SizedBox(height: 12),
            TextField(controller: codeCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Subject Code (e.g. PHY-10)')),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final subj = SubjectCurriculumModel(
                  id: 'subj_${DateTime.now().millisecondsSinceEpoch}',
                  name: nameCtrl.text.trim(),
                  code: codeCtrl.text.trim().toUpperCase(),
                  colorValue: 0xFF3B82F6,
                  chapters: [],
                );

                if (_selectedBoard == 'PRIVATE_CUSTOM' && _selectedPrivateSchoolId != null) {
                  await _curriculumService.savePrivateSchoolSubject(_selectedPrivateSchoolId!, subj);
                } else {
                  await _curriculumService.addSubjectToTemplate(_selectedBoard, subj);
                }

                if (ctx.mounted) Navigator.of(ctx).pop();
                setState(() => _selectedSubject = subj);
              },
              style: ElevatedButton.styleFrom(backgroundColor: EduStreakTheme.primaryViolet),
              child: const Text('Add Subject'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddChapterDialog() {
    if (_selectedSubject == null) return;
    final titleCtrl = TextEditingController();
    final numberCtrl = TextEditingController(text: '${_selectedSubject!.chapters.length + 1}');

    showAdaptiveEduStreakModal(
      context: context,
      maxWidth: 480,
      title: 'Add Chapter to ${_selectedSubject!.name}',
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Chapter Title (e.g. Thermodynamics)')),
            const SizedBox(height: 12),
            TextField(controller: numberCtrl, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Chapter Number')),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final newChapter = ChapterModel(
                  id: 'ch_${DateTime.now().millisecondsSinceEpoch}',
                  chapterNumber: int.tryParse(numberCtrl.text.trim()) ?? 1,
                  title: titleCtrl.text.trim(),
                  topics: [],
                );

                final updatedChapters = List<ChapterModel>.from(_selectedSubject!.chapters)..add(newChapter);
                final updatedSubject = SubjectCurriculumModel(
                  id: _selectedSubject!.id,
                  name: _selectedSubject!.name,
                  code: _selectedSubject!.code,
                  colorValue: _selectedSubject!.colorValue,
                  chapters: updatedChapters,
                );

                if (_selectedBoard == 'PRIVATE_CUSTOM' && _selectedPrivateSchoolId != null) {
                  await _curriculumService.savePrivateSchoolSubject(_selectedPrivateSchoolId!, updatedSubject);
                } else {
                  await _curriculumService.updateTemplateSubject(_selectedBoard, updatedSubject);
                }

                if (ctx.mounted) Navigator.of(ctx).pop();
                setState(() {
                  _selectedSubject = updatedSubject;
                  _selectedChapter = newChapter;
                });
              },
              style: ElevatedButton.styleFrom(backgroundColor: EduStreakTheme.primaryViolet),
              child: const Text('Save Chapter'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTopicDialog() {
    if (_selectedSubject == null || _selectedChapter == null) return;
    final titleCtrl = TextEditingController();
    final minCtrl = TextEditingController(text: '20');

    showAdaptiveEduStreakModal(
      context: context,
      maxWidth: 480,
      title: 'Add Topic to ${_selectedChapter!.title}',
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Topic Title (e.g. Laws of Heat Transfer)')),
            const SizedBox(height: 12),
            TextField(controller: minCtrl, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Estimated Minutes')),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final newTopic = TopicModel(
                  id: 'top_${DateTime.now().millisecondsSinceEpoch}',
                  order: _selectedChapter!.topics.length + 1,
                  title: titleCtrl.text.trim(),
                  estimatedMinutes: int.tryParse(minCtrl.text.trim()) ?? 20,
                );

                final updatedTopics = List<TopicModel>.from(_selectedChapter!.topics)..add(newTopic);
                final updatedChapter = ChapterModel(
                  id: _selectedChapter!.id,
                  chapterNumber: _selectedChapter!.chapterNumber,
                  title: _selectedChapter!.title,
                  topics: updatedTopics,
                );

                final updatedChapters = _selectedSubject!.chapters.map((c) => c.id == updatedChapter.id ? updatedChapter : c).toList();
                final updatedSubject = SubjectCurriculumModel(
                  id: _selectedSubject!.id,
                  name: _selectedSubject!.name,
                  code: _selectedSubject!.code,
                  colorValue: _selectedSubject!.colorValue,
                  chapters: updatedChapters,
                );

                if (_selectedBoard == 'PRIVATE_CUSTOM' && _selectedPrivateSchoolId != null) {
                  await _curriculumService.savePrivateSchoolSubject(_selectedPrivateSchoolId!, updatedSubject);
                } else {
                  await _curriculumService.updateTemplateSubject(_selectedBoard, updatedSubject);
                }

                if (ctx.mounted) Navigator.of(ctx).pop();
                setState(() {
                  _selectedSubject = updatedSubject;
                  _selectedChapter = updatedChapter;
                });
              },
              style: ElevatedButton.styleFrom(backgroundColor: EduStreakTheme.primaryViolet),
              child: const Text('Add Topic'),
            ),
          ],
        ),
      ),
    );
  }
}
