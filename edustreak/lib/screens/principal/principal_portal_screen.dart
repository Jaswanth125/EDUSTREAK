import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../services/auth_service.dart';
import '../../services/principal_service.dart';
import '../../models/user_model.dart';
import '../../models/school_model.dart';
import '../../utils/edustreak_theme.dart';
import '../../widgets/responsive/responsive_scaffold.dart';
import 'tabs/principal_dashboard_tab.dart';
import 'tabs/principal_school_overview_tab.dart';
import 'tabs/principal_students_tab.dart';
import 'tabs/principal_teachers_tab.dart';
import 'tabs/principal_academics_tab.dart';
import 'tabs/principal_attendance_tab.dart';
import 'tabs/principal_ai_insights_tab.dart';
import 'tabs/principal_parent_management_tab.dart';
import 'tabs/principal_approvals_tab.dart';
import 'tabs/principal_reports_tab.dart';
import 'tabs/principal_announcements_tab.dart';
import 'tabs/principal_settings_tab.dart';
import '../chat/realtime_chat_list_screen.dart';

class PrincipalPortalScreen extends StatefulWidget {
  final ValueChanged<String>? onPortalSwitch;

  const PrincipalPortalScreen({super.key, this.onPortalSwitch});

  @override
  State<PrincipalPortalScreen> createState() => _PrincipalPortalScreenState();
}

class _PrincipalPortalScreenState extends State<PrincipalPortalScreen> {
  final _principalService = PrincipalService();
  int _selectedNavIndex = 0;
  SchoolModel? _school;
  bool _isLoadingSchool = true;

  @override
  void initState() {
    super.initState();
    _loadSchool();
  }

  Future<void> _loadSchool() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final schoolId = userProvider.currentUser?.schoolId ?? 'sch_ap_001';
    final s = await _principalService.getSchoolDetails(schoolId);
    if (mounted) {
      setState(() {
        _school = s;
        _isLoadingSchool = false;
      });
    }
  }

  Future<void> _logout() async {
    final nav = Navigator.of(context, rootNavigator: true);
    await AuthService().signOut();
    if (mounted) {
      Provider.of<UserProvider>(context, listen: false).clearUser();
      nav.pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  UserModel _getEffectivePrincipal(UserModel? currentUser) {
    if (currentUser != null && currentUser.role.toLowerCase() == 'principal') {
      return currentUser;
    }
    return UserModel(
      id: currentUser?.id ?? 'prin_001',
      name: currentUser?.name.isNotEmpty == true && currentUser!.name != 'Student'
          ? currentUser.name
          : 'Dr. Sudhir Sharma',
      email: currentUser?.email.isNotEmpty == true
          ? currentUser!.email
          : 'principal@edustreak.com',
      role: 'principal',
      schoolId: 'sch_ap_001',
      schoolCode: 'AP-KRI-042',
      academicYear: '2024-2025',
    );
  }

  Widget _buildTabBody(UserModel principal, SchoolModel school) {
    switch (_selectedNavIndex) {
      case 1:
        return PrincipalSchoolOverviewTab(school: school, principal: principal);
      case 2:
        return PrincipalStudentsTab(school: school);
      case 3:
        return PrincipalTeachersTab(school: school);
      case 4:
        return PrincipalAcademicsTab(school: school);
      case 5:
        return PrincipalAttendanceTab(school: school);
      case 6:
        return PrincipalAIInsightsTab(school: school);
      case 7:
        return PrincipalParentManagementTab(
          school: school,
          onBroadcastToParents: () => setState(() => _selectedNavIndex = 10),
        );
      case 8:
        return PrincipalApprovalsTab(school: school, principal: principal);
      case 9:
        return PrincipalReportsTab(school: school);
      case 10:
        return PrincipalAnnouncementsTab(school: school, principal: principal);
      case 11:
        return const RealtimeChatListScreen(showAppBar: false);
      case 12:
        return PrincipalSettingsTab(school: school, principal: principal, onLogout: _logout);
      case 0:
      default:
        return PrincipalDashboardTab(
          school: school,
          principal: principal,
          onNavigateToTab: (index) => setState(() => _selectedNavIndex = index),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<UserProvider>(context).currentUser;
    final principal = _getEffectivePrincipal(currentUser);

    if (_isLoadingSchool || _school == null) {
      return const Scaffold(
        backgroundColor: EduStreakTheme.studentDarkBg,
        body: Center(
          child: CircularProgressIndicator(color: EduStreakTheme.primaryViolet),
        ),
      );
    }

    final school = _school!;
    final principalName = principal.name;

    return ResponsiveScaffold(
      portalType: 'principal',
      selectedIndex: _selectedNavIndex,
      onItemSelected: (index) => setState(() => _selectedNavIndex = index),
      onLogout: _logout,
      user: principal,
      userName: principalName,
      userSubtitle: '${school.code} • Principal',
      headerTitle: 'Principal Portal',
      headerSubtitle: '${school.name} • $principalName',
      portalIcon: Icons.account_balance_rounded,
      portalIconColor: EduStreakTheme.secondaryPurple,
      contextPillText: '${school.academicYear} • Active',
      contextPillOptions: [
        '${school.academicYear} • Active',
        '2023-2024 • Archived',
      ],
      onContextPillChanged: (_) {},
      onDevSwitchPortal: widget.onPortalSwitch,
      avatarWidget: Builder(
        builder: (ctx) {
          final isCompact = MediaQuery.sizeOf(ctx).width < 900;
          final avatar = Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF9333EA), Color(0xFF6B21A8)],
              ),
              border: Border.all(color: EduStreakTheme.secondaryPurple, width: 2),
            ),
            child: Center(
              child: Text(
                principalName.isNotEmpty ? principalName[0].toUpperCase() : 'P',
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
                  right: -1,
                  bottom: -1,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: EduStreakTheme.emeraldGreen,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF0C1030), width: 1.5),
                    ),
                  ),
                ),
              ],
            );
          }

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              avatar,
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    principalName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    school.code,
                    style: const TextStyle(
                      color: EduStreakTheme.studentDarkTextMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
      body: _buildTabBody(principal, school),
    );
  }
}
