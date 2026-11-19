import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/school_model.dart';
import '../../services/school_service.dart';
import '../../services/audit_service.dart';
import '../../utils/edustreak_theme.dart';
import '../../widgets/responsive/responsive_dialog.dart';

class ParentDirectoryScreen extends StatefulWidget {
  const ParentDirectoryScreen({super.key});

  @override
  State<ParentDirectoryScreen> createState() => _ParentDirectoryScreenState();
}

class _ParentDirectoryScreenState extends State<ParentDirectoryScreen> {
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

          // Parents Stream
          Expanded(child: _buildParentListStream()),
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
              Text('Parent & Guardian Directory', style: EduStreakTheme.fontHeading3(color: Colors.white, weight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text('Manage verified family links, multi-child associations, and portal access permissions.', style: EduStreakTheme.fontCaption(color: EduStreakTheme.textMuted)),
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
                width: isCompact ? double.infinity : 240,
                height: 40,
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Search parent or email...',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded, color: Colors.white54, size: 18),
                    filled: true,
                    fillColor: const Color(0xFF141A42),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
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

  Widget _buildParentListStream() {
    try {
      Query<Map<String, dynamic>> query = _firestore.collection('users').where('role', isEqualTo: 'parent');

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
                const Icon(Icons.family_restroom_outlined, size: 52, color: Colors.white24),
                const SizedBox(height: 14),
                Text('No parent profiles found.', style: EduStreakTheme.fontBody(color: Colors.white70)),
                const SizedBox(height: 8),
                Text('Parents link automatically via student enrollment or CSV import.', style: EduStreakTheme.fontCaption(color: EduStreakTheme.textMuted)),
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
            final parentId = doc.id;
            final parentName = data['name'] ?? 'Guardian';
            final email = data['email'] ?? 'parent@edustreak.internal';
            final schoolCode = data['schoolCode'] ?? 'AP';
            final childIds = (data['childIds'] as List?) ?? (data['childId'] != null ? [data['childId']] : []);

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
                    backgroundColor: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                    child: Text(
                      parentName.isNotEmpty ? parentName[0].toUpperCase() : 'P',
                      style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold),
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
                              parentName,
                              style: EduStreakTheme.fontLabel(color: Colors.white, weight: FontWeight.w700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text('${childIds.length} Linked Children', style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('$email • School: $schoolCode', style: EduStreakTheme.fontCaption(color: EduStreakTheme.textMuted)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.link_rounded, color: EduStreakTheme.neonCyan, size: 20),
                    tooltip: 'Link Child',
                    onPressed: () => _showLinkChildDialog(parentId, parentName, data['schoolId']),
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
            const Icon(Icons.people_outline, size: 56, color: Colors.white24),
            const SizedBox(height: 12),
            Text('No parents found', style: EduStreakTheme.fontHeading3(color: Colors.white60)),
          ],
        ),
      );
    }
  }

  void _showLinkChildDialog(String parentId, String parentName, String? schoolId) {
    final rollCtrl = TextEditingController();

    showAdaptiveEduStreakModal(
      context: context,
      maxWidth: 440,
      title: 'Link Student to $parentName',
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: rollCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Student Roll Number or Admission ID'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final roll = rollCtrl.text.trim();
                Query<Map<String, dynamic>> query = _firestore.collection('users').where('role', isEqualTo: 'student').where('rollNumber', isEqualTo: roll);
                if (schoolId != null) {
                  query = query.where('schoolId', isEqualTo: schoolId);
                }
                final snap = await query.limit(1).get();

                if (snap.docs.isEmpty) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No student found with that roll number.')));
                  }
                  return;
                }

                final studentId = snap.docs.first.id;
                await _firestore.collection('users').doc(parentId).update({
                  'childIds': FieldValue.arrayUnion([studentId]),
                });

                await _auditService.logAction(
                  action: 'PARENT_CHILD_LINKED',
                  targetType: 'parent',
                  targetId: parentId,
                  details: {'parentId': parentId, 'studentId': studentId, 'rollNo': roll},
                );

                if (ctx.mounted) Navigator.of(ctx).pop();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Child successfully linked to parent!')));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: EduStreakTheme.primaryViolet),
              child: const Text('Link Child'),
            ),
          ],
        ),
      ),
    );
  }
}
