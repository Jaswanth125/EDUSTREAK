import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/user_provider.dart';
import '../../services/auth_service.dart';
import '../../utils/theme.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  late AnimationController _bgController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _bgController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final authService = AuthService();
      final user = await authService.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (user != null && mounted) {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        await userProvider.loadUser(user.id);
      } else if (mounted) {
        _showError('Invalid credentials. Please try again.');
      }
    } catch (e) {
      if (mounted) _showError('Login failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.error_outline, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(msg, style: const TextStyle(color: Colors.white))),
      ]),
      backgroundColor: AppTheme.errorColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusMD),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Stack(
        children: [
          // ── Animated background orbs ──────────────────────────────
          _buildBackgroundOrbs(size),

          // ── Content ────────────────────────────────────────────────
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo
                      Center(
                        child: _buildLogo(),
                      ).animate().fadeIn(duration: 700.ms).scale(
                            begin: const Offset(0.6, 0.6),
                            duration: 800.ms,
                            curve: Curves.elasticOut,
                          ),

                      const SizedBox(height: 40),

                      // Headline
                      Text(
                        'Welcome\nBack 👋',
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                              color: AppTheme.textPrimary,
                              height: 1.15,
                            ),
                      )
                          .animate()
                          .fadeIn(delay: 200.ms, duration: 600.ms)
                          .slideY(begin: 0.3, end: 0, duration: 600.ms),

                      const SizedBox(height: 8),
                      Text(
                        'Sign in to continue your learning streak 🔥',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      )
                          .animate()
                          .fadeIn(delay: 300.ms, duration: 600.ms)
                          .slideY(begin: 0.2, end: 0, duration: 600.ms),

                      const SizedBox(height: 40),

                      // Email field
                      _PremiumTextField(
                        controller: _emailController,
                        label: 'Email address',
                        icon: Icons.mail_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Enter your email';
                          if (!v.contains('@')) return 'Enter a valid email';
                          return null;
                        },
                      ).animate().fadeIn(delay: 400.ms, duration: 600.ms).slideX(begin: -0.15, end: 0),

                      const SizedBox(height: 16),

                      // Password field
                      _PremiumTextField(
                        controller: _passwordController,
                        label: 'Password',
                        icon: Icons.lock_outline_rounded,
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: AppTheme.textTertiary,
                            size: 20,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Enter your password';
                          if (v.length < 6) return 'Password must be at least 6 characters';
                          return null;
                        },
                      ).animate().fadeIn(delay: 500.ms, duration: 600.ms).slideX(begin: -0.15, end: 0),

                      const SizedBox(height: 32),

                      // Login Button
                      _buildLoginButton().animate().fadeIn(delay: 600.ms, duration: 600.ms).slideY(begin: 0.2, end: 0),

                      const SizedBox(height: 20),

                      // Sign up link
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const SignUpScreen()),
                              ),
                              child: Text(
                                'Sign up',
                                style: TextStyle(
                                  color: AppTheme.primaryLight,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 700.ms, duration: 600.ms),

                      const SizedBox(height: 32),

                      // Role hints
                      _buildRoleHints().animate().fadeIn(delay: 800.ms, duration: 600.ms),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundOrbs(Size size) {
    return AnimatedBuilder(
      animation: _bgController,
      builder: (context, _) {
        return Stack(
          children: [
            // Top-right violet orb
            Positioned(
              top: -80,
              right: -80,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (ctx, _) => Container(
                  width: 280 + (_pulseController.value * 30),
                  height: 280 + (_pulseController.value * 30),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.primaryColor.withOpacity(0.35),
                        AppTheme.primaryColor.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Bottom-left teal orb
            Positioned(
              bottom: -100,
              left: -60,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (ctx, _) => Container(
                  width: 260 + (_pulseController.value * 20),
                  height: 260 + (_pulseController.value * 20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.secondaryColor.withOpacity(0.25),
                        AppTheme.secondaryColor.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Middle accent
            Positioned(
              top: size.height * 0.45,
              right: -40,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.accentColor.withOpacity(0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Subtle grid overlay
            Opacity(
              opacity: 0.04,
              child: CustomPaint(
                size: size,
                painter: _GridPainter(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: AppTheme.radiusLG,
        boxShadow: AppTheme.primaryGlowShadow,
      ),
      child: const Center(
        child: Text('🔥', style: TextStyle(fontSize: 40)),
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: AppTheme.radiusMD,
          boxShadow: AppTheme.primaryGlowShadow,
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _login,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusMD),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                )
              : const Text(
                  'Sign In',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    letterSpacing: 0.5,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildRoleHints() {
    final hints = [
      ('🎓', 'Student',  'student@edustreak.com'),
      ('👩‍🏫', 'Teacher',  'teacher1@edustreak.com'),
      ('👨‍👩‍👧', 'Parent',   'parent1@edustreak.com'),
      ('🛡️', 'Admin',    'admin@edustreak.com'),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkGlass,
        borderRadius: AppTheme.radiusMD,
        border: Border.all(color: AppTheme.darkBorder.withOpacity(0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.info_outline_rounded, color: AppTheme.primaryLight, size: 16),
            const SizedBox(width: 8),
            Text('Demo accounts', style: TextStyle(color: AppTheme.primaryLight, fontSize: 12, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: hints.map((h) => GestureDetector(
              onTap: () {
                _emailController.text = h.$3;
                _passwordController.text = h.$1 == '🛡️' ? 'admin123' : (h.$1 == '👩‍🏫' ? 'teacher123' : (h.$1 == '👨‍👩‍👧' ? 'parent123' : 'student123'));
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: AppTheme.radiusXS,
                  border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                ),
                child: Text('${h.$1} ${h.$2}', style: TextStyle(color: AppTheme.primaryLight, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Premium Text Field ─────────────────────────────────────────────────────
class _PremiumTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _PremiumTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primaryColor, size: 20),
        suffixIcon: suffixIcon,
      ),
    );
  }
}

// ── Grid Painter for subtle bg texture ──────────────────────────────────────
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 0.5;
    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => false;
}
