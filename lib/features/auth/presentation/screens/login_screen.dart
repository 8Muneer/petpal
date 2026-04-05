import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/core/utils/validators.dart';
import 'package:petpal/core/widgets/app_button.dart';
import 'package:petpal/core/widgets/app_card.dart';
import 'package:petpal/core/widgets/app_input.dart';
import 'package:petpal/core/widgets/app_scaffold.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _isLoading = false;
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // ── Validation ──────────────────────────────────────────────────────────────
  void _validateEmail(String value) {
    setState(() {
      if (value.trim().isEmpty) {
        _emailError = 'אנא הזן/י כתובת אימייל';
      } else if (!Validators.isValidEmail(value.trim())) {
        _emailError = 'כתובת אימייל לא תקינה';
      } else {
        _emailError = null;
      }
    });
  }

  void _validatePassword(String value) {
    setState(() {
      _passwordError = value.isEmpty ? 'אנא הזן/י סיסמה' : null;
    });
  }

  bool get _formValid =>
      _emailError == null &&
      _passwordError == null &&
      _emailCtrl.text.isNotEmpty &&
      _passwordCtrl.text.isNotEmpty;

  // ── Friendly Firebase errors ─────────────────────────────────────────────────
  String _authError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'כתובת אימייל לא תקינה';
      case 'user-disabled':
        return 'המשתמש חסום';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
      case 'INVALID_LOGIN_CREDENTIALS':
        return 'אימייל או סיסמה שגויים';
      case 'network-request-failed':
        return 'בעיית רשת. בדוק/י את החיבור ונסה/י שוב';
      case 'too-many-requests':
        return 'יותר מדי ניסיונות. נסה/י שוב מאוחר יותר';
      default:
        return 'שגיאה בהתחברות: ${e.message ?? e.code}';
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.danger : AppColors.primary,
      ),
    );
  }

  // ── Actions ──────────────────────────────────────────────────────────────────
  Future<void> _handleLogin() async {
    _validateEmail(_emailCtrl.text);
    _validatePassword(_passwordCtrl.text);
    if (!_formValid) return;

    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      if (!mounted) return;
      context.go('/');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _showSnack(_authError(e), isError: true);
    } catch (_) {
      if (!mounted) return;
      _showSnack('שגיאה לא צפויה. נסה/י שוב.', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !Validators.isValidEmail(email)) {
      _showSnack('אנא הזן/י כתובת אימייל תקינה לאיפוס סיסמה', isError: true);
      return;
    }
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      _showSnack('קישור לאיפוס סיסמה נשלח לאימייל');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _showSnack(_authError(e), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── UI ───────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AppScaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: AppSpacing.pagePadding,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Back + title row
                  Row(
                    children: [
                      _BackButton(onTap: () => context.pop()),
                      const SizedBox(width: AppSpacing.sm),
                      Text('התחברות', style: AppTextStyles.h2),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Hero icon
                  Center(child: _HeroIcon()),

                  const SizedBox(height: AppSpacing.lg),

                  // Greeting
                  Text(
                    'שמחים שחזרת!',
                    style: AppTextStyles.h1,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'התחבר/י כדי להמשיך',
                    style: AppTextStyles.caption,
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Form card
                  AppCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      children: [
                        AppInput(
                          controller: _emailCtrl,
                          label: 'אימייל',
                          hint: 'name@example.com',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          textDirection: TextDirection.ltr,
                          errorText: _emailError,
                          onChanged: _validateEmail,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppInput(
                          controller: _passwordCtrl,
                          label: 'סיסמה',
                          icon: Icons.lock_outline_rounded,
                          isPassword: true,
                          textInputAction: TextInputAction.done,
                          textDirection: TextDirection.ltr,
                          errorText: _passwordError,
                          onChanged: _validatePassword,
                          onEditingComplete: _isLoading ? null : _handleLogin,
                        ),
                        const SizedBox(height: AppSpacing.sm),

                        // Forgot password
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed:
                                _isLoading ? null : _handleForgotPassword,
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'שכחת סיסמה?',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: AppSpacing.md),

                        AppButton(
                          label: 'התחברות',
                          onTap: _isLoading ? null : _handleLogin,
                          isLoading: _isLoading,
                          leadingIcon: Icons.login_rounded,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Sign-up link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('אין לך חשבון?', style: AppTextStyles.caption),
                      TextButton(
                        onPressed:
                            _isLoading ? null : () => context.push('/signup'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'הרשמה',
                          style: AppTextStyles.bodyBold
                              .copyWith(color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadius.mdRadius,
          boxShadow: AppShadows.card,
        ),
        child: const Icon(
          Icons.arrow_forward_rounded,
          size: 20,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _HeroIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        borderRadius: AppRadius.xlRadius,
        gradient: AppColors.primaryGradient,
        boxShadow: AppShadows.button,
      ),
      child: const Icon(
        Icons.pets_rounded,
        size: 36,
        color: Colors.white,
      ),
    );
  }
}
