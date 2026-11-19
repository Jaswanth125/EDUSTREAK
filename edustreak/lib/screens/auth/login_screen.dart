import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../services/auth_service.dart';
import '../../utils/edustreak_theme.dart';
import '../../widgets/edustreak_illustrations.dart';
import '../../widgets/responsive/responsive_dialog.dart';
import 'principal_invitation_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final _authService = AuthService();
  int _selectedRoleIndex = 0; // 0: Student, 1: Teacher, 2: Parent, 3: Admin
  bool _isLoading = false;
  bool _obscurePassword = true;

  // Student Form Controllers
  final _studentSchoolCodeController = TextEditingController();
  final _studentRollNoController = TextEditingController();
  final _studentPasswordController = TextEditingController();

  // General Form Controllers (Teacher, Parent, Admin)
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _studentSchoolCodeController.dispose();
    _studentRollNoController.dispose();
    _studentPasswordController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      if (_selectedRoleIndex == 0) {
        // ── STUDENT AUTH (School Code + Roll Number + Password) ────────────
        final user = await _authService.signInStudent(
          schoolCode: _studentSchoolCodeController.text.trim(),
          rollNumber: _studentRollNoController.text.trim(),
          password: _studentPasswordController.text,
        );

        if (user != null && mounted) {
          await userProvider.loadUser(user.id);
        }
      } else {
        // ── TEACHER / PARENT / ADMIN AUTH (Email + Password) ───────────────
        final user = await _authService.signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );

        if (user != null && mounted) {
          // Verify expected role matches
          final expectedRole = _getRoleNameByIndex(_selectedRoleIndex);
          if (user.role.toLowerCase() != expectedRole) {
            await _authService.signOut();
            userProvider.clearUser();
            throw Exception('This account is registered as a ${user.role.toUpperCase()}, not a ${expectedRole.toUpperCase()}. Please switch to the correct tab.');
          }
          await userProvider.loadUser(user.id);
        }
      }
    } catch (e) {
      if (mounted) {
        final message = e.toString().replaceFirst('Exception: ', '');
        _showErrorSnackBar(message);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getRoleNameByIndex(int index) {
    switch (index) {
      case 0:
        return 'student';
      case 1:
        return 'teacher';
      case 2:
        return 'principal';
      case 3:
        return 'parent';
      case 4:
        return 'admin';
      default:
        return 'student';
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: const TextStyle(color: Colors.white))),
          ],
        ),
        backgroundColor: EduStreakTheme.rosePink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController();
    showAdaptiveEduStreakModal(
      context: context,
      title: 'Reset Password',
      isDark: true,
      icon: const Icon(Icons.lock_reset_rounded, color: EduStreakTheme.neonCyan),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter your registered email address and we will send you a password reset link.',
            style: EduStreakTheme.fontBody(color: EduStreakTheme.darkTextSub),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: resetEmailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'user@edustreak.com',
              hintStyle: const TextStyle(color: Colors.white38),
              prefixIcon: const Icon(Icons.email_outlined, color: EduStreakTheme.primaryViolet),
              filled: true,
              fillColor: const Color(0xFF141A42),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF283168)),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
        ),
        ElevatedButton(
          onPressed: () async {
            final email = resetEmailController.text.trim();
            if (email.isEmpty) return;
            Navigator.pop(context);
            try {
              await _authService.sendPasswordResetEmail(email);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Password reset link sent to $email'),
                    backgroundColor: EduStreakTheme.emeraldGreen,
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                _showErrorSnackBar(e.toString().replaceFirst('Exception: ', ''));
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: EduStreakTheme.primaryViolet,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Send Reset Link', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 800;
    final isCompactMobile = screenWidth < 480;

    return Scaffold(
      backgroundColor: EduStreakTheme.darkNavyBg,
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isCompactMobile ? 14 : 24,
            vertical: isCompactMobile ? 20 : 32,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isDesktop ? 520 : double.infinity),
            child: Container(
              padding: EdgeInsets.all(isCompactMobile ? 20 : 32),
              decoration: EduStreakTheme.darkCardDecoration(
                radius: isCompactMobile ? 18 : 24,
                borderColor: EduStreakTheme.primaryViolet.withValues(alpha: 0.5),
                glowOpacity: 0.2,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Brand Header Logo
                    const EduStreakBrandHeader(isDark: true),

                    const SizedBox(height: 28),

                    // Segmented Role Switcher
                    _buildRoleSegmentedBar(),

                    const SizedBox(height: 24),

                    // Role Title & Instruction Subhead
                    _buildRoleInstructionHeader(),

                    const SizedBox(height: 20),

                    // Active Role Form Fields
                    if (_selectedRoleIndex == 0)
                      _buildStudentFormFields()
                    else
                      _buildGeneralEmailPasswordFields(),

                    const SizedBox(height: 12),

                    // Forgot Password Row
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _showForgotPasswordDialog,
                        child: Text(
                          'Forgot Password?',
                          style: EduStreakTheme.fontCaption(
                            color: EduStreakTheme.neonCyan,
                            weight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Submit Button
                    _buildSubmitButton(),

                    const SizedBox(height: 24),

                    // Sign up / Invitation prompt
                    if (_selectedRoleIndex == 2)
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            "Have a Principal invitation? ",
                            style: EduStreakTheme.fontCaption(color: EduStreakTheme.darkTextMuted),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const PrincipalInvitationScreen(),
                                ),
                              );
                            },
                            child: Text(
                              'Accept Invitation',
                              style: EduStreakTheme.fontLabel(
                                color: EduStreakTheme.neonCyan,
                                weight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      )
                    else if (_selectedRoleIndex == 4)
                      Text(
                        'Central Administration accounts are provisioned exclusively via platform governance.',
                        textAlign: TextAlign.center,
                        style: EduStreakTheme.fontCaption(color: EduStreakTheme.darkTextMuted),
                      )
                    else
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: EduStreakTheme.fontCaption(color: EduStreakTheme.darkTextMuted),
                          ),
                          GestureDetector(
                            onTap: () {
                              int? initialRole;
                              if (_selectedRoleIndex == 0) initialRole = 0;
                              if (_selectedRoleIndex == 1) initialRole = 1;
                              if (_selectedRoleIndex == 3) initialRole = 2;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SignUpScreen(
                                    initialRoleIndex: initialRole,
                                  ),
                                ),
                              );
                            },
                            child: Text(
                              'Claim School Record',
                              style: EduStreakTheme.fontLabel(
                                color: EduStreakTheme.primaryVioletLight,
                                weight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 24),
                    const Divider(color: Color(0xFF222B5C)),
                    const SizedBox(height: 14),

                    // Quick Test Autofill Bar
                    _buildQuickAutofillBar(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSegmentedBar() {
    final roles = [
      ('🎓', 'Student'),
      ('👩‍🏫', 'Teacher'),
      ('🏛️', 'Principal'),
      ('👨‍👩‍👧', 'Parent'),
      ('🛡️', 'Admin'),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 560;

        Widget buildRoleItem(int index) {
          final isSelected = _selectedRoleIndex == index;
          final r = roles[index];

          return InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              setState(() {
                _selectedRoleIndex = index;
                _formKey.currentState?.reset();
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
              decoration: BoxDecoration(
                gradient: isSelected ? EduStreakTheme.activePillGradient : null,
                borderRadius: BorderRadius.circular(12),
                boxShadow: isSelected ? EduStreakTheme.violetGlow : null,
              ),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(r.$1, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 4),
                      Text(
                        r.$2,
                        style: TextStyle(
                          color: isSelected ? Colors.white : EduStreakTheme.darkTextMuted,
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        if (isMobile) {
          // 2-row layout on mobile ensuring all 5 roles (Student, Teacher, Principal, Parent, Admin)
          // are always visible, large, touch-friendly, and never cut off.
          return Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF0C1030),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF222B5C)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: buildRoleItem(0)),
                    const SizedBox(width: 4),
                    Expanded(child: buildRoleItem(1)),
                    const SizedBox(width: 4),
                    Expanded(child: buildRoleItem(2)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(child: buildRoleItem(3)),
                    const SizedBox(width: 4),
                    Expanded(child: buildRoleItem(4)),
                  ],
                ),
              ],
            ),
          );
        }

        // Single row with all 5 roles on wider screens
        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFF0C1030),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF222B5C)),
          ),
          child: Row(
            children: List.generate(roles.length, (index) {
              return Expanded(
                child: buildRoleItem(index),
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildRoleInstructionHeader() {
    String title;
    String subtitle;
    IconData icon;
    Color color;

    switch (_selectedRoleIndex) {
      case 0:
        title = 'Student Sign-In';
        subtitle = 'Enter your institution code and roll number to continue your quest.';
        icon = Icons.school_rounded;
        color = EduStreakTheme.primaryViolet;
        break;
      case 1:
        title = 'Teacher Faculty Portal';
        subtitle = 'Sign in with your verified school educator credentials.';
        icon = Icons.co_present_rounded;
        color = EduStreakTheme.neonCyan;
        break;
      case 2:
        title = 'Principal Administration Portal';
        subtitle = 'School-level oversight, faculty monitoring, and institutional performance.';
        icon = Icons.account_balance_rounded;
        color = EduStreakTheme.secondaryPurple;
        break;
      case 3:
        title = 'Parent & Guardian Portal';
        subtitle = 'Sign in to monitor your linked child\'s academic growth and daily streak.';
        icon = Icons.family_restroom_rounded;
        color = EduStreakTheme.magentaPink;
        break;
      case 4:
      default:
        title = 'Central Admin Operations';
        subtitle = 'Restricted master administrator access for state-wide governance.';
        icon = Icons.admin_panel_settings_rounded;
        color = EduStreakTheme.amberGold;
        break;
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: EduStreakTheme.fontHeading3(color: Colors.white, weight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: EduStreakTheme.fontCaption(color: EduStreakTheme.darkTextMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── STUDENT FORM FIELDS (SCHOOL CODE + ROLL NO + PASSWORD) ───────────────
  Widget _buildStudentFormFields() {
    return Column(
      children: [
        // School Code Field
        _buildTextField(
          controller: _studentSchoolCodeController,
          label: 'School Code',
          hint: 'e.g. AP-KRI-042 or CBSE-AP-012',
          icon: Icons.account_balance_rounded,
          textCapitalization: TextCapitalization.characters,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Enter your School Code';
            return null;
          },
        ),

        const SizedBox(height: 16),

        // Roll Number / Admission Number Field
        _buildTextField(
          controller: _studentRollNoController,
          label: 'Roll Number / Admission No.',
          hint: 'e.g. 12 or ADM-2024-8120',
          icon: Icons.badge_rounded,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Enter your Roll or Admission Number';
            return null;
          },
        ),

        const SizedBox(height: 16),

        // Password Field
        _buildTextField(
          controller: _studentPasswordController,
          label: 'Password',
          hint: '••••••••',
          icon: Icons.lock_outline_rounded,
          obscureText: _obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: Colors.white38,
              size: 20,
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Enter your password';
            if (v.length < 6) return 'Password must be at least 6 characters';
            return null;
          },
        ),
      ],
    );
  }

  // ── GENERAL EMAIL / PASSWORD FIELDS (TEACHER, PARENT, ADMIN) ─────────────
  Widget _buildGeneralEmailPasswordFields() {
    final roleName = _getRoleNameByIndex(_selectedRoleIndex);
    String emailLabel = 'Email Address';
    String emailHint = '$roleName@edustreak.com';

    if (_selectedRoleIndex == 3) {
      emailLabel = 'Registered Email or Mobile ID';
      emailHint = 'parent1@edustreak.com';
    }

    return Column(
      children: [
        // Email Field
        _buildTextField(
          controller: _emailController,
          label: emailLabel,
          hint: emailHint,
          icon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Enter your email address';
            if (!v.contains('@')) return 'Enter a valid email address';
            return null;
          },
        ),

        const SizedBox(height: 16),

        // Password Field
        _buildTextField(
          controller: _passwordController,
          label: 'Password',
          hint: '••••••••',
          icon: Icons.lock_outline_rounded,
          obscureText: _obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: Colors.white38,
              size: 20,
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Enter your password';
            if (v.length < 6) return 'Password must be at least 6 characters';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: EduStreakTheme.darkTextSub, fontSize: 13),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
        prefixIcon: Icon(icon, color: EduStreakTheme.primaryViolet, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFF141A42),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF283168)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: EduStreakTheme.primaryViolet, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: EduStreakTheme.rosePink),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: EduStreakTheme.rosePink, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: EduStreakTheme.activePillGradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: EduStreakTheme.violetGlow,
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _handleSignIn,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        'Sign In as ${_getRoleNameByIndex(_selectedRoleIndex).toUpperCase()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildQuickAutofillBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.flash_on_rounded, color: EduStreakTheme.amberGold, size: 14),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Quick Test Autofill (Click to populate fields):',
                style: EduStreakTheme.fontCaption(color: EduStreakTheme.darkTextSub, weight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            ActionChip(
              backgroundColor: const Color(0xFF141A42),
              side: const BorderSide(color: Color(0xFF283168)),
              avatar: const Text('🎓', style: TextStyle(fontSize: 12)),
              label: const Text('Student (Sai Charan • 8A • SVVM)', style: TextStyle(color: Colors.white70, fontSize: 11)),
              onPressed: () {
                setState(() => _selectedRoleIndex = 0);
                _studentSchoolCodeController.text = 'AP-KRI-SVVM';
                _studentRollNoController.text = '801';
                _studentPasswordController.text = 'student123';
              },
            ),
            ActionChip(
              backgroundColor: const Color(0xFF141A42),
              side: const BorderSide(color: Color(0xFF283168)),
              avatar: const Text('👩‍🏫', style: TextStyle(fontSize: 12)),
              label: const Text('Teacher (K. Srinivas • Math)', style: TextStyle(color: Colors.white70, fontSize: 11)),
              onPressed: () {
                setState(() => _selectedRoleIndex = 1);
                _emailController.text = 'k.srinivas.math@svvm.edustreak.ap.gov.in';
                _passwordController.text = 'teacher123';
              },
            ),
            ActionChip(
              backgroundColor: const Color(0xFF141A42),
              side: const BorderSide(color: Color(0xFF283168)),
              avatar: const Text('🏛️', style: TextStyle(fontSize: 12)),
              label: const Text('Principal (K. Srinivas Rao)', style: TextStyle(color: Colors.white70, fontSize: 11)),
              onPressed: () {
                setState(() => _selectedRoleIndex = 2);
                _emailController.text = 'principal.svvm@edustreak.ap.gov.in';
                _passwordController.text = 'principal123';
              },
            ),
            ActionChip(
              backgroundColor: const Color(0xFF141A42),
              side: const BorderSide(color: Color(0xFF283168)),
              avatar: const Text('👨‍👩‍👧', style: TextStyle(fontSize: 12)),
              label: const Text('Parent (K. Ramesh • Roll 801)', style: TextStyle(color: Colors.white70, fontSize: 11)),
              onPressed: () {
                setState(() => _selectedRoleIndex = 3);
                _emailController.text = 'k.ramesh.801@gmail.com';
                _passwordController.text = 'parent123';
              },
            ),
            ActionChip(
              backgroundColor: const Color(0xFF141A42),
              side: const BorderSide(color: Color(0xFF283168)),
              avatar: const Text('🛡️', style: TextStyle(fontSize: 12)),
              label: const Text('Admin (Platform Master)', style: TextStyle(color: Colors.white70, fontSize: 11)),
              onPressed: () {
                setState(() => _selectedRoleIndex = 4);
                _emailController.text = 'admin@edustreak.com';
                _passwordController.text = 'admin123';
              },
            ),
          ],
        ),
      ],
    );
  }
}
