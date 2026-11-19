import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/school_model.dart';
import '../../services/school_service.dart';
import '../../services/audit_service.dart';
import '../../utils/edustreak_theme.dart';
import '../../widgets/responsive/responsive_dialog.dart';

class TeacherDirectoryScreen extends StatefulWidget {
  const TeacherDirectoryScreen({super.key});

  @override
  State<TeacherDirectoryScreen> createState() => _TeacherDirectoryScreenState();
}

class _TeacherDirectoryScreenState extends State<TeacherDirectoryScreen> {
  final _schoolService = SchoolService();
  final _auditService = AuditService();
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  String? _selectedSchoolId;
  String _searchQuery = '';
  List<SchoolModel> _schools = [];
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSchools();
  }

  Future<void> _loadSchools() async {
    try {
      final stream = _schoolService.getSchoolsStream();
      final list = await stream.first;
      if (mounted) {
        setState(() => _schools = list);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchController.dispose();
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
          // Filter Bar
          _buildFilterBar(),

          const SizedBox(height: 18),

          // Teachers Stream
          Expanded(child: _buildTeacherListStream()),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1535),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EduStreakTheme.cardBorder),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 750;
          final titleWidget = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Faculty & Teacher Directory', style: EduStreakTheme.fontHeading3(color: Colors.white, weight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text('Assign faculty to schools, manage subject specializations and monitor teaching workloads.', style: EduStreakTheme.fontCaption(color: EduStreakTheme.textMuted)),
            ],
          );

          final controlsWidget = Wrap(
            spacing: 12,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // School Dropdown
              SizedBox(
                width: isCompact ? double.infinity : 220,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141A42),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF26326E)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: _selectedSchoolId,
                      dropdownColor: const Color(0xFF141A42),
                      isExpanded: true,
                      hint: const Text('All Institutions', style: TextStyle(color: Colors.white70, fontSize: 12), overflow: TextOverflow.ellipsis),
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.white54),
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      items: [
                        const DropdownMenuItem<String?>(value: null, child: Text('All Institutions', overflow: TextOverflow.ellipsis)),
                        ..._schools.map((s) => DropdownMenuItem<String?>(
                          value: s.id,
                          child: Text('${s.name} (${s.code})', overflow: TextOverflow.ellipsis),
                        )),
                      ],
                      onChanged: (val) => setState(() => _selectedSchoolId = val),
                    ),
                  ),
                ),
              ),

              // Search input
              SizedBox(
                width: isCompact ? double.infinity : 220,
                height: 40,
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Search faculty...',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded, color: Colors.white54, size: 18),
                    filled: true,
                    fillColor: const Color(0xFF141A42),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),

              SizedBox(
                width: isCompact ? double.infinity : null,
                child: ElevatedButton.icon(
                  onPressed: _showRegisterTeacherDialog,
                  icon: const Icon(Icons.person_add_rounded, size: 18),
                  label: const Text('Add Teacher'),
                  style: ElevatedButton.styleFrom(backgroundColor: EduStreakTheme.primaryViolet),
                ),
              ),
            ],
          );

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                titleWidget,
                const SizedBox(height: 14),
                controlsWidget,
              ],
            );
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: titleWidget),
              const SizedBox(width: 16),
              controlsWidget,
            ],
          );
        },
      ),
    );
  }

  Widget _buildTeacherListStream() {
    try {
      Query<Map<String, dynamic>> query = _firestore.collection('users').where('role', isEqualTo: 'teacher');

      if (_selectedSchoolId != null) {
        query = query.where('schoolId', isEqualTo: _selectedSchoolId);
      }

      return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: EduStreakTheme.primaryViolet));
        }

        var docs = snapshot.data?.docs ?? [];
        if (_searchQuery.isNotEmpty) {
          docs = docs.where((doc) {
            final data = doc.data();
            final name = (data['name'] ?? '').toString().toLowerCase();
            final email = (data['email'] ?? '').toString().toLowerCase();
            return name.contains(_searchQuery) || email.contains(_searchQuery);
          }).toList();
        }

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.supervisor_account_outlined, size: 52, color: Colors.white24),
                const SizedBox(height: 14),
                Text('No faculty members found.', style: EduStreakTheme.fontBody(color: Colors.white70)),
                const SizedBox(height: 8),
                Text('Click "Add Teacher" above to onboard educators.', style: EduStreakTheme.fontCaption(color: EduStreakTheme.textMuted)),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.only(bottom: 96),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data();
            final teacherId = doc.id;
            final teacherName = data['name'] ?? 'Faculty Member';
            final email = data['email'] ?? 'faculty@edustreak.edu';
            final subject = data['subject'] ?? 'General Education';
            final schoolCode = data['schoolCode'] ?? 'AP';
            final isActive = data['isActive'] ?? true;
            final classes = (data['classes'] as List?)?.join(', ') ?? 'Class 8, 9, 10';

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1535),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: EduStreakTheme.cardBorder),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFF00E5FF).withValues(alpha: 0.2),
                    child: Text(
                      teacherName.isNotEmpty ? teacherName[0].toUpperCase() : 'T',
                      style: const TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              teacherName,
                              style: EduStreakTheme.fontLabel(color: Colors.white, weight: FontWeight.w700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(subject, style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$email • School: $schoolCode • Classes: $classes',
                          style: EduStreakTheme.fontCaption(color: EduStreakTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(isActive ? Icons.lock_open_rounded : Icons.lock_rounded, color: isActive ? Colors.white60 : Colors.redAccent, size: 20),
                    tooltip: isActive ? 'Suspend Faculty Access' : 'Activate Faculty Access',
                    onPressed: () async {
                      await _firestore.collection('users').doc(teacherId).update({'isActive': !isActive});
                      await _auditService.logAction(
                        action: !isActive ? 'TEACHER_ACTIVATED' : 'TEACHER_SUSPENDED',
                        targetType: 'teacher',
                        targetId: teacherId,
                        details: {'name': teacherName},
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    } catch (_) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.school_outlined, size: 56, color: Colors.white24),
            const SizedBox(height: 12),
            Text('No faculty records found', style: EduStreakTheme.fontHeading3(color: Colors.white60)),
          ],
        ),
      );
    }
  }

  void _showRegisterTeacherDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final subjectCtrl = TextEditingController(text: 'Mathematics');
    String? assignedSchoolId = _selectedSchoolId ?? (_schools.isNotEmpty ? _schools.first.id : null);

    showAdaptiveEduStreakModal(
      context: context,
      maxWidth: 480,
      title: 'Register New Faculty Member',
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Faculty Full Name')),
                const SizedBox(height: 12),
                TextField(controller: emailCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Official Email')),
                const SizedBox(height: 12),
                TextField(controller: subjectCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Subject Specialization')),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: assignedSchoolId,
                  dropdownColor: const Color(0xFF141A42),
                  decoration: const InputDecoration(labelText: 'Assigned School'),
                  items: _schools.map((s) => DropdownMenuItem(value: s.id, child: Text('${s.name} (${s.code})'))).toList(),
                  onChanged: (val) => setModalState(() => assignedSchoolId = val),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: assignedSchoolId == null
                      ? null
                      : () async {
                          final school = _schools.firstWhere((s) => s.id == assignedSchoolId);
                          final docRef = _firestore.collection('users').doc();
                          await docRef.set({
                            'id': docRef.id,
                            'name': nameCtrl.text.trim(),
                            'email': emailCtrl.text.trim(),
                            'role': 'teacher',
                            'subject': subjectCtrl.text.trim(),
                            'schoolId': school.id,
                            'schoolCode': school.code,
                            'isActive': true,
                            'createdAt': FieldValue.serverTimestamp(),
                          });

                          await _auditService.logAction(
                            action: 'TEACHER_REGISTERED',
                            targetType: 'teacher',
                            targetId: docRef.id,
                            details: {
                              'name': nameCtrl.text.trim(),
                              'school': school.code,
                              'subject': subjectCtrl.text.trim(),
                            },
                          );

                          try {
                            await _firestore.collection('schools').doc(school.id).update({
                              'totalTeachers': FieldValue.increment(1),
                            });
                          } catch (_) {}

                          if (ctx.mounted) Navigator.of(ctx).pop();
                        },
                  style: ElevatedButton.styleFrom(backgroundColor: EduStreakTheme.primaryViolet),
                  child: const Text('Register Faculty'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
