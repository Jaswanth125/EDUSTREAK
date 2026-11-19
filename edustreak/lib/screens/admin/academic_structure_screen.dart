import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/curriculum_model.dart';
import '../../models/school_model.dart';
import '../../services/academic_service.dart';
import '../../services/school_service.dart';
import '../../utils/edustreak_theme.dart';
import '../../widgets/responsive/responsive_dialog.dart';

class AcademicStructureScreen extends StatefulWidget {
  const AcademicStructureScreen({super.key});

  @override
  State<AcademicStructureScreen> createState() => _AcademicStructureScreenState();
}

class _AcademicStructureScreenState extends State<AcademicStructureScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _academicService = AcademicService();
  final _schoolService = SchoolService();

  List<SchoolModel> _schools = [];
  String? _selectedSchoolId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSchools();
  }

  Future<void> _loadSchools() async {
    try {
      final stream = _schoolService.getSchoolsStream();
      final list = await stream.first;
      if (mounted) {
        setState(() {
          _schools = list;
          if (_schools.isNotEmpty) {
            _selectedSchoolId = _schools.first.id;
            _academicService.seedStandardClassesIfEmpty(_schools.first.id);
          }
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF070B1E),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1535),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: EduStreakTheme.cardBorder),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 650;
                final titleSection = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Academic Structure & Operations', style: EduStreakTheme.fontHeading3(color: Colors.white, weight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text('Manage academic calendar cycles, grade levels, sections, and faculty assignments.', style: EduStreakTheme.fontCaption(color: EduStreakTheme.textMuted)),
                  ],
                );

                final tabBarWidget = Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF141A42),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF26326E)),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    indicator: BoxDecoration(
                      color: EduStreakTheme.primaryViolet,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white60,
                    tabs: const [
                      Tab(text: 'Academic Years Lifecycle'),
                      Tab(text: 'Classes, Sections & Faculty'),
                    ],
                  ),
                );

                if (isCompact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      titleSection,
                      const SizedBox(height: 12),
                      tabBarWidget,
                    ],
                  );
                }

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: titleSection),
                    const SizedBox(width: 16),
                    tabBarWidget,
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAcademicYearsTab(),
                _buildClassesAndSectionsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── TAB 1: ACADEMIC YEARS LIFECYCLE ──────────────────────────────────────
  Widget _buildAcademicYearsTab() {
    return StreamBuilder<List<AcademicYearModel>>(
      stream: _academicService.getAcademicYearsStream(),
      builder: (context, snapshot) {
        final years = snapshot.data ?? [];

        return LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 650;
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 10,
                    children: [
                      Text('State Academic Cycles', style: EduStreakTheme.fontHeading3(color: Colors.white, weight: FontWeight.w700)),
                      ElevatedButton.icon(
                        onPressed: _showCreateYearDialog,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('New Academic Year'),
                        style: ElevatedButton.styleFrom(backgroundColor: EduStreakTheme.primaryViolet),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (years.isEmpty)
                    const Center(child: CircularProgressIndicator(color: EduStreakTheme.primaryViolet))
                  else
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: years.map((ay) {
                        return Container(
                          width: isCompact ? double.infinity : 320,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F1535),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: ay.isCurrent ? EduStreakTheme.primaryViolet : EduStreakTheme.cardBorder,
                              width: ay.isCurrent ? 2 : 1,
                            ),
                            boxShadow: ay.isCurrent ? EduStreakTheme.violetGlow : null,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      ay.label,
                                      style: EduStreakTheme.fontHeading2(color: Colors.white, weight: FontWeight.w800),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: ay.isCurrent ? Colors.green.withValues(alpha: 0.2) : Colors.white10,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: ay.isCurrent ? Colors.green : Colors.white24),
                                    ),
                                    child: Text(
                                      ay.isCurrent ? 'ACTIVE NOW' : 'ARCHIVED',
                                      style: TextStyle(
                                        color: ay.isCurrent ? Colors.greenAccent : Colors.white60,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                          const SizedBox(height: 12),
                          Text('Duration: ${ay.startDate.year}-${ay.startDate.month.toString().padLeft(2, '0')} to ${ay.endDate.year}-${ay.endDate.month.toString().padLeft(2, '0')}',
                              style: EduStreakTheme.fontCaption(color: EduStreakTheme.textMuted)),
                          const SizedBox(height: 16),
                          if (!ay.isCurrent)
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () async {
                                  await _academicService.setActiveAcademicYear(ay.id);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Academic Year ${ay.label} activated across EduStreak.')),
                                    );
                                  }
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: EduStreakTheme.neonCyan,
                                  side: const BorderSide(color: EduStreakTheme.neonCyan),
                                ),
                                child: const Text('Set as Current Active Year'),
                              ),
                            )
                          else
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: EduStreakTheme.primaryViolet.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Text('Governing All Active Schools', style: TextStyle(color: EduStreakTheme.primaryVioletLight, fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        );
      },
    );
  },
);
  }

  // ─── TAB 2: CLASSES & SECTIONS ────────────────────────────────────────────
  Widget _buildClassesAndSectionsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // School Selector Dropdown
        LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 650;
            return Wrap(
              spacing: 14,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('Select Target Institution:', style: EduStreakTheme.fontLabel(color: Colors.white70, weight: FontWeight.w700)),
                SizedBox(
                  width: isCompact ? double.infinity : 320,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F1535),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: EduStreakTheme.primaryViolet),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedSchoolId,
                        dropdownColor: const Color(0xFF0F1535),
                        isExpanded: true,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        items: _schools.map((s) {
                          return DropdownMenuItem(
                            value: s.id,
                            child: Text('${s.name} (${s.code})', overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedSchoolId = val);
                            _academicService.seedStandardClassesIfEmpty(val);
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 18),

        Expanded(
          child: _selectedSchoolId == null
              ? const Center(child: Text('Please select a school to inspect its roster.'))
              : StreamBuilder<List<GradeClassModel>>(
                  stream: _academicService.getSchoolClassesStream(_selectedSchoolId!),
                  builder: (context, snapshot) {
                    final classes = snapshot.data ?? [];
                    if (classes.isEmpty) {
                      return const Center(child: CircularProgressIndicator(color: EduStreakTheme.primaryViolet));
                    }

                    return ListView.separated(
                      itemCount: classes.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final cls = classes[index];

                        return Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F1535),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: EduStreakTheme.cardBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                alignment: WrapAlignment.spaceBetween,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 10,
                                runSpacing: 8,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: EduStreakTheme.primaryViolet.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(Icons.school_rounded, color: EduStreakTheme.primaryVioletLight, size: 20),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(cls.gradeName, style: EduStreakTheme.fontHeading2(color: Colors.white, weight: FontWeight.w700)),
                                    ],
                                  ),
                                  TextButton.icon(
                                    onPressed: () => _showAddSectionDialog(cls.id),
                                    icon: const Icon(Icons.add_rounded, size: 16),
                                    label: const Text('Add Section'),
                                    style: TextButton.styleFrom(foregroundColor: EduStreakTheme.neonCyan),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              LayoutBuilder(
                                builder: (context, cardConstraints) {
                                  final isCardCompact = cardConstraints.maxWidth < 550;
                                  return Wrap(
                                    spacing: 14,
                                    runSpacing: 14,
                                    children: cls.sections.map((sec) {
                                      return Container(
                                        width: isCardCompact ? double.infinity : 250,
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF141A42),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: const Color(0xFF26326E)),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    'Section ${sec.name}',
                                                    style: EduStreakTheme.fontLabel(color: Colors.white, weight: FontWeight.w700),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(6)),
                                                  child: Text('${sec.totalStudents} Students', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                                                ),
                                              ],
                                            ),
                                        const SizedBox(height: 8),
                                        Text('Class Teacher:', style: EduStreakTheme.fontCaption(color: EduStreakTheme.textMuted)),
                                        const SizedBox(height: 2),
                                        Text(
                                          sec.classTeacherName ?? 'Not Assigned',
                                          style: TextStyle(
                                            color: sec.classTeacherName != null ? EduStreakTheme.primaryVioletLight : Colors.white38,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        OutlinedButton(
                                          onPressed: () => _showAssignTeacherDialog(cls.id, sec.id),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.white70,
                                            side: const BorderSide(color: Color(0xFF334086)),
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          ),
                                          child: const Text('Assign Teacher', style: TextStyle(fontSize: 11)),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              );
                            },
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
    );
  }

  // ─── DIALOGS ──────────────────────────────────────────────────────────────
  void _showCreateYearDialog() {
    final labelCtrl = TextEditingController(text: '2025-2026');
    bool isCurrent = false;

    showAdaptiveEduStreakModal(
      context: context,
      maxWidth: 480,
      title: 'Create Academic Year',
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: labelCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Academic Year Label (e.g. 2025-2026)'),
                ),
                const SizedBox(height: 14),
                CheckboxListTile(
                  title: const Text('Set as Current Active Year', style: TextStyle(color: Colors.white)),
                  value: isCurrent,
                  onChanged: (v) => setModalState(() => isCurrent = v ?? false),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    await _academicService.createAcademicYear(
                      label: labelCtrl.text.trim(),
                      startDate: DateTime(2025, 6, 1),
                      endDate: DateTime(2026, 4, 30),
                      isCurrent: isCurrent,
                    );
                    if (ctx.mounted) Navigator.of(ctx).pop();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: EduStreakTheme.primaryViolet),
                  child: const Text('Save Academic Year'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddSectionDialog(String classId) {
    if (_selectedSchoolId == null) return;
    final nameCtrl = TextEditingController();

    showAdaptiveEduStreakModal(
      context: context,
      maxWidth: 420,
      title: 'Add Section',
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Section Code (e.g. C)'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final sec = SectionModel(
                  id: 'sec_${classId}_${nameCtrl.text.trim().toLowerCase()}',
                  name: nameCtrl.text.trim().toUpperCase(),
                  classId: classId,
                );
                await _academicService.addSectionToClass(_selectedSchoolId!, classId, sec);
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              style: ElevatedButton.styleFrom(backgroundColor: EduStreakTheme.primaryViolet),
              child: const Text('Add Section'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAssignTeacherDialog(String classId, String sectionId) {
    if (_selectedSchoolId == null) return;

    showAdaptiveEduStreakModal(
      context: context,
      maxWidth: 480,
      title: 'Assign Class Teacher',
      builder: (ctx) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'teacher')
            .where('schoolId', isEqualTo: _selectedSchoolId)
            .snapshots(),
        builder: (context, snapshot) {
          final teachers = snapshot.data?.docs ?? [];

          if (teachers.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: const Center(
                child: Text('No teachers found registered under this school.', style: TextStyle(color: Colors.white70)),
              ),
            );
          }

          return Container(
            padding: const EdgeInsets.all(16),
            height: 320,
            child: ListView.separated(
              itemCount: teachers.length,
              separatorBuilder: (_, __) => const Divider(color: Color(0xFF222B5C)),
              itemBuilder: (context, idx) {
                final tData = teachers[idx].data();
                final tId = teachers[idx].id;
                final tName = tData['name'] ?? 'Faculty Member';

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: EduStreakTheme.primaryViolet.withValues(alpha: 0.2),
                    child: Text(tName[0], style: const TextStyle(color: Colors.white)),
                  ),
                  title: Text(tName, style: const TextStyle(color: Colors.white)),
                  subtitle: Text(tData['subject'] ?? 'Faculty', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  trailing: TextButton(
                    onPressed: () async {
                      await _academicService.assignClassTeacher(
                        schoolId: _selectedSchoolId!,
                        classId: classId,
                        sectionId: sectionId,
                        teacherId: tId,
                        teacherName: tName,
                      );
                      if (ctx.mounted) Navigator.of(ctx).pop();
                    },
                    child: const Text('Assign'),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
