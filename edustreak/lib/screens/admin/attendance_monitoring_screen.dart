import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/school_model.dart';
import '../../services/school_service.dart';
import '../../services/audit_service.dart';
import '../../utils/edustreak_theme.dart';
import '../../widgets/responsive/responsive_dialog.dart';

class AttendanceMonitoringScreen extends StatefulWidget {
  const AttendanceMonitoringScreen({super.key});

  @override
  State<AttendanceMonitoringScreen> createState() => _AttendanceMonitoringScreenState();
}

class _AttendanceMonitoringScreenState extends State<AttendanceMonitoringScreen> {
  final _schoolService = SchoolService();
  final _auditService = AuditService();
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  String? _selectedSchoolId;
  DateTime _selectedDate = DateTime.now();
  List<SchoolModel> _schools = [];

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

  String get _dateKey =>
      '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

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

          // Attendance Metrics Row
          _buildMetricsRow(),

          const SizedBox(height: 18),

          // Live Attendance Roster
          Expanded(child: _buildAttendanceRoster()),
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
              Text('State Attendance Governance & Oversight', style: EduStreakTheme.fontHeading3(color: Colors.white, weight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text('Live daily verification, unexcused absence audits, and administrative corrections.', style: EduStreakTheme.fontCaption(color: EduStreakTheme.textMuted)),
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
                        ..._schools.map((s) => DropdownMenuItem<String?>(value: s.id, child: Text('${s.name} (${s.code})', overflow: TextOverflow.ellipsis))),
                      ],
                      onChanged: (val) => setState(() => _selectedSchoolId = val),
                    ),
                  ),
                ),
              ),

              // Date Picker
              SizedBox(
                width: isCompact ? double.infinity : null,
                child: InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2023),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() => _selectedDate = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141A42),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: EduStreakTheme.primaryViolet),
                    ),
                    child: Row(
                      mainAxisSize: isCompact ? MainAxisSize.max : MainAxisSize.min,
                      mainAxisAlignment: isCompact ? MainAxisAlignment.center : MainAxisAlignment.start,
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 16, color: EduStreakTheme.primaryVioletLight),
                        const SizedBox(width: 8),
                        Text(_dateKey, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
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

  Widget _buildMetricsRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 650;
        final c1 = _buildMetricCard('State Present Rate', '95.2%', Icons.check_circle_rounded, Colors.greenAccent);
        final c2 = _buildMetricCard('Late Arrivals', '3.1%', Icons.access_time_filled_rounded, Colors.orangeAccent);
        final c3 = _buildMetricCard('Unexcused Absences', '1.7%', Icons.cancel_rounded, Colors.redAccent);
        final c4 = _buildMetricCard('Schools Reported', '${_schools.length} / ${_schools.length}', Icons.apartment_rounded, Colors.cyanAccent);

        if (isSmall) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: c1),
                  const SizedBox(width: 12),
                  Expanded(child: c2),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: c3),
                  const SizedBox(width: 12),
                  Expanded(child: c4),
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: c1),
            const SizedBox(width: 16),
            Expanded(child: c2),
            const SizedBox(width: 16),
            Expanded(child: c3),
            const SizedBox(width: 16),
            Expanded(child: c4),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard(String title, String val, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1535),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(val, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                Text(title, style: EduStreakTheme.fontCaption(color: EduStreakTheme.textMuted), overflow: TextOverflow.ellipsis, maxLines: 1),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceRoster() {
    try {
      Query<Map<String, dynamic>> query = _firestore.collection('users').where('role', isEqualTo: 'student');
      if (_selectedSchoolId != null) {
        query = query.where('schoolId', isEqualTo: _selectedSchoolId);
      }

      return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: query.limit(40).snapshots(),
        builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: EduStreakTheme.primaryViolet));
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Text('No student attendance records for $_dateKey.', style: EduStreakTheme.fontBody(color: Colors.white70)),
          );
        }

        return ListView.separated(
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final studentId = docs[index].id;
            final name = data['name'] ?? 'Student';
            final roll = data['rollNumber'] ?? data['rollNo'] ?? '101';
            final schoolCode = data['schoolCode'] ?? 'AP';
            final grade = data['grade'] ?? '10';

            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1535),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: EduStreakTheme.cardBorder),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: EduStreakTheme.primaryViolet.withValues(alpha: 0.2),
                    child: Text(name[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: EduStreakTheme.fontLabel(color: Colors.white, weight: FontWeight.w700)),
                        Text('Roll: $roll • Class $grade • School: $schoolCode', style: EduStreakTheme.fontCaption(color: EduStreakTheme.textMuted)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.green),
                    ),
                    child: const Text('PRESENT', style: TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.edit_note_rounded, color: EduStreakTheme.neonCyan, size: 20),
                    tooltip: 'Administrative Attendance Override',
                    onPressed: () => _showCorrectionDialog(studentId, name, roll),
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
        child: Text('No attendance records available.', style: EduStreakTheme.fontBody(color: Colors.white70)),
      );
    }
  }

  void _showCorrectionDialog(String studentId, String name, String roll) {
    String newStatus = 'PRESENT';
    final reasonCtrl = TextEditingController(text: 'Medical certificate approved by Central Administration');

    showAdaptiveEduStreakModal(
      context: context,
      maxWidth: 480,
      title: 'Attendance Override: $name',
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: newStatus,
                  dropdownColor: const Color(0xFF141A42),
                  decoration: const InputDecoration(labelText: 'Corrected Attendance Status'),
                  items: const [
                    DropdownMenuItem(value: 'PRESENT', child: Text('Present (Full Credit)')),
                    DropdownMenuItem(value: 'EXCUSED_ABSENT', child: Text('Excused Absence')),
                    DropdownMenuItem(value: 'LATE', child: Text('Late Arrival')),
                    DropdownMenuItem(value: 'UNEXCUSED_ABSENT', child: Text('Unexcused Absence')),
                  ],
                  onChanged: (v) {
                    if (v != null) setModalState(() => newStatus = v);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Required Administrative Reason'),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    await _auditService.logAction(
                      action: 'ATTENDANCE_OVERRIDDEN',
                      targetType: 'student',
                      targetId: studentId,
                      details: {
                        'date': _dateKey,
                        'newStatus': newStatus,
                        'reason': reasonCtrl.text.trim(),
                        'studentRoll': roll,
                      },
                    );

                    if (ctx.mounted) Navigator.of(ctx).pop();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Attendance override recorded and saved to audit trail.')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: EduStreakTheme.primaryViolet),
                  child: const Text('Save Override'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
