import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'student/student_portal_screen.dart';
import 'teacher/teacher_portal_screen.dart';
import 'principal/principal_portal_screen.dart';
import 'parent/parent_portal_screen.dart';
import 'admin/central_admin_portal_screen.dart';

/// Production-ready role-enforced portal router.
/// Displays the dedicated portal strictly bound to the authenticated user's role.
/// Only accounts with the verified 'admin' role may preview or switch across portals.
class EduStreakPortalRouter extends StatefulWidget {
  final String initialRole;

  const EduStreakPortalRouter({
    super.key,
    this.initialRole = 'student',
  });

  @override
  State<EduStreakPortalRouter> createState() => _EduStreakPortalRouterState();
}

class _EduStreakPortalRouterState extends State<EduStreakPortalRouter> {
  String? _selectedRole;

  void _switchPortal(String targetRole) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.currentUser;
    final userRole = currentUser?.role.toLowerCase() ?? widget.initialRole.toLowerCase();

    // Central Admin is authorized to preview and switch portals
    if (userRole == 'admin') {
      setState(() {
        _selectedRole = targetRole.toLowerCase();
      });
      return;
    }

    // Non-admin roles are strictly prohibited from switching to unauthorized portals
    if (targetRole.toLowerCase() != userRole) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Access Restricted: Your verified role is "${userRole.toUpperCase()}". Unauthorized portal switching is prohibited.',
          ),
          backgroundColor: const Color(0xFFEF4444),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() {
      _selectedRole = targetRole.toLowerCase();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<UserProvider>(context).currentUser;
    final effectiveRole = _selectedRole ?? (currentUser?.role.toLowerCase() ?? widget.initialRole.toLowerCase());

    switch (effectiveRole) {
      case 'principal':
        return PrincipalPortalScreen(onPortalSwitch: _switchPortal);
      case 'teacher':
        return TeacherPortalScreen(onPortalSwitch: _switchPortal);
      case 'parent':
        return ParentPortalScreen(onPortalSwitch: _switchPortal);
      case 'admin':
        return CentralAdminPortalScreen(onPortalSwitch: _switchPortal);
      case 'student':
      default:
        return StudentPortalScreen(onPortalSwitch: _switchPortal);
    }
  }
}

