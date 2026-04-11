import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/core/utils/validators.dart';
import 'package:petpal/core/widgets/app_button.dart';
import 'package:petpal/core/widgets/app_input.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _isLoading = false;
  bool _acceptTerms = false;
  bool _isPetOwner = true;

  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmError;

  final _auth = FirebaseAuth.instance;
  final _usersRef = FirebaseFirestore.instance.collection('users');

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

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
        _confirmError =
            v != _passwordCtrl.text ? 'הסיסמאות אינן תואמות' : null;
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

  String _authError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'האימייל כבר בשימוש. נסה/י להתחבר או השתמש/י באימייל אחר.';
      case 'invalid-email':
        return 'כתובת האימייל לא תקינה.';
      case 'weak-password':
        return 'הסיסמה חלשה מדי. נסה/י סיסמה חזקה יותר.';
      case 'network-request-failed':
        return 'בעיית רשת. בדוק/י את החיבור ונסה/י שוב.';
      default:
        return 'שגיאה בהרשמה. נסה/י שוב.';
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

  Future<void> _handleSignup() async {
    _validateName(_nameCtrl.text);
    _validateEmail(_emailCtrl.text);
    _validatePassword(_passwordCtrl.text);
    _validateConfirm(_confirmCtrl.text);

    if (!_acceptTerms) {
      _showSnack('יש לאשר את תנאי השימוש', isError: true);
      return;
    }
    if (!_formValid) return;

    setState(() => _isLoading = true);
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );

      final uid = cred.user?.uid;

      try {
        await cred.user?.updateDisplayName(_nameCtrl.text.trim());
      } catch (_) {}

      if (uid != null) {
        try {
          await _usersRef.doc(uid).set(
            {
              'uid': uid,
              'name': _nameCtrl.text.trim(),
              'email': _emailCtrl.text.trim(),
              'role': _isPetOwner ? 'petOwner' : 'serviceProvider',
              'isVerified': false,
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
        } catch (_) {}
      }

      if (!mounted) return;
      _showSnack('החשבון נוצר בהצלחה! ברוך/ה הבא/ה 🎉');
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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.surfaceCard,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),

                // Back button
                Align(
                  alignment: Alignment.centerRight,
                  child: _BackButton(onTap: () => context.pop()),
                ),

                const SizedBox(height: 20),

                Text('יצירת חשבון', style: AppTextStyles.h1),
                const SizedBox(height: 4),
                Text('הצטרף/י לקהילת PetPal', style: AppTextStyles.caption),

                const SizedBox(height: 28),

                // Role selector
                _RoleSelector(
                  isPetOwner: _isPetOwner,
                  onChanged: (v) => setState(() => _isPetOwner = v),
                ),

                const SizedBox(height: 20),

                // Form fields
                AppInput(
                  controller: _nameCtrl,
                  label: 'שם מלא',
                  hint: 'הזן/י שם',
                  icon: Icons.badge_outlined,
                  textInputAction: TextInputAction.next,
                  errorText: _nameError,
                  onChanged: _validateName,
                ),
                const SizedBox(height: 14),
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
                const SizedBox(height: 14),
                AppInput(
                  controller: _passwordCtrl,
                  label: 'סיסמה',
                  icon: Icons.lock_outline_rounded,
                  isPassword: true,
                  textInputAction: TextInputAction.next,
                  textDirection: TextDirection.ltr,
                  errorText: _passwordError,
                  onChanged: _validatePassword,
                ),
                const SizedBox(height: 14),
                AppInput(
                  controller: _confirmCtrl,
                  label: 'אימות סיסמה',
                  icon: Icons.lock_reset_outlined,
                  isPassword: true,
                  textInputAction: TextInputAction.done,
                  textDirection: TextDirection.ltr,
                  errorText: _confirmError,
                  onChanged: _validateConfirm,
                  onEditingComplete: _isLoading ? null : _handleSignup,
                ),

                const SizedBox(height: 16),

                // Terms checkbox
                GestureDetector(
                  onTap: () =>
                      setState(() => _acceptTerms = !_acceptTerms),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _acceptTerms,
                          onChanged: (v) =>
                              setState(() => _acceptTerms = v ?? false),
                          activeColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.smRadius,
                          ),
                          side: const BorderSide(
                              color: AppColors.border, width: 1.5),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'אני מאשר/ת את תנאי השימוש והמדיניות',
                          style: AppTextStyles.caption,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                AppButton(
                  label: 'צור חשבון',
                  onTap: _isLoading ? null : _handleSignup,
                  isLoading: _isLoading,
                  leadingIcon: Icons.check_rounded,
                ),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('כבר יש לך חשבון?', style: AppTextStyles.caption),
                    TextButton(
                      onPressed:
                          _isLoading ? null : () => context.push('/login'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'התחבר/י',
                        style: AppTextStyles.bodyBold
                            .copyWith(color: AppColors.primary),
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
    );
  }
}

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
          color: AppColors.surfaceBase,
          borderRadius: AppRadius.mdRadius,
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

class _RoleSelector extends StatelessWidget {
  final bool isPetOwner;
  final ValueChanged<bool> onChanged;

  const _RoleSelector({
    required this.isPetOwner,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('בחר/י סוג משתמש', style: AppTextStyles.h3),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _RoleTile(
                label: 'בעל חיית מחמד',
                subtitle: 'מחפש/ת מטפל/ת',
                icon: Icons.pets_rounded,
                color: AppColors.walks,
                isSelected: isPetOwner,
                onTap: () => onChanged(true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _RoleTile(
                label: 'מטפל/ת',
                subtitle: 'מציע/ה שירותים',
                icon: Icons.favorite_rounded,
                color: AppColors.sitting,
                isSelected: !isPetOwner,
                onTap: () => onChanged(false),
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
            style: AppTextStyles.caption,
          ),
        ),
      ],
    );
  }
}

class _RoleTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleTile({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.08)
              : AppColors.surfaceBase,
          borderRadius: AppRadius.lgRadius,
          border: Border.all(
            color: isSelected
                ? color.withValues(alpha: 0.50)
                : AppColors.border,
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                color: isSelected ? color : AppColors.textMuted, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppTextStyles.label.copyWith(
                color: isSelected ? color : AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              subtitle,
              style: AppTextStyles.label.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
