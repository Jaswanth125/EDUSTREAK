import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../services/school_registration_service.dart';
import '../../utils/edustreak_theme.dart';
import '../../utils/responsive_breakpoints.dart';
import '../portal_router.dart';

class PrincipalInvitationScreen extends StatefulWidget {
  final String? initialCode;
  final String? initialToken;

  const PrincipalInvitationScreen({
    super.key,
    this.initialCode,
    this.initialToken,
  });

  @override
  State<PrincipalInvitationScreen> createState() => _PrincipalInvitationScreenState();
}

class _PrincipalInvitationScreenState extends State<PrincipalInvitationScreen> {
  final _service = SchoolRegistrationService();
  final _formKey = GlobalKey<FormState>();

  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  PrincipalInvitationPreview? _verifiedInvitation;
  bool _isSuccess = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialCode != null && widget.initialCode!.isNotEmpty) {
      _codeController.text = widget.initialCode!;
      _verifyInvitation();
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _verifyInvitation() async {
    final query = _codeController.text.trim();
    if (query.isEmpty) {
      setState(() => _errorMessage = 'Please enter an invitation code or authorized email.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final preview = await _service.verifyPrincipalInvitation(query);
      setState(() {
        _verifiedInvitation = preview;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _activateAccount() async {
    if (_verifiedInvitation == null) return;
    if (!_formKey.currentState!.validate()) return;

    final pass = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (pass != confirm) {
      setState(() => _errorMessage = 'Passwords do not match.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await _service.acceptPrincipalInvitation(
        invitationCode: _verifiedInvitation!.invitationCode,
        password: pass,
      );

      if (mounted) {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        await userProvider.loadUser(user.id);
        setState(() {
          _isSuccess = true;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToPortal() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const EduStreakPortalRouter(initialRole: 'principal'),
      ),
      (route) => false,
    );
  }

  double _calculatePasswordStrength(String pass) {
    if (pass.isEmpty) return 0.0;
    double score = 0.0;
    if (pass.length >= 8) score += 0.3;
    if (pass.length >= 12) score += 0.2;
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
    return 'Strong & Secure';
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = context.screenWidth < 600;

    return Scaffold(
      backgroundColor: const Color(0xFF070B1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF070B1E),
        elevation: 0,
        leading: IconButton(
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
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 16 : 24,
              vertical: 20,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 580),
              child: _isSuccess
                  ? _buildSuccessView()
                  : (_verifiedInvitation == null
                      ? _buildLookupView(isCompact)
                      : _buildActivationView(isCompact)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLookupView(bool isCompact) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 18 : 28),
      decoration: BoxDecoration(
        color: const Color(0xFF11102B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2C2456), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: EduStreakTheme.cyanAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: EduStreakTheme.cyanAccent.withValues(alpha: 0.3)),
            ),
            child: const FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.vpn_key_rounded, size: 14, color: EduStreakTheme.cyanAccent),
                  SizedBox(width: 6),
                  Text(
                    'INSTITUTIONAL INVITATION ONLY',
                    style: TextStyle(
                      color: EduStreakTheme.cyanAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Accept Principal Invitation',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Principal accounts are strictly invitation-only. Central Administration issues formal invitations upon authorizing a school. Enter your invitation code or official email below.',
            style: TextStyle(
              color: Color(0xFFA5A0C8),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),

          // Code Input Field
          const Text(
            'INVITATION CODE OR REGISTERED EMAIL',
            style: TextStyle(
              color: Color(0xFFD6D0F5),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _codeController,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'e.g. INV-PRIN-APKRI042-8821 or principal@school.edu',
              hintStyle: const TextStyle(color: Color(0xFF6B658E), fontSize: 13),
              filled: true,
              fillColor: const Color(0xFF1B173E),
              prefixIcon: const Icon(Icons.mail_outline_rounded, color: EduStreakTheme.cyanAccent, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF2F285C)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF2F285C)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: EduStreakTheme.cyanAccent, width: 1.5),
              ),
            ),
            onSubmitted: (_) => _verifyInvitation(),
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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

          const SizedBox(height: 20),

          // Demo quick-fill chips for evaluation
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                backgroundColor: const Color(0xFF201A42),
                side: const BorderSide(color: Color(0xFF382F66)),
                label: const Text('Autofill Demo Code', style: TextStyle(color: Color(0xFFC4B5FD), fontSize: 11)),
                onPressed: () {
                  _codeController.text = 'INV-PRIN-APKRI042-DEMO';
                  _verifyInvitation();
                },
              ),
              ActionChip(
                backgroundColor: const Color(0xFF201A42),
                side: const BorderSide(color: Color(0xFF382F66)),
                label: const Text('Autofill Principal Email', style: TextStyle(color: Color(0xFFC4B5FD), fontSize: 11)),
                onPressed: () {
                  _codeController.text = 'dr.sudhir.principal@apgov.edu.in';
                  _verifyInvitation();
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Verify Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _verifyInvitation,
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
                  : const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Verify Invitation Code', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivationView(bool isCompact) {
    final preview = _verifiedInvitation!;
    final strength = _calculatePasswordStrength(_passwordController.text);
    final strengthColor = _getStrengthColor(strength);

    return Container(
      padding: EdgeInsets.all(isCompact ? 18 : 28),
      decoration: BoxDecoration(
        color: const Color(0xFF11102B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2C2456), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Verified banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF10B981)),
                  SizedBox(width: 6),
                  Text(
                    'OFFICIAL INVITATION VERIFIED',
                    style: TextStyle(
                      color: Color(0xFF10B981),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // School & Principal preview card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A143D),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF382B70)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: EduStreakTheme.primaryViolet.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.account_balance_rounded, color: EduStreakTheme.cyanAccent, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              preview.schoolName,
                              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                            ),
                            Text(
                              'Code: ${preview.schoolCode}',
                              style: const TextStyle(color: EduStreakTheme.cyanAccent, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Color(0xFF2C2456), height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Designated Principal:', style: TextStyle(color: Color(0xFFA5A0C8), fontSize: 12)),
                      Text(preview.principalName, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Official Email:', style: TextStyle(color: Color(0xFFA5A0C8), fontSize: 12)),
                      Text(preview.principalEmail, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            const Text(
              'Set Administrative Password',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Create a strong administrative password (at least 8 characters) to secure your school portal.',
              style: TextStyle(color: Color(0xFFA5A0C8), fontSize: 12),
            ),
            const SizedBox(height: 16),

            // New Password
            TextFormField(
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
              validator: (val) {
                if (val == null || val.length < 8) {
                  return 'Password must be at least 8 characters.';
                }
                return null;
              },
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

            // Confirm Password
            TextFormField(
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
              validator: (val) {
                if (val != _passwordController.text) {
                  return 'Passwords do not match.';
                }
                return null;
              },
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _verifiedInvitation = null),
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
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _activateAccount,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: EduStreakTheme.primaryViolet,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 4,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Activate Principal Portal',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    final preview = _verifiedInvitation!;

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFF11102B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.15),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
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
            'Principal Portal Activated!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Welcome, ${preview.principalName}. You now have full administrative governance over ${preview.schoolName} (${preview.schoolCode}).',
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
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NEXT STEPS AS SCHOOL PRINCIPAL:',
                  style: TextStyle(
                    color: EduStreakTheme.cyanAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                  ),
                ),
                SizedBox(height: 8),
                Text('• Upload your official Student CSV roster', style: TextStyle(color: Colors.white70, fontSize: 12)),
                SizedBox(height: 4),
                Text('• Upload your official Teacher CSV roster', style: TextStyle(color: Colors.white70, fontSize: 12)),
                SizedBox(height: 4),
                Text('• Manage class sections and monitor student streaks', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _navigateToPortal,
              style: ElevatedButton.styleFrom(
                backgroundColor: EduStreakTheme.primaryViolet,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Enter Principal Portal', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
