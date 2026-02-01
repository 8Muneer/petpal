import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/features/auth/presentation/signup_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  static const String _logTag = '[LoginScreen]';

  void _log(String message, {Object? error, StackTrace? stackTrace}) {
    debugPrint('$_logTag $message');
    if (error != null) debugPrint('$_logTag   error: $error');
    if (stackTrace != null) debugPrint('$_logTag   stackTrace: $stackTrace');
  }

  @override
  void initState() {
    super.initState();
    _log('initState');
  }

  @override
  void dispose() {
    _log('dispose');
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Color get _bgTop => const Color(0xFFECFDF5);
  Color get _bgMid => const Color(0xFFF6F7FB);
  Color get _bgBottom => const Color(0xFFFFFFFF);

  void _showSnack(String msg, {bool isError = false}) {
    _log('SnackBar: $msg');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Text(msg),
        backgroundColor: isError ? const Color(0xFFB91C1C) : const Color(0xFF0F766E),
      ),
    );
  }

  String _friendlyAuthErrorHe(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'כתובת אימייל לא תקינה';
      case 'user-disabled':
        return 'המשתמש חסום';
      case 'user-not-found':
        return 'לא נמצא משתמש עם האימייל הזה';
      case 'wrong-password':
        return 'סיסמה שגויה';
      case 'invalid-credential':
      case 'INVALID_LOGIN_CREDENTIALS':
        return 'אימייל או סיסמה לא נכונים';
      case 'network-request-failed':
        return 'בעיית רשת. בדוק/י אינטרנט ונסה/י שוב';
      case 'too-many-requests':
        return 'יותר מדי ניסיונות. נסה/י שוב מאוחר יותר';
      default:
        return 'התחברות נכשלה: ${e.message ?? e.code}';
    }
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showSnack('אנא מלא/י אימייל וסיסמה', isError: true);
      _log('validation failed: empty email/password');
      return;
    }

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(email)) {
      _showSnack('אנא הזן/י כתובת אימייל תקינה', isError: true);
      _log('validation failed: invalid email', error: email);
      return;
    }

    _log('attempting login', error: 'email=$email, passwordLength=${password.length}');
    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;

      // ✅ IMPORTANT: go to AuthGate (/) so it routes by Firestore role
      _log('login success, navigating to AuthGate (/) for role-based routing');
      Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
    } on FirebaseAuthException catch (e) {
      _log('FirebaseAuthException during login: ${e.code} | ${e.message}');
      if (!mounted) return;
      _showSnack(_friendlyAuthErrorHe(e), isError: true);
    } catch (e, st) {
      _log('Unexpected error during login', error: e, stackTrace: st);
      if (!mounted) return;
      _showSnack('שגיאה לא צפויה. נסה/י שוב.', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showSnack('אנא הזן/י אימייל כדי לאפס סיסמה', isError: true);
      return;
    }

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(email)) {
      _showSnack('אנא הזן/י כתובת אימייל תקינה', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      _showSnack('נשלח קישור לאיפוס סיסמה ✅');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _showSnack(_friendlyAuthErrorHe(e), isError: true);
    } catch (_) {
      if (!mounted) return;
      _showSnack('שגיאה לא צפויה. נסה/י שוב.', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bgBottom,
        body: Stack(
          children: [
            // Background gradient (same as Signup)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [_bgTop, _bgMid, _bgBottom],
                  ),
                ),
              ),
            ),

            // Decorative blobs (same style)
            Positioned(
              top: -120,
              left: -90,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF34D399).withOpacity(0.22),
                      const Color(0xFF0EA5E9).withOpacity(0.14),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 90,
              right: -110,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF22C55E).withOpacity(0.12),
                      const Color(0xFF0F766E).withOpacity(0.14),
                    ],
                  ),
                ),
              ),
            ),

            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header row (same vibe)
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_forward_rounded),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'התחברות',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Small hero icon (consistent)
                    Center(
                      child: Container(
                        width: 82,
                        height: 82,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          color: Colors.white.withOpacity(0.65),
                          border: Border.all(color: Colors.white.withOpacity(0.48)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 26,
                              offset: const Offset(0, 16),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.pets_rounded,
                          size: 42,
                          color: Color(0xFF0F766E),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    const Text(
                      'ברוכים הבאים 👋',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'התחברו כדי להמשיך',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF334155).withOpacity(0.80),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Glass card (same as Signup)
                    _GlassCard(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          _InputField(
                            controller: _emailController,
                            label: 'אימייל',
                            hint: 'name@example.com',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 12),

                          // password with toggle
                          TextField(
                            controller: _passwordController,
                            obscureText: !_isPasswordVisible,
                            textDirection: TextDirection.ltr,
                            decoration: InputDecoration(
                              labelText: 'סיסמה',
                              hintText: '••••••••',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                onPressed: () => setState(
                                  () => _isPasswordVisible = !_isPasswordVisible,
                                ),
                                icon: Icon(
                                  _isPasswordVisible
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.65),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.6)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: const Color(0xFFE2E8F0).withOpacity(0.9),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: Color(0xFF0F766E),
                                  width: 1.6,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                              onPressed: _isLoading ? null : _handleForgotPassword,
                              child: Text(
                                'שכחת סיסמה?',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF0F766E).withOpacity(0.95),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 6),

                          _PrimaryGradientButton(
                            text: _isLoading ? 'מתחבר...' : 'התחבר',
                            icon: _isLoading
                                ? Icons.hourglass_top_rounded
                                : Icons.login_rounded,
                            onTap: _isLoading ? null : _handleLogin,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'אין לך חשבון?',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF334155).withOpacity(0.85),
                          ),
                        ),
                        TextButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const SignupScreen()),
                                  );
                                },
                          child: const Text(
                            'הרשמה',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F766E),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// --- Same helpers style as Signup (copied for consistency) ---

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;

  const _InputField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textDirection: TextDirection.ltr,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white.withOpacity(0.65),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.6)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: const Color(0xFFE2E8F0).withOpacity(0.9)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF0F766E), width: 1.6),
        ),
      ),
    );
  }
}

class _PrimaryGradientButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback? onTap;

  const _PrimaryGradientButton({
    required this.text,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFF0F766E), Color(0xFF22C55E)],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 24,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.22)),
              ),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const _GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.76),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withOpacity(0.48)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 26,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}
