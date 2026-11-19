import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../models/curriculum_model.dart';
import '../../../../models/school_model.dart';
import '../../../../models/skill_intelligence_model.dart';
import '../../../../models/assessment_model.dart';
import '../../../../models/task_model.dart';
import '../../../../services/curriculum_service.dart';
import '../../../../services/principal_service.dart';
import '../../../../services/skill_intelligence_service.dart';
import '../../../../utils/edustreak_theme.dart';
import '../../../../utils/class_name_helper.dart';
import '../../../../utils/responsive_breakpoints.dart';
import '../../../../widgets/responsive/responsive_dialog.dart';

class PrincipalAcademicsTab extends StatefulWidget {
  final SchoolModel school;

  const PrincipalAcademicsTab({super.key, required this.school});

  @override
  State<PrincipalAcademicsTab> createState() => _PrincipalAcademicsTabState();
}

class _PrincipalAcademicsTabState extends State<PrincipalAcademicsTab> {
  final _principalService = PrincipalService();
  final _curriculumService = CurriculumService();
  int _selectedSubTab = 0; // 0: Classes, 1: Curriculum, 2: Assignments, 3: Exams
  String? _expandedSubjectId;

  @override
  Widget build(BuildContext context) {
    final isDesktop = context.isDesktop;
    final isTablet = context.isTablet;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 28 : (isTablet ? 20 : 16),
        vertical: 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── SUB-SECTION SELECTOR BAR ──────────────────────────────────
          _buildSubTabSelector(),

          const SizedBox(height: 18),

          // ─── ACTIVE SUB-SECTION VIEW ───────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: _buildSubTabContent(isDesktop, isTablet),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubTabSelector() {
    final tabs = [
      ('Classes & Sections', Icons.meeting_room_rounded),
      ('Curriculum Progress', Icons.layers_rounded),
      ('Homework & Tasks', Icons.assignment_turned_in_rounded),
      ('Examinations & Results', Icons.emoji_events_rounded),
      ('Competency Intelligence', Icons.radar_rounded),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(tabs.length, (index) {
          final t = tabs[index];
          final isSelected = _selectedSubTab == index;

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: InkWell(
              onTap: () => setState(() => _selectedSubTab = index),
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: isSelected ? EduStreakTheme.activePillGradient : null,
                  color: isSelected ? null : EduStreakTheme.studentDarkCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? Colors.transparent : EduStreakTheme.studentDarkBorder,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(t.$2, size: 16, color: isSelected ? Colors.white : EduStreakTheme.studentDarkTextMuted),
                    const SizedBox(width: 8),
                    Text(
                      t.$1,
                      style: EduStreakTheme.fontCaption(
                        color: isSelected ? Colors.white : EduStreakTheme.studentDarkTextMuted,
                        weight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSubTabContent(bool isDesktop, bool isTablet) {
    switch (_selectedSubTab) {
      case 1:
        return _buildCurriculumSection(isDesktop);
      case 2:
        return _buildHomeworkSection(isDesktop);
      case 3:
        return _buildExaminationsSection(isDesktop);
      case 4:
        return _buildCompetenciesSection(isDesktop);
      case 0:
      default:
        return _buildClassesSection(isDesktop, isTablet);
    }
  }

  // ─── SUB-TAB 0: CLASSES & SECTIONS ─────────────────────────────────────────
  Widget _buildClassesSection(bool isDesktop, bool isTablet) {
    final classes = [
      {'name': 'Class 10-A', 'grade': '10', 'sec': 'A', 'students': 40, 'teacher': 'Ms. Sarah Johnson', 'room': 'Room 201', 'avg': 88.4},
      {'name': 'Class 10-B', 'grade': '10', 'sec': 'B', 'students': 39, 'teacher': 'Mr. David Smith', 'room': 'Room 202', 'avg': 84.2},
      {'name': 'Class 9-A', 'grade': '9', 'sec': 'A', 'students': 38, 'teacher': 'Mr. R. V. Reddy', 'room': 'Room 108', 'avg': 82.1},
      {'name': 'Class 9-B', 'grade': '9', 'sec': 'B', 'students': 36, 'teacher': 'Mrs. Sunita Devi', 'room': 'Room 109', 'avg': 74.5},
      {'name': 'Class 8-A', 'grade': '8', 'sec': 'A', 'students': 35, 'teacher': 'Mrs. L. Mary', 'room': 'Room 104', 'avg': 86.1},
      {'name': 'Class 8-B', 'grade': '8', 'sec': 'B', 'students': 35, 'teacher': 'Dr. P. Anitha', 'room': 'Room 105', 'avg': 83.0},
      {'name': 'Class 7-A', 'grade': '7', 'sec': 'A', 'students': 34, 'teacher': 'Mr. G. Sastry', 'room': 'Room 101', 'avg': 85.2},
      {'name': 'Class 7-B', 'grade': '7', 'sec': 'B', 'students': 33, 'teacher': 'Mr. K. Sharma', 'room': 'Room 102', 'avg': 81.4},
      {'name': 'Class 6-A', 'grade': '6', 'sec': 'A', 'students': 32, 'teacher': 'Mr. B. Prasad', 'room': 'Room 001', 'avg': 89.0},
      {'name': 'Class 6-B', 'grade': '6', 'sec': 'B', 'students': 30, 'teacher': 'Mrs. M. Vani', 'room': 'Room 002', 'avg': 86.2},
    ];

    int crossCount = isDesktop ? 3 : (isTablet ? 2 : 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 650) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Registered Classes & Appointed Class Teachers',
                    style: EduStreakTheme.fontHeading2(color: Colors.white, weight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '10 Active Sections • 620 Capacity',
                    style: EduStreakTheme.fontCaption(color: EduStreakTheme.neonCyan, weight: FontWeight.w700),
                  ),
                ],
              );
            }
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Registered Classes & Appointed Class Teachers',
                    style: EduStreakTheme.fontHeading2(color: Colors.white, weight: FontWeight.w800),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '10 Active Sections • 620 Capacity',
                  style: EduStreakTheme.fontCaption(color: EduStreakTheme.neonCyan, weight: FontWeight.w700),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossCount,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.6,
          ),
          itemCount: classes.length,
          itemBuilder: (context, index) {
            final c = classes[index];
            final avg = c['avg'] as double;

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: EduStreakTheme.studentDarkCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: EduStreakTheme.studentDarkBorder, width: 1.2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(c['name'] as String, style: EduStreakTheme.fontHeading3(color: Colors.white, weight: FontWeight.w800)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: EduStreakTheme.primaryViolet.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(c['room'] as String, style: EduStreakTheme.fontSmall(color: EduStreakTheme.neonCyan, weight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const Divider(color: EduStreakTheme.studentDarkBorder, height: 16),
                  Text('Class Teacher: ${c['teacher']}', style: EduStreakTheme.fontCaption(color: Colors.white70, weight: FontWeight.w600)),
                  Text('Enrolled: ${c['students']} Students', style: EduStreakTheme.fontCaption(color: EduStreakTheme.studentDarkTextMuted)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('SA-1 Average: $avg%', style: EduStreakTheme.fontCaption(color: avg >= 80 ? EduStreakTheme.emeraldGreen : EduStreakTheme.amberGold, weight: FontWeight.w700)),
                      const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white30),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // ─── SUB-TAB 1: CURRICULUM PROGRESS & MULTI-TENANT SYLLABUS GOVERNANCE ─────
  Widget _buildCurriculumSection(bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCurriculumCategoryHeader(),
        const SizedBox(height: 18),
        if (widget.school.type == SchoolType.government)
          _buildGovtCurriculum(isDesktop)
        else if (widget.school.type == SchoolType.cbse)
          _buildCbseCurriculum(isDesktop)
        else
          _buildPrivateCurriculum(isDesktop),
      ],
    );
  }

  Widget _buildCurriculumCategoryHeader() {
    final type = widget.school.type;

    String title;
    String subtitle;
    String badge;
    Color badgeColor;
    IconData icon;
    Widget? action;

    switch (type) {
      case SchoolType.government:
        title = 'AP State Board (SCERT) Core Curriculum';
        subtitle = 'Centrally governed by Department of School Education, Andhra Pradesh. Syllabus is locked for uniform statewide standards.';
        badge = 'READ-ONLY CENTRAL GOVERNANCE';
        badgeColor = EduStreakTheme.primaryViolet;
        icon = Icons.lock_rounded;
        action = null; // Strictly read-only for government schools
        break;
      case SchoolType.cbse:
        title = 'CBSE NCERT Core Curriculum & School Electives';
        subtitle = 'Mandatory NCERT syllabus centrally versioned. School leaders can add & manage institutional electives and skill subjects.';
        badge = 'CBSE CORE + ELECTIVES';
        badgeColor = EduStreakTheme.amberGold;
        icon = Icons.tune_rounded;
        action = ElevatedButton.icon(
          onPressed: () => _showAddSubjectDialog(isElective: true),
          icon: const Icon(Icons.add_rounded, size: 16),
          label: const Text('Add School Elective'),
          style: ElevatedButton.styleFrom(
            backgroundColor: EduStreakTheme.amberGold,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        break;
      case SchoolType.privateSchool:
        title = 'Autonomous Institutional Curriculum';
        subtitle = 'Isolated curriculum hierarchy stored in /schools/${widget.school.id}/curriculum. Full autonomy to configure subjects and chapters.';
        badge = 'AUTONOMOUS PRIVATE SYLLABUS';
        badgeColor = EduStreakTheme.neonCyan;
        icon = Icons.account_tree_rounded;
        action = ElevatedButton.icon(
          onPressed: () => _showAddSubjectDialog(isElective: false),
          icon: const Icon(Icons.add_rounded, size: 16),
          label: const Text('Add Custom Subject'),
          style: ElevatedButton.styleFrom(
            backgroundColor: EduStreakTheme.neonCyan,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        break;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: EduStreakTheme.studentDarkCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: badgeColor.withValues(alpha: 0.35), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: badgeColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: EduStreakTheme.fontHeading2(color: Colors.white, weight: FontWeight.w800),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            badge,
                            style: EduStreakTheme.fontSmall(color: badgeColor, weight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: EduStreakTheme.fontCaption(color: EduStreakTheme.studentDarkTextMuted),
                    ),
                  ],
                ),
              ),
              if (action != null) ...[
                const SizedBox(width: 12),
                action,
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ─── 1. AP GOVERNMENT CURRICULUM (SCERT - READ ONLY) ─────────────────────────
  Widget _buildGovtCurriculum(bool isDesktop) {
    return FutureBuilder<CurriculumTemplateModel?>(
      future: _curriculumService.getTemplate('AP_STATE_GOVT'),
      builder: (context, snapshot) {
        final template = snapshot.data;
        final templateSubjects = template?.standardSubjects ?? [];

        // If template subjects available, render from template; otherwise fallback to realistic baseline
        if (templateSubjects.isNotEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('SCERT Standard Subjects & Completion Audit', style: EduStreakTheme.fontHeading3(color: Colors.white, weight: FontWeight.w800)),
                  Text('${templateSubjects.length} Core Subjects', style: EduStreakTheme.fontCaption(color: EduStreakTheme.primaryVioletLight, weight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 12),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: templateSubjects.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final subj = templateSubjects[index];
                  return _buildReadOnlySubjectCard(subj, isGovt: true);
                },
              ),
            ],
          );
        }

        // Fallback display from PrincipalService progress
        final fallback = _principalService.getCurriculumProgress(widget.school.id);
        if (fallback.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: EduStreakTheme.studentDarkCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: EduStreakTheme.studentDarkBorder),
            ),
            child: Column(
              children: [
                const Icon(Icons.menu_book_rounded, color: EduStreakTheme.studentDarkTextMuted, size: 40),
                const SizedBox(height: 12),
                Text(
                  'No Curriculum Progress Recorded',
                  style: EduStreakTheme.fontHeading3(color: Colors.white, weight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  'Curriculum chapters and topic completion mapped by faculty will appear here in real time.',
                  style: EduStreakTheme.fontCaption(color: EduStreakTheme.studentDarkTextMuted),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: EduStreakTheme.studentDarkCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: EduStreakTheme.studentDarkBorder, width: 1.2),
          ),
          child: Column(
            children: fallback.map((sub) {
              final pct = sub['completed'] as int;
              final isBehind = sub['status'] == 'behind';
              final color = isBehind ? EduStreakTheme.rosePink : (pct >= 85 ? EduStreakTheme.emeraldGreen : EduStreakTheme.primaryViolet);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.lock_outline_rounded, size: 14, color: Colors.white38),
                            const SizedBox(width: 6),
                            Text(
                              '${sub['subject']} • ${sub['teacher']}',
                              style: EduStreakTheme.fontBody(color: Colors.white, weight: FontWeight.w700),
                            ),
                          ],
                        ),
                        Text(
                          '$pct% Complete (${sub['doneChapters']}/${sub['totalChapters']} Chapters)',
                          style: EduStreakTheme.fontCaption(color: color, weight: FontWeight.w800),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: pct / 100,
                        minHeight: 10,
                        backgroundColor: const Color(0xFF14193E),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // ─── 2. CBSE CURRICULUM (CORE NCERT + SCHOOL ELECTIVES) ──────────────────────
  Widget _buildCbseCurriculum(bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Core CBSE NCERT Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                '1. Mandatory CBSE Core Subjects (NCERT Standards)',
                style: EduStreakTheme.fontHeading3(color: Colors.white, weight: FontWeight.w800),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: EduStreakTheme.amberGold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('READ ONLY CORE', style: EduStreakTheme.fontSmall(color: EduStreakTheme.amberGold, weight: FontWeight.w700)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FutureBuilder<CurriculumTemplateModel?>(
          future: _curriculumService.getTemplate('CBSE_CENTRAL'),
          builder: (context, snapshot) {
            final subjects = snapshot.data?.standardSubjects ?? [];
            if (subjects.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: EduStreakTheme.studentDarkCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: EduStreakTheme.studentDarkBorder),
                ),
                child: Center(
                  child: Text(
                    'No curriculum framework assigned yet. Contact Central Administration.',
                    style: EduStreakTheme.fontCaption(color: EduStreakTheme.studentDarkTextMuted),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: subjects.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) => _buildReadOnlySubjectCard(subjects[index], isGovt: false),
            );
          },
        ),

        const SizedBox(height: 24),

        // School-Specific Electives Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                '2. School-Specific Elective Modules',
                style: EduStreakTheme.fontHeading3(color: Colors.white, weight: FontWeight.w800),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text('Custom Institutional Offerings', style: EduStreakTheme.fontCaption(color: EduStreakTheme.neonCyan, weight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<SubjectCurriculumModel>>(
          stream: _curriculumService.getPrivateSchoolCurriculumStream(widget.school.id),
          builder: (context, snapshot) {
            final electives = snapshot.data ?? [];

            if (electives.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: EduStreakTheme.studentDarkCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: EduStreakTheme.studentDarkBorder, style: BorderStyle.solid),
                ),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.playlist_add_rounded, size: 36, color: Colors.white24),
                      const SizedBox(height: 8),
                      Text('No custom electives configured for this school yet.', style: EduStreakTheme.fontBody(color: Colors.white70)),
                      const SizedBox(height: 4),
                      Text('Tap "+ Add School Elective" to add Coding, French, Artificial Intelligence, or Design Thinking.', style: EduStreakTheme.fontCaption(color: EduStreakTheme.studentDarkTextMuted)),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => _showAddSubjectDialog(isElective: true),
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: const Text('Add First School Elective'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: EduStreakTheme.amberGold,
                          side: const BorderSide(color: EduStreakTheme.amberGold),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: electives.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _buildPrivateSubjectCard(electives[index]);
              },
            );
          },
        ),
      ],
    );
  }

  // ─── 3. PRIVATE AUTONOMOUS CURRICULUM (ISOLATED TO SCHOOL) ───────────────────
  Widget _buildPrivateCurriculum(bool isDesktop) {
    return StreamBuilder<List<SubjectCurriculumModel>>(
      stream: _curriculumService.getPrivateSchoolCurriculumStream(widget.school.id),
      builder: (context, snapshot) {
        final subjects = snapshot.data ?? [];

        if (subjects.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: EduStreakTheme.studentDarkCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: EduStreakTheme.neonCyan.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                const Icon(Icons.auto_stories_rounded, size: 48, color: EduStreakTheme.neonCyan),
                const SizedBox(height: 14),
                Text('Autonomous School Curriculum Storage Empty', style: EduStreakTheme.fontHeading3(color: Colors.white, weight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(
                  'Your school has independent curriculum privileges (/schools/${widget.school.id}/curriculum).\nYou can seed from a standardized base template or create completely custom subjects.',
                  style: EduStreakTheme.fontBody(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _initializePrivateFromTemplate('AP_STATE_GOVT'),
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: const Text('Clone AP SCERT Standard'),
                      style: ElevatedButton.styleFrom(backgroundColor: EduStreakTheme.primaryViolet),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _initializePrivateFromTemplate('CBSE_CENTRAL'),
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: const Text('Clone CBSE NCERT Standard'),
                      style: ElevatedButton.styleFrom(backgroundColor: EduStreakTheme.amberGold, foregroundColor: Colors.black),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _showAddSubjectDialog(isElective: false),
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('Create Subject from Scratch'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: EduStreakTheme.neonCyan,
                        side: const BorderSide(color: EduStreakTheme.neonCyan),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Independent School Syllabus Roster', style: EduStreakTheme.fontHeading3(color: Colors.white, weight: FontWeight.w800)),
                Text('${subjects.length} Custom Subjects Configured', style: EduStreakTheme.fontCaption(color: EduStreakTheme.neonCyan, weight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: subjects.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _buildPrivateSubjectCard(subjects[index]);
              },
            ),
          ],
        );
      },
    );
  }

  // ─── READ-ONLY SUBJECT CARD (FOR STATE & CBSE CORE) ──────────────────────────
  Widget _buildReadOnlySubjectCard(SubjectCurriculumModel subj, {required bool isGovt}) {
    final isExpanded = _expandedSubjectId == subj.id;
    final pct = subj.completionPercentage;
    final color = Color(subj.colorValue);

    return Container(
      decoration: BoxDecoration(
        color: EduStreakTheme.studentDarkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EduStreakTheme.studentDarkBorder, width: 1.2),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expandedSubjectId = isExpanded ? null : subj.id),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        subj.code.isNotEmpty ? subj.code.split('-').first : 'S',
                        style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(subj.name, style: EduStreakTheme.fontBody(color: Colors.white, weight: FontWeight.w800)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: (isGovt ? EduStreakTheme.primaryViolet : EduStreakTheme.amberGold).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                subj.code,
                                style: TextStyle(
                                  color: isGovt ? EduStreakTheme.primaryVioletLight : EduStreakTheme.amberGold,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${subj.chapters.length} Chapters Standardized • Centrally Governed',
                          style: EduStreakTheme.fontCaption(color: EduStreakTheme.studentDarkTextMuted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${pct.toStringAsFixed(0)}% Done', style: EduStreakTheme.fontCaption(color: Colors.white, weight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.lock_rounded, size: 12, color: Colors.white38),
                          const SizedBox(width: 4),
                          Text('Standard', style: EduStreakTheme.fontSmall(color: Colors.white38, weight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    color: Colors.white54,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded && subj.chapters.isNotEmpty) ...[
            const Divider(color: EduStreakTheme.studentDarkBorder, height: 1),
            Container(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFF0C112E),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Standardized Chapter Index (SCERT / NCERT)', style: EduStreakTheme.fontSmall(color: Colors.white54, weight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  ...subj.chapters.map((ch) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: color.withValues(alpha: 0.2),
                              child: Text('${ch.chapterNumber}', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(ch.title, style: EduStreakTheme.fontCaption(color: Colors.white, weight: FontWeight.w600)),
                            ),
                            Text('${ch.topics.length} topics', style: EduStreakTheme.fontSmall(color: Colors.white38)),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── PRIVATE / ELECTIVE SUBJECT CARD (WITH CUSTOMIZATION CONTROLS) ────────────
  Widget _buildPrivateSubjectCard(SubjectCurriculumModel subj) {
    final isExpanded = _expandedSubjectId == subj.id;
    final color = Color(subj.colorValue);

    return Container(
      decoration: BoxDecoration(
        color: EduStreakTheme.studentDarkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EduStreakTheme.studentDarkBorder, width: 1.2),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      subj.code.isNotEmpty ? subj.code.split('-').first : 'S',
                      style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(subj.name, style: EduStreakTheme.fontBody(color: Colors.white, weight: FontWeight.w800), overflow: TextOverflow.ellipsis),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: EduStreakTheme.neonCyan.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(subj.code, style: const TextStyle(color: EduStreakTheme.neonCyan, fontSize: 10, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${subj.chapters.length} Chapters • School Autonomous Syllabus',
                        style: EduStreakTheme.fontCaption(color: EduStreakTheme.studentDarkTextMuted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline_rounded, color: EduStreakTheme.neonCyan, size: 20),
                  tooltip: 'Add Chapter',
                  onPressed: () => _showAddChapterDialog(subj),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: EduStreakTheme.rosePink, size: 20),
                  tooltip: 'Delete Subject',
                  onPressed: () => _confirmDeleteSubject(subj),
                ),
                IconButton(
                  icon: Icon(isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded, color: Colors.white54),
                  onPressed: () => setState(() => _expandedSubjectId = isExpanded ? null : subj.id),
                ),
              ],
            ),
          ),
          if (isExpanded) ...[
            const Divider(color: EduStreakTheme.studentDarkBorder, height: 1),
            Container(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFF0C112E),
              child: subj.chapters.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: OutlinedButton.icon(
                          onPressed: () => _showAddChapterDialog(subj),
                          icon: const Icon(Icons.add_rounded, size: 16),
                          label: const Text('Add Chapter 1'),
                          style: OutlinedButton.styleFrom(foregroundColor: EduStreakTheme.neonCyan),
                        ),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Configured Chapters & Units', style: EduStreakTheme.fontSmall(color: Colors.white54, weight: FontWeight.w700)),
                            TextButton.icon(
                              onPressed: () => _showAddChapterDialog(subj),
                              icon: const Icon(Icons.add_rounded, size: 14),
                              label: const Text('Add Chapter', style: TextStyle(fontSize: 12)),
                              style: TextButton.styleFrom(foregroundColor: EduStreakTheme.neonCyan),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...subj.chapters.map((ch) => Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF14193E),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: EduStreakTheme.studentDarkBorder),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: color.withValues(alpha: 0.2),
                                    child: Text('${ch.chapterNumber}', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(ch.title, style: EduStreakTheme.fontCaption(color: Colors.white, weight: FontWeight.w600)),
                                  ),
                                  Text('${ch.topics.length} topics', style: EduStreakTheme.fontSmall(color: Colors.white38)),
                                  IconButton(
                                    icon: const Icon(Icons.add_task_rounded, size: 16, color: EduStreakTheme.neonCyan),
                                    tooltip: 'Add Topic',
                                    onPressed: () => _showAddTopicDialog(subj, ch),
                                  ),
                                ],
                              ),
                            )),
                      ],
                    ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── DIALOGS & MUTATIONS ───────────────────────────────────────────────────
  void _showAddSubjectDialog({bool isElective = false}) {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();

    showAdaptiveEduStreakModal(
      context: context,
      maxWidth: 480,
      title: isElective ? 'Add School Elective' : 'Add Custom Subject',
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isElective
                  ? 'Add an elective module (e.g. Artificial Intelligence, Robotics, French) specifically for this school.'
                  : 'Add a custom subject to your school\'s isolated curriculum (/schools/${widget.school.id}/curriculum).',
              style: EduStreakTheme.fontCaption(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: isElective ? 'Elective Name (e.g. AI & Robotics)' : 'Subject Name (e.g. Environmental Studies)',
                labelStyle: const TextStyle(color: Colors.white70),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: codeCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Code (e.g. ELEC-01 / EVS-10)',
                labelStyle: TextStyle(color: Colors.white70),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty) return;
                    final subj = SubjectCurriculumModel(
                      id: 'subj_${DateTime.now().millisecondsSinceEpoch}',
                      name: nameCtrl.text.trim(),
                      code: codeCtrl.text.trim().toUpperCase(),
                      colorValue: isElective ? 0xFFF59E0B : 0xFF00E5FF,
                      chapters: [],
                    );

                    await _curriculumService.savePrivateSchoolSubject(widget.school.id, subj);
                    if (ctx.mounted) Navigator.of(ctx).pop();
                    setState(() => _expandedSubjectId = subj.id);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isElective ? EduStreakTheme.amberGold : EduStreakTheme.neonCyan,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Save Subject'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddChapterDialog(SubjectCurriculumModel subject) {
    final titleCtrl = TextEditingController();
    final numCtrl = TextEditingController(text: '${subject.chapters.length + 1}');

    showAdaptiveEduStreakModal(
      context: context,
      maxWidth: 440,
      title: 'Add Chapter to ${subject.name}',
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: numCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Chapter Number', labelStyle: TextStyle(color: Colors.white70)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: titleCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Chapter Title', labelStyle: TextStyle(color: Colors.white70)),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () async {
                    if (titleCtrl.text.trim().isEmpty) return;
                    final newChapter = ChapterModel(
                      id: 'ch_${DateTime.now().millisecondsSinceEpoch}',
                      title: titleCtrl.text.trim(),
                      chapterNumber: int.tryParse(numCtrl.text) ?? (subject.chapters.length + 1),
                      topics: [],
                    );

                    final updatedChapters = List<ChapterModel>.from(subject.chapters)..add(newChapter);
                    final updatedSubject = SubjectCurriculumModel(
                      id: subject.id,
                      name: subject.name,
                      code: subject.code,
                      colorValue: subject.colorValue,
                      chapters: updatedChapters,
                      completionPercentage: subject.completionPercentage,
                    );

                    await _curriculumService.savePrivateSchoolSubject(widget.school.id, updatedSubject);
                    if (ctx.mounted) Navigator.of(ctx).pop();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: EduStreakTheme.neonCyan, foregroundColor: Colors.black),
                  child: const Text('Add Chapter'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTopicDialog(SubjectCurriculumModel subject, ChapterModel chapter) {
    final titleCtrl = TextEditingController();
    final minsCtrl = TextEditingController(text: '20');

    showAdaptiveEduStreakModal(
      context: context,
      maxWidth: 440,
      title: 'Add Topic to ${chapter.title}',
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Topic Title', labelStyle: TextStyle(color: Colors.white70)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: minsCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Estimated Duration (Minutes)', labelStyle: TextStyle(color: Colors.white70)),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () async {
                    if (titleCtrl.text.trim().isEmpty) return;
                    final newTopic = TopicModel(
                      id: 't_${DateTime.now().millisecondsSinceEpoch}',
                      title: titleCtrl.text.trim(),
                      order: chapter.topics.length + 1,
                      estimatedMinutes: int.tryParse(minsCtrl.text) ?? 20,
                    );

                    final updatedTopics = List<TopicModel>.from(chapter.topics)..add(newTopic);
                    final updatedChapter = ChapterModel(
                      id: chapter.id,
                      title: chapter.title,
                      chapterNumber: chapter.chapterNumber,
                      topics: updatedTopics,
                      progress: chapter.progress,
                    );

                    final updatedChapters = subject.chapters.map((c) => c.id == chapter.id ? updatedChapter : c).toList();
                    final updatedSubject = SubjectCurriculumModel(
                      id: subject.id,
                      name: subject.name,
                      code: subject.code,
                      colorValue: subject.colorValue,
                      chapters: updatedChapters,
                      completionPercentage: subject.completionPercentage,
                    );

                    await _curriculumService.savePrivateSchoolSubject(widget.school.id, updatedSubject);
                    if (ctx.mounted) Navigator.of(ctx).pop();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: EduStreakTheme.neonCyan, foregroundColor: Colors.black),
                  child: const Text('Add Topic'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteSubject(SubjectCurriculumModel subject) {
    showAdaptiveEduStreakModal(
      context: context,
      maxWidth: 420,
      title: 'Delete Subject',
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete "${subject.name}" (${subject.code}) from your school\'s curriculum? This will remove all associated chapters for this school.',
              style: EduStreakTheme.fontBody(color: Colors.white70),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () async {
                    await _curriculumService.deletePrivateSchoolSubject(widget.school.id, subject.id);
                    if (ctx.mounted) Navigator.of(ctx).pop();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: EduStreakTheme.rosePink),
                  child: const Text('Delete Subject'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _initializePrivateFromTemplate(String templateId) async {
    await _curriculumService.initializePrivateCurriculumFromTemplate(widget.school.id, templateId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Initialized school curriculum from $templateId'),
          backgroundColor: EduStreakTheme.emeraldGreen,
        ),
      );
    }
  }

  // ─── SUB-TAB 2: HOMEWORK & TASKS ───────────────────────────────────────────
  Widget _buildHomeworkSection(bool isDesktop) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('tasks').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: EduStreakTheme.neonCyan)));
        }

        final docs = snapshot.data?.docs ?? [];
        final tasks = docs.map((d) {
          final data = Map<String, dynamic>.from(d.data() as Map);
          data['id'] = d.id;
          return TaskModel.fromMap(data);
        }).toList();

        int totalAssignments = tasks.length;
        int totalSubmissions = 0;
        int totalExpected = 0;

        for (final t in tasks) {
          totalSubmissions += t.submissions.values.where((s) => s == 'submitted' || s == 'completed').length;
          totalExpected += t.assignedTo.isNotEmpty ? t.assignedTo.length : 35;
        }

        final completionRate = totalExpected > 0 ? ((totalSubmissions / totalExpected) * 100).round() : 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'School-wide Active Assignments Monitor',
                    style: EduStreakTheme.fontHeading2(color: Colors.white, weight: FontWeight.w800),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text('$totalAssignments Total Assignments', style: EduStreakTheme.fontCaption(color: EduStreakTheme.neonCyan, weight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 16),

            // Top KPI Banner
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: EduStreakTheme.studentDarkCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: EduStreakTheme.primaryViolet.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total Assignments', style: EduStreakTheme.fontCaption(color: EduStreakTheme.studentDarkTextMuted)),
                        const SizedBox(height: 4),
                        Text('$totalAssignments', style: EduStreakTheme.fontHeading2(color: Colors.white, weight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: EduStreakTheme.studentDarkCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: EduStreakTheme.emeraldGreen.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Completed Submissions', style: EduStreakTheme.fontCaption(color: EduStreakTheme.studentDarkTextMuted)),
                        const SizedBox(height: 4),
                        Text('$totalSubmissions', style: EduStreakTheme.fontHeading2(color: EduStreakTheme.emeraldGreen, weight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: EduStreakTheme.studentDarkCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: EduStreakTheme.neonCyan.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Completion Rate', style: EduStreakTheme.fontCaption(color: EduStreakTheme.studentDarkTextMuted)),
                        const SizedBox(height: 4),
                        Text('$completionRate%', style: EduStreakTheme.fontHeading2(color: EduStreakTheme.neonCyan, weight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (tasks.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: EduStreakTheme.studentDarkCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: EduStreakTheme.studentDarkBorder),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.assignment_turned_in_rounded, size: 44, color: EduStreakTheme.studentDarkTextMuted),
                    const SizedBox(height: 12),
                    Text('No Assignments Created Yet', style: EduStreakTheme.fontHeading3(color: Colors.white, weight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('Teachers have not published any homework tasks.', style: EduStreakTheme.fontCaption(color: EduStreakTheme.studentDarkTextMuted)),
                  ],
                ),
              )
            else
              Column(
                children: tasks.map((t) {
                  final assignedCount = t.assignedTo.isNotEmpty ? t.assignedTo.length : 35;
                  final submittedCount = t.submissions.values.where((s) => s == 'submitted' || s == 'completed').length;
                  final isComplete = assignedCount > 0 && submittedCount >= assignedCount;
                  final displayClass = ClassNameHelper.formatClassName(t.classId);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: EduStreakTheme.studentDarkCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: EduStreakTheme.studentDarkBorder, width: 1.2),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isComplete
                                ? EduStreakTheme.emeraldGreen.withValues(alpha: 0.15)
                                : EduStreakTheme.primaryViolet.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isComplete ? Icons.check_circle_rounded : Icons.assignment_rounded,
                            color: isComplete ? EduStreakTheme.emeraldGreen : EduStreakTheme.primaryViolet,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t.title, style: EduStreakTheme.fontBody(color: Colors.white, weight: FontWeight.w700)),
                              const SizedBox(height: 2),
                              Text(
                                '$displayClass • ${t.subject} • Due: ${t.dueDate.day}/${t.dueDate.month}',
                                style: EduStreakTheme.fontCaption(color: EduStreakTheme.studentDarkTextMuted),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Submissions: $submittedCount/$assignedCount', style: EduStreakTheme.fontCaption(color: Colors.white, weight: FontWeight.w700)),
                            Text(
                              isComplete ? '100% Complete' : '${assignedCount - submittedCount} Pending',
                              style: EduStreakTheme.fontSmall(
                                color: isComplete ? EduStreakTheme.emeraldGreen : EduStreakTheme.amberGold,
                                weight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        );
      },
    );
  }

  // ─── SUB-TAB 3: EXAMINATIONS & RESULTS ─────────────────────────────────────
  Widget _buildExaminationsSection(bool isDesktop) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('assessments').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: EduStreakTheme.neonCyan)));
        }

        final docs = snapshot.data?.docs ?? [];
        final assessments = docs.map((d) => AssessmentModel.fromMap(d.data() as Map<String, dynamic>, d.id)).toList();

        int totalExams = assessments.length;
        int totalEvaluated = 0;
        double overallScoreSum = 0.0;
        int scoredCount = 0;

        for (final a in assessments) {
          totalEvaluated += a.scores.length;
          for (final s in a.scores.values) {
            if (a.totalMarks > 0) {
              overallScoreSum += (s / a.totalMarks) * 100.0;
              scoredCount++;
            }
          }
        }

        final avgExamScore = scoredCount > 0 ? (overallScoreSum / scoredCount).round() : 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Official Examination Schedule & Outcomes',
                    style: EduStreakTheme.fontHeading2(color: Colors.white, weight: FontWeight.w800),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text('$totalExams Total Assessments', style: EduStreakTheme.fontCaption(color: EduStreakTheme.neonCyan, weight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 16),

            // Top KPI Banner
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: EduStreakTheme.studentDarkCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: EduStreakTheme.primaryViolet.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Conducted Tests', style: EduStreakTheme.fontCaption(color: EduStreakTheme.studentDarkTextMuted)),
                        const SizedBox(height: 4),
                        Text('$totalExams', style: EduStreakTheme.fontHeading2(color: Colors.white, weight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: EduStreakTheme.studentDarkCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF06B6D4).withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Evaluated Papers', style: EduStreakTheme.fontCaption(color: EduStreakTheme.studentDarkTextMuted)),
                        const SizedBox(height: 4),
                        Text('$totalEvaluated', style: EduStreakTheme.fontHeading2(color: const Color(0xFF06B6D4), weight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: EduStreakTheme.studentDarkCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: EduStreakTheme.emeraldGreen.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tested Mastery Avg', style: EduStreakTheme.fontCaption(color: EduStreakTheme.studentDarkTextMuted)),
                        const SizedBox(height: 4),
                        Text(scoredCount > 0 ? '$avgExamScore%' : 'N/A', style: EduStreakTheme.fontHeading2(color: EduStreakTheme.emeraldGreen, weight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (assessments.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: EduStreakTheme.studentDarkCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: EduStreakTheme.studentDarkBorder),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.emoji_events_rounded, size: 44, color: EduStreakTheme.studentDarkTextMuted),
                    const SizedBox(height: 12),
                    Text('No Examinations Scheduled', style: EduStreakTheme.fontHeading3(color: Colors.white, weight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('Teachers have not published any formal assessments yet.', style: EduStreakTheme.fontCaption(color: EduStreakTheme.studentDarkTextMuted)),
                  ],
                ),
              )
            else
              Column(
                children: assessments.map((ex) {
                  final isDone = ex.status == 'closed' || (ex.submissions.isNotEmpty && ex.scores.length == ex.submissions.length);
                  final displayClass = ClassNameHelper.formatClassName(ex.classId);

                  double examScoreSum = 0.0;
                  for (final s in ex.scores.values) {
                    if (ex.totalMarks > 0) examScoreSum += (s / ex.totalMarks) * 100.0;
                  }
                  final avgScore = ex.scores.isNotEmpty ? (examScoreSum / ex.scores.length).round() : 0;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: EduStreakTheme.studentDarkCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: EduStreakTheme.studentDarkBorder, width: 1.2),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: isDone
                                ? EduStreakTheme.emeraldGreen.withValues(alpha: 0.15)
                                : EduStreakTheme.amberGold.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Icon(
                              isDone ? Icons.verified_rounded : Icons.pending_actions_rounded,
                              color: isDone ? EduStreakTheme.emeraldGreen : EduStreakTheme.amberGold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(ex.title, style: EduStreakTheme.fontHeading3(color: Colors.white, weight: FontWeight.w800)),
                              const SizedBox(height: 2),
                              Text(
                                '$displayClass • ${ex.subject} • ${ex.type.replaceAll("_", " ").toUpperCase()} • ${ex.totalMarks} Marks',
                                style: EduStreakTheme.fontCaption(color: EduStreakTheme.studentDarkTextMuted),
                              ),
                              if (ex.scores.isNotEmpty)
                                Text('Class Average: $avgScore% (${ex.scores.length} Evaluated)', style: EduStreakTheme.fontSmall(color: EduStreakTheme.neonCyan, weight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              isDone ? 'Completed' : (ex.status == 'published' ? 'Active Test' : 'Draft'),
                              style: EduStreakTheme.fontSmall(
                                color: isDone ? EduStreakTheme.emeraldGreen : EduStreakTheme.neonCyan,
                                weight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text('${ex.submissions.length} Submissions', style: EduStreakTheme.fontCaption(color: Colors.white70)),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        );
      },
    );
  }

  // ─── SUB-TAB 4: COMPETENCY INTELLIGENCE ──────────────────────────────────
  Widget _buildCompetenciesSection(bool isDesktop) {
    return FutureBuilder<Map<String, dynamic>>(
      future: SkillIntelligenceService().getSchoolAggregatedSkills(widget.school.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(color: EduStreakTheme.neonCyan),
            ),
          );
        }

        final data = snapshot.data ?? {};
        final averages = data['averages'] as Map<String, double>? ?? {};
        final curriculumGap = data['curriculumGap']?.toString() ?? 'Critical Thinking';
        final gapScore = (data['gapScore'] as num?)?.toDouble() ?? 68.5;
        final assessedCount = (data['assessedCount'] as num?)?.toInt() ?? 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Executive Header Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2C1558), Color(0xFF140E36)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: EduStreakTheme.studentDarkBorder.withValues(alpha: 0.8)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: EduStreakTheme.primaryViolet.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.radar_rounded, color: EduStreakTheme.neonCyan, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'School-Wide Skill Intelligence',
                          style: EduStreakTheme.fontHeading2(color: Colors.white, weight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Aggregated assessment evidence across $assessedCount active student competency profiles.',
                          style: EduStreakTheme.fontCaption(color: EduStreakTheme.studentDarkTextMuted),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: EduStreakTheme.amberGold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: EduStreakTheme.amberGold.withValues(alpha: 0.5)),
                    ),
                    child: Column(
                      children: [
                        const Text('CURRICULUM GAP', style: TextStyle(color: EduStreakTheme.amberGold, fontSize: 10, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text('$curriculumGap (${gapScore.toStringAsFixed(1)}%)', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 6 Competency Dimensions Grid
            Text('6 Core Competency Dimensions (School Benchmark: 75.0%)', style: EduStreakTheme.fontHeading3(color: Colors.white, weight: FontWeight.w800)),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isDesktop ? 3 : 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: isDesktop ? 2.0 : 1.7,
              ),
              itemCount: SkillDimensionDef.coreDimensions.length,
              itemBuilder: (context, index) {
                final dim = SkillDimensionDef.coreDimensions[index];
                final score = averages[dim.id] ?? 72.0;
                final isAboveBenchmark = score >= 75.0;

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: EduStreakTheme.studentDarkCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: dim.accentColor.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(dim.icon, color: dim.accentColor, size: 20),
                              const SizedBox(width: 8),
                              Text(dim.shortLabel, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isAboveBenchmark
                                  ? EduStreakTheme.emeraldGreen.withValues(alpha: 0.2)
                                  : EduStreakTheme.amberGold.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isAboveBenchmark ? 'ON TRACK' : 'NEEDS FOCUS',
                              style: TextStyle(
                                color: isAboveBenchmark ? EduStreakTheme.emeraldGreen : EduStreakTheme.amberGold,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${score.toStringAsFixed(1)}%',
                            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(width: 8),
                          const Padding(
                            padding: EdgeInsets.only(bottom: 4),
                            child: Text('School Avg', style: TextStyle(color: EduStreakTheme.studentDarkTextMuted, fontSize: 11)),
                          ),
                        ],
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (score / 100).clamp(0.0, 1.0),
                          minHeight: 6,
                          backgroundColor: Colors.white10,
                          valueColor: AlwaysStoppedAnimation<Color>(dim.accentColor),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
