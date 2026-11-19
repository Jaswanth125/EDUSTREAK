import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../services/auth_service.dart';
import '../../services/school_service.dart';
import '../../services/curriculum_service.dart';
import '../../services/csv_import_service.dart';
import '../../models/school_model.dart';
import '../../models/curriculum_model.dart';
import '../../utils/edustreak_theme.dart';
import '../../widgets/responsive/responsive_scaffold.dart';
import '../../widgets/responsive/adaptive_dashboard_grid.dart';
import '../../widgets/responsive/responsive_dialog.dart';
import 'analytics_screen.dart';
import 'admin_profile_dialog.dart';
import 'school_details_screen.dart';
import 'principal_management_screen.dart';
import 'curriculum_builder_screen.dart';
import 'student_directory_screen.dart';
import 'teacher_directory_screen.dart';
import 'parent_directory_screen.dart';
import 'academic_structure_screen.dart';
import 'platform_settings_screen.dart';
import '../chat/realtime_chat_list_screen.dart';

class CentralAdminPortalScreen extends StatefulWidget {
  final ValueChanged<String>? onPortalSwitch;

  const CentralAdminPortalScreen({super.key, this.onPortalSwitch});

  @override
  State<CentralAdminPortalScreen> createState() => _CentralAdminPortalScreenState();
}

class _CentralAdminPortalScreenState extends State<CentralAdminPortalScreen> {
  final _schoolService = SchoolService();
  final _curriculumService = CurriculumService();
  final _csvService = CsvImportService();

  int _selectedNavIndex = 0;
  String _selectedScope = 'All Schools';

  Map<String, int> _counts = {
    'totalSchools': 0,
    'activeSchools': 0,
    'pendingSchools': 0,
    'suspendedSchools': 0,
    'government': 0,
    'private': 0,
    'cbse': 0,
    'principals': 0,
    'students': 0,
    'teachers': 0,
    'parents': 0,
  };

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    // Seed initial institutions and standard templates if database is fresh
    await _schoolService.seedInitialSchoolsIfEmpty();
    await _curriculumService.seedCurriculumTemplatesIfEmpty();
    await _fetchLiveDatabaseCounts();
  }

  Future<void> _fetchLiveDatabaseCounts() async {
    try {
      final schoolCounts = await _schoolService.getRealSchoolCounts();

      // Query real user counts by role
      final firestore = FirebaseFirestore.instance;
      final principalCountSnap = await firestore.collection('users').where('role', isEqualTo: 'principal').count().get();
      final studentCountSnap = await firestore.collection('users').where('role', isEqualTo: 'student').count().get();
      final teacherCountSnap = await firestore.collection('users').where('role', isEqualTo: 'teacher').count().get();
      final parentCountSnap = await firestore.collection('users').where('role', isEqualTo: 'parent').count().get();

      if (mounted) {
        setState(() {
          _counts = {
            'totalSchools': schoolCounts['total'] ?? 0,
            'activeSchools': schoolCounts['active'] ?? 0,
            'pendingSchools': schoolCounts['pending'] ?? 0,
            'suspendedSchools': schoolCounts['suspended'] ?? 0,
            'government': schoolCounts['government'] ?? 0,
            'private': schoolCounts['private'] ?? 0,
            'cbse': schoolCounts['cbse'] ?? 0,
            'principals': principalCountSnap.count ?? 0,
            'students': studentCountSnap.count ?? 0,
            'teachers': teacherCountSnap.count ?? 0,
            'parents': parentCountSnap.count ?? 0,
          };
        });
      }
    } catch (e) {
      // Non-fatal
    }
  }

  Future<void> _logout() async {
    await AuthService().signOut();
    if (mounted) {
      Provider.of<UserProvider>(context, listen: false).clearUser();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).currentUser;
    final adminName = user?.name.isNotEmpty == true ? user!.name : 'Central Administrator';

    return ResponsiveScaffold(
      portalType: 'admin',
      selectedIndex: _selectedNavIndex,
      onItemSelected: (index) => setState(() => _selectedNavIndex = index),
      onLogout: _logout,
      user: user,
      userName: adminName,
      userSubtitle: 'Central Administration',
      headerTitle: 'Central Admin Portal',
      headerSubtitle: 'State Educational Operations • Unified Governance',
      portalIcon: Icons.admin_panel_settings_rounded,
      portalIconColor: EduStreakTheme.primaryViolet,
      contextPillText: _selectedScope,
      contextPillOptions: const ['All Schools', 'Government Only', 'Private Only', 'CBSE Only'],
      onContextPillChanged: (val) {
        setState(() => _selectedScope = val);
      },
      onDevSwitchPortal: widget.onPortalSwitch,
      avatarWidget: Tooltip(
        message: 'Master Admin Security & Profile',
        child: InkWell(
          onTap: () => AdminProfileDialog.show(context, user),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Builder(
              builder: (ctx) {
                final isCompact = MediaQuery.sizeOf(ctx).width < 600;
                final avatar = Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF1E265C),
                    border: Border.all(color: EduStreakTheme.primaryViolet, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      adminName.isNotEmpty ? adminName[0].toUpperCase() : 'A',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );

                if (isCompact) {
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      avatar,
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: EduStreakTheme.primaryViolet,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.shield_rounded, size: 10, color: Colors.white),
                        ),
                      ),
                    ],
                  );
                }

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: EduStreakTheme.primaryViolet.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: EduStreakTheme.primaryViolet.withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.shield_rounded, size: 14, color: EduStreakTheme.primaryViolet),
                          const SizedBox(width: 4),
                          Text(
                            'Master Admin',
                            style: EduStreakTheme.fontLabel(
                              color: EduStreakTheme.primaryVioletLight,
                              weight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    avatar,
                  ],
                );
              },
            ),
          ),
        ),
      ),
      body: _buildCurrentTab(),
    );
  }

  Widget _buildCurrentTab() {
    switch (_selectedNavIndex) {
      case 0:
        return _buildDashboardContent();
      case 1:
        return _buildSchoolsDirectoryTab();
      case 2:
        return const PrincipalManagementScreen();
      case 3:
        return const CurriculumBuilderScreen();
      case 4:
        return const StudentDirectoryScreen();
      case 5:
        return const TeacherDirectoryScreen();
      case 6:
        return const ParentDirectoryScreen();
      case 7:
        return const AcademicStructureScreen();
      case 8:
        return const AnalyticsScreen();
      case 9:
        return const PlatformSettingsScreen();
      case 10:
        return const RealtimeChatListScreen(showAppBar: false);
      default:
        return _buildDashboardContent();
    }
  }

  // ─── DASHBOARD CONTENT (WITH REAL LIVE FIRESTORE METRICS) ────────────────
  Widget _buildDashboardContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 4 Macro KPI Cards
          _buildMacroKpiCards(),

          const SizedBox(height: 22),

          // Pending Institutional Approvals
          _buildPendingSchoolApprovalsSection(),

          // Middle Row: Donut Chart + Curriculum Management
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 950) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _buildSchoolsByTypeCard()),
                    const SizedBox(width: 20),
                    Expanded(flex: 3, child: _buildCurriculumManagementCard()),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildSchoolsByTypeCard(),
                    const SizedBox(height: 20),
                    _buildCurriculumManagementCard(),
                  ],
                );
              }
            },
          ),

          const SizedBox(height: 22),

          // Bottom Row: Live School Registry Stream
          _buildInstitutionalAuditCard(),
        ],
      ),
    );
  }

  // ─── 4 MACRO KPI CARDS (COMPUTED LIVE) ───────────────────────────────────
  Widget _buildMacroKpiCards() {
    final totalSchools = _counts['totalSchools'] ?? 0;
    final activeSchools = _counts['activeSchools'] ?? 0;
    final pendingSchools = _counts['pendingSchools'] ?? 0;
    final totalPrincipals = _counts['principals'] ?? 0;
    final totalStudents = _counts['students'] ?? 0;
    final totalTeachers = _counts['teachers'] ?? 0;
    final totalParents = _counts['parents'] ?? 0;

    final kpis = [
      {
        'title': '$totalSchools Schools',
        'subtitle': '$activeSchools Active • $pendingSchools Pending',
        'icon': Icons.account_balance_rounded,
        'color': EduStreakTheme.neonCyan,
      },
      {
        'title': totalPrincipals == 0 ? '0 Principals' : '$totalPrincipals Leaders',
        'subtitle': 'Authorized School Heads',
        'icon': Icons.admin_panel_settings_rounded,
        'color': EduStreakTheme.emeraldGreen,
      },
      {
        'title': totalStudents == 0 ? '0 Students' : '$totalStudents Enrolled',
        'subtitle': 'Active Student Profiles',
        'icon': Icons.school_rounded,
        'color': EduStreakTheme.primaryViolet,
      },
      {
        'title': totalTeachers == 0 ? '0 Teachers' : '$totalTeachers Faculty',
        'subtitle': 'Assigned Educators',
        'icon': Icons.supervisor_account_rounded,
        'color': EduStreakTheme.amberGold,
      },
      {
        'title': totalParents == 0 ? '0 Parents' : '$totalParents Guardians',
        'subtitle': 'Linked Parent Accounts',
        'icon': Icons.family_restroom_rounded,
        'color': EduStreakTheme.magentaPink,
      },
    ];

    return AdaptiveDashboardGrid.metrics(
      mainAxisExtent: 110,
      children: kpis.map((k) {
        final color = k['color'] as Color;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: EduStreakTheme.darkCardDecoration(
            borderColor: color.withValues(alpha: 0.35),
            glowOpacity: 0.15,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Icon(k['icon'] as IconData, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      k['title'] as String,
                      style: EduStreakTheme.fontHeading2(
                        color: Colors.white,
                        weight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      k['subtitle'] as String,
                      style: EduStreakTheme.fontCaption(
                        color: EduStreakTheme.emeraldGreen,
                        weight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ─── PENDING INSTITUTIONAL APPROVALS SECTION ─────────────────────────────
  Widget _buildPendingSchoolApprovalsSection() {
    return StreamBuilder<List<SchoolModel>>(
      stream: _schoolService.getSchoolsStream(),
      builder: (context, snapshot) {
        final allSchools = snapshot.data ?? [];
        final pendingSchools = allSchools.where((s) => s.isPendingApproval).toList();

        if (pendingSchools.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 22),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF161536),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: EduStreakTheme.amberGold.withValues(alpha: 0.5), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: EduStreakTheme.amberGold.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: EduStreakTheme.amberGold.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.gavel_rounded, color: EduStreakTheme.amberGold, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Institutional Registrations Awaiting Verification',
                            style: EduStreakTheme.fontHeading2(color: Colors.white, weight: FontWeight.w800),
                          ),
                          Text(
                            '${pendingSchools.length} ${pendingSchools.length == 1 ? 'school has' : 'schools have'} submitted accreditation documents for Central Admin approval.',
                            style: EduStreakTheme.fontCaption(color: EduStreakTheme.studentDarkTextMuted),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: EduStreakTheme.amberGold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: EduStreakTheme.amberGold),
                    ),
                    child: Text(
                      '${pendingSchools.length} ACTION REQUIRED',
                      style: const TextStyle(color: EduStreakTheme.amberGold, fontSize: 11, fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: pendingSchools.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final school = pendingSchools[index];

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F1230),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: EduStreakTheme.studentDarkBorder),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: school.type.color.withValues(alpha: 0.2),
                          child: Icon(Icons.account_balance_rounded, color: school.type.color, size: 20),
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
                                      school.name,
                                      style: EduStreakTheme.fontBody(color: Colors.white, weight: FontWeight.w800),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: school.type.color.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      school.type.displayName,
                                      style: TextStyle(color: school.type.color, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Code: ${school.code}',
                                    style: const TextStyle(color: EduStreakTheme.neonCyan, fontSize: 11, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${school.cityOrVillage.isNotEmpty ? "${school.cityOrVillage}, " : ""}${school.mandal}, ${school.district} • Contact: ${school.contactPerson} (${school.contactEmail})',
                                style: EduStreakTheme.fontCaption(color: EduStreakTheme.studentDarkTextMuted),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Wrap(
                          spacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => _showRejectSchoolDialog(school),
                              icon: const Icon(Icons.close_rounded, size: 16),
                              label: const Text('Reject'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: EduStreakTheme.rosePink,
                                side: const BorderSide(color: EduStreakTheme.rosePink),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () => _confirmApproveSchool(school),
                              icon: const Icon(Icons.check_circle_rounded, size: 16),
                              label: const Text('Authorize & Activate'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: EduStreakTheme.emeraldGreen,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmApproveSchool(SchoolModel school) async {
    try {
      await _schoolService.approveSchoolRegistration(school.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${school.name} registration approved and activated!'),
            backgroundColor: EduStreakTheme.emeraldGreen,
          ),
        );
        _fetchLiveDatabaseCounts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Approval failed: $e'),
            backgroundColor: EduStreakTheme.rosePink,
          ),
        );
      }
    }
  }

  void _showRejectSchoolDialog(SchoolModel school) {
    final reasonCtrl = TextEditingController();

    showAdaptiveEduStreakModal(
      context: context,
      maxWidth: 450,
      title: 'Reject Registration: ${school.name}',
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please provide a regulatory or document deficiency reason for rejecting this institution. The school administrator will be notified.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Rejection Reason (Required)',
                labelStyle: TextStyle(color: Colors.white70),
                hintText: 'e.g. Invalid affiliation certificate or unrecognized board code.',
                hintStyle: TextStyle(color: Colors.white30),
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
                    final reason = reasonCtrl.text.trim();
                    if (reason.isEmpty) return;
                    await _schoolService.rejectSchoolRegistration(school.id, reason);
                    if (ctx.mounted) Navigator.of(ctx).pop();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${school.name} registration rejected.'),
                          backgroundColor: EduStreakTheme.rosePink,
                        ),
                      );
                      _fetchLiveDatabaseCounts();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EduStreakTheme.rosePink,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Reject Registration'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── SCHOOLS BY TYPE DONUT CHART CARD (LIVE PROPORTIONS) ─────────────────
  Widget _buildSchoolsByTypeCard() {
    final total = _counts['totalSchools'] ?? 0;
    final gov = _counts['government'] ?? 0;
    final pvt = _counts['private'] ?? 0;
    final cbse = _counts['cbse'] ?? 0;

    final govPct = total > 0 ? (gov / total * 100).toStringAsFixed(1) : '0.0';
    final pvtPct = total > 0 ? (pvt / total * 100).toStringAsFixed(1) : '0.0';
    final cbsePct = total > 0 ? (cbse / total * 100).toStringAsFixed(1) : '0.0';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: EduStreakTheme.darkCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.pie_chart_rounded, size: 18, color: EduStreakTheme.neonCyan),
                  const SizedBox(width: 8),
                  Text(
                    'Schools by Type',
                    style: EduStreakTheme.fontHeading2(
                      color: Colors.white,
                      weight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: EduStreakTheme.primaryViolet.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$total Total',
                  style: EduStreakTheme.fontCaption(
                    color: EduStreakTheme.primaryVioletLight,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, chartConstraints) {
              final chartWidget = SizedBox(
                width: 130,
                height: 130,
                child: CustomPaint(
                  painter: _LiveDonutChartPainter(gov: gov, pvt: pvt, cbse: cbse, total: total),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$total',
                          style: EduStreakTheme.fontHeading1(
                            color: Colors.white,
                            weight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Schools',
                          style: EduStreakTheme.fontCaption(
                            color: EduStreakTheme.darkTextSub,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );

              final legendWidget = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLegendItem(
                    label: 'Government',
                    count: '$gov',
                    percent: '$govPct%',
                    color: const Color(0xFF7C6FFF),
                    description: 'AP State Board / SCERT',
                  ),
                  const SizedBox(height: 10),
                  _buildLegendItem(
                    label: 'Private Schools',
                    count: '$pvt',
                    percent: '$pvtPct%',
                    color: const Color(0xFF00E5FF),
                    description: 'Custom & Autonomous',
                  ),
                  const SizedBox(height: 10),
                  _buildLegendItem(
                    label: 'CBSE Affiliated',
                    count: '$cbse',
                    percent: '$cbsePct%',
                    color: const Color(0xFFF59E0B),
                    description: 'Central NCERT Pattern',
                  ),
                ],
              );

              if (chartConstraints.maxWidth < 420) {
                return Column(
                  children: [
                    Center(child: chartWidget),
                    const SizedBox(height: 20),
                    legendWidget,
                  ],
                );
              }

              return Row(
                children: [
                  chartWidget,
                  const SizedBox(width: 24),
                  Expanded(child: legendWidget),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required String label,
    required String count,
    required String percent,
    required Color color,
    required String description,
  }) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.5),
                blurRadius: 6,
                offset: const Offset(0, 1),
              )
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      style: EduStreakTheme.fontLabel(
                        color: Colors.white,
                        weight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$count ($percent)',
                    style: EduStreakTheme.fontCaption(
                      color: color,
                      weight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: EduStreakTheme.fontCaption(
                  color: EduStreakTheme.darkTextMuted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── CURRICULUM MANAGEMENT STREAM ────────────────────────────────────────
  Widget _buildCurriculumManagementCard() {
    return StreamBuilder<List<CurriculumTemplateModel>>(
      stream: _curriculumService.getTemplatesStream(),
      builder: (context, snapshot) {
        final templates = snapshot.data ?? [];

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: EduStreakTheme.darkCardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 420;
                  return isCompact
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.layers_rounded, size: 18, color: EduStreakTheme.primaryVioletLight),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Curriculum Management',
                                    style: EduStreakTheme.fontHeading3(
                                      color: Colors.white,
                                      weight: FontWeight.w800,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: () {
                                  setState(() => _selectedNavIndex = 2);
                                },
                                icon: const Text('Manage Standards'),
                                label: const Icon(Icons.arrow_forward_rounded, size: 14),
                                style: TextButton.styleFrom(
                                  foregroundColor: EduStreakTheme.neonCyan,
                                  padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  const Icon(Icons.layers_rounded, size: 18, color: EduStreakTheme.primaryVioletLight),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      'Curriculum Management',
                                      style: EduStreakTheme.fontHeading2(
                                        color: Colors.white,
                                        weight: FontWeight.w800,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                setState(() => _selectedNavIndex = 2);
                              },
                              icon: const Text('Manage Standards'),
                              label: const Icon(Icons.arrow_forward_rounded, size: 14),
                              style: TextButton.styleFrom(
                                foregroundColor: EduStreakTheme.neonCyan,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ],
                        );
                },
              ),
              const SizedBox(height: 14),
              if (templates.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: CircularProgressIndicator(color: EduStreakTheme.primaryViolet),
                  ),
                )
              else
                ...templates.map((tpl) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F1434),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF222B5C)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: EduStreakTheme.primaryViolet.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.auto_stories_rounded, color: EduStreakTheme.primaryViolet, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tpl.name,
                                style: EduStreakTheme.fontLabel(
                                  color: Colors.white,
                                  weight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                tpl.description,
                                style: EduStreakTheme.fontCaption(
                                  color: EduStreakTheme.darkTextMuted,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: EduStreakTheme.emeraldGreen.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            tpl.isActive ? 'Active Aligned' : 'Draft',
                            style: EduStreakTheme.fontCaption(
                              color: EduStreakTheme.emeraldGreen,
                              weight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  // ─── LIVE SCHOOL REGISTRY STREAM & ACTIONS ────────────────────────────────
  Widget _buildInstitutionalAuditCard() {
    return StreamBuilder<List<SchoolModel>>(
      stream: _schoolService.getSchoolsStream(),
      builder: (context, snapshot) {
        final schools = snapshot.data ?? [];

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: EduStreakTheme.darkCardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, headerConstraints) {
                  final isCompact = headerConstraints.maxWidth < 650;
                  final titleWidget = Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified_user_rounded, size: 18, color: EduStreakTheme.emeraldGreen),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Live Institutional Directory & Compliance Registry',
                          style: EduStreakTheme.fontHeading2(
                            color: Colors.white,
                            weight: FontWeight.w800,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  );

                  final buttonsWidget = Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _showRegisterSchoolDialog,
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: const Text('Register School'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: EduStreakTheme.primaryViolet,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: _showCsvImportDialog,
                        icon: const Icon(Icons.upload_file_rounded, size: 16),
                        label: const Text('Import Students CSV'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: EduStreakTheme.neonCyan,
                          side: const BorderSide(color: EduStreakTheme.neonCyan),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  );

                  if (isCompact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        titleWidget,
                        const SizedBox(height: 12),
                        buttonsWidget,
                      ],
                    );
                  }

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: titleWidget),
                      const SizedBox(width: 12),
                      buttonsWidget,
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              if (schools.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.account_balance_outlined, size: 48, color: Colors.white24),
                        const SizedBox(height: 12),
                        Text('No institutions registered yet.', style: EduStreakTheme.fontBody(color: Colors.white70)),
                        const SizedBox(height: 8),
                        Text('Click "Register School" above to onboard your first school.', style: EduStreakTheme.fontCaption()),
                      ],
                    ),
                  ),
                )
              else
                ...schools.map((sch) {
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => SchoolDetailsScreen.open(context, sch),
                      borderRadius: BorderRadius.circular(10),
                      hoverColor: EduStreakTheme.primaryViolet.withValues(alpha: 0.1),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F1434),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF222B5C)),
                        ),
                        child: LayoutBuilder(
                          builder: (context, cardConstraints) {
                            final isCardCompact = cardConstraints.maxWidth < 460;
                            final badgeWidget = Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: sch.type.color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: sch.type.color.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                sch.type.displayName,
                                style: EduStreakTheme.fontCaption(
                                  color: sch.type.color,
                                  weight: FontWeight.w700,
                                ),
                              ),
                            );

                            return Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: sch.type.color.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Icon(Icons.school_rounded, color: sch.type.color, size: 20),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        sch.name,
                                        style: EduStreakTheme.fontLabel(
                                          color: Colors.white,
                                          weight: FontWeight.w700,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        '${sch.code} • ${sch.district}, ${sch.state} • ${sch.totalStudents} Students • ${sch.totalTeachers} Teachers',
                                        style: EduStreakTheme.fontCaption(
                                          color: EduStreakTheme.darkTextMuted,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (isCardCompact) ...[
                                        const SizedBox(height: 6),
                                        badgeWidget,
                                      ],
                                    ],
                                  ),
                                ),
                                if (!isCardCompact) ...[
                                  const SizedBox(width: 8),
                                  badgeWidget,
                                ],
                                const SizedBox(width: 8),
                                const Icon(Icons.chevron_right_rounded, color: Colors.white38, size: 20),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  // ─── DIALOG: REGISTER NEW SCHOOL ─────────────────────────────────────────
  void _showRegisterSchoolDialog() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final codeController = TextEditingController();
    final districtController = TextEditingController();
    SchoolType selectedType = SchoolType.government;
    bool isSubmitting = false;

    showAdaptiveEduStreakModal(
      context: context,
      isDark: true,
      title: 'Register New Institution',
      icon: const Icon(Icons.add_business_rounded, color: EduStreakTheme.neonCyan),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Form(
            key: formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Institution Name',
                      hintText: 'e.g. Z.P. High School, Kankipadu',
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Enter school name' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: codeController,
                    style: const TextStyle(color: Colors.white),
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: 'Unique School Code',
                      hintText: 'e.g. AP-KRI-042 or CBSE-VIJ-108',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.auto_fix_high_rounded, color: EduStreakTheme.neonCyan, size: 20),
                        tooltip: 'Generate Unique Code',
                        onPressed: () async {
                          final district = districtController.text.trim();
                          final autoCode = await _schoolService.generateUniqueSchoolCode(
                            type: selectedType,
                            district: district.isNotEmpty ? district : 'GEN',
                          );
                          setDialogState(() {
                            codeController.text = autoCode;
                          });
                        },
                      ),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Enter unique school code' : null,
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<SchoolType>(
                    initialValue: selectedType,
                    dropdownColor: const Color(0xFF141A42),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'School Type / Board Pattern'),
                    items: SchoolType.values.map((t) {
                      return DropdownMenuItem(
                        value: t,
                        child: Text(t.displayName, style: TextStyle(color: t.color)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedType = val);
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: districtController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'District',
                      hintText: 'e.g. Krishna, NTR, Visakhapatnam',
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Enter district' : null,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;
                                setDialogState(() => isSubmitting = true);
                                try {
                                  await _schoolService.createSchool(
                                    name: nameController.text.trim(),
                                    code: codeController.text.trim(),
                                    type: selectedType,
                                    district: districtController.text.trim(),
                                    curriculumTemplateId: selectedType.defaultCurriculumCode,
                                  );
                                  await _fetchLiveDatabaseCounts();
                                  if (ctx.mounted) Navigator.pop(ctx);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Institution registered successfully!'),
                                        backgroundColor: EduStreakTheme.emeraldGreen,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  setDialogState(() => isSubmitting = false);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: EduStreakTheme.rosePink),
                                    );
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(backgroundColor: EduStreakTheme.primaryViolet),
                        child: isSubmitting
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Register Institution', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

  // ─── DIALOG: CSV STUDENT ROSTER IMPORT ───────────────────────────────────
  void _showCsvImportDialog() {
    final csvController = TextEditingController(
      text: '''roll_number,student_name,class,section,parent_name,parent_email,parent_phone
101,Alex Chen,10,A,John Chen,parent1@edustreak.com,9848012345
102,Emma Wilson,10,A,Mary Wilson,parent2@edustreak.com,9848012346
103,James Anderson,10,A,David Anderson,parent3@edustreak.com,9848012347''',
    );

    String? selectedSchoolId;
    String? selectedSchoolCode;
    CsvValidationResult? validationResult;
    bool isValidating = false;
    bool isImporting = false;

    showAdaptiveEduStreakModal(
      context: context,
      isDark: true,
      maxWidth: 620,
      title: 'Import Students Roster via CSV',
      icon: const Icon(Icons.upload_file_rounded, color: EduStreakTheme.neonCyan),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Select target school and paste CSV records. Format: roll_number, student_name, class, section, parent_name, parent_email, parent_phone',
                  style: EduStreakTheme.fontCaption(color: EduStreakTheme.darkTextSub),
                ),
                const SizedBox(height: 14),
                // Target School Selector
                StreamBuilder<List<SchoolModel>>(
                  stream: _schoolService.getSchoolsStream(),
                  builder: (context, snap) {
                    final schools = snap.data ?? [];
                    if (schools.isNotEmpty && selectedSchoolId == null) {
                      selectedSchoolId = schools.first.id;
                      selectedSchoolCode = schools.first.code;
                    }

                    return DropdownButtonFormField<String>(
                      initialValue: selectedSchoolId,
                      dropdownColor: const Color(0xFF141A42),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Target Institution'),
                      items: schools.map((s) {
                        return DropdownMenuItem(
                          value: s.id,
                          child: Text('${s.name} (${s.code})'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          final sch = schools.firstWhere((e) => e.id == val);
                          setDialogState(() {
                            selectedSchoolId = sch.id;
                            selectedSchoolCode = sch.code;
                            validationResult = null; // Re-validate needed
                          });
                        }
                      },
                    );
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: csvController,
                  maxLines: 6,
                  style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 12),
                  decoration: const InputDecoration(
                    labelText: 'CSV Data (Raw Text)',
                    hintText: 'Paste comma-separated rows here...',
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: isValidating
                          ? null
                          : () async {
                              if (selectedSchoolId == null) return;
                              setDialogState(() => isValidating = true);
                              final res = await _csvService.validateCsv(
                                csvContent: csvController.text,
                                schoolId: selectedSchoolId!,
                              );
                              setDialogState(() {
                                validationResult = res;
                                isValidating = false;
                              });
                            },
                      icon: const Icon(Icons.rule_rounded, size: 16),
                      label: const Text('Validate CSV'),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E265C)),
                    ),
                    if (validationResult != null)
                      Text(
                        '${validationResult!.validRows.length} Valid • ${validationResult!.invalidRows.length} Errors',
                        style: TextStyle(
                          color: validationResult!.hasErrors ? EduStreakTheme.rosePink : EduStreakTheme.emeraldGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
                if (validationResult != null && validationResult!.invalidRows.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: EduStreakTheme.rosePink.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: EduStreakTheme.rosePink),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: validationResult!.invalidRows.take(4).map((r) {
                        return Text(
                          'Row ${r.rowIndex}: ${r.error}',
                          style: const TextStyle(color: Colors.white, fontSize: 11),
                        );
                      }).toList(),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: (validationResult == null || validationResult!.validRows.isEmpty || isImporting)
                          ? null
                          : () async {
                              setDialogState(() => isImporting = true);
                              try {
                                final summary = await _csvService.executeImport(
                                  schoolId: selectedSchoolId!,
                                  schoolCode: selectedSchoolCode ?? 'SCH',
                                  rows: validationResult!.validRows,
                                );
                                await _fetchLiveDatabaseCounts();
                                if (ctx.mounted) Navigator.pop(ctx);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Import Complete! Created ${summary.studentsCreated} students and ${summary.parentsCreated} parent accounts.',
                                      ),
                                      backgroundColor: EduStreakTheme.emeraldGreen,
                                    ),
                                  );
                                }
                              } catch (e) {
                                setDialogState(() => isImporting = false);
                              }
                            },
                      style: ElevatedButton.styleFrom(backgroundColor: EduStreakTheme.neonCyan),
                      child: isImporting
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                          : const Text('Commit & Create Accounts', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── TABS ────────────────────────────────────────────────────────────────
  Widget _buildSchoolsDirectoryTab() => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
    child: _buildInstitutionalAuditCard(),
  );
}

/// Custom painter for the Donut Chart rendering live proportions
class _LiveDonutChartPainter extends CustomPainter {
  final int gov;
  final int pvt;
  final int cbse;
  final int total;

  _LiveDonutChartPainter({
    required this.gov,
    required this.pvt,
    required this.cbse,
    required this.total,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 14.0;

    final paintGov = Paint()
      ..color = const Color(0xFF7C6FFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final paintPvt = Paint()
      ..color = const Color(0xFF00E5FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final paintCbse = Paint()
      ..color = const Color(0xFFF59E0B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final paintEmpty = Paint()
      ..color = const Color(0xFF1E265C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

    if (total == 0) {
      canvas.drawCircle(center, radius - strokeWidth / 2, paintEmpty);
      return;
    }

    final sweepGov = (gov / total) * 2 * math.pi;
    final sweepPvt = (pvt / total) * 2 * math.pi;
    final sweepCbse = (cbse / total) * 2 * math.pi;

    double startAngle = -math.pi / 2;
    const gap = 0.05;

    if (sweepGov > gap) {
      canvas.drawArc(rect, startAngle, sweepGov - gap, false, paintGov);
      startAngle += sweepGov;
    }

    if (sweepPvt > gap) {
      canvas.drawArc(rect, startAngle, sweepPvt - gap, false, paintPvt);
      startAngle += sweepPvt;
    }

    if (sweepCbse > gap) {
      canvas.drawArc(rect, startAngle, sweepCbse - gap, false, paintCbse);
    }
  }

  @override
  bool shouldRepaint(covariant _LiveDonutChartPainter oldDelegate) =>
      oldDelegate.total != total ||
      oldDelegate.gov != gov ||
      oldDelegate.pvt != pvt ||
      oldDelegate.cbse != cbse;
}
