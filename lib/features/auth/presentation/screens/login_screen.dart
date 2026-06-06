import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/core/utils/validators.dart';
import 'package:petpal/core/widgets/app_input.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();

  late final AnimationController _animCtrl;
  late final Animation<double>   _fadeAnim;
  late final Animation<Offset>   _slideAnim;

  bool    _isLoading     = false;
  String? _emailError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.10),
      end:   Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // ── Validation ──────────────────────────────────────────────────────────────

  void _validateEmail(String v) => setState(() {
        if (v.trim().isEmpty) {
          _emailError = 'אנא הזן/י כתובת אימייל';
        } else if (!Validators.isValidEmail(v.trim())) {
          _emailError = 'כתובת אימייל לא תקינה';
        } else {
          _emailError = null;
        }
      });

  void _validatePassword(String v) =>
      setState(() => _passwordError = v.isEmpty ? 'אנא הזן/י סיסמה' : null);

  bool get _formValid =>
      _emailError == null &&
      _passwordError == null &&
      _emailCtrl.text.isNotEmpty &&
      _passwordCtrl.text.isNotEmpty;

  // ── Auth helpers ─────────────────────────────────────────────────────────────

  String _authError(FirebaseAuthException e) => switch (e.code) {
        'invalid-email'          => 'כתובת אימייל לא תקינה',
        'user-disabled'          => 'המשתמש חסום',
        'user-not-found'         ||
        'wrong-password'         ||
        'invalid-credential'     ||
        'INVALID_LOGIN_CREDENTIALS' => 'אימייל או סיסמה שגויים',
        'network-request-failed' => 'בעיית רשת. בדוק/י את החיבור ונסה/י שוב',
        'too-many-requests'      => 'יותר מדי ניסיונות. נסה/י שוב מאוחר יותר',
        _                        => 'שגיאה בהתחברות: ${e.message ?? e.code}',
      };

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Text(msg),
        backgroundColor: isError ? AppColors.danger : AppColors.primary,
      ),
    );
  }

  Future<void> _handleLogin() async {
    _validateEmail(_emailCtrl.text);
    _validatePassword(_passwordCtrl.text);
    if (!_formValid) return;

    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email:    _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      if (!mounted) return;
      context.go('/');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _snack(_authError(e), isError: true);
    } catch (_) {
      if (!mounted) return;
      _snack('שגיאה לא צפויה. נסה/י שוב.', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !Validators.isValidEmail(email)) {
      _snack('אנא הזן/י כתובת אימייל תקינה לאיפוס סיסמה', isError: true);
      return;
    }
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      _snack('קישור לאיפוס סיסמה נשלח לאימייל');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _snack(_authError(e), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final topPadding     = MediaQuery.of(context).padding.top;
    final bottomPadding  = MediaQuery.of(context).padding.bottom;
    final keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;
    final screenHeight   = MediaQuery.of(context).size.height;
    final keyboardOpen   = keyboardHeight > 0;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            // ── Background image — starts at top, extends 56 px past the
            //    form card's top edge.  This covers the 36 px corner-radius
            //    spandrels AND the upward box-shadow (~48 px above the form)
            //    so there is no white/gap visible anywhere around the form's
            //    rounded corners. ───────────────────────────────────────────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: screenHeight * 0.5,
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: const NetworkImage(
                      'https://images.unsplash.com/photo-1583511655857-d19b40a7a54e?q=80&w=2000',
                    ),
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withValues(alpha: 0.10),
                      BlendMode.darken,
                    ),
                  ),
                ),
              ),
            ),

            // ── Gradient fade over bottom of image ───────────────────────
            Positioned(
              top: screenHeight * 0.22,
              left: 0,
              right: 0,
              height: screenHeight * 0.38,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.75),
                    ],
                  ),
                ),
              ),
            ),

            // ── Back button ───────────────────────────────────────────────
            Positioned(
              top: topPadding + 16,
              right: 20,
              child: _CircleBackButton(onTap: () => context.pop()),
            ),

            // ── Title + subtitle — sits at the bottom of the image crop ────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: screenHeight * 0.46,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: keyboardOpen ? 0.0 : 1.0,
                child: Stack(
                  children: [
                    Positioned(
                      bottom: 22, left: 0, right: 0,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'שמחים שחזרת!',
                            style: AppTextStyles.h1.copyWith(
                              color: Colors.white,
                              fontSize: 28,
                              letterSpacing: -0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'התחבר/י כדי להמשיך',
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white.withValues(alpha: 0.88),
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Form card (slides to top when keyboard opens) ─────────────
            AnimatedPositioned(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeInOut,
              bottom: 0,
              left: 0,
              right: 0,
              top: keyboardOpen ? topPadding : screenHeight * 0.46,
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.pureWhite,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(36),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                          24, 24, 24, 16 + keyboardHeight + bottomPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ── Email ────────────────────────────────────────
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

                          const SizedBox(height: 12),

                          // ── Password ─────────────────────────────────────
                          AppInput(
                            controller: _passwordCtrl,
                            label: 'סיסמה',
                            icon: Icons.lock_outline_rounded,
                            isPassword: true,
                            textInputAction: TextInputAction.done,
                            textDirection: TextDirection.ltr,
                            errorText: _passwordError,
                            onChanged: _validatePassword,
                            onEditingComplete:
                                _isLoading ? null : () { _handleLogin(); },
                          ),

                          const SizedBox(height: 6),

                          // ── Forgot password ──────────────────────────────
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed:
                                  _isLoading ? null : _handleForgotPassword,
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'שכחת סיסמה?',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // ── Login button ─────────────────────────────────
                          _GradientButton(
                            label: 'התחברות',
                            icon: Icons.login_rounded,
                            isLoading: _isLoading,
                            onTap: _isLoading ? null : _handleLogin,
                          ),

                          const SizedBox(height: 20),

                          // ── Divider ──────────────────────────────────────
                          Row(
                            children: [
                              const Expanded(
                                  child: Divider(color: AppColors.divider)),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14),
                                child: Text(
                                  'או',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textMuted,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const Expanded(
                                  child: Divider(color: AppColors.divider)),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // ── Google button ─────────────────────────────────
                          _GoogleButton(
                            onTap: () =>
                                _snack('התחברות עם Google תהיה זמינה בקרוב'),
                          ),

                          const SizedBox(height: 14),

                          // ── Sign-up link ──────────────────────────────────
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'אין לך חשבון?',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textMuted,
                                ),
                              ),
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: _isLoading
                                    ? null
                                    : () => context.push('/signup'),
                                child: Text(
                                  'הרשמה עכשיו',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w800,
                                  ),
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
            ),
          ],
        ),
      ),
    );
  }
}

// ── Gradient login button ─────────────────────────────────────────────────────

class _GradientButton extends StatelessWidget {
  final String    label;
  final IconData  icon;
  final bool      isLoading;
  final VoidCallback? onTap;

  const _GradientButton({
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: isLoading
            ? null
            : const LinearGradient(
                colors: [AppColors.primary, AppColors.regalNavy],
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
              ),
        color: isLoading ? AppColors.primary : null,
        boxShadow: isLoading
            ? null
            : [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.45),
                  blurRadius: 24,
                  spreadRadius: 0,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Icon(icon, color: Colors.white, size: 20),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ── Google button ─────────────────────────────────────────────────────────────

class _GoogleButton extends StatelessWidget {
  final VoidCallback onTap;
  const _GoogleButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppColors.pureWhite,
        border: Border.all(color: AppColors.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'המשך עם Google',
                style: AppTextStyles.bodyBold.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Image.network(
                'https://www.gstatic.com/images/branding/googleg/1x/googleg_standard_color_128dp.png',
                height: 22,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.person_outline,
                  size: 22,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Back button ───────────────────────────────────────────────────────────────

class _CircleBackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CircleBackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: AppRadius.mdRadius,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: const Icon(
          Icons.arrow_back_rounded,
          size: 20,
          color: Colors.white,
        ),
      ),
    );
  }
}
