import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import '../../services/school_registration_service.dart';
import '../../utils/edustreak_theme.dart';
import '../../utils/responsive_breakpoints.dart';
import '../../widgets/responsive/registration_step_indicator.dart';
import '../portal_router.dart';
import 'principal_invitation_screen.dart';

class SignUpScreen extends StatefulWidget {
  final int? initialRoleIndex; // 0: Student, 1: Teacher, 2: Parent, null: Landing Page

  const SignUpScreen({super.key, this.initialRoleIndex});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _service = SchoolRegistrationService();

  // Navigation State
  String? _selectedRole; // 'student' | 'teacher' | 'parent' | null (Landing view)
  int _currentStep = 0; // 0: School Record, 1: Identity, 2: Password, 3: Success

  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Student Form State
  final _studentSchoolCodeController = TextEditingController();
  final _studentRollController = TextEditingController();
  StudentVerificationPreview? _studentPreview;

  // Teacher Form State
  final _teacherSchoolCodeController = TextEditingController();
  final _teacherEmpIdController = TextEditingController();
  TeacherVerificationPreview? _teacherPreview;

  // Parent Form State
  final _parentSchoolCodeController = TextEditingController();
  final _parentStudentIdController = TextEditingController();
  final _parentContactController = TextEditingController();
  final _parentNameController = TextEditingController();
  final _parentEmailController = TextEditingController();
  ParentVerificationPreview? _parentPreview;

  // Step 2: Verification Challenge State
  final _otpOrPinController = TextEditingController();
  IdentityVerificationChallenge? _challenge;
  bool _usePinVerification = false;

  // Step 3: Password & Security State
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Step 4: Provisioned Account State
  UserModel? _createdUser;

  @override
  void initState() {
    super.initState();
    if (widget.initialRoleIndex != null) {
      if (widget.initialRoleIndex == 0) _selectedRole = 'student';
      if (widget.initialRoleIndex == 1) _selectedRole = 'teacher';
      if (widget.initialRoleIndex == 2) _selectedRole = 'parent';
    }
  }

  @override
  void dispose() {
    _studentSchoolCodeController.dispose();
    _studentRollController.dispose();
    _teacherSchoolCodeController.dispose();
    _teacherEmpIdController.dispose();
    _parentSchoolCodeController.dispose();
    _parentStudentIdController.dispose();
    _parentContactController.dispose();
    _parentNameController.dispose();
    _parentEmailController.dispose();
    _otpOrPinController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _resetFlow() {
    setState(() {
      _selectedRole = null;
      _currentStep = 0;
      _errorMessage = null;
      _studentPreview = null;
      _teacherPreview = null;
      _parentPreview = null;
      _challenge = null;
      _createdUser = null;
      _otpOrPinController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
    });
  }

  // ── STEP 1: VERIFY INSTITUTIONAL RECORD ────────────────────────────────────
  Future<void> _verifyStudentRecord() async {
    final schoolCode = _studentSchoolCodeController.text.trim();
    final roll = _studentRollController.text.trim();

    if (schoolCode.isEmpty || roll.isEmpty) {
      setState(() => _errorMessage = 'Please enter both School Code and Roll / Admission Number.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final preview = await _service.lookupStudentRecord(schoolCode, roll);
      // Auto-send OTP challenge for step 2
      final challenge = await _service.sendIdentityVerification(
        schoolCode: preview.schoolCode,
        targetType: 'student',
        rosterId: preview.rosterId,
        contactMethod: preview.requiresPin ? 'pin' : 'sms',
      );

      setState(() {
        _studentPreview = preview;
        _challenge = challenge;
        _usePinVerification = preview.requiresPin;
        _currentStep = 1;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyTeacherRecord() async {
    final schoolCode = _teacherSchoolCodeController.text.trim();
    final empId = _teacherEmpIdController.text.trim();

    if (schoolCode.isEmpty || empId.isEmpty) {
      setState(() => _errorMessage = 'Please enter both School Code and Employee ID.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final preview = await _service.lookupTeacherRecord(schoolCode, empId);
      final challenge = await _service.sendIdentityVerification(
        schoolCode: preview.schoolCode,
        targetType: 'teacher',
        rosterId: preview.rosterId,
        contactMethod: 'email',
      );

      setState(() {
        _teacherPreview = preview;
        _challenge = challenge;
        _currentStep = 1;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyParentRelationship() async {
    final schoolCode = _parentSchoolCodeController.text.trim();
    final studentId = _parentStudentIdController.text.trim();
    final contact = _parentContactController.text.trim();

    if (schoolCode.isEmpty || studentId.isEmpty || contact.isEmpty) {
      setState(() => _errorMessage = 'Please provide School Code, Student ID, and your Phone or Email.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final preview = await _service.lookupParentRelationship(
        schoolCode: schoolCode,
        studentIdentifier: studentId,
        parentContact: contact,
      );

      final challenge = await _service.sendIdentityVerification(
        schoolCode: preview.schoolCode,
        targetType: 'student',
        rosterId: preview.rosterId,
        contactMethod: preview.requiresPin ? 'pin' : 'sms',
      );

      setState(() {
        _parentPreview = preview;
        _challenge = challenge;
        _usePinVerification = preview.requiresPin;
        _currentStep = 1;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── STEP 2: VERIFY IDENTITY CHALLENGE (OTP OR PIN) ─────────────────────────
  Future<void> _verifyChallenge() async {
    final code = _otpOrPinController.text.trim();
    if (code.isEmpty) {
      setState(() => _errorMessage = 'Please enter the 6-digit verification code or school PIN.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String? rosterId;
      String? targetType;

      if (_selectedRole == 'student') {
        rosterId = _studentPreview?.rosterId;
        targetType = 'student';
      } else if (_selectedRole == 'teacher') {
        rosterId = _teacherPreview?.rosterId;
        targetType = 'teacher';
      } else if (_selectedRole == 'parent') {
        rosterId = _parentPreview?.rosterId;
        targetType = 'student';
      }

      final isValid = await _service.verifyIdentityChallenge(
        challengeId: _challenge?.challengeId ?? '',
        code: code,
        pin: code,
        rosterId: rosterId,
        targetType: targetType,
      );

      if (!isValid) {
        throw Exception('Invalid verification code or PIN. Please try again.');
      }

      setState(() {
        _currentStep = 2;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── STEP 3: CREATE PASSWORD & CLAIM ACCOUNT ───────────────────────────────
  Future<void> _createPasswordAndClaim() async {
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (password.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters.');
      return;
    }
    if (password != confirm) {
      setState(() => _errorMessage = 'Passwords do not match.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      UserModel user;
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      if (_selectedRole == 'student') {
        final preview = _studentPreview!;
        user = await _service.claimStudentAccount(
          schoolCode: preview.schoolCode,
          identifier: preview.rollNumber,
          password: password,
          pin: _otpOrPinController.text.trim(),
        );
      } else if (_selectedRole == 'teacher') {
        final preview = _teacherPreview!;
        user = await _service.claimTeacherAccount(
          schoolCode: preview.schoolCode,
          employeeId: preview.employeeId,
          password: password,
          pin: _otpOrPinController.text.trim(),
        );
      } else if (_selectedRole == 'parent') {
        final preview = _parentPreview!;
        final name = _parentNameController.text.trim();
        final email = _parentEmailController.text.trim();

        if (name.isEmpty) throw Exception('Please enter your full parent or guardian name.');
        if (email.isEmpty || !email.contains('@')) throw Exception('Please enter a valid email address.');

        user = await _service.registerParentAndLinkChild(
          parentName: name,
          email: email,
          password: password,
          schoolCode: preview.schoolCode,
          studentIdentifier: preview.rollNumber,
          verificationPin: _otpOrPinController.text.trim(),
        );
      } else {
        throw Exception('Invalid registration context.');
      }

      await userProvider.loadUser(user.id);

      setState(() {
        _createdUser = user;
        _currentStep = 3;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToRolePortal() {
    final role = _createdUser?.role ?? _selectedRole ?? 'student';
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => EduStreakPortalRouter(initialRole: role),
      ),
      (route) => false,
    );
  }

  double _calculatePasswordStrength(String pass) {
    if (pass.isEmpty) return 0.0;
    double score = 0.0;
    if (pass.length >= 6) score += 0.3;
    if (pass.length >= 10) score += 0.2;
    if (RegExp(r'[A-Z]').hasMatch(pass)) score += 0.2;
    if (RegExp(r'[0-9]').hasMatch(pass)) score += 0.15;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(pass)) score += 0.15;
    return score.clamp(0.0, 1.0);
  }

  Color _getStrengthColor(double strength) {
    if (strength < 0.4) return const Color(0xFFEF4444);
    if (strength < 0.7) return const Color(0xFFF59E0B);
    return const Color(0xFF10B981);
  }

  String _getStrengthLabel(double strength) {
    if (strength < 0.4) return 'Weak';
    if (strength < 0.7) return 'Moderate';
    return 'Strong';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = context.screenWidth;
    final isDesktopSplit = screenWidth >= 1024;

    return Scaffold(
      backgroundColor: const Color(0xFF070B1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF070B1E),
        elevation: 0,
        leading: _selectedRole != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () {
                  if (_currentStep > 0 && _currentStep < 3) {
                    setState(() => _currentStep--);
                  } else {
                    _resetFlow();
                  }
                },
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [EduStreakTheme.primaryViolet, EduStreakTheme.cyanAccent],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 8),
              const Text(
                'EDUSTREAK',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (screenWidth < 360)
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              tooltip: 'Sign In',
              icon: const Icon(Icons.login_rounded, size: 20, color: EduStreakTheme.cyanAccent),
            )
          else
            TextButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.login_rounded, size: 16, color: EduStreakTheme.cyanAccent),
              label: const Text(
                'Sign In',
                style: TextStyle(color: EduStreakTheme.cyanAccent, fontWeight: FontWeight.bold),
              ),
            ),
          const SizedBox(width: 4),
        ],
        centerTitle: screenWidth >= 600,
      ),
      body: SafeArea(
        child: isDesktopSplit
            ? _buildDesktopSplitLayout()
            : _buildMobileOrTabletLayout(),
      ),
    );
  }

  /// Desktop split layout (Hero showcase on left, Card/Wizard on right)
  Widget _buildDesktopSplitLayout() {
    return Row(
      children: [
        // Left Column: Branding Showcase
        Expanded(
          flex: 5,
          child: Container(
            padding: const EdgeInsets.all(48),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0F0B2C), Color(0xFF1B1446)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: EduStreakTheme.cyanAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: EduStreakTheme.cyanAccent.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_user_rounded, color: EduStreakTheme.cyanAccent, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'ZERO UNVERIFIED PUBLIC SIGNUPS',
                        style: TextStyle(
                          color: EduStreakTheme.cyanAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Institutional Verification Architecture',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'EduStreak operates strictly on school rosters authorized and uploaded by Principals. Claim your record with your institution code to start your learning journey.',
                  style: TextStyle(
                    color: Color(0xFFA5A0C8),
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 36),
                _buildSecurityFeatureRow(
                  Icons.shield_outlined,
                  'Tamper-Proof Rosters',
                  'Only institutional CSV records uploaded by Principals can be registered.',
                ),
                const SizedBox(height: 18),
                _buildSecurityFeatureRow(
                  Icons.lock_reset_rounded,
                  'Atomic Identity Claim',
                  'Roster records are claimed once with password encryption; duplicate signups are blocked.',
                ),
                const SizedBox(height: 18),
                _buildSecurityFeatureRow(
                  Icons.domain_verification_rounded,
                  'Role-Based Portals',
                  'Students, Teachers, and Parents receive direct access to their assigned portal.',
                ),
              ],
            ),
          ),
        ),

        // Right Column: Form Wizard / Landing Content
        Expanded(
          flex: 6,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 580),
                child: _selectedRole == null
                    ? _buildLandingView()
                    : _buildWizardContainer(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityFeatureRow(IconData icon, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: EduStreakTheme.primaryViolet.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: EduStreakTheme.cyanAccent, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 4),
              Text(desc, style: const TextStyle(color: Color(0xFF8E88B0), fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  /// Mobile and Tablet Layout
  Widget _buildMobileOrTabletLayout() {
    final isCompact = context.screenWidth < 600;

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 16 : 24,
          vertical: 16,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: _selectedRole == null
              ? _buildLandingView()
              : _buildWizardContainer(),
        ),
      ),
    );
  }

  // ── LANDING VIEW: ROLE SELECTION & PRINCIPAL INVITATION CALLOUT ───────────
  Widget _buildLandingView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Heading
        const Text(
          'Join EduStreak',
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Select your role to claim your official school-verified account.',
          style: TextStyle(color: Color(0xFFA5A0C8), fontSize: 14),
        ),
        const SizedBox(height: 24),

        // 3 Role Cards
        _buildRoleSelectionCard(
          role: 'student',
          title: 'Student Registration',
          subtitle: 'Verify with your School Code & Roll / Admission Number',
          icon: Icons.school_rounded,
          accentColor: EduStreakTheme.primaryViolet,
          badgeText: 'Verified Roster',
        ),
        const SizedBox(height: 12),
        _buildRoleSelectionCard(
          role: 'teacher',
          title: 'Faculty / Teacher Registration',
          subtitle: 'Verify with your School Code & Faculty Employee ID',
          icon: Icons.person_search_rounded,
          accentColor: EduStreakTheme.cyanAccent,
          badgeText: 'School Authorized',
        ),
        const SizedBox(height: 12),
        _buildRoleSelectionCard(
          role: 'parent',
          title: 'Parent & Guardian Portal',
          subtitle: 'Link to your student with School Code & Verified Contact',
          icon: Icons.family_restroom_rounded,
          accentColor: const Color(0xFF10B981),
          badgeText: 'Child Linked',
        ),

        const SizedBox(height: 24),

        // Principal Invitation Banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1B163F), Color(0xFF261A54)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF4C3688)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: EduStreakTheme.amberGold.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.vpn_key_rounded, color: EduStreakTheme.amberGold, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'School Principal Invitation',
                          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Have an invitation code from Central Admin?',
                          style: TextStyle(color: Color(0xFFA5A0C8), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PrincipalInvitationScreen()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: EduStreakTheme.amberGold,
                    side: const BorderSide(color: EduStreakTheme.amberGold),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Accept Principal Invitation', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Central Admin Governance Notice
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF110E26),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF231D45)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.security_rounded, size: 18, color: Color(0xFF8881AB)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Central Administration accounts cannot be created publicly and are provisioned directly by the Platform Governance Authority.',
                  style: TextStyle(color: Color(0xFF8881AB), fontSize: 11, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRoleSelectionCard({
    required String role,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required String badgeText,
  }) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedRole = role;
          _currentStep = 0;
          _errorMessage = null;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF11102B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2C2456), width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accentColor, size: 22),
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
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(color: accentColor, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Color(0xFFA5A0C8), fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF756D99), size: 14),
          ],
        ),
      ),
    );
  }

  // ── WIZARD CONTAINER WITH STEP INDICATOR ──────────────────────────────────
  Widget _buildWizardContainer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Reusable Step Indicator
        RegistrationStepIndicator(
          currentStep: _currentStep,
          isDark: true,
        ),
        const SizedBox(height: 20),

        // Step Content Card
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFF11102B),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF2C2456), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: EduStreakTheme.rosePink.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: EduStreakTheme.rosePink.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: EduStreakTheme.rosePink, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Switch on Step
              if (_currentStep == 0) _buildStep1SchoolVerification(),
              if (_currentStep == 1) _buildStep2IdentityVerification(),
              if (_currentStep == 2) _buildStep3PasswordSetup(),
              if (_currentStep == 3) _buildStep4Success(),
            ],
          ),
        ),
      ],
    );
  }

  // ── STEP 1: INSTITUTIONAL LOOKUP FORM ─────────────────────────────────────
  Widget _buildStep1SchoolVerification() {
    if (_selectedRole == 'student') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Student School Verification',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Enter your School Code and Roll / Admission Number as recorded on your school roster.',
            style: TextStyle(color: Color(0xFFA5A0C8), fontSize: 12),
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _studentSchoolCodeController,
            label: 'School Code',
            hint: 'e.g. AP-KRI-042',
            icon: Icons.account_balance_rounded,
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _studentRollController,
            label: 'Roll Number or Admission Number',
            hint: 'e.g. 101 or ADM001',
            icon: Icons.badge_rounded,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                backgroundColor: const Color(0xFF201A42),
                side: const BorderSide(color: Color(0xFF382F66)),
                label: const Text('Autofill Demo (Ravi Kumar #101)', style: TextStyle(color: Color(0xFFC4B5FD), fontSize: 11)),
                onPressed: () {
                  _studentSchoolCodeController.text = 'AP-KRI-042';
                  _studentRollController.text = '101';
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildPrimaryButton(
            title: 'Verify Student Record',
            onPressed: _isLoading ? null : _verifyStudentRecord,
          ),
        ],
      );
    } else if (_selectedRole == 'teacher') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Faculty School Verification',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Enter your School Code and assigned Employee ID from your appointment records.',
            style: TextStyle(color: Color(0xFFA5A0C8), fontSize: 12),
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _teacherSchoolCodeController,
            label: 'School Code',
            hint: 'e.g. AP-KRI-042',
            icon: Icons.account_balance_rounded,
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _teacherEmpIdController,
            label: 'Employee ID',
            hint: 'e.g. EMP014',
            icon: Icons.work_outline_rounded,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                backgroundColor: const Color(0xFF201A42),
                side: const BorderSide(color: Color(0xFF382F66)),
                label: const Text('Autofill Demo (Dr. Sarah #EMP014)', style: TextStyle(color: Color(0xFFC4B5FD), fontSize: 11)),
                onPressed: () {
                  _teacherSchoolCodeController.text = 'AP-KRI-042';
                  _teacherEmpIdController.text = 'EMP014';
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildPrimaryButton(
            title: 'Verify Faculty Record',
            onPressed: _isLoading ? null : _verifyTeacherRecord,
          ),
        ],
      );
    } else {
      // Parent
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Parent & Guardian Verification',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Enter the student’s School Code, Student ID, and your registered phone number or email address.',
            style: TextStyle(color: Color(0xFFA5A0C8), fontSize: 12),
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _parentSchoolCodeController,
            label: 'School Code',
            hint: 'e.g. AP-KRI-042',
            icon: Icons.account_balance_rounded,
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _parentStudentIdController,
            label: 'Student Roll / Admission Number',
            hint: 'e.g. 101',
            icon: Icons.child_care_rounded,
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _parentContactController,
            label: 'Parent Phone or Email on Record',
            hint: 'e.g. 9876543210 or parent@gmail.com',
            icon: Icons.contact_phone_rounded,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                backgroundColor: const Color(0xFF201A42),
                side: const BorderSide(color: Color(0xFF382F66)),
                label: const Text('Autofill Demo (Ravi #101)', style: TextStyle(color: Color(0xFFC4B5FD), fontSize: 11)),
                onPressed: () {
                  _parentSchoolCodeController.text = 'AP-KRI-042';
                  _parentStudentIdController.text = '101';
                  _parentContactController.text = '9440123456';
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildPrimaryButton(
            title: 'Verify Student Link',
            onPressed: _isLoading ? null : _verifyParentRelationship,
          ),
        ],
      );
    }
  }

  // ── STEP 2: IDENTITY VERIFICATION (OTP OR PIN) ────────────────────────────
  Widget _buildStep2IdentityVerification() {
    final masked = _challenge?.recipientMasked ?? 'registered contact';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Record Verified! Confirm Identity',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF19133D),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF342866)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_studentPreview != null) ...[
                Text('Student: ${_studentPreview!.studentName}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text('Class: ${_studentPreview!.classLabel} | ${_studentPreview!.schoolName}', style: const TextStyle(color: Color(0xFFA5A0C8), fontSize: 12)),
              ],
              if (_teacherPreview != null) ...[
                Text('Faculty: ${_teacherPreview!.teacherName}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text('Assigned: ${_teacherPreview!.assignedSubjects.join(", ")}', style: const TextStyle(color: Color(0xFFA5A0C8), fontSize: 12)),
              ],
              if (_parentPreview != null) ...[
                Text('Child: ${_parentPreview!.studentName} (${_parentPreview!.classLabel})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text('School: ${_parentPreview!.schoolName}', style: const TextStyle(color: Color(0xFFA5A0C8), fontSize: 12)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(
          _usePinVerification
              ? 'Enter the 4-digit verification PIN provided by your school administration.'
              : 'Enter the 6-digit verification code dispatched to $masked.',
          style: const TextStyle(color: Color(0xFFA5A0C8), fontSize: 13),
        ),
        const SizedBox(height: 14),
        _buildTextField(
          controller: _otpOrPinController,
          label: _usePinVerification ? 'Verification PIN' : '6-Digit Verification Code',
          hint: _usePinVerification ? 'e.g. 4821' : 'e.g. 123456',
          icon: Icons.pin_rounded,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            ActionChip(
              backgroundColor: const Color(0xFF201A42),
              side: const BorderSide(color: Color(0xFF382F66)),
              label: const Text('Autofill Code (123456)', style: TextStyle(color: Color(0xFFC4B5FD), fontSize: 11)),
              onPressed: () {
                _otpOrPinController.text = '123456';
              },
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _currentStep = 0),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFA5A0C8),
                  side: const BorderSide(color: Color(0xFF382F66)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: _buildPrimaryButton(
                title: 'Confirm Identity',
                onPressed: _isLoading ? null : _verifyChallenge,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── STEP 3: PASSWORD & CREDENTIAL SETUP ────────────────────────────────────
  Widget _buildStep3PasswordSetup() {
    final strength = _calculatePasswordStrength(_passwordController.text);
    final strengthColor = _getStrengthColor(strength);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Set Account Password',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        const Text(
          'Create a secure password to protect your EduStreak account and streaks.',
          style: TextStyle(color: Color(0xFFA5A0C8), fontSize: 12),
        ),
        const SizedBox(height: 18),

        // Additional parent info fields if registering as parent
        if (_selectedRole == 'parent') ...[
          _buildTextField(
            controller: _parentNameController,
            label: 'Parent / Guardian Full Name',
            hint: 'e.g. Ramesh Kumar',
            icon: Icons.person_rounded,
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _parentEmailController,
            label: 'Your Personal Email Address',
            hint: 'e.g. ramesh.kumar@gmail.com',
            icon: Icons.email_outlined,
          ),
          const SizedBox(height: 14),
        ],

        // Password field
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: 'New Password',
            labelStyle: const TextStyle(color: Color(0xFFC4B5FD), fontSize: 13),
            filled: true,
            fillColor: const Color(0xFF1B173E),
            prefixIcon: const Icon(Icons.lock_outline_rounded, color: EduStreakTheme.cyanAccent, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                color: const Color(0xFFA5A0C8),
                size: 20,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2F285C)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: EduStreakTheme.cyanAccent, width: 1.5),
            ),
          ),
        ),

        if (_passwordController.text.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: strength,
                    minHeight: 4,
                    backgroundColor: const Color(0xFF28214E),
                    valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _getStrengthLabel(strength),
                style: TextStyle(color: strengthColor, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],

        const SizedBox(height: 14),

        // Confirm Password field
        TextField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            labelText: 'Confirm Password',
            labelStyle: const TextStyle(color: Color(0xFFC4B5FD), fontSize: 13),
            filled: true,
            fillColor: const Color(0xFF1B173E),
            prefixIcon: const Icon(Icons.lock_rounded, color: EduStreakTheme.cyanAccent, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                color: const Color(0xFFA5A0C8),
                size: 20,
              ),
              onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2F285C)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: EduStreakTheme.cyanAccent, width: 1.5),
            ),
          ),
        ),

        const SizedBox(height: 24),

        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _currentStep = 1),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFA5A0C8),
                  side: const BorderSide(color: Color(0xFF382F66)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: _buildPrimaryButton(
                title: 'Claim & Activate',
                onPressed: _isLoading ? null : _createPasswordAndClaim,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── STEP 4: ACTIVATION SUCCESS ────────────────────────────────────────────
  Widget _buildStep4Success() {
    final user = _createdUser;
    final userName = user?.name ?? 'Learner';
    final roleName = user?.role.toUpperCase() ?? 'STUDENT';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF10B981), Color(0xFF059669)],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 36),
        ),
        const SizedBox(height: 18),
        const Text(
          'Account Activated!',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Welcome to EduStreak, $userName. Your verified institutional account is now active under the $roleName role.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFA5A0C8),
            fontSize: 13,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1A143D),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF2C2456)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('School: ${user?.schoolCode ?? "AP-KRI-042"}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 4),
              Text('Login Identifier: ${user?.email ?? user?.rollNumber ?? ""}', style: const TextStyle(color: Color(0xFFA5A0C8), fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildPrimaryButton(
          title: 'Enter ${user?.role.toUpperCase() ?? "ROLE"} Portal',
          onPressed: _navigateToRolePortal,
        ),
      ],
    );
  }

  // ── HELPER WIDGETS ────────────────────────────────────────────────────────
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFFC4B5FD), fontSize: 13),
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF6B658E), fontSize: 13),
        filled: true,
        fillColor: const Color(0xFF1B173E),
        prefixIcon: Icon(icon, color: EduStreakTheme.cyanAccent, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2F285C)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: EduStreakTheme.cyanAccent, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String title,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: EduStreakTheme.primaryViolet,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 4,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 16),
                  ],
                ),
              ),
      ),
    );
  }
}
