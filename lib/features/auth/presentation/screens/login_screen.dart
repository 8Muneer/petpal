import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/core/utils/validators.dart';

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
  String? _serverError;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
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

  // ── Validation ───────────────────────────────────────────────────────────────

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
        'invalid-email'             => 'כתובת אימייל לא תקינה',
        'user-disabled'             => 'המשתמש חסום',
        'user-not-found'            ||
        'wrong-password'            ||
        'invalid-credential'        ||
        'INVALID_LOGIN_CREDENTIALS' => 'אימייל או סיסמה שגויים',
        'network-request-failed'    => 'בעיית רשת. בדוק/י את החיבור ונסה/י שוב',
        'too-many-requests'         => 'יותר מדי ניסיונות. נסה/י שוב מאוחר יותר',
        _                           => 'שגיאה בהתחברות: ${e.message ?? e.code}',
      };

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).clearSnackBars();
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
    setState(() => _serverError = null);
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
      final msg = _authError(e);
      setState(() => _serverError = msg);
      _snack(msg, isError: true);
    } catch (_) {
      if (!mounted) return;
      const msg = 'שגיאה לא צפויה. נסה/י שוב.';
      setState(() => _serverError = msg);
      _snack(msg, isError: true);
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

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final topPadding     = MediaQuery.of(context).padding.top;
    final bottomPadding  = MediaQuery.of(context).padding.bottom;
    final keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // ── Full-screen background image ──────────────────────────────
            Positioned.fill(
              child: Image.network(
                'https://images.unsplash.com/photo-1583511655857-d19b40a7a54e?q=80&w=2000',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),

            // ── Dark gradient overlay ─────────────────────────────────────
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.28, 0.58, 1.0],
                    colors: [
                      Colors.black.withValues(alpha: 0.62),
                      Colors.black.withValues(alpha: 0.28),
                      Colors.black.withValues(alpha: 0.58),
                      Colors.black.withValues(alpha: 0.82),
                    ],
                  ),
                ),
              ),
            ),

            // ── Radial vignette ───────────────────────────────────────────
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.1,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.35),
                    ],
                  ),
                ),
              ),
            ),

            // ── Scrollable content ────────────────────────────────────────
            Positioned.fill(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      24,
                      topPadding + 76,
                      24,
                      24 + keyboardHeight + bottomPadding,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── Title ────────────────────────────────────────
                        Text(
                          'שמחים שחזרת!',
                          style: AppTextStyles.h1.copyWith(
                            color: Colors.white,
                            fontSize: 30,
                            letterSpacing: -0.5,
                            shadows: [
                              Shadow(
                                color:      Colors.black.withValues(alpha: 0.55),
                                blurRadius: 18,
                                offset:     const Offset(0, 3),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'התחבר/י כדי להמשיך',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 14,
                            shadows: [
                              Shadow(
                                color:      Colors.black.withValues(alpha: 0.45),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 36),

                        // ── Email ─────────────────────────────────────────
                        _GlassInput(
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

                        // ── Password ──────────────────────────────────────
                        _GlassInput(
                          controller: _passwordCtrl,
                          label: 'סיסמה',
                          icon: Icons.lock_outline_rounded,
                          isPassword: true,
                          textInputAction: TextInputAction.done,
                          textDirection: TextDirection.ltr,
                          errorText: _passwordError,
                          onChanged: _validatePassword,
                          onEditingComplete:
                              _isLoading ? null : _handleLogin,
                        ),

                        const SizedBox(height: 8),

                        // ── Forgot password ───────────────────────────────
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _isLoading ? null : _handleForgotPassword,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'שכחת סיסמה?',
                              style: AppTextStyles.caption.copyWith(
                                color: Colors.white.withValues(alpha: 0.80),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ── Login button ──────────────────────────────────
                        _GradientButton(
                          label: 'התחברות',
                          icon: Icons.login_rounded,
                          isLoading: _isLoading,
                          onTap: _isLoading ? null : _handleLogin,
                        ),

                        if (_serverError != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.danger.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: AppColors.danger.withValues(alpha: 0.45)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline_rounded,
                                    color: AppColors.danger, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _serverError!,
                                    style: const TextStyle(
                                      color: AppColors.danger,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

                        // ── Divider ───────────────────────────────────────
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: Colors.white.withValues(alpha: 0.22),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              child: Text(
                                'או',
                                style: AppTextStyles.caption.copyWith(
                                  color: Colors.white.withValues(alpha: 0.55),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: Colors.white.withValues(alpha: 0.22),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // ── Google button ─────────────────────────────────
                        _GlassGoogleButton(
                          onTap: () =>
                              _snack('התחברות עם Google תהיה זמינה בקרוב'),
                        ),

                        const SizedBox(height: 20),

                        // ── Sign-up link ──────────────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'אין לך חשבון?',
                              style: AppTextStyles.caption.copyWith(
                                color: Colors.white.withValues(alpha: 0.70),
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
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Back button (on top so it receives taps) ──────────────────
            Positioned(
              top: topPadding + 16,
              right: 20,
              child: _CircleBackButton(onTap: () => context.pop()),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Glass text input ──────────────────────────────────────────────────────────

class _GlassInput extends StatefulWidget {
  final TextEditingController controller;
  final String                label;
  final String?               hint;
  final IconData              icon;
  final bool                  isPassword;
  final TextInputType?        keyboardType;
  final TextInputAction?      textInputAction;
  final TextDirection?        textDirection;
  final String?               errorText;
  final ValueChanged<String>? onChanged;
  final VoidCallback?         onEditingComplete;

  const _GlassInput({
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.isPassword          = false,
    this.keyboardType,
    this.textInputAction,
    this.textDirection,
    this.errorText,
    this.onChanged,
    this.onEditingComplete,
  });

  @override
  State<_GlassInput> createState() => _GlassInputState();
}

class _GlassInputState extends State<_GlassInput> {
  final _focus = FocusNode();
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final focused  = _focus.hasFocus;
    final hasError = widget.errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            color: hasError
                ? AppColors.danger
                : focused
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.72),
            fontSize:    13,
            fontWeight:  FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 6),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.28),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: hasError
                  ? AppColors.danger
                  : focused
                      ? Colors.white.withValues(alpha: 0.85)
                      : Colors.white.withValues(alpha: 0.22),
              width: focused ? 1.5 : 1.0,
            ),
          ),
          child: TextField(
            controller:        widget.controller,
            focusNode:         _focus,
            obscureText:       widget.isPassword && _obscure,
            keyboardType:      widget.keyboardType,
            textInputAction:   widget.textInputAction,
            textDirection:     widget.textDirection,
            onChanged:         widget.onChanged,
            onEditingComplete: widget.onEditingComplete,
            cursorColor:       Colors.white,
            style: const TextStyle(
              color:      Colors.white,
              fontSize:   15,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText:  widget.hint,
              hintStyle: TextStyle(
                color:    Colors.white.withValues(alpha: 0.45),
                fontSize: 14,
              ),
              prefixIcon: Icon(
                widget.icon,
                color: focused
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.60),
                size: 20,
              ),
              suffixIcon: widget.isPassword
                  ? IconButton(
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.white.withValues(alpha: 0.60),
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    )
                  : null,
              filled:    true,
              fillColor: Colors.transparent,
              border:         InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical:   15,
              ),
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 5, right: 4),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 12, color: AppColors.danger),
                const SizedBox(width: 4),
                Text(
                  widget.errorText!,
                  style: const TextStyle(
                    color:      AppColors.danger,
                    fontSize:   11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ── Glass Google button ───────────────────────────────────────────────────────

class _GlassGoogleButton extends StatelessWidget {
  final VoidCallback onTap;
  const _GlassGoogleButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.28),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.22),
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'המשך עם Google',
              style: AppTextStyles.bodyBold.copyWith(
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Image.network(
              'https://www.gstatic.com/images/branding/googleg/1x/googleg_standard_color_128dp.png',
              height: 22,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.person_outline,
                size: 22,
                color: Colors.white,
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
  final String        label;
  final IconData      icon;
  final bool          isLoading;
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
                begin:  Alignment.centerRight,
                end:    Alignment.centerLeft,
              ),
        color: isLoading ? AppColors.primary : null,
        boxShadow: isLoading
            ? null
            : [
                BoxShadow(
                  color:      AppColors.primary.withValues(alpha: 0.50),
                  blurRadius: 28,
                  spreadRadius: 0,
                  offset:     const Offset(0, 8),
                ),
                BoxShadow(
                  color:      AppColors.primary.withValues(alpha: 0.18),
                  blurRadius: 8,
                  offset:     const Offset(0, 2),
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
                    width:  24,
                    height: 24,
                    child:  CircularProgressIndicator(
                      color:       Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          color:        Colors.white,
                          fontWeight:   FontWeight.w800,
                          fontSize:     16,
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

// ── Circle back button ────────────────────────────────────────────────────────

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
            color: Colors.white.withValues(alpha: 0.30),
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
