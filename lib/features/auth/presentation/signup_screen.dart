import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:petpal/core/theme/app_theme.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _acceptTerms = false;

  // Role selection (PetOwner vs ServiceProvider)
  bool _isPetOwnerSelected = true;

  final _auth = FirebaseAuth.instance;
  final _usersRef = FirebaseFirestore.instance.collection('users');

  void _log(String message, {Object? error, StackTrace? stackTrace}) {
    // ignore: avoid_print
    print('[SignupScreen] $message');
    if (error != null) {
      // ignore: avoid_print
      print('[SignupScreen] error: $error');
    }
    if (stackTrace != null) {
      // ignore: avoid_print
      print('[SignupScreen] stackTrace: $stackTrace');
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
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

  String _friendlyRegisterErrorHe(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'האימייל כבר בשימוש. נסה/י להתחבר או השתמש/י באימייל אחר.';
      case 'invalid-email':
        return 'כתובת האימייל לא תקינה.';
      case 'weak-password':
        return 'הסיסמה חלשה מדי. נסה/י סיסמה חזקה יותר.';
      case 'operation-not-allowed':
        return 'שיטת ההרשמה הזו לא זמינה כרגע.';
      case 'network-request-failed':
        return 'בעיית רשת. בדוק/י את החיבור ונסה/י שוב.';
      default:
        return 'שגיאה בהרשמה. נסה/י שוב.';
    }
  }

  Future<void> _handleSignup() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    _log(
      'attempting signup',
      error:
          'email=$email, nameLength=${name.length}, passwordLength=${password.length}, role=${_isPetOwnerSelected ? 'petOwner' : 'serviceProvider'}',
    );

    if (!_acceptTerms) {
      _showSnack('יש לאשר את תנאי השימוש', isError: true);
      return;
    }
    if (name.isEmpty) {
      _showSnack('אנא הזן/י שם מלא', isError: true);
      return;
    }
    if (email.isEmpty) {
      _showSnack('אנא הזן/י כתובת אימייל', isError: true);
      return;
    }

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(email)) {
      _showSnack('כתובת אימייל לא תקינה', isError: true);
      return;
    }

    if (password.isEmpty) {
      _showSnack('אנא הזן/י סיסמה', isError: true);
      return;
    }
    if (password.length < 6) {
      _showSnack('הסיסמה חייבת להכיל לפחות 6 תווים', isError: true);
      return;
    }
    if (password != confirmPassword) {
      _showSnack('הסיסמאות אינן תואמות', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user?.uid;

      _log('signup success uid=$uid');

      // display name (non-fatal)
      try {
        await credential.user?.updateDisplayName(name);
      } catch (_) {}

      // ✅ Save role in Firestore (non-fatal)
      if (uid != null) {
        try {
          await _usersRef.doc(uid).set(
            {
              'uid': uid,
              'name': name,
              'email': email,
              // ✅ UPDATED: role values
              'role': _isPetOwnerSelected ? 'petOwner' : 'serviceProvider',
              'isVerified': false,
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
          _log('Firestore user doc upserted');
        } catch (e, st) {
          _log('Firestore user doc write failed (non-fatal)',
              error: e, stackTrace: st);
        }
      }

      if (!mounted) return;

      _showSnack('החשבון נוצר בהצלחה ✅');

      // ✅ UPDATED: go to AuthGate (/) after signup so it routes by role
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _showSnack(_friendlyRegisterErrorHe(e), isError: true);
    } catch (e) {
      if (!mounted) return;
      _showSnack('שגיאה לא צפויה. נסה/י שוב.', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Color get _bgTop => const Color(0xFFECFDF5);
  Color get _bgMid => const Color(0xFFF6F7FB);
  Color get _bgBottom => const Color(0xFFFFFFFF);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bgBottom,
        body: Stack(
          children: [
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
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_forward_rounded),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'יצירת חשבון',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Role selection
                    _GlassCard(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'בחר/י סוג משתמש',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: ChoiceChip(
                                  label: const Text('בעל חיית מחמד'),
                                  selected: _isPetOwnerSelected,
                                  onSelected: (v) {
                                    setState(() => _isPetOwnerSelected = true);
                                  },
                                  selectedColor: const Color(0xFF0F766E).withOpacity(0.16),
                                  labelStyle: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: _isPetOwnerSelected
                                        ? const Color(0xFF0F766E)
                                        : const Color(0xFF334155),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    side: BorderSide(
                                      color: _isPetOwnerSelected
                                          ? const Color(0xFF0F766E).withOpacity(0.35)
                                          : const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ChoiceChip(
                                  label: const Text('מטפל/ת'),
                                  selected: !_isPetOwnerSelected,
                                  onSelected: (v) {
                                    setState(() => _isPetOwnerSelected = false);
                                  },
                                  selectedColor: const Color(0xFF0EA5E9).withOpacity(0.16),
                                  labelStyle: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: !_isPetOwnerSelected
                                        ? const Color(0xFF0EA5E9)
                                        : const Color(0xFF334155),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    side: BorderSide(
                                      color: !_isPetOwnerSelected
                                          ? const Color(0xFF0EA5E9).withOpacity(0.35)
                                          : const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _isPetOwnerSelected
                                ? 'לבעלי חיות מחמד שמחפשים דוג-ווקר/סיטר'
                                : 'למטפלים/דוג-ווקרים שמציעים שירותים',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF334155).withOpacity(0.80),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    _GlassCard(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          _InputField(
                            controller: _nameController,
                            label: 'שם מלא',
                            hint: 'הזן/י שם',
                            icon: Icons.badge_outlined,
                          ),
                          const SizedBox(height: 12),
                          _InputField(
                            controller: _emailController,
                            label: 'אימייל',
                            hint: 'name@example.com',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 12),
                          _InputField(
                            controller: _passwordController,
                            label: 'סיסמה',
                            hint: '••••••••',
                            icon: Icons.lock_outline,
                            obscureText: true,
                          ),
                          const SizedBox(height: 12),
                          _InputField(
                            controller: _confirmPasswordController,
                            label: 'אימות סיסמה',
                            hint: '••••••••',
                            icon: Icons.lock_reset_outlined,
                            obscureText: true,
                          ),
                          const SizedBox(height: 14),

                          Row(
                            children: [
                              Checkbox(
                                value: _acceptTerms,
                                onChanged: (v) => setState(() => _acceptTerms = v ?? false),
                                activeColor: const Color(0xFF0F766E),
                              ),
                              Expanded(
                                child: Text(
                                  'אני מאשר/ת את תנאי השימוש והמדיניות',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF334155).withOpacity(0.90),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          _PrimaryGradientButton(
                            text: _isLoading ? 'יוצר חשבון...' : 'צור חשבון',
                            icon: _isLoading ? Icons.hourglass_top_rounded : Icons.check_rounded,
                            onTap: _isLoading ? null : _handleSignup,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'כבר יש לך חשבון?',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF334155).withOpacity(0.85),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pushNamed(context, '/login'),
                          child: const Text(
                            'התחבר/י',
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
