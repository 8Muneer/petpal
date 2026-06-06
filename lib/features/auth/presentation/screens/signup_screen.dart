import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/core/utils/validators.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  final _nameCtrl     = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl  = TextEditingController();

  late AnimationController _animCtrl;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  bool    _isLoading   = false;
  bool    _acceptTerms = false;
  bool    _isPetOwner  = true;

  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmError;

  final _auth     = FirebaseAuth.instance;
  final _usersRef = FirebaseFirestore.instance.collection('users');

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
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
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // ── Validation ───────────────────────────────────────────────────────────────

  void _validateName(String v) => setState(() {
        _nameError = v.trim().isEmpty ? 'אנא הזן/י שם מלא' : null;
      });

  void _validateEmail(String v) => setState(() {
        if (v.trim().isEmpty) {
          _emailError = 'אנא הזן/י כתובת אימייל';
        } else if (!Validators.isValidEmail(v.trim())) {
          _emailError = 'כתובת אימייל לא תקינה';
        } else {
          _emailError = null;
        }
      });

  void _validatePassword(String v) => setState(() {
        if (v.isEmpty) {
          _passwordError = 'אנא הזן/י סיסמה';
        } else if (v.length < 6) {
          _passwordError = 'הסיסמה חייבת להכיל לפחות 6 תווים';
        } else {
          _passwordError = null;
        }
        if (_confirmCtrl.text.isNotEmpty) _validateConfirm(_confirmCtrl.text);
      });

  void _validateConfirm(String v) => setState(() {
        _confirmError = v != _passwordCtrl.text ? 'הסיסמאות אינן תואמות' : null;
      });

  bool get _formValid =>
      _nameError == null &&
      _emailError == null &&
      _passwordError == null &&
      _confirmError == null &&
      _nameCtrl.text.isNotEmpty &&
      _emailCtrl.text.isNotEmpty &&
      _passwordCtrl.text.isNotEmpty &&
      _confirmCtrl.text.isNotEmpty;

  // ── Auth ─────────────────────────────────────────────────────────────────────

  String _authError(FirebaseAuthException e) => switch (e.code) {
        'email-already-in-use'   => 'האימייל כבר בשימוש. נסה/י להתחבר או השתמש/י באימייל אחר.',
        'invalid-email'          => 'כתובת האימייל לא תקינה.',
        'weak-password'          => 'הסיסמה חלשה מדי. נסה/י סיסמה חזקה יותר.',
        'network-request-failed' => 'בעיית רשת. בדוק/י את החיבור ונסה/י שוב.',
        _                        => 'שגיאה בהרשמה. נסה/י שוב.',
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

  Future<void> _handleSignup() async {
    _validateName(_nameCtrl.text);
    _validateEmail(_emailCtrl.text);
    _validatePassword(_passwordCtrl.text);
    _validateConfirm(_confirmCtrl.text);

    if (!_acceptTerms) {
      _snack('יש לאשר את תנאי השימוש', isError: true);
      return;
    }
    if (!_formValid) return;

    setState(() => _isLoading = true);
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email:    _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      final uid = cred.user?.uid;
      try { await cred.user?.updateDisplayName(_nameCtrl.text.trim()); } catch (_) {}

      if (uid != null) {
        try {
          await _usersRef.doc(uid).set({
            'uid':        uid,
            'name':       _nameCtrl.text.trim(),
            'email':      _emailCtrl.text.trim(),
            'role':       _isPetOwner ? 'petOwner' : 'serviceProvider',
            'isVerified': false,
            'createdAt':  FieldValue.serverTimestamp(),
            'updatedAt':  FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } catch (_) {}
      }

      if (!mounted) return;
      _snack('החשבון נוצר בהצלחה! ברוך/ה הבא/ה 🎉');
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
                          'יצירת חשבון',
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
                          'הצטרף/י לקהילת PetPal',
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

                        const SizedBox(height: 28),

                        // ── Role selector ─────────────────────────────────
                        _GlassRoleSelector(
                          isPetOwner: _isPetOwner,
                          onChanged: (v) => setState(() => _isPetOwner = v),
                        ),

                        const SizedBox(height: 20),

                        // ── Full name ─────────────────────────────────────
                        _GlassInput(
                          controller: _nameCtrl,
                          label: 'שם מלא',
                          hint: 'הזן/י שם',
                          icon: Icons.badge_outlined,
                          textInputAction: TextInputAction.next,
                          errorText: _nameError,
                          onChanged: _validateName,
                        ),

                        const SizedBox(height: 12),

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
                          textInputAction: TextInputAction.next,
                          errorText: _passwordError,
                          onChanged: _validatePassword,
                        ),

                        const SizedBox(height: 12),

                        // ── Confirm password ──────────────────────────────
                        _GlassInput(
                          controller: _confirmCtrl,
                          label: 'אימות סיסמה',
                          icon: Icons.lock_reset_outlined,
                          isPassword: true,
                          textInputAction: TextInputAction.done,
                          errorText: _confirmError,
                          onChanged: _validateConfirm,
                          onEditingComplete: _isLoading ? null : _handleSignup,
                        ),

                        const SizedBox(height: 16),

                        // ── Terms ─────────────────────────────────────────
                        _GlassTermsRow(
                          accepted: _acceptTerms,
                          onTap: () =>
                              setState(() => _acceptTerms = !_acceptTerms),
                        ),

                        const SizedBox(height: 28),

                        // ── Submit ────────────────────────────────────────
                        _GradientButton(
                          label: 'יצירת חשבון',
                          icon: Icons.check_rounded,
                          isLoading: _isLoading,
                          onTap: _isLoading ? null : _handleSignup,
                        ),

                        const SizedBox(height: 20),

                        // ── Login link ────────────────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'כבר יש לך חשבון?',
                              style: AppTextStyles.caption.copyWith(
                                color: Colors.white.withValues(alpha: 0.70),
                              ),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: _isLoading
                                  ? null
                                  : () => context.push('/login'),
                              child: Text(
                                'התחבר/י',
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
    final focused   = _focus.hasFocus;
    final hasError  = widget.errorText != null;

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
            fontSize: 13,
            fontWeight: FontWeight.w600,
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

// ── Glass role selector ───────────────────────────────────────────────────────

class _GlassRoleSelector extends StatelessWidget {
  final bool               isPetOwner;
  final ValueChanged<bool> onChanged;

  const _GlassRoleSelector({
    required this.isPetOwner,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'בחר/י סוג משתמש',
          style: TextStyle(
            color:       Colors.white.withValues(alpha: 0.72),
            fontSize:    13,
            fontWeight:  FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _GlassRoleTile(
                label:       'בעל חיית מחמד',
                subtitle:    'מחפש/ת מטפל/ת',
                icon:        Icons.pets_rounded,
                accentColor: AppColors.walks,
                isSelected:  isPetOwner,
                onTap:       () => onChanged(true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _GlassRoleTile(
                label:       'מטפל/ת',
                subtitle:    'מציע/ה שירותים',
                icon:        Icons.favorite_rounded,
                accentColor: AppColors.sitting,
                isSelected:  !isPetOwner,
                onTap:       () => onChanged(false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            key: ValueKey(isPetOwner),
            isPetOwner
                ? 'לבעלי חיות מחמד שמחפשים דוג-ווקר/סיטר'
                : 'למטפלים/דוג-ווקרים שמציעים שירותים',
            style: TextStyle(
              color:    Colors.white.withValues(alpha: 0.52),
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _GlassRoleTile extends StatelessWidget {
  final String       label;
  final String       subtitle;
  final IconData     icon;
  final Color        accentColor;
  final bool         isSelected;
  final VoidCallback onTap;

  const _GlassRoleTile({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: 0.22)
              : Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? accentColor
                : Colors.white.withValues(alpha: 0.35),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color:      accentColor.withValues(alpha: 0.40),
                    blurRadius: 20,
                    offset:     const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width:  42,
              height: 42,
              decoration: BoxDecoration(
                color: isSelected
                    ? accentColor.withValues(alpha: 0.30)
                    : Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? accentColor
                    : Colors.white.withValues(alpha: 0.55),
                size: 22,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color:      Colors.white,
                fontWeight: FontWeight.w700,
                fontSize:   13,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                color:    Colors.white.withValues(alpha: 0.48),
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Glass terms row ───────────────────────────────────────────────────────────

class _GlassTermsRow extends StatelessWidget {
  final bool         accepted;
  final VoidCallback onTap;

  const _GlassTermsRow({required this.accepted, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve:    Curves.easeInOut,
            width:  22,
            height: 22,
            decoration: BoxDecoration(
              color: accepted ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: accepted
                    ? AppColors.primary
                    : Colors.white.withValues(alpha: 0.30),
                width: 1.5,
              ),
              boxShadow: accepted
                  ? [
                      BoxShadow(
                        color:      AppColors.primary.withValues(alpha: 0.50),
                        blurRadius: 12,
                        spreadRadius: 1,
                        offset:     const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: accepted
                ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'אני מאשר/ת את תנאי השימוש והמדיניות',
              style: TextStyle(
                color:      Colors.white.withValues(alpha: 0.80),
                fontSize:   13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Gradient submit button ────────────────────────────────────────────────────

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
                          color:       Colors.white,
                          fontWeight:  FontWeight.w800,
                          fontSize:    16,
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
